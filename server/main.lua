local QBCore = exports['qb-core']:GetCoreObject()

-- Initialize server-side data
local StoreInventory = {}
local ClothingStock = {}

-- Load store inventory data on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    print("^2[clothing-system] ^7Loading store inventories...")
    LoadStoreInventories()
    
    -- Set up restock timer if stock system is enabled
    if Config.StockSystem then
        CreateThread(function()
            while true do
                RestockAllStores()
                Wait(Config.RestockInterval * 60 * 60 * 1000) -- Convert hours to milliseconds
            end
        end)
    end
end)

-- Load store inventories from config and database
function LoadStoreInventories()
    for store, data in pairs(Config.Stores) do
        StoreInventory[store] = data.inventory
        
        if Config.StockSystem then
            -- Load stock data from DB
            MySQL.Async.fetchAll('SELECT * FROM clothing_stores WHERE store = ?', {store}, function(results)
                ClothingStock[store] = {}
                
                -- Initialize stock data for this store
                if results and #results > 0 then
                    for _, item in ipairs(results) do
                        ClothingStock[store][item.item] = item.stock
                    end
                else
                    -- Create initial stock entries for this store
                    for _, item in ipairs(data.inventory) do
                        local initialStock = math.random(5, 15)
                        ClothingStock[store][item] = initialStock
                        
                        MySQL.Async.execute('INSERT INTO clothing_stores (store, item, stock) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE stock = ?', 
                            {store, item, initialStock, initialStock})
                    end
                end
            end)
        end
    end
    
    print("^2[clothing-system] ^7Store inventories loaded successfully")
end

-- Restock all stores
function RestockAllStores()
    if not Config.StockSystem then return end
    
    print("^2[clothing-system] ^7Restocking all clothing stores...")
    
    for store, _ in pairs(Config.Stores) do
        for item, _ in pairs(ClothingStock[store] or {}) do
            -- Random restock amount based on rarity
            local itemData = QBCore.Shared.Items[item]
            local rarity = itemData and itemData.client and itemData.client.rarity or "common"
            
            local restockAmount = 0
            if rarity == "common" then
                restockAmount = math.random(5, 10)
            elseif rarity == "uncommon" then
                restockAmount = math.random(3, 7)
            elseif rarity == "rare" then
                restockAmount = math.random(1, 4)
            elseif rarity == "exclusive" then
                restockAmount = math.random(1, 2)
            elseif rarity == "limited" then
                restockAmount = math.random(0, 1)
            end
            
            if restockAmount > 0 then
                ClothingStock[store][item] = (ClothingStock[store][item] or 0) + restockAmount
                
                MySQL.Async.execute('UPDATE clothing_stores SET stock = ?, last_restock = CURRENT_TIMESTAMP WHERE store = ? AND item = ?',
                    {ClothingStock[store][item], store, item})
            end
        end
    end
    
    print("^2[clothing-system] ^7All clothing stores restocked")
end

-- Get store inventory callback
QBCore.Functions.CreateCallback('clothing-system:server:getStoreInventory', function(source, cb, storeName)
    local store = Config.Stores[storeName]
    if not store then
        cb(false)
        return
    end
    
    if Config.StockSystem then
        -- Filter out of stock items
        local inventory = {}
        for _, item in ipairs(store.inventory) do
            if ClothingStock[storeName] and ClothingStock[storeName][item] and ClothingStock[storeName][item] > 0 then
                table.insert(inventory, item)
            end
        end
        cb(inventory)
    else
        -- Return full inventory if stock system is disabled
        cb(store.inventory)
    end
end)

-- Purchase clothing item callback
QBCore.Functions.CreateCallback('clothing-system:server:purchaseItem', function(source, cb, itemName, price, variation, storeName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        cb(false, "Player not found")
        return
    end
    
    -- Check if item exists
    local item = QBCore.Shared.Items[itemName]
    if not item then
        cb(false, "Item not found")
        return
    end
    
    -- Check if item is in stock for this store
    if Config.StockSystem then
        if not ClothingStock[storeName] or not ClothingStock[storeName][itemName] or ClothingStock[storeName][itemName] <= 0 then
            cb(false, "Item out of stock")
            return
        end
    end
    
    -- Check if player has enough money
    local playerMoney = Player.PlayerData.money["cash"]
    if playerMoney < price then
        cb(false, "Not enough money")
        return
    end
    
    -- Create item object with metadata for variations
    local itemMetadata = {}
    if variation > 0 and item.client and item.client.variations and item.client.variations[variation + 1] then
        itemMetadata.variation = variation
        itemMetadata.texture = item.client.variations[variation + 1].texture
    end
    
    -- Add condition metadata
    itemMetadata.condition = 100 -- New item starts at 100% condition
    
    -- Remove money & add item to inventory
    if Player.Functions.RemoveMoney("cash", price) then
        if Player.Functions.AddItem(itemName, 1, nil, itemMetadata) then
            -- Update stock if stock system is enabled
            if Config.StockSystem then
                ClothingStock[storeName][itemName] = ClothingStock[storeName][itemName] - 1
                MySQL.Async.execute('UPDATE clothing_stores SET stock = stock - 1 WHERE store = ? AND item = ?', {storeName, itemName})
            end
            
            -- Log purchase
            TriggerEvent('qb-log:server:CreateLog', 'clothing', 'Item Purchased', 'green', 
                string.format('%s purchased %s for $%d', Player.PlayerData.name, item.label, price))
            
            cb(true)
        else
            -- Refund money if inventory full
            Player.Functions.AddMoney("cash", price)
            cb(false, "Inventory full")
        end
    else
        cb(false, "Transaction failed")
    end
end)

-- Get player's clothing inventory, saved outfits, and wishlist
QBCore.Functions.CreateCallback('clothing-system:server:getPlayerClothing', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        cb(false)
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Get all clothing items from player's inventory
    local clothing = {}
    for _, item in pairs(Player.PlayerData.items) do
        -- Check if it's a clothing item (has client data with category)
        if item and item.name and QBCore.Shared.Items[item.name] and QBCore.Shared.Items[item.name].client and 
           QBCore.Shared.Items[item.name].client.category then
            -- Add item to clothing list with slot info
            table.insert(clothing, {
                name = item.name,
                label = item.label,
                slot = item.slot,
                info = item.info, -- Contains metadata like condition and variation
                category = QBCore.Shared.Items[item.name].client.category,
                drawable = QBCore.Shared.Items[item.name].client.drawable,
                texture = item.info and item.info.texture or QBCore.Shared.Items[item.name].client.texture,
                variations = QBCore.Shared.Items[item.name].client.variations or {},
                component = QBCore.Shared.Items[item.name].client.component,
                gender = QBCore.Shared.Items[item.name].client.gender,
                condition = item.info and item.info.condition or 100,
                rarity = QBCore.Shared.Items[item.name].client.rarity or "common",
                event = QBCore.Shared.Items[item.name].client.event
            })
        end
    end
    
    -- Get player's saved outfits
    MySQL.Async.fetchAll('SELECT * FROM player_outfits WHERE citizenid = ?', {citizenid}, function(outfitsResults)
        local outfits = {}
        
        if outfitsResults and #outfitsResults > 0 then
            for _, outfit in ipairs(outfitsResults) do
                table.insert(outfits, {
                    id = outfit.id,
                    name = outfit.outfitname,
                    items = json.decode(outfit.outfit)
                })
            end
        end
        
        -- Get player's wishlist
        MySQL.Async.fetchAll('SELECT * FROM player_wishlist WHERE citizenid = ?', {citizenid}, function(wishlistResults)
            local wishlist = {}
            
            if wishlistResults and #wishlistResults > 0 then
                for _, wishlistItem in ipairs(wishlistResults) do
                    local item = QBCore.Shared.Items[wishlistItem.item]
                    if item then
                        table.insert(wishlist, {
                            name = wishlistItem.item,
                            label = item.label,
                            category = item.client and item.client.category or "unknown",
                            rarity = item.client and item.client.rarity or "common",
                            variations = item.client and item.client.variations or {}
                        })
                    end
                end
            end
            
            cb(clothing, outfits, wishlist)
        end)
    end)
end)

-- Get dirty clothing (condition < 50)
QBCore.Functions.CreateCallback('clothing-system:server:getDirtyClothing', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        cb(false)
        return
    end
    
    local dirtyClothing = {}
    
    for _, item in pairs(Player.PlayerData.items) do
        if item and item.name and QBCore.Shared.Items[item.name] and QBCore.Shared.Items[item.name].client and 
           QBCore.Shared.Items[item.name].client.category then
            -- Check if item is dirty (condition < 50)
            local condition = item.info and item.info.condition or 100
            if condition < 50 then
                table.insert(dirtyClothing, {
                    name = item.name,
                    label = item.label,
                    slot = item.slot,
                    condition = condition,
                    rarity = QBCore.Shared.Items[item.name].client and QBCore.Shared.Items[item.name].client.rarity or "common"
                })
            end
        end
    end
    
    cb(dirtyClothing)
end)

-- Get damaged clothing (condition < 30)
QBCore.Functions.CreateCallback('clothing-system:server:getDamagedClothing', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        cb(false)
        return
    end
    
    local damagedClothing = {}
    
    for _, item in pairs(Player.PlayerData.items) do
        if item and item.name and QBCore.Shared.Items[item.name] and QBCore.Shared.Items[item.name].client and 
           QBCore.Shared.Items[item.name].client.category then
            -- Check if item is damaged (condition < 30)
            local condition = item.info and item.info.condition or 100
            if condition < 30 then
                table.insert(damagedClothing, {
                    name = item.name,
                    label = item.label,
                    slot = item.slot,
                    condition = condition,
                    rarity = QBCore.Shared.Items[item.name].client and QBCore.Shared.Items[item.name].client.rarity or "common"
                })
            end
        end
    end
    
    cb(damagedClothing)
end)

-- Wash clothing
QBCore.Functions.CreateCallback('clothing-system:server:washClothing', function(source, cb, itemName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        cb(false, "Player not found")
        return
    end
    
    -- Find item in inventory
    local item = nil
    for _, invItem in pairs(Player.PlayerData.items) do
        if invItem and invItem.name == itemName then
            item = invItem
            break
        end
    end
    
    if not item then
        cb(false, "Item not found in inventory")
        return
    end
    
    -- Check if player has enough money
    if Player.PlayerData.money["cash"] < Config.Condition.washCost then
        cb(false, "Not enough money")
        return
    end
    
    -- Get current condition
    local condition = item.info and item.info.condition or 100
    
    -- Check if washing is needed
    if condition >= 95 then
        cb(false, "This item doesn't need washing")
        return
    end
    
    -- Remove money
    if Player.Functions.RemoveMoney("cash", Config.Condition.washCost) then
        -- Update item condition
        local info = item.info or {}
        info.condition = math.min(95, condition + 50) -- Washing improves condition by 50%, max 95%
        
        -- Update item in inventory
        Player.Functions.UpdateItemInfo(item.slot, info)
        
        -- Update in database
        TriggerEvent('clothing-system:server:syncClothingCondition', src, itemName, info.condition)
        
        cb(true)
    else
        cb(false, "Transaction failed")
    end
end)

-- Repair clothing
QBCore.Functions.CreateCallback('clothing-system:server:repairClothing', function(source, cb, itemName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        cb(false, "Player not found")
        return
    end
    
    -- Find item in inventory
    local item = nil
    for _, invItem in pairs(Player.PlayerData.items) do
        if invItem and invItem.name == itemName then
            item = invItem
            break
        end
    end
    
    if not item then
        cb(false, "Item not found in inventory")
        return
    end
    
    -- Get item rarity for repair cost
    local itemData = QBCore.Shared.Items[itemName]
    local rarity = itemData and itemData.client and itemData.client.rarity or "common"
    local repairCost = Config.Condition.repairCosts[rarity] or Config.Condition.repairCosts.common
    
    -- Check if player has enough money
    if Player.PlayerData.money["cash"] < repairCost then
        cb(false, "Not enough money (Costs $" .. repairCost .. ")")
        return
    end
    
    -- Get current condition
    local condition = item.info and item.info.condition or 100
    
    -- Check if repair is needed
    if condition >= 95 then
        cb(false, "This item doesn't need repairs")
        return
    end
    
    -- Remove money
    if Player.Functions.RemoveMoney("cash", repairCost) then
        -- Update item condition to 100%
        local info = item.info or {}
        info.condition = 100
        
        -- Update item in inventory
        Player.Functions.UpdateItemInfo(item.slot, info)
        
        -- Update in database
        TriggerEvent('clothing-system:server:syncClothingCondition', src, itemName, info.condition)
        
        cb(true)
    else
        cb(false, "Transaction failed")
    end
end)

-- Update wishlist event
RegisterNetEvent('clothing-system:server:updateWishlist', function(wishlist)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Delete current wishlist items for this player
    MySQL.Async.execute('DELETE FROM player_wishlist WHERE citizenid = ?', {citizenid})
    
    -- Add new wishlist items
    for _, item in ipairs(wishlist) do
        MySQL.Async.execute('INSERT INTO player_wishlist (citizenid, item) VALUES (?, ?)', {citizenid, item.name})
    end
end)

-- Save outfit event
RegisterNetEvent('clothing-system:server:saveOutfit', function(outfit)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local outfitName = outfit.name
    local outfitItems = json.encode(outfit.items)
    
    -- Check if player has reached outfit limit
    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM player_outfits WHERE citizenid = ?', {citizenid}, function(count)
        if count >= Config.MaxOutfits then
            TriggerClientEvent('QBCore:Notify', src, "You've reached the maximum number of outfits (" .. Config.MaxOutfits .. ")", "error")
            return
        end
        
        -- Save new outfit
        MySQL.Async.execute('INSERT INTO player_outfits (citizenid, outfitname, outfit) VALUES (?, ?, ?)', 
            {citizenid, outfitName, outfitItems})
            
        TriggerClientEvent('QBCore:Notify', src, "Outfit saved: " .. outfitName, "success")
    end)
end)

-- Wear saved outfit event
RegisterNetEvent('clothing-system:server:wearOutfit', function(outfitName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Find outfit by name
    MySQL.Async.fetchAll('SELECT * FROM player_outfits WHERE citizenid = ? AND outfitname = ?', {citizenid, outfitName}, function(results)
        if not results or #results == 0 then
            TriggerClientEvent('QBCore:Notify', src, "Outfit not found: " .. outfitName, "error")
            return
        end
        
        local outfit = json.decode(results[1].outfit)
        
        -- Check if player has all the items in the outfit
        local hasAllItems = true
        local missingItems = {}
        
        for _, item in ipairs(outfit) do
            if not Player.Functions.HasItem(item.name) then
                hasAllItems = false
                table.insert(missingItems, QBCore.Shared.Items[item.name].label)
            end
        end
        
        if not hasAllItems then
            TriggerClientEvent('QBCore:Notify', src, "Missing items: " .. table.concat(missingItems, ", "), "error")
            return
        end
        
        -- Send event to client to apply the outfit
        TriggerClientEvent('clothing-system:client:applyOutfit', src, outfit)
        TriggerClientEvent('QBCore:Notify', src, "Wearing outfit: " .. outfitName, "success")
    end)
end)

-- Degrade clothing condition event
RegisterNetEvent('clothing-system:server:degradeClothing', function(itemName, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player or not Config.Condition.enabled then return end
    
    -- Find item in inventory
    for slot, item in pairs(Player.PlayerData.items) do
        if item and item.name == itemName then
            -- Update condition
            local info = item.info or {}
            local currentCondition = info.condition or 100
            local newCondition = math.max(0, currentCondition - amount)
            
            info.condition = newCondition
            Player.Functions.UpdateItemInfo(slot, info)
            
            -- Sync condition to database
            TriggerEvent('clothing-system:server:syncClothingCondition', src, itemName, newCondition)
            
            -- Notify player of very damaged clothing
            if newCondition <= 10 and currentCondition > 10 then
                TriggerClientEvent('QBCore:Notify', src, "Your " .. QBCore.Shared.Items[itemName].label .. " is severely damaged and needs repairs", "error")
            elseif newCondition <= 30 and currentCondition > 30 then
                TriggerClientEvent('QBCore:Notify', src, "Your " .. QBCore.Shared.Items[itemName].label .. " is damaged and should be repaired", "warning")
            elseif newCondition <= 50 and currentCondition > 50 then
                TriggerClientEvent('QBCore:Notify', src, "Your " .. QBCore.Shared.Items[itemName].label .. " is dirty and could use a wash", "primary")
            end
            
            break
        end
    end
end)

-- Sync clothing condition to database
RegisterNetEvent('clothing-system:server:syncClothingCondition', function(playerId, itemName, condition)
    local Player = QBCore.Functions.GetPlayer(playerId)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Update condition in database
    MySQL.Async.execute('INSERT INTO player_clothing_condition (citizenid, item, condition, last_worn) VALUES (?, ?, ?, CURRENT_TIMESTAMP) ON DUPLICATE KEY UPDATE condition = ?, last_worn = CURRENT_TIMESTAMP',
        {citizenid, itemName, condition, condition})
end)

-- Register server export functions
exports('addClothingItem', function(source, itemName)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local item = QBCore.Shared.Items[itemName]
    if not item then return false end
    
    -- Add item with default metadata
    local metadata = {
        condition = 100
    }
    
    return Player.Functions.AddItem(itemName, 1, nil, metadata)
end)

exports('removeClothingItem', function(source, itemName)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    return Player.Functions.RemoveItem(itemName, 1)
end)

exports('getPlayerOutfits', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {} end
    
    local citizenid = Player.PlayerData.citizenid
    local outfits = {}
    
    local results = MySQL.Sync.fetchAll('SELECT * FROM player_outfits WHERE citizenid = ?', {citizenid})
    
    if results then
        for _, outfit in ipairs(results) do
            table.insert(outfits, {
                id = outfit.id,
                name = outfit.outfitname,
                items = json.decode(outfit.outfit)
            })
        end
    end
    
    return outfits
end) 