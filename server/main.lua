local QBCore = exports['qb-core']:GetCoreObject()

-- Global variables for store stock management
local StoreStock = {}
local DegradationIntervals = {}
local NeedsRestock = {}

-- Function to ensure database tables are set up correctly
function SetupDatabase()
    -- Check if the player_outfits table needs updates
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `player_outfits` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `citizenid` varchar(50) DEFAULT NULL,
            `outfitname` varchar(50) DEFAULT NULL,
            `outfit` longtext DEFAULT NULL,
            `is_default` tinyint(1) DEFAULT 0,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function()
        -- Check if the columns exist
        MySQL.Async.fetchAll('SHOW COLUMNS FROM player_outfits', {}, function(columns)
            local hasOutfit = false
            local hasIsDefault = false
            
            for i=1, #columns do
                if columns[i].Field == 'outfit' then
                    hasOutfit = true
                end
                if columns[i].Field == 'is_default' then
                    hasIsDefault = true
                end
            end
            
            -- Add the outfit column if it doesn't exist
            if not hasOutfit then
                print("^3[vein-clothing] Adding missing 'outfit' column to player_outfits table^7")
                MySQL.Async.execute('ALTER TABLE player_outfits ADD COLUMN outfit longtext DEFAULT NULL', {})
            end
            
            -- Add the is_default column if it doesn't exist
            if not hasIsDefault then
                print("^3[vein-clothing] Adding missing 'is_default' column to player_outfits table^7")
                MySQL.Async.execute('ALTER TABLE player_outfits ADD COLUMN is_default tinyint(1) DEFAULT 0', {})
            end
        end)
    end)
    
    -- Create other tables if they don't exist
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `player_wishlist` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `citizenid` varchar(50) DEFAULT NULL,
            `item` varchar(50) DEFAULT NULL,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})
    
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `player_clothing_condition` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `citizenid` varchar(50) DEFAULT NULL,
            `item` varchar(50) DEFAULT NULL,
            `condition` int(11) DEFAULT 100,
            `is_dirty` tinyint(1) DEFAULT 0,
            `is_damaged` tinyint(1) DEFAULT 0,
            `last_worn` timestamp NULL DEFAULT NULL,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})
    
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `store_inventory` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `store` varchar(50) DEFAULT NULL,
            `item` varchar(50) DEFAULT NULL,
            `stock` int(11) DEFAULT 0,
            `last_restock` timestamp NULL DEFAULT NULL,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})
    
    print("^2[vein-clothing] Database tables setup complete^7")
end

-- Initialize store stock from config
function InitializeStoreStock()
    for storeType, storeData in pairs(Config.Stores) do
        StoreStock[storeType] = {}
        
        -- Initialize stock based on config
        for _, itemName in ipairs(storeData.inventory) do
            -- Check if the item exists in QBCore.Shared.Items
            if QBCore.Shared.Items[itemName] then
                -- Get rarity with proper nil checking
                local rarity = "common"
                if QBCore.Shared.Items[itemName].client then
                    rarity = QBCore.Shared.Items[itemName].client.rarity or "common"
                end
                
                -- Check if Config.Rarity[rarity] exists and get maxStock
                local maxStock = 10
                if Config.Rarity[rarity] then
                    maxStock = Config.Rarity[rarity].maxStock or 10
                end
                
                StoreStock[storeType][itemName] = {
                    stock = math.random(1, maxStock),
                    maxStock = maxStock,
                    rarity = rarity,
                    lastRestock = os.time()
                }
            else
                print("^1[ERROR] Item not found in QBCore.Shared.Items: " .. itemName .. "^7")
            end
        end
        
        NeedsRestock[storeType] = false
    end
end

-- Function to load store stock from database
function LoadStoreStockFromDatabase()
    MySQL.Async.fetchAll('SELECT * FROM store_inventory', {}, function(results)
        if results and #results > 0 then
            -- Initialize empty store stock if needed
            for storeType, _ in pairs(Config.Stores) do
                if not StoreStock[storeType] then
                    StoreStock[storeType] = {}
                end
            end
            
            -- Load data from database
            for _, row in ipairs(results) do
                local storeType = row.store
                local itemName = row.item
                
                -- Make sure the store type exists in our config
                if Config.Stores[storeType] then
                    -- Make sure the item exists in shared items
                    if QBCore.Shared.Items[itemName] then
                        -- Get rarity
                        local rarity = "common"
                        if QBCore.Shared.Items[itemName].client then
                            rarity = QBCore.Shared.Items[itemName].client.rarity or "common"
                        end
                        
                        -- Get max stock
                        local maxStock = 10
                        if Config.Rarity and Config.Rarity[rarity] then
                            maxStock = Config.Rarity[rarity].maxStock or 10
                        end
                        
                        -- Parse timestamp or use current time - with extra safety checks
                        local lastRestock = os.time()
                        
                        -- Additional safety check to ensure row.last_restock exists and is valid
                        if row.last_restock ~= nil then
                            -- Check if last_restock is a string or a number
                            if type(row.last_restock) == "string" then
                                -- Try to parse the timestamp string
                                local pattern = "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)"
                                local year, month, day, hour, min, sec = row.last_restock:match(pattern)
                                if year then
                                    lastRestock = os.time({
                                        year = tonumber(year),
                                        month = tonumber(month),
                                        day = tonumber(day),
                                        hour = tonumber(hour),
                                        min = tonumber(min),
                                        sec = tonumber(sec)
                                    })
                                end
                            elseif type(row.last_restock) == "number" then
                                -- If it's already a number (UNIX timestamp), use it directly
                                lastRestock = row.last_restock
                            end
                        else
                            print("^3[WARNING] Missing last_restock value for item " .. itemName .. " in store " .. storeType .. ", using current time^7")
                        end
                        
                        -- Store the data
                        StoreStock[storeType][itemName] = {
                            stock = tonumber(row.stock),
                            maxStock = maxStock,
                            rarity = rarity,
                            lastRestock = lastRestock
                        }
                    end
                end
            end
            
            if Config.Debug then
                print("^2[INFO] Store stock loaded from database^7")
            end
        else
            -- No data in database, initialize from config
            print("^3[WARNING] No store stock found in database, initializing from config^7")
            InitializeStoreStock()
        end
    end)
end

-- Function to save store stock to database
function SaveStoreStockToDatabase()
    if not StoreStock then return end
    
    -- First clean up old data
    MySQL.Async.execute('DELETE FROM store_inventory', {}, function()
        -- Now insert fresh data
        for storeType, items in pairs(StoreStock) do
            for itemName, stockData in pairs(items) do
                MySQL.Async.execute('INSERT INTO store_inventory (store, item, stock, last_restock) VALUES (?, ?, ?, ?)', {
                    storeType,
                    itemName,
                    stockData.stock,
                    type(stockData.lastRestock) == "number" and os.date('%Y-%m-%d %H:%M:%S', stockData.lastRestock) or os.date('%Y-%m-%d %H:%M:%S', os.time())
                })
            end
        end
        
        if Config.Debug then
            print("^2[INFO] Store stock saved to database^7")
        end
    end)
end

-- Initialize function (called on script start)
function Initialize()
    -- Set up the database tables first
    SetupDatabase()
    
    -- Initialize store stock from database
    LoadStoreStockFromDatabase()
    
    -- Start periodic functions
    StartPeriodicFunctions()
    
    -- Register callbacks
    RegisterCallbacks()
    
    print("^2[vein-clothing] Initialization completed successfully^7")
end

-- Start periodic functions
function StartPeriodicFunctions()
    -- Restock stores periodically
    CreateThread(function()
        while true do
            Wait(Config.Restocking.Interval * 60 * 1000) -- Convert minutes to milliseconds
            RestockStores()
        end
    end)
    
    -- Update clothing condition for players
    CreateThread(function()
        while true do
            Wait(Config.Condition.DegradationInterval) -- Already in milliseconds
            UpdateClothingCondition()
        end
    end)
    
    -- Periodically save store stock to database
    CreateThread(function()
        while true do
            Wait(300000) -- Save every 5 minutes
            SaveStoreStockToDatabase()
        end
    end)
end

-- Register callbacks
function RegisterCallbacks()
    -- Get store inventory callback
    QBCore.Functions.CreateCallback('vein-clothing:server:getStoreInventory', function(source, cb, storeType)
        if not StoreStock[storeType] then
            cb(nil)
            return
        end
        
        local inventory = {}
        
        for itemName, stockData in pairs(StoreStock[storeType]) do
            if stockData.stock > 0 then
                local item = QBCore.Shared.Items[itemName]
                if item then
                    -- Get price based on rarity and store type
                    local basePrice = item.price or 100
                    local rarityMultiplier = Config.Rarity[stockData.rarity].priceMultiplier or 1.0
                    local storeMultiplier = Config.Stores[storeType].priceMultiplier or 1.0
                    local price = math.floor(basePrice * rarityMultiplier * storeMultiplier)
                    
                    -- Add to inventory
                    table.insert(inventory, {
                        name = itemName,
                        label = item.label,
                        price = price,
                        stock = stockData.stock,
                        rarity = stockData.rarity,
                        category = item.client and item.client.category or "unknown",
                        description = item.description or "",
                        images = item.client and item.client.images or {}
                    })
                end
            end
        end
        
        cb(inventory)
    end)
    
    -- Get store items callback
    QBCore.Functions.CreateCallback('vein-clothing:server:getStoreItems', function(source, cb, storeName, gender)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        
        print("^2[DEBUG-SERVER] getStoreItems callback triggered for store: " .. (storeName or "nil") .. ", gender: " .. (gender or "nil") .. "^7")
        
        if not Player then
            print("^1[ERROR-SERVER] Player not found in getStoreItems callback^7")
            cb(nil, {})
            return
        end
        
        local citizenid = Player.PlayerData.citizenid
        local storeData = Config.Stores[storeName]
        
        if not storeData then
            print("^1[ERROR-SERVER] Store data not found for: " .. (storeName or "nil") .. "^7")
            cb(nil, {})
            return
        end
        
        print("^2[DEBUG-SERVER] Store " .. storeName .. " has " .. #(storeData.inventory or {}) .. " items in inventory config^7")
        
        local storeItems = {}
        
        -- Get items from store inventory
        for _, itemName in ipairs(storeData.inventory or {}) do
            local item = QBCore.Shared.Items[itemName]
            
            if item then
                -- Create default client data if missing
                if not item.client then
                    print("^3[DEBUG-SERVER] Item " .. itemName .. " has no client data, creating default^7")
                    local categoryMap = {
                        -- Improved category mapping with more specific patterns
                        ["shoe"] = "shoes",
                        ["boot"] = "shoes", 
                        ["sneaker"] = "shoes",
                        ["heel"] = "shoes",
                        ["loafer"] = "shoes",
                        ["sandal"] = "shoes",
                        ["slipper"] = "shoes",
                        ["suit"] = "shirts",
                        ["shirt"] = "shirts",
                        ["tshirt"] = "shirts",
                        ["tee"] = "shirts",
                        ["top"] = "shirts",
                        ["jacket"] = "jackets",
                        ["coat"] = "jackets",
                        ["hoodie"] = "jackets",
                        ["sweater"] = "jackets",
                        ["pant"] = "pants",
                        ["jean"] = "pants",
                        ["trouser"] = "pants",
                        ["short"] = "pants",
                        ["skirt"] = "pants",
                        ["hat"] = "hats",
                        ["cap"] = "hats",
                        ["beanie"] = "hats",
                        ["helmet"] = "hats",
                        ["mask"] = "masks",
                        ["glass"] = "glasses",
                        ["watch"] = "accessories",
                        ["jewel"] = "accessories",
                        ["necklace"] = "accessories",
                        ["ring"] = "accessories",
                        ["bracelet"] = "accessories",
                        ["earring"] = "accessories",
                        ["belt"] = "accessories",
                        ["tie"] = "accessories",
                        ["scarf"] = "accessories",
                        ["glove"] = "accessories",
                        ["bag"] = "bags",
                        ["backpack"] = "bags",
                        ["purse"] = "bags"
                    }
                    
                    -- Determine category based on item name with improved matching
                    local category = "shirts" -- Default category
                    local itemNameLower = string.lower(itemName)
                    
                    for keyword, cat in pairs(categoryMap) do
                        if string.find(itemNameLower, keyword) then
                            category = cat
                            print("^3[DEBUG-SERVER] Matched keyword '" .. keyword .. "' for item '" .. itemName .. "', setting category: " .. cat .. "^7")
                            break
                        end
                    end
                    
                    -- Create default client data
                    item.client = {
                        category = category,
                        rarity = "common",
                        gender = "unisex",
                        variations = {
                            {
                                name = "Default",
                                color = "#333333"
                            }
                        },
                        images = {}
                    }
                    
                    print("^3[DEBUG-SERVER] Created default client data with category: " .. category .. "^7")
                end
                
                -- Skip if gender-specific and doesn't match player gender
                if item.client.gender and item.client.gender ~= gender and item.client.gender ~= "unisex" then
                    print("^3[DEBUG-SERVER] Skipping item " .. itemName .. " due to gender mismatch^7")
                    goto continue
                end
                
                -- Calculate price
                local basePrice = item.price or 100
                local rarity = item.client.rarity or "common"
                
                -- Ensure Config.Rarity exists and has the specific rarity
                if not Config.Rarity then
                    print("^1[ERROR-SERVER] Config.Rarity is missing, creating default^7")
                    Config.Rarity = {
                        ["common"] = { priceMultiplier = 1.0, maxStock = 10, minRestock = 1, maxRestock = 5 },
                        ["uncommon"] = { priceMultiplier = 1.5, maxStock = 8, minRestock = 1, maxRestock = 3 },
                        ["rare"] = { priceMultiplier = 2.0, maxStock = 5, minRestock = 1, maxRestock = 2 },
                        ["exclusive"] = { priceMultiplier = 3.0, maxStock = 3, minRestock = 0, maxRestock = 1 },
                        ["limited"] = { priceMultiplier = 5.0, maxStock = 1, minRestock = 0, maxRestock = 1 }
                    }
                end
                
                if not Config.Rarity[rarity] then
                    print("^1[ERROR-SERVER] Rarity " .. rarity .. " not found in Config.Rarity, using common^7")
                    rarity = "common"
                end
                
                local rarityMultiplier = (Config.Rarity[rarity] and Config.Rarity[rarity].priceMultiplier) or 1.0
                local storeMultiplier = storeData.priceMultiplier or 1.0
                local price = math.floor(basePrice * rarityMultiplier * storeMultiplier)
                
                -- Get stock info
                local stock = 10 -- Default stock
                if StoreStock[storeName] and StoreStock[storeName][itemName] then
                    stock = StoreStock[storeName][itemName].stock
                else
                    -- Create default stock entry if missing
                    if not StoreStock[storeName] then
                        StoreStock[storeName] = {}
                    end
                    
                    StoreStock[storeName][itemName] = {
                        stock = stock,
                        maxStock = 10,
                        rarity = rarity,
                        lastRestock = os.time()
                    }
                    
                    print("^3[DEBUG-SERVER] Created default stock entry for " .. itemName .. "^7")
                end
                
                -- Skip if out of stock
                if stock <= 0 then
                    print("^3[DEBUG-SERVER] Skipping item " .. itemName .. " because it's out of stock^7")
                    goto continue
                end
                
                -- Add to store items list
                table.insert(storeItems, {
                    name = itemName,
                    label = item.label or itemName,
                    price = price,
                    stock = stock,
                    rarity = rarity,
                    category = item.client.category or "unknown",
                    description = item.description or "A stylish clothing item.",
                    component = item.client.component,
                    drawable = item.client.drawable,
                    texture = item.client.texture,
                    variations = item.client.variations or {{ name = "Default", color = "#333333" }},
                    gender = item.client.gender or "unisex",
                    images = item.client.images or {}
                })
                
                print("^2[DEBUG-SERVER] Added item " .. itemName .. " to store items list^7")
                
                ::continue::
            else
                print("^1[ERROR-SERVER] Item " .. itemName .. " not found in QBCore.Shared.Items^7")
            end
        end
        
        print("^2[DEBUG-SERVER] Returning " .. #storeItems .. " items to client^7")
        
        -- Get player's wishlist
        local wishlist = {}
        local wishlistResults = MySQL.Sync.fetchAll('SELECT * FROM player_wishlist WHERE citizenid = ?', {citizenid})
        
        if wishlistResults then
            for _, item in ipairs(wishlistResults) do
                table.insert(wishlist, item.item)
            end
        end
        
        cb(storeItems, wishlist)
    end)
    
    -- Purchase item callback
    QBCore.Functions.CreateCallback('vein-clothing:server:purchaseItem', function(source, cb, itemName, price, variation, storeType, paymentMethod)
        -- Add payment method support (cash or bank)
        local paymentSource = paymentMethod or "cash" -- Default to cash if not specified
        
        if paymentSource ~= "cash" and paymentSource ~= "bank" then
            print("^1[ERROR-SERVER] Invalid payment method: " .. tostring(paymentMethod) .. ", defaulting to cash^7")
            paymentSource = "cash"
        end
        
        print("^2[DEBUG-SERVER] Purchase attempt for " .. itemName .. " using payment method: " .. paymentSource .. "^7")
        
        local success, message = PurchaseItem(source, itemName, storeType, paymentSource)
        cb(success, message)
    end)
    
    -- Get player's clothing callback
    QBCore.Functions.CreateCallback('vein-clothing:server:getPlayerClothing', function(source, cb)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        
        if not Player then
            print("^1[ERROR-SERVER] Player not found in getPlayerClothing callback^7")
            cb({}, {}, {})
            return
        end
        
        -- Get all clothing items from player inventory
        local clothing = {}
        local items = Player.PlayerData.items
        
        print("^2[DEBUG-SERVER] Checking " .. (items and #items or 0) .. " items in player inventory^7")
        
        local itemsChecked = 0
        local itemsFound = 0
        local missingClientData = 0
        
        for slot, item in pairs(items) do
            itemsChecked = itemsChecked + 1
            
            -- Debug empty slots
            if item == nil then
                print("^3[DEBUG-SERVER] Found nil item in slot " .. slot .. "^7")
                goto continue
            end
            
            -- Additional category debug
            local hasName = item.name ~= nil
            local isInSharedItems = QBCore.Shared.Items[item.name] ~= nil
            local hasClientData = (isInSharedItems and QBCore.Shared.Items[item.name].client ~= nil) or false
            local hasCategory = (hasClientData and QBCore.Shared.Items[item.name].client.category ~= nil) or false
            
            if hasName and not isInSharedItems then
                print("^1[ERROR-SERVER] Item " .. item.name .. " not found in QBCore.Shared.Items^7")
            elseif hasName and isInSharedItems and not hasClientData then
                print("^3[WARNING-SERVER] Item " .. item.name .. " missing client data^7")
                missingClientData = missingClientData + 1
                
                -- Add default client data for clothing items that lack it
                if string.match(item.name, "shirt") or string.match(item.name, "top") or string.match(item.name, "jacket") or 
                   string.match(item.name, "hoodie") or string.match(item.name, "sweater") or string.match(item.name, "tshirt") then
                    QBCore.Shared.Items[item.name].client = {
                        category = "shirts",
                        component = 11,
                        drawable = 0,
                        texture = 0,
                        rarity = "common",
                        event = "vein-clothing:client:wearItem"
                    }
                    hasClientData = true
                    hasCategory = true
                    print("^2[DEBUG-SERVER] Added shirts category to " .. item.name .. "^7")
                elseif string.match(item.name, "jean") or string.match(item.name, "pant") or string.match(item.name, "trouser") or
                       string.match(item.name, "short") or string.match(item.name, "skirt") then
                    QBCore.Shared.Items[item.name].client = {
                        category = "pants",
                        component = 4,
                        drawable = 0,
                        texture = 0,
                        rarity = "common",
                        event = "vein-clothing:client:wearItem"
                    }
                    hasClientData = true
                    hasCategory = true
                    print("^2[DEBUG-SERVER] Added pants category to " .. item.name .. "^7")
                elseif string.match(item.name, "shoe") or string.match(item.name, "boot") or string.match(item.name, "sneaker") or
                       string.match(item.name, "heel") or string.match(item.name, "footwear") then
                    QBCore.Shared.Items[item.name].client = {
                        category = "shoes",
                        component = 6,
                        drawable = 0,
                        texture = 0,
                        rarity = "common",
                        event = "vein-clothing:client:wearItem"
                    }
                    hasClientData = true
                    hasCategory = true
                    print("^2[DEBUG-SERVER] Added shoes category to " .. item.name .. "^7")
                elseif string.match(item.name, "hat") or string.match(item.name, "cap") or string.match(item.name, "helmet") or
                       string.match(item.name, "beanie") then
                    QBCore.Shared.Items[item.name].client = {
                        category = "hats",
                        component = 0,
                        drawable = 0,
                        texture = 0,
                        rarity = "common",
                        event = "vein-clothing:client:wearProp"
                    }
                    hasClientData = true
                    hasCategory = true
                    print("^2[DEBUG-SERVER] Added hats category to " .. item.name .. "^7")
                elseif string.match(item.name, "glass") or string.match(item.name, "sunglass") or string.match(item.name, "eyewear") then
                    QBCore.Shared.Items[item.name].client = {
                        category = "glasses",
                        component = 1,
                        drawable = 0,
                        texture = 0,
                        rarity = "common",
                        event = "vein-clothing:client:wearProp"
                    }
                    hasClientData = true
                    hasCategory = true
                    print("^2[DEBUG-SERVER] Added glasses category to " .. item.name .. "^7")
                end
            end
            
            -- Only include clothing items (items with client data and category)
            if hasCategory then
                local itemInfo = QBCore.Shared.Items[item.name]
                
                -- Format for UI
                local formattedItem = {
                    name = item.name,
                    label = itemInfo.label,
                    description = itemInfo.description or "",
                    slot = slot,
                    count = item.amount,
                    info = item.info or {},
                    rarity = (itemInfo.client and itemInfo.client.rarity) or "common",
                    category = (itemInfo.client and itemInfo.client.category) or "shirts",
                    component = (itemInfo.client and itemInfo.client.component) or 11
                }
                
                -- Add texture/drawable info if available
                if itemInfo.client then
                    formattedItem.drawable = itemInfo.client.drawable
                    formattedItem.texture = itemInfo.client.texture
                end
                
                -- Add condition info if available
                if item.info and item.info.condition then
                    formattedItem.condition = item.info.condition
                else
                    formattedItem.condition = 100
                end
                
                table.insert(clothing, formattedItem)
                itemsFound = itemsFound + 1
            end
            
            ::continue::
        end
        
        -- Log summary
        print("^2[DEBUG-SERVER] Wardrobe summary: " .. itemsChecked .. " items checked, " .. 
              itemsFound .. " clothing items found, " .. missingClientData .. " missing client data^7")
        
        -- Get player's saved outfits
        local citizenid = Player.PlayerData.citizenid
        local outfits = {}
        
        -- Handle database calls
        MySQL.Async.fetchAll('SELECT * FROM player_outfits WHERE citizenid = ?', {citizenid}, function(outfitResults)
            if outfitResults then
                for _, outfit in ipairs(outfitResults) do
                    -- Look for different column names depending on the database schema
                    local outfitData = json.decode(outfit.outfit or outfit.outfitdata or outfit.outfit_data or outfit.data or "{}")
                    
                    if outfitData then
                        table.insert(outfits, {
                            id = outfit.id,
                            name = outfit.outfitname,
                            outfitData = outfitData
                        })
                    end
                end
            end
            
            -- Get player's wishlist
            MySQL.Async.fetchAll('SELECT * FROM player_wishlist WHERE citizenid = ?', {citizenid}, function(wishlistResults)
                local wishlist = {}
                
                if wishlistResults then
                    for _, item in ipairs(wishlistResults) do
                        table.insert(wishlist, item.item)
                    end
                end
                
                cb(clothing, outfits, wishlist)
            end)
        end)
    end)
    
    -- Get player's default outfit callback
    QBCore.Functions.CreateCallback('vein-clothing:server:getDefaultOutfit', function(source, cb)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        
        if not Player then
            cb(nil)
            return
        end
        
        local citizenid = Player.PlayerData.citizenid
        
        -- First check if we need to use a fallback query
        MySQL.Async.fetchAll('SHOW COLUMNS FROM player_outfits', {}, function(columns)
            local hasIsDefault = false
            local outfitColumnName = 'outfit'
            
            -- Find the columns we need
            for i=1, #columns do
                if columns[i].Field == 'is_default' then
                    hasIsDefault = true
                end
                if columns[i].Field == 'outfit' or columns[i].Field == 'outfitdata' or columns[i].Field == 'outfit_data' or columns[i].Field == 'data' then
                    outfitColumnName = columns[i].Field
                end
            end
            
            if hasIsDefault then
                -- Use the is_default column if it exists
                local query = string.format('SELECT %s FROM player_outfits WHERE citizenid = ? AND is_default = 1 LIMIT 1', outfitColumnName)
                MySQL.Async.fetchScalar(query, {citizenid}, function(result)
                    if result then
                        cb(json.decode(result))
                    else
                        -- Try to get one with outfitname = "default" as a fallback
                        local fallbackQuery = string.format('SELECT %s FROM player_outfits WHERE citizenid = ? AND outfitname = ? LIMIT 1', outfitColumnName)
                        MySQL.Async.fetchScalar(fallbackQuery, {citizenid, "default"}, function(defaultResult)
                            if defaultResult then
                                cb(json.decode(defaultResult))
                            else
                                cb(nil)
                            end
                        end)
                    end
                end)
            else
                -- Fallback to using outfitname = "default"
                local fallbackQuery = string.format('SELECT %s FROM player_outfits WHERE citizenid = ? AND outfitname = ? LIMIT 1', outfitColumnName)
                MySQL.Async.fetchScalar(fallbackQuery, {citizenid, "default"}, function(defaultResult)
                    if defaultResult then
                        cb(json.decode(defaultResult))
                    else
                        cb(nil)
                    end
                end)
            end
        end)
    end)
    
    -- Get specific outfit by ID callback
    QBCore.Functions.CreateCallback('vein-clothing:server:getOutfit', function(source, cb, outfitId)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        
        if not Player then
            cb(nil)
            return
        end
        
        local citizenid = Player.PlayerData.citizenid
        
        -- Get the correct column name
        MySQL.Async.fetchAll('SHOW COLUMNS FROM player_outfits', {}, function(columns)
            local outfitColumnName = 'outfit'
            
            -- Find the actual column that stores outfit data
            for i=1, #columns do
                local column = columns[i].Field
                if column == 'outfit' or column == 'outfitdata' or column == 'outfit_data' or column == 'data' then
                    outfitColumnName = column
                    break
                end
            end
            
            -- Now use the correct column name
            local query = string.format('SELECT %s FROM player_outfits WHERE id = ? AND citizenid = ?', outfitColumnName)
            MySQL.Async.fetchScalar(query, {outfitId, citizenid}, function(result)
                if result then
                    cb(json.decode(result))
                else
                    cb(nil)
                end
            end)
        end)
    end)
    
    -- Get dirty clothing callback
    QBCore.Functions.CreateCallback('vein-clothing:server:getDirtyClothing', function(source, cb)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        
        if not Player then
            cb({})
            return
        end
        
        -- Get all dirty clothing items from player inventory
        local dirtyClothing = {}
        local items = Player.PlayerData.items
        
        for _, item in pairs(items) do
            -- Check if it's a clothing item and is dirty
            if item and item.name and QBCore.Shared.Items[item.name] and QBCore.Shared.Items[item.name].client and QBCore.Shared.Items[item.name].client.category then
                local condition = item.info and item.info.condition or 100
                local isDirty = condition <= Config.Condition.DirtyThreshold
                
                if isDirty then
                    table.insert(dirtyClothing, {
                        name = item.name,
                        label = QBCore.Shared.Items[item.name].label,
                        slot = item.slot,
                        metadata = item.info or {}
                    })
                end
            end
        end
        
        cb(dirtyClothing)
    end)
    
    -- Get damaged clothing callback
    QBCore.Functions.CreateCallback('vein-clothing:server:getDamagedClothing', function(source, cb)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        
        if not Player then
            cb({})
            return
        end
        
        -- Get all damaged clothing items from player inventory
        local damagedClothing = {}
        local items = Player.PlayerData.items
        
        for _, item in pairs(items) do
            -- Check if it's a clothing item and is damaged
            if item and item.name and QBCore.Shared.Items[item.name] and QBCore.Shared.Items[item.name].client and QBCore.Shared.Items[item.name].client.category then
                local condition = item.info and item.info.condition or 100
                local isDamaged = condition <= Config.Condition.DamagedThreshold
                
                if isDamaged then
                    table.insert(damagedClothing, {
                        name = item.name,
                        label = QBCore.Shared.Items[item.name].label,
                        slot = item.slot,
                        metadata = item.info or {}
                    })
                end
            end
        end
        
        cb(damagedClothing)
    end)
    
    -- Restock store callback
    QBCore.Functions.CreateCallback('vein-clothing:server:restockStore', function(source, cb, storeType)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        
        if not Player then
            cb(false)
            return
        end
        
        -- Check permissions
        local hasPermission = false
        for _, group in ipairs(Config.Permissions.Features['restock']) do
            if Player.PlayerData.group == group then
                hasPermission = true
                break
            end
        end
        
        if not hasPermission then
            QBCore.Functions.Notify(src, "You don't have permission to restock stores", "error")
            cb(false)
            return
        end
        
        -- Restock store
        RestockStore(storeType)
        cb(true)
    end)
end

-- Restock a specific store
function RestockStore(storeType)
    if not StoreStock[storeType] then return end
    
    for itemName, stockData in pairs(StoreStock[storeType]) do
        local rarity = stockData.rarity
        local minRestock = Config.Rarity[rarity].minRestock
        local maxRestock = Config.Rarity[rarity].maxRestock
        
        local restockAmount = math.random(minRestock, maxRestock)
        stockData.stock = math.min(stockData.stock + restockAmount, stockData.maxStock)
        stockData.lastRestock = os.time() -- Ensure this is a number (UNIX timestamp)
        
        -- Update database with restock
        MySQL.Async.execute('UPDATE store_inventory SET stock = ?, last_restock = ? WHERE store = ? AND item = ?', {
            stockData.stock,
            os.date('%Y-%m-%d %H:%M:%S', stockData.lastRestock),
            storeType,
            itemName
        }, function(rowsChanged)
            if rowsChanged == 0 then
                -- Record doesn't exist yet, create it
                MySQL.Async.execute('INSERT INTO store_inventory (store, item, stock, last_restock) VALUES (?, ?, ?, ?)', {
                    storeType,
                    itemName,
                    stockData.stock,
                    os.date('%Y-%m-%d %H:%M:%S', stockData.lastRestock)
                })
            end
        end)
    end
    
    NeedsRestock[storeType] = false
    
    if Config.Debug then
        print("^2[INFO] Restocked store: " .. storeType .. "^7")
    end
end

-- Restock stores
function RestockStores()
    for storeType, items in pairs(StoreStock) do
        -- Determine how many items to restock
        local itemsToRestock = math.random(Config.Restocking.MinItems, Config.Restocking.MaxItems)
        local restocked = 0
        
        -- Restock random items
        if not Config.Restocking.RestockAll then
            -- Create a list of items to potentially restock
            local restockCandidates = {}
            for itemName, stockData in pairs(items) do
                if stockData.stock < stockData.maxStock then
                    table.insert(restockCandidates, {
                        name = itemName,
                        data = stockData
                    })
                end
            end
            
            -- Shuffle the candidates
            for i = #restockCandidates, 2, -1 do
                local j = math.random(i)
                restockCandidates[i], restockCandidates[j] = restockCandidates[j], restockCandidates[i]
            end
            
            -- Restock up to itemsToRestock items
            for i = 1, math.min(itemsToRestock, #restockCandidates) do
                local item = restockCandidates[i]
                local itemName = item.name
                
                -- Make sure the item exists in QBCore
                if QBCore.Shared.Items[itemName] then
                    -- Get rarity with proper nil checking
                    local rarity = "common"
                    if QBCore.Shared.Items[itemName].client then
                        rarity = QBCore.Shared.Items[itemName].client.rarity or "common"
                    end
                    
                    -- Check if Config.Rarity[rarity] exists
                    if Config.Rarity[rarity] then
                        local minRestock = Config.Rarity[rarity].minRestock or 1
                        local maxRestock = Config.Rarity[rarity].maxRestock or 3
                        local amountToRestock = math.random(minRestock, maxRestock)
                        
                        local oldStock = StoreStock[storeType][itemName].stock
                        StoreStock[storeType][itemName].stock = math.min(
                            oldStock + amountToRestock,
                            StoreStock[storeType][itemName].maxStock
                        )
                        
                        -- Update lastRestock time
                        StoreStock[storeType][itemName].lastRestock = os.time()
                        
                        restocked = restocked + 1
                    end
                end
            end
        else
            -- Restock all items
            for itemName, stockData in pairs(items) do
                if stockData.stock < stockData.maxStock then
                    -- Make sure the item exists in QBCore
                    if QBCore.Shared.Items[itemName] then
                        -- Get rarity with proper nil checking
                        local rarity = "common"
                        if QBCore.Shared.Items[itemName].client then
                            rarity = QBCore.Shared.Items[itemName].client.rarity or "common"
                        end
                        
                        -- Check if Config.Rarity[rarity] exists
                        if Config.Rarity[rarity] then
                            local minRestock = Config.Rarity[rarity].minRestock or 1
                            local maxRestock = Config.Rarity[rarity].maxRestock or 3
                            local amountToRestock = math.random(minRestock, maxRestock)
                            
                            local oldStock = StoreStock[storeType][itemName].stock
                            StoreStock[storeType][itemName].stock = math.min(
                                oldStock + amountToRestock,
                                StoreStock[storeType][itemName].maxStock
                            )
                            
                            -- Update lastRestock time
                            StoreStock[storeType][itemName].lastRestock = os.time()
                            
                            restocked = restocked + 1
                        end
                    end
                end
            end
        end
        
        -- Print debug information
        if Config.Debug then
            print("^2[INFO] Restocked " .. restocked .. " items for store: " .. storeType .. "^7")
        end
    end
    
    -- Save all store stock to database
    SaveStoreStockToDatabase()
end

-- Update clothing condition for all players
function UpdateClothingCondition()
    local players = QBCore.Functions.GetQBPlayers()
    
    for _, player in pairs(players) do
        local items = player.PlayerData.items
        
        for _, item in pairs(items) do
            if item and item.name and QBCore.Shared.Items[item.name] and QBCore.Shared.Items[item.name].client and QBCore.Shared.Items[item.name].client.category then
                local rarity = QBCore.Shared.Items[item.name].client.rarity or "common"
                local condition = item.info and item.info.condition or 100
                
                -- Calculate degradation based on whether item is worn or stored
                local degradation = 0
                if item.info and item.info.worn then
                    degradation = math.random(Config.Condition.WornDegradationMin, Config.Condition.WornDegradationMax)
                else
                    degradation = math.random(Config.Condition.StoredDegradationMin, Config.Condition.StoredDegradationMax)
                end
                
                -- Apply rarity multiplier to degradation
                local rarityMultiplier = Config.RarityRepairMultiplier[rarity] or 1.0
                degradation = math.floor(degradation * rarityMultiplier)
                
                -- Update condition
                condition = math.max(0, condition - degradation)
                
                -- Update item metadata
                if not item.info then item.info = {} end
                item.info.condition = condition
                
                -- Update item in inventory
                player.Functions.RemoveItem(item.name, 1, item.slot)
                player.Functions.AddItem(item.name, 1, item.slot, item.info)
            end
        end
    end
end

-- Player purchased an item
function PurchaseItem(source, itemName, storeType, paymentMethod)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        return false, "Player not found"
    end
    
    -- Debug output
    print("^2[DEBUG-SERVER] Purchase attempt for " .. itemName .. " using payment method: " .. (paymentMethod or "cash") .. "^7")
    
    local item = QBCore.Shared.Items[itemName]
    
    if not item then
        print("^1[ERROR-SERVER] Item not found in QBCore.Shared.Items: " .. itemName .. "^7")
        return false, "Item not found"
    end
    
    -- Special debug for necklace items
    if string.find(string.lower(itemName), "necklace") or string.find(string.lower(itemName), "chain") or string.find(string.lower(itemName), "pearl") then
        print("^3[NECKLACE-DEBUG] Processing necklace item: " .. itemName .. "^7")
        print("^3[NECKLACE-DEBUG] Item data:")
        print("^3[NECKLACE-DEBUG] - label: " .. tostring(item.label))
        print("^3[NECKLACE-DEBUG] - category: " .. tostring(item.client and item.client.category))
        print("^3[NECKLACE-DEBUG] - component: " .. tostring(item.client and item.client.component))
        print("^3[NECKLACE-DEBUG] - drawable: " .. tostring(item.client and item.client.drawable))
        print("^3[NECKLACE-DEBUG] - texture: " .. tostring(item.client and item.client.texture))
        
        -- Ensure necklace has correct component
        if item.client and not item.client.component then
            item.client.component = 7 -- 7 is for necklaces
            print("^3[NECKLACE-DEBUG] Fixed missing component, set to 7 (necklace)^7")
        end
        
        -- Ensure drawable and texture
        if item.client and not item.client.drawable then
            item.client.drawable = 0
            print("^3[NECKLACE-DEBUG] Fixed missing drawable, set to 0^7")
        end
        
        if item.client and not item.client.texture then
            item.client.texture = 0
            print("^3[NECKLACE-DEBUG] Fixed missing texture, set to 0^7")
        end
    end
    
    -- Verify the item has all required client data
    if not item.client or not item.client.component or not item.client.drawable or not item.client.texture then
        print("^1[ERROR-SERVER] Item missing required client data: " .. itemName .. "^7")
        print("^1[ERROR-SERVER] component: " .. tostring(item.client and item.client.component) .. 
              ", drawable: " .. tostring(item.client and item.client.drawable) .. 
              ", texture: " .. tostring(item.client and item.client.texture) .. "^7")
        
        -- Attempt to fix missing data
        if not item.client then
            item.client = {}
            print("^3[WARNING-SERVER] Created missing client object for: " .. itemName .. "^7")
        end
        
        if not item.client.component then
            item.client.component = 11 -- Default to torso
            print("^3[WARNING-SERVER] Set default component 11 for: " .. itemName .. "^7")
        end
        
        if not item.client.drawable then
            item.client.drawable = 0
            print("^3[WARNING-SERVER] Set default drawable 0 for: " .. itemName .. "^7")
        end
        
        if not item.client.texture then
            item.client.texture = 0
            print("^3[WARNING-SERVER] Set default texture 0 for: " .. itemName .. "^7")
        end
    end
    
    -- Calculate price
    local basePrice = item.price or 100
    local rarity = (item.client and item.client.rarity) or "common"
    
    -- Ensure Config.Rarity exists and has valid entries
    if not Config.Rarity or not Config.Rarity[rarity] or not Config.Rarity[rarity].priceMultiplier then
        print("^1[ERROR-SERVER] Missing rarity config for " .. rarity .. ", using default multiplier^7")
        Config.Rarity = Config.Rarity or {}
        Config.Rarity[rarity] = Config.Rarity[rarity] or { priceMultiplier = 1.0 }
    end
    
    local rarityMultiplier = Config.Rarity[rarity].priceMultiplier or 1.0
    local storeMultiplier = 1.0
    
    -- Apply store multiplier if available
    if storeType and Config.Stores and Config.Stores[storeType] and Config.Stores[storeType].priceMultiplier then
        storeMultiplier = Config.Stores[storeType].priceMultiplier
    end
    
    local price = math.floor(basePrice * rarityMultiplier * storeMultiplier)
    
    -- Check stock
    local hasStock = true
    if StoreStock[storeType] and StoreStock[storeType][itemName] then
        if StoreStock[storeType][itemName].stock <= 0 then
            hasStock = false
        end
    end
    
    if not hasStock then
        return false, "Item out of stock"
    end
    
    -- Modified to support payment method
    local paymentSource = paymentMethod or "cash" -- Default to cash
    local moneyType = paymentSource == "bank" and "bank" or "cash"
    
    -- Check if player has enough money
    if Player.PlayerData.money[moneyType] < price then
        return false, "Not enough " .. moneyType
    end
    
    -- Remove money from player
    Player.Functions.RemoveMoney(moneyType, price)
    
    -- Add item to player inventory with variation data
    local info = {
        variation = 0, -- Default variation
        condition = 100, -- Perfect condition
        dirty = false, -- Not dirty
        purchased = true -- Indicates item was purchased (not found/crafted)
    }
    
    -- Try direct method for items that have issues with HandleInventory
    local added = false
    if string.find(string.lower(itemName), "necklace") or string.find(string.lower(itemName), "chain") or string.find(string.lower(itemName), "pearl") then
        print("^3[NECKLACE-DEBUG] Using direct Player.Functions.AddItem for necklace^7")
        added = Player.Functions.AddItem(itemName, 1, nil, info)
    else
        -- Use the HandleInventory function to add item
        added = HandleInventory('addItem', src, itemName, 1, info)
        
        -- Try direct method if HandleInventory fails
        if not added then
            print("^3[WARNING-SERVER] HandleInventory function failed, trying direct method^7")
            added = Player.Functions.AddItem(itemName, 1, nil, info)
        end
    end
    
    if not added then
        -- Refund the player if the item couldn't be added
        print("^1[ERROR-SERVER] Failed to add item to inventory: " .. itemName .. "^7")
        Player.Functions.AddMoney(moneyType, price)
        return false, "Inventory full or item invalid"
    end
    
    -- Update stock
    if StoreStock[storeType] and StoreStock[storeType][itemName] then
        StoreStock[storeType][itemName].stock = StoreStock[storeType][itemName].stock - 1
        
        -- Save the updated stock to database immediately
        MySQL.Async.execute('UPDATE store_inventory SET stock = ? WHERE store = ? AND item = ?', {
            StoreStock[storeType][itemName].stock,
            storeType,
            itemName
        }, function(rowsChanged)
            if rowsChanged == 0 then
                -- Record doesn't exist yet, create it
                MySQL.Async.execute('INSERT INTO store_inventory (store, item, stock, last_restock) VALUES (?, ?, ?, ?)', {
                    storeType,
                    itemName,
                    StoreStock[storeType][itemName].stock,
                    type(StoreStock[storeType][itemName].lastRestock) == "number" and os.date('%Y-%m-%d %H:%M:%S', StoreStock[storeType][itemName].lastRestock) or os.date('%Y-%m-%d %H:%M:%S', os.time())
                })
            end
        end)
    end
    
    -- Log the transaction
    print("^2[vein-clothing] Player " .. Player.PlayerData.citizenid .. " purchased " .. itemName .. " for $" .. price .. " using " .. moneyType .. "^7")
    
    -- Refresh player inventory
    TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[itemName], "add")
    
    return true, "Item purchased"
end

-- Expose functions for export
exports('purchaseItem', PurchaseItem)
exports('restockStore', function(storeType)
    if not StoreStock[storeType] then
        return false, "Store not found"
    end
    
    NeedsRestock[storeType] = true
    RestockStores()
    return true, "Store restocked"
end)

exports('addShopItem', function(storeType, itemName, amount)
    if not StoreStock[storeType] then
        return false, "Store not found"
    end
    
    if not QBCore.Shared.Items[itemName] then
        return false, "Item not found"
    end
    
    if not StoreStock[storeType][itemName] then
        -- Get rarity
        local rarity = QBCore.Shared.Items[itemName].client and QBCore.Shared.Items[itemName].client.rarity or "common"
        local maxStock = Config.Rarity[rarity].maxStock or 10
        
        -- Add to store inventory
        StoreStock[storeType][itemName] = {
            stock = amount or 1,
            maxStock = maxStock,
            rarity = rarity,
            lastRestock = os.time()
        }
        
        -- Add to store config for persistence
        table.insert(Config.Stores[storeType].inventory, itemName)
    else
        -- Add to existing stock
        local currentStock = StoreStock[storeType][itemName].stock
        local maxStock = StoreStock[storeType][itemName].maxStock
        
        StoreStock[storeType][itemName].stock = math.min(currentStock + (amount or 1), maxStock)
    end
    
    return true, "Item added to store"
end)

exports('removeShopItem', function(storeType, itemName, amount)
    if not StoreStock[storeType] or not StoreStock[storeType][itemName] then
        return false, "Item not found in store"
    end
    
    local currentStock = StoreStock[storeType][itemName].stock
    local removeAmount = amount or currentStock
    
    if removeAmount >= currentStock then
        -- Remove from inventory table
        for i, item in ipairs(Config.Stores[storeType].inventory) do
            if item == itemName then
                table.remove(Config.Stores[storeType].inventory, i)
                break
            end
        end
        
        -- Remove from stock
        StoreStock[storeType][itemName] = nil
    else
        -- Reduce stock
        StoreStock[storeType][itemName].stock = currentStock - removeAmount
    end
    
    return true, "Item removed from store"
end)

-- Function to get all clothing items in the game
exports('getAllClothing', function()
    local clothing = {}
    
    for name, item in pairs(QBCore.Shared.Items) do
        if item.client and item.client.category then
            table.insert(clothing, {
                name = name,
                label = item.label,
                category = item.client.category,
                rarity = item.client.rarity or "common",
                description = item.description or "",
                price = item.price or 100
            })
        end
    end
    
    return clothing
end)

-- Function to handle server-side inventory operations based on config
function HandleInventory(action, source, ...)
    local args = {...}
    local inventoryType = Config.Inventory.Type
    
    if action == 'addItem' then
        local item, amount, metadata = args[1], args[2] or 1, args[3] or nil
        if inventoryType == 'qb-inventory' then
            return exports['qb-core']:GetCoreObject().Functions.AddItem(source, item, amount, metadata)
        elseif inventoryType == 'ox_inventory' then
            return exports.ox_inventory:AddItem(source, item, amount, metadata)
        elseif inventoryType == 'custom' then
            -- Custom inventory add item
            return exports[Config.Inventory.ResourceName][Config.Inventory.Custom.AddItem](source, item, amount, metadata)
        end
    elseif action == 'removeItem' then
        local item, amount, metadata = args[1], args[2] or 1, args[3] or nil
        if inventoryType == 'qb-inventory' then
            return exports['qb-core']:GetCoreObject().Functions.RemoveItem(source, item, amount, metadata)
        elseif inventoryType == 'ox_inventory' then
            return exports.ox_inventory:RemoveItem(source, item, amount, metadata)
        elseif inventoryType == 'custom' then
            -- Custom inventory remove item
            return exports[Config.Inventory.ResourceName][Config.Inventory.Custom.RemoveItem](source, item, amount, metadata)
        end
    elseif action == 'getItem' then
        local item = args[1]
        if inventoryType == 'qb-inventory' then
            return exports['qb-core']:GetCoreObject().Shared.Items[item]
        elseif inventoryType == 'ox_inventory' then
            return exports.ox_inventory:Items()[item]
        elseif inventoryType == 'custom' then
            -- Custom inventory get item
            return exports[Config.Inventory.ResourceName][Config.Inventory.Custom.GetItemLabel](item)
        end
    elseif action == 'notification' then
        local item, type, qty = args[1], args[2], args[3] or 1
        if inventoryType == 'qb-inventory' then
            TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[item], type, qty)
        elseif inventoryType == 'ox_inventory' then
            local title = type == 'add' and 'Item Added' or 'Item Removed'
            TriggerClientEvent('ox_inventory:notify', source, {
                title = title,
                description = QBCore.Shared.Items[item].label .. ' x' .. qty,
                type = type == 'add' and 'success' or 'error'
            })
        elseif inventoryType == 'custom' then
            -- Custom inventory notification
            TriggerClientEvent(Config.Inventory.Custom.TriggerEvent, source, item, type, qty)
        end
    elseif action == 'hasItem' then
        local item, amount = args[1], args[2] or 1
        if inventoryType == 'qb-inventory' then
            return exports['qb-core']:GetCoreObject().Functions.HasItem(source, item, amount)
        elseif inventoryType == 'ox_inventory' then
            return exports.ox_inventory:GetItemCount(source, item) >= amount
        elseif inventoryType == 'custom' then
            -- Custom inventory check
            return exports[Config.Inventory.ResourceName][Config.Inventory.Custom.HasItem](source, item, amount)
        end
    end
    
    return false
end

-- Function to check if player can afford an item
function CanPlayerAfford(source, price)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local money = Player.Functions.GetMoney('cash')
    return money >= price
end

-- Function to remove money from player
function RemovePlayerMoney(source, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    Player.Functions.RemoveMoney('cash', amount)
    return true
end

-- Update existing callbacks and events to use the new functions
QBCore.Functions.CreateCallback('vein-clothing:server:buyItem', function(source, cb, item, price, storeId)
    if not CanPlayerAfford(source, price) then
        TriggerClientEvent('QBCore:Notify', source, "You don't have enough money", 'error')
        cb(false)
        return
    end
    
    -- Remove money from player
    RemovePlayerMoney(source, price)
    
    -- Add item to player's inventory
    local success = HandleInventory('addItem', source, item, 1)
    if success then
        -- Update store stock
        UpdateStoreStock(storeId, item, -1)
        cb(true)
    else
        -- Refund player if item couldn't be added
        local Player = QBCore.Functions.GetPlayer(source)
        Player.Functions.AddMoney('cash', price)
        cb(false)
    end
end)

-- Example of updated event handler
RegisterNetEvent('vein-clothing:server:degradeClothing', function(item, amount)
    local src = source
    if not item or not amount then return end
    
    -- Get player identifier
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Update clothing condition in database
    UpdateClothingCondition(citizenid, item, amount)
end)

-- Register all clothing items as useable
Citizen.CreateThread(function()
    -- Wait a moment to ensure all items are loaded
    Citizen.Wait(1000)
    
    print("^2[vein-clothing] Registering useable clothing items...^7")
    local registeredCount = 0
    
    -- Loop through all items to find clothing
    for itemName, item in pairs(QBCore.Shared.Items) do
        if item.client and (item.client.category or item.client.component) then
            -- Determine if it's a prop or regular clothing
            local isProp = (item.client.type == 'prop' or 
                           (item.client.category and 
                            (item.client.category == 'hats' or 
                             item.client.category == 'glasses' or 
                             item.client.category == 'ears' or 
                             item.client.category == 'watches' or 
                             item.client.category == 'bracelets')))
            
            -- Register the item as useable
            QBCore.Functions.CreateUseableItem(itemName, function(source, itemData)
                local Player = QBCore.Functions.GetPlayer(source)
                if not Player then return end
                
                local fullItemData = QBCore.Shared.Items[itemName]
                if not fullItemData or not fullItemData.client then
                    print("^1[ERROR] Missing client data for item: " .. itemName .. "^7")
                    return
                end
                
                -- Make a complete item object to pass to client
                local clientItem = {
                    name = itemName,
                    label = fullItemData.label,
                    client = {
                        component = fullItemData.client.component,
                        drawable = fullItemData.client.drawable,
                        texture = fullItemData.client.texture,
                        category = fullItemData.client.category,
                        event = isProp and "vein-clothing:client:wearProp" or "vein-clothing:client:wearItem"
                    }
                }
                
                -- Additional logging to debug
                if Config.Debug then
                    print("^2[vein-clothing] Using item " .. itemName .. " (component: " .. 
                          tostring(fullItemData.client.component) .. ", drawable: " .. 
                          tostring(fullItemData.client.drawable) .. ", texture: " .. 
                          tostring(fullItemData.client.texture) .. ")^7")
                end
                
                if isProp then
                    -- Trigger prop wear event
                    TriggerClientEvent('vein-clothing:client:wearProp', source, clientItem)
                else
                    -- Trigger regular clothing wear event
                    TriggerClientEvent('vein-clothing:client:wearItem', source, clientItem)
                end
                
                -- Log the clothing usage
                if Config.Debug then
                    print("^2[vein-clothing] Player " .. Player.PlayerData.citizenid .. " used clothing item: " .. itemName .. "^7")
                end
            end)
            
            registeredCount = registeredCount + 1
        end
    end
    
    print("^2[vein-clothing] Successfully registered " .. registeredCount .. " useable clothing items^7")
end)

-- Main Initialize function - called when resource starts
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    print("^2[vein-clothing] Initializing clothing system...^7")
    
    -- Wait for QB-Core to fully load
    Wait(1000)
    
    -- Initialize the clothing system
    Initialize()
    
    print("^2[vein-clothing] Clothing system initialized successfully!^7")
end)

-- Handle resource stopping
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    print("^3[vein-clothing] Clothing system shutting down...^7")
    
    -- Save store stock to database
    SaveStoreStockToDatabase()
    
    print("^3[vein-clothing] Clothing system shutdown complete.^7")
end)

-- Call Initialize manually to ensure it runs
CreateThread(function()
    Wait(2000) -- Wait for everything to load
    Initialize()
end)

-- Export vanilla clothes for other resources
exports('GetVanillaClothes', function()
    return Config.VanillaClothes
end)

-- Register vanilla clothes as items
Citizen.CreateThread(function()
    Citizen.Wait(2000) -- Wait for QBCore to fully load
    
    print("^2[vein-clothing] Registering vanilla clothing items in QBCore.Shared.Items...^7")
    local registeredCount = 0
    
    -- Helper function to register a clothing item
    local function RegisterClothingItem(name, data)
        -- Skip if item already exists
        if QBCore.Shared.Items[name] then
            return false
        end
        
        -- Create the item data
        QBCore.Shared.Items[name] = {
            name = name,
            label = data.label,
            weight = 250,
            type = 'item',
            image = name .. '.png', -- You may need to add these images
            unique = true,
            useable = true,
            shouldClose = true,
            combinable = nil,
            description = data.description or "A clothing item",
            price = data.price or 100,
            client = {
                category = data.category,
                component = data.component,
                drawable = data.drawable,
                texture = data.texture,
                rarity = data.rarity or "common",
                gender = (name:find("_f") and "female") or "male",
                event = data.type == "prop" and "vein-clothing:client:wearProp" or "vein-clothing:client:wearItem"
            }
        }
        
        return true
    end
    
    -- Register male clothing
    for category, items in pairs(Config.VanillaClothes.male) do
        for _, item in ipairs(items) do
            if RegisterClothingItem(item.name, item) then
                registeredCount = registeredCount + 1
            end
        end
    end
    
    -- Register female clothing
    for category, items in pairs(Config.VanillaClothes.female) do
        for _, item in ipairs(items) do
            if RegisterClothingItem(item.name, item) then
                registeredCount = registeredCount + 1
            end
        end
    end
    
    print("^2[vein-clothing] Successfully registered " .. registeredCount .. " vanilla clothing items^7")
    
    -- Add vanilla clothing to store inventory database after a brief delay
    Citizen.Wait(3000)
    PopulateStoreInventories()
end)

-- Function to populate store inventories with vanilla clothing
function PopulateStoreInventories()
    print("^2[vein-clothing] Populating store inventories with vanilla clothing...^7")
    
    -- Define which items go in which stores
    local storeInventories = {
        ['suburban'] = {
            -- Male items (corrected to match the vanilla_clothes.lua file)
            male = {"white_tshirt", "black_tshirt", "red_tshirt", "hoodie_black", "hoodie_gray", 
                "jeans_blue", "jeans_black", "sneakers_white", "sneakers_black", "cap_black", "cap_blue"},
            -- Female items (corrected to match the vanilla_clothes.lua file)
            female = {"white_tanktop", "black_tanktop", "tshirt_white_f", "tshirt_black_f", 
                "jeans_blue_f", "jeans_black_f", "shorts_f", "sneakers_white_f", "cap_pink"}
        },
        ['ponsonbys'] = {
            -- Male items (corrected to match the vanilla_clothes.lua file)
            male = {"suit_black", "suit_blue", "suit_pants_black", "suit_pants_blue", 
                "dress_shoes_black", "dress_shoes_brown", "watch_classic", "sunglasses_black"},
            -- Female items (corrected to match the vanilla_clothes.lua file)
            female = {"suit_jacket_f", "suit_pants_f", "heels_black", "blouse_white", 
                "necklace_pearl", "watch_gold_f", "sunglasses_cat"}
        }
    }
    
    -- Check each store type in the store inventory
    for storeType, genderItems in pairs(storeInventories) do
        -- Make sure the store exists in Config.Stores
        if not Config.Stores[storeType] then
            print("^3[WARNING] Store type " .. storeType .. " not found in Config.Stores, skipping^7")
            goto continue_store
        end
        
        -- Process male items for this store
        for _, itemName in ipairs(genderItems.male) do
            -- Make sure the item exists in QBCore.Shared.Items
            if not QBCore.Shared.Items[itemName] then
                print("^1[ERROR] Item " .. itemName .. " not found in QBCore.Shared.Items^7")
                goto continue_item_male
            end
            
            -- Ensure item has proper client data with component, drawable, texture
            if not QBCore.Shared.Items[itemName].client then
                QBCore.Shared.Items[itemName].client = {}
                print("^3[DEBUG-ITEMS] Adding missing client object to item: " .. itemName .. "^7")
            end
            
            -- Add default component based on category if missing
            if not QBCore.Shared.Items[itemName].client.component then
                -- Determine category from name if not set
                local category = "shirts"
                local itemNameLower = string.lower(itemName)
                
                if string.find(itemNameLower, "pant") or string.find(itemNameLower, "jean") or string.find(itemNameLower, "trouser") then
                    category = "pants"
                    QBCore.Shared.Items[itemName].client.component = 4 -- Legs
                elseif string.find(itemNameLower, "shoe") or string.find(itemNameLower, "boot") or string.find(itemNameLower, "sneaker") then
                    category = "shoes"
                    QBCore.Shared.Items[itemName].client.component = 6 -- Feet
                elseif string.find(itemNameLower, "hat") or string.find(itemNameLower, "cap") or string.find(itemNameLower, "helmet") then
                    category = "hats"
                    QBCore.Shared.Items[itemName].client.component = 0 -- Head props
                elseif string.find(itemNameLower, "glass") or string.find(itemNameLower, "sunglass") then
                    category = "glasses"
                    QBCore.Shared.Items[itemName].client.component = 1 -- Eye props
                elseif string.find(itemNameLower, "watch") then
                    category = "accessories"
                    QBCore.Shared.Items[itemName].client.component = 6 -- Wrist
                elseif string.find(itemNameLower, "necklace") or string.find(itemNameLower, "chain") then
                    category = "accessories"
                    QBCore.Shared.Items[itemName].client.component = 7 -- Neck
                else
                    -- Default to torso
                    QBCore.Shared.Items[itemName].client.component = 11 -- Torso
                end
                
                QBCore.Shared.Items[itemName].client.category = QBCore.Shared.Items[itemName].client.category or category
                print("^3[DEBUG-ITEMS] Added component " .. QBCore.Shared.Items[itemName].client.component .. " to item: " .. itemName .. "^7")
            end
            
            -- Add default drawable/texture if missing
            if not QBCore.Shared.Items[itemName].client.drawable then
                QBCore.Shared.Items[itemName].client.drawable = 0
                print("^3[DEBUG-ITEMS] Added default drawable 0 to item: " .. itemName .. "^7")
            end
            
            if not QBCore.Shared.Items[itemName].client.texture then
                QBCore.Shared.Items[itemName].client.texture = 0
                print("^3[DEBUG-ITEMS] Added default texture 0 to item: " .. itemName .. "^7")
            end
            
            -- Create stock data
            local rarity = QBCore.Shared.Items[itemName].client and QBCore.Shared.Items[itemName].client.rarity or "common"
            local maxStock = (Config.Rarity[rarity] and Config.Rarity[rarity].maxStock) or 10
            local stock = math.random(1, maxStock)
            
            -- Add to StoreStock
            StoreStock[storeType][itemName] = {
                stock = stock, 
                maxStock = maxStock,
                rarity = rarity,
                lastRestock = os.time()
            }
            
            -- Force insert into database
            MySQL.Async.fetchScalar('SELECT COUNT(*) FROM store_inventory WHERE store = ? AND item = ?', {
                storeType,
                itemName
            }, function(count)
                if count and count > 0 then
                    -- Update existing record
                    MySQL.Async.execute('UPDATE store_inventory SET stock = ?, last_restock = ? WHERE store = ? AND item = ?', {
                        stock,
                        os.date('%Y-%m-%d %H:%M:%S', os.time()),
                        storeType,
                        itemName
                    }, function(rowsAffected)
                        print("^2[DATABASE] Updated item " .. itemName .. " for store " .. storeType .. " (Rows affected: " .. tostring(rowsAffected) .. ")^7")
                    end)
                else
                    -- Insert new record
                    MySQL.Async.execute('INSERT INTO store_inventory (store, item, stock, last_restock) VALUES (?, ?, ?, ?)', {
                        storeType,
                        itemName,
                        stock,
                        os.date('%Y-%m-%d %H:%M:%S', os.time())
                    }, function(rowsAffected)
                        print("^2[DATABASE] Inserted item " .. itemName .. " for store " .. storeType .. " (Rows affected: " .. tostring(rowsAffected) .. ")^7")
                    end)
                end
            end)
            
            -- Add to store config inventory
            local found = false
            for _, item in ipairs(Config.Stores[storeType].inventory) do
                if item == itemName then
                    found = true
                    break
                end
            end
            
            if not found then
                table.insert(Config.Stores[storeType].inventory, itemName)
            end
            
            addedItems = addedItems + 1
            print("^2[SUCCESS] Added " .. itemName .. " to " .. storeType .. " (Stock: " .. stock .. ")^7")
            
            ::continue_item_male::
        end
        
        -- Process female items for this store
        for _, itemName in ipairs(genderItems.female) do
            -- Make sure the item exists in QBCore.Shared.Items
            if not QBCore.Shared.Items[itemName] then
                print("^1[ERROR] Item " .. itemName .. " not found in QBCore.Shared.Items^7")
                goto continue_item_female
            end
            
            -- Ensure item has proper client data with component, drawable, texture
            if not QBCore.Shared.Items[itemName].client then
                QBCore.Shared.Items[itemName].client = {}
                print("^3[DEBUG-ITEMS] Adding missing client object to item: " .. itemName .. "^7")
            end
            
            -- Add default component based on category if missing
            if not QBCore.Shared.Items[itemName].client.component then
                -- Determine category from name if not set
                local category = "shirts"
                local itemNameLower = string.lower(itemName)
                
                if string.find(itemNameLower, "pant") or string.find(itemNameLower, "jean") or string.find(itemNameLower, "trouser") or string.find(itemNameLower, "skirt") then
                    category = "pants"
                    QBCore.Shared.Items[itemName].client.component = 4 -- Legs
                elseif string.find(itemNameLower, "shoe") or string.find(itemNameLower, "boot") or string.find(itemNameLower, "heel") or string.find(itemNameLower, "sneaker") then
                    category = "shoes"
                    QBCore.Shared.Items[itemName].client.component = 6 -- Feet
                elseif string.find(itemNameLower, "hat") or string.find(itemNameLower, "cap") or string.find(itemNameLower, "helmet") then
                    category = "hats"
                    QBCore.Shared.Items[itemName].client.component = 0 -- Head props
                elseif string.find(itemNameLower, "glass") or string.find(itemNameLower, "sunglass") then
                    category = "glasses"
                    QBCore.Shared.Items[itemName].client.component = 1 -- Eye props
                elseif string.find(itemNameLower, "watch") then
                    category = "accessories"
                    QBCore.Shared.Items[itemName].client.component = 6 -- Wrist
                elseif string.find(itemNameLower, "necklace") or string.find(itemNameLower, "pearl") or string.find(itemNameLower, "chain") then
                    category = "accessories"
                    QBCore.Shared.Items[itemName].client.component = 7 -- Neck / Neck accessories
                elseif string.find(itemNameLower, "earring") then
                    category = "accessories"
                    QBCore.Shared.Items[itemName].client.component = 2 -- Ears
                else
                    -- Default to torso
                    QBCore.Shared.Items[itemName].client.component = 11 -- Torso
                end
                
                QBCore.Shared.Items[itemName].client.category = QBCore.Shared.Items[itemName].client.category or category
                print("^3[DEBUG-ITEMS] Added component " .. QBCore.Shared.Items[itemName].client.component .. " to item: " .. itemName .. "^7")
            end
            
            -- Add default drawable/texture if missing
            if not QBCore.Shared.Items[itemName].client.drawable then
                QBCore.Shared.Items[itemName].client.drawable = 0
                print("^3[DEBUG-ITEMS] Added default drawable 0 to item: " .. itemName .. "^7")
            end
            
            if not QBCore.Shared.Items[itemName].client.texture then
                QBCore.Shared.Items[itemName].client.texture = 0
                print("^3[DEBUG-ITEMS] Added default texture 0 to item: " .. itemName .. "^7")
            end
            
            -- Create stock data
            local rarity = QBCore.Shared.Items[itemName].client and QBCore.Shared.Items[itemName].client.rarity or "common"
            local maxStock = (Config.Rarity[rarity] and Config.Rarity[rarity].maxStock) or 10
            local stock = math.random(1, maxStock)
            
            -- Add to StoreStock
            StoreStock[storeType][itemName] = {
                stock = stock, 
                maxStock = maxStock,
                rarity = rarity,
                lastRestock = os.time()
            }
            
            -- Force insert into database
            MySQL.Async.fetchScalar('SELECT COUNT(*) FROM store_inventory WHERE store = ? AND item = ?', {
                storeType,
                itemName
            }, function(count)
                if count and count > 0 then
                    -- Update existing record
                    MySQL.Async.execute('UPDATE store_inventory SET stock = ?, last_restock = ? WHERE store = ? AND item = ?', {
                        stock,
                        os.date('%Y-%m-%d %H:%M:%S', os.time()),
                        storeType,
                        itemName
                    }, function(rowsAffected)
                        print("^2[DATABASE] Updated item " .. itemName .. " for store " .. storeType .. " (Rows affected: " .. tostring(rowsAffected) .. ")^7")
                    end)
                else
                    -- Insert new record
                    MySQL.Async.execute('INSERT INTO store_inventory (store, item, stock, last_restock) VALUES (?, ?, ?, ?)', {
                        storeType,
                        itemName,
                        stock,
                        os.date('%Y-%m-%d %H:%M:%S', os.time())
                    }, function(rowsAffected)
                        print("^2[DATABASE] Inserted item " .. itemName .. " for store " .. storeType .. " (Rows affected: " .. tostring(rowsAffected) .. ")^7")
                    end)
                end
            end)
            
            -- Add to store config inventory
            local found = false
            for _, item in ipairs(Config.Stores[storeType].inventory) do
                if item == itemName then
                    found = true
                    break
                end
            end
            
            if not found then
                table.insert(Config.Stores[storeType].inventory, itemName)
            end
            
            addedItems = addedItems + 1
            print("^2[SUCCESS] Added " .. itemName .. " to " .. storeType .. " (Stock: " .. stock .. ")^7")
            
            ::continue_item_female::
        end
        
        ::continue_store::
    end
    
    print("^2[vein-clothing] Successfully populated store inventories with vanilla clothing^7")
end

-- Function to manually refresh store inventory
function RefreshStoreInventories()
    print("^2[vein-clothing] Manually refreshing store inventories...^7")
    PopulateStoreInventories()
end

-- Register command to refresh store inventories
RegisterCommand("refreshclothingstores", function(source, args)
    -- Only allow server console or admins to use this command
    if source == 0 then
        RefreshStoreInventories()
    else
        local Player = QBCore.Functions.GetPlayer(source)
        if Player and Player.PlayerData.group == "admin" then
            RefreshStoreInventories()
            TriggerClientEvent('QBCore:Notify', source, "Store inventories refreshed", "success")
        else
            TriggerClientEvent('QBCore:Notify', source, "You don't have permission to use this command", "error")
        end
    end
end, true)

-- Register command to manually trigger vanilla clothing population
RegisterCommand("addvanillaclothes", function(source)
    local src = source
    
    -- Allow anyone to run the command for testing purposes
    if src == 0 then -- Called from server console
        AddVanillaClothes()
    else -- Called by a player
        AddVanillaClothes()
        TriggerClientEvent('QBCore:Notify', src, "Added vanilla clothes to database", "success")
    end
end, false) -- Changed to false to make it unrestricted

-- Function to add vanilla clothes and force database updates
function AddVanillaClothes()
    print("^2[vein-clothing] Starting vanilla clothes population...^7")
    
    -- Initialize counter for added items
    local addedItems = 0
    
    -- First, register items in QBCore.Shared.Items if not already there
    local registeredCount = 0
    
    -- Helper function to register a clothing item
    local function RegisterClothingItem(name, data)
        -- Skip if item already exists
        if QBCore.Shared.Items[name] then
            print("^3[INFO] Item " .. name .. " already exists in QBCore.Shared.Items^7")
            return false
        end
        
        -- Create the item data
        QBCore.Shared.Items[name] = {
            name = name,
            label = data.label,
            weight = 250,
            type = 'item',
            image = name .. '.png', -- You may need to add these images
            unique = true,
            useable = true,
            shouldClose = true,
            combinable = nil,
            description = data.description or "A clothing item",
            price = data.price or 100,
            client = {
                category = data.category,
                component = data.component,
                drawable = data.drawable,
                texture = data.texture,
                rarity = data.rarity or "common",
                gender = (name:find("_f") and "female") or "male",
                event = data.type == "prop" and "vein-clothing:client:wearProp" or "vein-clothing:client:wearItem"
            }
        }
        
        print("^2[SUCCESS] Registered item " .. name .. " in QBCore.Shared.Items^7")
        return true
    end
    
    -- Make sure Config.VanillaClothes exists
    if not Config.VanillaClothes then
        print("^1[ERROR] Config.VanillaClothes is missing!^7")
        return
    end
    
    -- Register male clothing
    print("^3[INFO] Registering male clothing items...^7")
    for category, items in pairs(Config.VanillaClothes.male) do
        for _, item in ipairs(items) do
            if RegisterClothingItem(item.name, item) then
                registeredCount = registeredCount + 1
            end
        end
    end
    
    -- Register female clothing
    print("^3[INFO] Registering female clothing items...^7")
    for category, items in pairs(Config.VanillaClothes.female) do
        for _, item in ipairs(items) do
            if RegisterClothingItem(item.name, item) then
                registeredCount = registeredCount + 1
            end
        end
    end
    
    print("^2[SUCCESS] Registered " .. registeredCount .. " vanilla clothing items^7")
    
    -- Now manually populate the store inventories
    print("^3[INFO] Now populating store inventories with vanilla clothing...^7")
    local addedItems = 0
    
    -- Define which items go in which stores
    local storeInventories = {
        ['suburban'] = {
            -- Male items
            male = {"white_tshirt", "black_tshirt", "red_tshirt", "hoodie_black", "hoodie_gray", 
                "jeans_blue", "jeans_black", "sneakers_white", "sneakers_black", "cap_black", "cap_blue"},
            -- Female items
            female = {"white_tanktop", "black_tanktop", "tshirt_white_f", "tshirt_black_f", 
                "jeans_blue_f", "jeans_black_f", "shorts_f", "sneakers_white_f", "cap_pink"}
        },
        ['ponsonbys'] = {
            -- Male items
            male = {"suit_black", "suit_blue", "suit_pants_black", "suit_pants_blue", 
                "dress_shoes_black", "dress_shoes_brown", "watch_classic", "sunglasses_black"},
            -- Female items
            female = {"suit_jacket_f", "suit_pants_f", "heels_black", "blouse_white", 
                "necklace_pearl", "watch_gold_f", "sunglasses_cat"}
        }
    }
    
    -- Loop through each store
    for storeType, genderItems in pairs(storeInventories) do
        -- Make sure the store exists in Config.Stores
        if not Config.Stores[storeType] then
            print("^1[ERROR] Store " .. storeType .. " not found in Config.Stores^7")
            goto continue_store
        end
        
        print("^3[INFO] Adding items to store: " .. storeType .. "^7")
        
        -- Initialize StoreStock for this store if needed
        if not StoreStock[storeType] then
            StoreStock[storeType] = {}
        end
        
        -- Process male items
        for _, itemName in ipairs(genderItems.male) do
            if not QBCore.Shared.Items[itemName] then
                print("^1[ERROR] Item " .. itemName .. " not found in QBCore.Shared.Items^7")
                goto continue_item_male
            end
            
            -- Create stock data
            local rarity = QBCore.Shared.Items[itemName].client and QBCore.Shared.Items[itemName].client.rarity or "common"
            local maxStock = (Config.Rarity[rarity] and Config.Rarity[rarity].maxStock) or 10
            local stock = math.random(1, maxStock)
            
            -- Add to StoreStock
            StoreStock[storeType][itemName] = {
                stock = stock, 
                maxStock = maxStock,
                rarity = rarity,
                lastRestock = os.time()
            }
            
            -- Force insert into database
            MySQL.Async.fetchScalar('SELECT COUNT(*) FROM store_inventory WHERE store = ? AND item = ?', {
                storeType,
                itemName
            }, function(count)
                if count and count > 0 then
                    -- Update existing record
                    MySQL.Async.execute('UPDATE store_inventory SET stock = ?, last_restock = ? WHERE store = ? AND item = ?', {
                        stock,
                        os.date('%Y-%m-%d %H:%M:%S', os.time()),
                        storeType,
                        itemName
                    }, function(rowsAffected)
                        print("^2[DATABASE] Updated item " .. itemName .. " for store " .. storeType .. " (Rows affected: " .. tostring(rowsAffected) .. ")^7")
                    end)
                else
                    -- Insert new record
                    MySQL.Async.execute('INSERT INTO store_inventory (store, item, stock, last_restock) VALUES (?, ?, ?, ?)', {
                        storeType,
                        itemName,
                        stock,
                        os.date('%Y-%m-%d %H:%M:%S', os.time())
                    }, function(rowsAffected)
                        print("^2[DATABASE] Inserted item " .. itemName .. " for store " .. storeType .. " (Rows affected: " .. tostring(rowsAffected) .. ")^7")
                    end)
                end
            end)
            
            -- Add to store config inventory
            local found = false
            for _, item in ipairs(Config.Stores[storeType].inventory) do
                if item == itemName then
                    found = true
                    break
                end
            end
            
            if not found then
                table.insert(Config.Stores[storeType].inventory, itemName)
            end
            
            addedItems = addedItems + 1
            print("^2[SUCCESS] Added " .. itemName .. " to " .. storeType .. " (Stock: " .. stock .. ")^7")
            
            ::continue_item_male::
        end
        
        -- Process female items (similar to male items)
        for _, itemName in ipairs(genderItems.female) do
            -- Make sure the item exists in QBCore.Shared.Items
            if not QBCore.Shared.Items[itemName] then
                print("^1[ERROR] Item " .. itemName .. " not found in QBCore.Shared.Items^7")
                goto continue_item_female
            end
            
            -- Ensure item has proper client data with component, drawable, texture
            if not QBCore.Shared.Items[itemName].client then
                QBCore.Shared.Items[itemName].client = {}
                print("^3[DEBUG-ITEMS] Adding missing client object to item: " .. itemName .. "^7")
            end
            
            -- Add default component based on category if missing
            if not QBCore.Shared.Items[itemName].client.component then
                -- Determine category from name if not set
                local category = "shirts"
                local itemNameLower = string.lower(itemName)
                
                if string.find(itemNameLower, "pant") or string.find(itemNameLower, "jean") or string.find(itemNameLower, "trouser") or string.find(itemNameLower, "skirt") then
                    category = "pants"
                    QBCore.Shared.Items[itemName].client.component = 4 -- Legs
                elseif string.find(itemNameLower, "shoe") or string.find(itemNameLower, "boot") or string.find(itemNameLower, "heel") or string.find(itemNameLower, "sneaker") then
                    category = "shoes"
                    QBCore.Shared.Items[itemName].client.component = 6 -- Feet
                elseif string.find(itemNameLower, "hat") or string.find(itemNameLower, "cap") or string.find(itemNameLower, "helmet") then
                    category = "hats"
                    QBCore.Shared.Items[itemName].client.component = 0 -- Head props
                elseif string.find(itemNameLower, "glass") or string.find(itemNameLower, "sunglass") then
                    category = "glasses"
                    QBCore.Shared.Items[itemName].client.component = 1 -- Eye props
                elseif string.find(itemNameLower, "watch") then
                    category = "accessories"
                    QBCore.Shared.Items[itemName].client.component = 6 -- Wrist
                elseif string.find(itemNameLower, "necklace") or string.find(itemNameLower, "pearl") or string.find(itemNameLower, "chain") then
                    category = "accessories"
                    QBCore.Shared.Items[itemName].client.component = 7 -- Neck / Neck accessories
                elseif string.find(itemNameLower, "earring") then
                    category = "accessories"
                    QBCore.Shared.Items[itemName].client.component = 2 -- Ears
                else
                    -- Default to torso
                    QBCore.Shared.Items[itemName].client.component = 11 -- Torso
                end
                
                QBCore.Shared.Items[itemName].client.category = QBCore.Shared.Items[itemName].client.category or category
                print("^3[DEBUG-ITEMS] Added component " .. QBCore.Shared.Items[itemName].client.component .. " to item: " .. itemName .. "^7")
            end
            
            -- Add default drawable/texture if missing
            if not QBCore.Shared.Items[itemName].client.drawable then
                QBCore.Shared.Items[itemName].client.drawable = 0
                print("^3[DEBUG-ITEMS] Added default drawable 0 to item: " .. itemName .. "^7")
            end
            
            if not QBCore.Shared.Items[itemName].client.texture then
                QBCore.Shared.Items[itemName].client.texture = 0
                print("^3[DEBUG-ITEMS] Added default texture 0 to item: " .. itemName .. "^7")
            end
            
            -- Create stock data
            local rarity = QBCore.Shared.Items[itemName].client and QBCore.Shared.Items[itemName].client.rarity or "common"
            local maxStock = (Config.Rarity[rarity] and Config.Rarity[rarity].maxStock) or 10
            local stock = math.random(1, maxStock)
            
            -- Add to StoreStock
            StoreStock[storeType][itemName] = {
                stock = stock, 
                maxStock = maxStock,
                rarity = rarity,
                lastRestock = os.time()
            }
            
            -- Force insert into database
            MySQL.Async.fetchScalar('SELECT COUNT(*) FROM store_inventory WHERE store = ? AND item = ?', {
                storeType,
                itemName
            }, function(count)
                if count and count > 0 then
                    -- Update existing record
                    MySQL.Async.execute('UPDATE store_inventory SET stock = ?, last_restock = ? WHERE store = ? AND item = ?', {
                        stock,
                        os.date('%Y-%m-%d %H:%M:%S', os.time()),
                        storeType,
                        itemName
                    }, function(rowsAffected)
                        print("^2[DATABASE] Updated item " .. itemName .. " for store " .. storeType .. " (Rows affected: " .. tostring(rowsAffected) .. ")^7")
                    end)
                else
                    -- Insert new record
                    MySQL.Async.execute('INSERT INTO store_inventory (store, item, stock, last_restock) VALUES (?, ?, ?, ?)', {
                        storeType,
                        itemName,
                        stock,
                        os.date('%Y-%m-%d %H:%M:%S', os.time())
                    }, function(rowsAffected)
                        print("^2[DATABASE] Inserted item " .. itemName .. " for store " .. storeType .. " (Rows affected: " .. tostring(rowsAffected) .. ")^7")
                    end)
                end
            end)
            
            -- Add to store config inventory
            local found = false
            for _, item in ipairs(Config.Stores[storeType].inventory) do
                if item == itemName then
                    found = true
                    break
                end
            end
            
            if not found then
                table.insert(Config.Stores[storeType].inventory, itemName)
            end
            
            addedItems = addedItems + 1
            print("^2[SUCCESS] Added " .. itemName .. " to " .. storeType .. " (Stock: " .. stock .. ")^7")
            
            ::continue_item_female::
        end
        
        ::continue_store::
    end
    
    print("^2[SUCCESS] Added/Updated " .. addedItems .. " vanilla clothing items to stores^7")
    print("^2[vein-clothing] Vanilla clothes population completed!^7")
    
    -- Register items as usable again
    RegisterClothingAsUsable()
end

-- Function to register all clothing items as usable
function RegisterClothingAsUsable()
    print("^3[INFO] Registering all clothing items as usable...^7")
    local registeredCount = 0
    
    -- Loop through all items to find clothing
    for itemName, item in pairs(QBCore.Shared.Items) do
        if item.client and (item.client.category or item.client.component) then
            -- Determine if it's a prop or regular clothing
            local isProp = (item.client.type == 'prop' or 
                           (item.client.category and 
                            (item.client.category == 'hats' or 
                             item.client.category == 'glasses' or 
                             item.client.category == 'ears' or 
                             item.client.category == 'watches' or 
                             item.client.category == 'bracelets')))
            
            -- Enhanced debugging output
            print("^3[CLOTHING-ITEM] Registering item: " .. itemName .. 
                " - Component: " .. tostring(item.client.component) .. 
                " - Drawable: " .. tostring(item.client.drawable) .. 
                " - Texture: " .. tostring(item.client.texture) .. 
                " - Category: " .. tostring(item.client.category) .. 
                " - Type: " .. (isProp and "prop" or "component") .. "^7")
            
            -- Register the item as useable
            QBCore.Functions.CreateUseableItem(itemName, function(source, itemData)
                local Player = QBCore.Functions.GetPlayer(source)
                if not Player then return end
                
                local fullItemData = QBCore.Shared.Items[itemName]
                if not fullItemData or not fullItemData.client then
                    print("^1[ERROR] Missing client data for item: " .. itemName .. "^7")
                    return
                end
                
                -- Make a complete item object to pass to client
                local clientItem = {
                    name = itemName,
                    label = fullItemData.label,
                    client = {
                        component = fullItemData.client.component,
                        drawable = fullItemData.client.drawable,
                        texture = fullItemData.client.texture,
                        category = fullItemData.client.category,
                        event = isProp and "vein-clothing:client:wearProp" or "vein-clothing:client:wearItem"
                    }
                }
                
                -- Additional debug logging
                print("^2[USE-CLOTHING] Player " .. Player.PlayerData.citizenid .. " is using clothing item: " .. 
                    itemName .. " (Component: " .. tostring(fullItemData.client.component) .. 
                    ", Drawable: " .. tostring(fullItemData.client.drawable) .. 
                    ", Texture: " .. tostring(fullItemData.client.texture) .. ")^7")
                
                if isProp then
                    -- Trigger prop wear event
                    TriggerClientEvent('vein-clothing:client:wearProp', source, clientItem)
                else
                    -- Trigger regular clothing wear event
                    TriggerClientEvent('vein-clothing:client:wearItem', source, clientItem)
                end
            end)
            
            registeredCount = registeredCount + 1
        end
    end
    
    print("^2[SUCCESS] Registered " .. registeredCount .. " clothing items as usable^7")
end 