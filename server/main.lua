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

-- Initialize function (called on script start)
function Initialize()
    -- Set up the database tables first
    SetupDatabase()
    
    -- Initialize store stock
    InitializeStoreStock()
    
    -- Start periodic functions
    StartPeriodicFunctions()
    
    -- Register callbacks
    RegisterCallbacks()
    
    print("^2[vein-clothing] Initialization completed successfully^7")
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
                        ["suit"] = "shirts",
                        ["dress"] = "shirts",
                        ["shoes"] = "shoes",
                        ["watch"] = "accessories",
                        ["glasses"] = "glasses",
                        ["hat"] = "hats",
                        ["mask"] = "masks",
                        ["pants"] = "pants"
                    }
                    
                    -- Determine category based on item name
                    local category = "shirts" -- Default category
                    for keyword, cat in pairs(categoryMap) do
                        if string.find(string.lower(itemName), keyword) then
                            category = cat
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
    QBCore.Functions.CreateCallback('vein-clothing:server:purchaseItem', function(source, cb, itemName, price, variation, storeType)
        local success, message = PurchaseItem(source, itemName, storeType)
        cb(success, message)
    end)
    
    -- Get player's clothing callback
    QBCore.Functions.CreateCallback('vein-clothing:server:getPlayerClothing', function(source, cb)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        
        if not Player then
            cb({}, {}, {})
            return
        end
        
        -- Get all clothing items from player inventory
        local clothing = {}
        local items = Player.PlayerData.items
        
        for _, item in pairs(items) do
            -- Check if it's a clothing item
            if item and item.name and QBCore.Shared.Items[item.name] and QBCore.Shared.Items[item.name].client and QBCore.Shared.Items[item.name].client.category then
                table.insert(clothing, {
                    name = item.name,
                    label = QBCore.Shared.Items[item.name].label,
                    slot = item.slot,
                    metadata = item.info or {},
                    category = QBCore.Shared.Items[item.name].client.category,
                    rarity = QBCore.Shared.Items[item.name].client.rarity or "common"
                })
            end
        end
        
        -- Get player's outfits
        local citizenid = Player.PlayerData.citizenid
        local outfits = {}
        
        local results = MySQL.Sync.fetchAll('SELECT * FROM player_outfits WHERE citizenid = ?', {citizenid})
        
        if results then
            for _, outfit in ipairs(results) do
                table.insert(outfits, {
                    id = outfit.id,
                    name = outfit.outfitname,
                    items = json.decode(outfit.outfit),
                    isDefault = outfit.is_default == 1
                })
            end
        end
        
        -- Get player's wishlist
        local wishlist = {}
        
        local wishlistResults = MySQL.Sync.fetchAll('SELECT * FROM player_wishlist WHERE citizenid = ?', {citizenid})
        
        if wishlistResults then
            for _, item in ipairs(wishlistResults) do
                table.insert(wishlist, item.item)
            end
        end
        
        cb(clothing, outfits, wishlist)
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
        stockData.lastRestock = os.time()
    end
    
    NeedsRestock[storeType] = false
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
                        
                        StoreStock[storeType][itemName].stock = math.min(
                            StoreStock[storeType][itemName].stock + amountToRestock,
                            StoreStock[storeType][itemName].maxStock
                        )
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
                            
                            StoreStock[storeType][itemName].stock = math.min(
                                StoreStock[storeType][itemName].stock + amountToRestock,
                                StoreStock[storeType][itemName].maxStock
                            )
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

-- Initialize on resource start
Initialize()

-- Player purchased an item
function PurchaseItem(source, itemName, storeType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        return false, "Player not found"
    end
    
    if not StoreStock[storeType] or not StoreStock[storeType][itemName] then
        return false, "Item not available in this store"
    end
    
    -- Check if item is in stock
    if StoreStock[storeType][itemName].stock <= 0 then
        return false, "Item out of stock"
    end
    
    -- Calculate price
    local item = QBCore.Shared.Items[itemName]
    if not item then
        return false, "Item not found"
    end
    
    local stockData = StoreStock[storeType][itemName]
    local rarityMultiplier = Config.Rarity[stockData.rarity].priceMultiplier or 1.0
    local storeMultiplier = Config.Stores[storeType].priceMultiplier or 1.0
    local price = math.floor((item.price or 100) * rarityMultiplier * storeMultiplier)
    
    -- Check if player has enough money
    local playerMoney = Player.PlayerData.money.cash
    if playerMoney < price then
        return false, "Not enough money"
    end
    
    -- Remove money
    if not Player.Functions.RemoveMoney('cash', price) then
        return false, "Failed to remove money"
    end
    
    -- Add item to player inventory with metadata
    local metadata = {
        condition = 100,
        lastWorn = 0,
        dirty = false,
        variation = 0
    }
    
    local success = Player.Functions.AddItem(itemName, 1, nil, metadata)
    
    if not success then
        -- Refund money if item couldn't be added
        Player.Functions.AddMoney('cash', price)
        return false, "Inventory full"
    end
    
    -- Reduce stock
    StoreStock[storeType][itemName].stock = StoreStock[storeType][itemName].stock - 1
    
    -- Check if store needs restock
    local needsRestock = true
    for _, stockData in pairs(StoreStock[storeType]) do
        if stockData.stock > 0 then
            needsRestock = false
            break
        end
    end
    
    if needsRestock then
        NeedsRestock[storeType] = true
    end
    
    -- Notify player
    TriggerClientEvent('vein-clothing:client:itemPurchased', src, itemName, Config.Stores[storeType].label)
    
    return true, "Purchase successful"
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
function HandleInventory(action, ...)
    local args = {...}
    local inventoryType = Config.Inventory.Type
    local source = args[1]
    
    if action == 'addItem' then
        local item, amount, metadata = args[2], args[3] or 1, args[4] or nil
        if inventoryType == 'qb-inventory' then
            return exports['qb-core']:GetCoreObject().Functions.AddItem(source, item, amount, metadata)
        elseif inventoryType == 'ox_inventory' then
            return exports.ox_inventory:AddItem(source, item, amount, metadata)
        elseif inventoryType == 'custom' then
            -- Custom inventory add item
            return exports[Config.Inventory.ResourceName][Config.Inventory.Custom.AddItem](source, item, amount, metadata)
        end
    elseif action == 'removeItem' then
        local item, amount, metadata = args[2], args[3] or 1, args[4] or nil
        if inventoryType == 'qb-inventory' then
            return exports['qb-core']:GetCoreObject().Functions.RemoveItem(source, item, amount, metadata)
        elseif inventoryType == 'ox_inventory' then
            return exports.ox_inventory:RemoveItem(source, item, amount, metadata)
        elseif inventoryType == 'custom' then
            -- Custom inventory remove item
            return exports[Config.Inventory.ResourceName][Config.Inventory.Custom.RemoveItem](source, item, amount, metadata)
        end
    elseif action == 'getItem' then
        local item = args[2]
        if inventoryType == 'qb-inventory' then
            return exports['qb-core']:GetCoreObject().Shared.Items[item]
        elseif inventoryType == 'ox_inventory' then
            return exports.ox_inventory:Items()[item]
        elseif inventoryType == 'custom' then
            -- Custom inventory get item
            return exports[Config.Inventory.ResourceName][Config.Inventory.Custom.GetItemLabel](item)
        end
    elseif action == 'hasItem' then
        local item, amount = args[2], args[3] or 1
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
    
    -- Save any persistent data here if needed
    
    print("^3[vein-clothing] Clothing system shutdown complete.^7")
end)

-- Call Initialize manually to ensure it runs
CreateThread(function()
    Wait(2000) -- Wait for everything to load
    Initialize()
end) 