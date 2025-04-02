local QBCore = exports['qb-core']:GetCoreObject()

-- Global variables for store stock management
local StoreStock = {}
local DegradationIntervals = {}
local NeedsRestock = {}

-- Initialize function (called on script start)
function Initialize()
    -- Initialize store stock
    InitializeStoreStock()
    -- Start periodic functions
    StartPeriodicFunctions()
    -- Register callbacks
    RegisterCallbacks()
end

-- Initialize store stock from config
function InitializeStoreStock()
    for storeType, storeData in pairs(Config.Stores) do
        StoreStock[storeType] = {}
        
        -- Initialize stock based on config
        for _, itemName in ipairs(storeData.inventory) do
            -- Set initial stock
            local rarity = QBCore.Shared.Items[itemName].client and QBCore.Shared.Items[itemName].client.rarity or "common"
            local maxStock = Config.Rarity[rarity].maxStock or 10
            
            StoreStock[storeType][itemName] = {
                stock = math.random(1, maxStock),
                maxStock = maxStock,
                rarity = rarity,
                lastRestock = os.time()
            }
        end
        
        NeedsRestock[storeType] = false
    end
end

-- Start periodic functions
function StartPeriodicFunctions()
    -- Restock stores periodically
    CreateThread(function()
        while true do
            Wait(Config.RestockInterval * 60 * 1000) -- Convert minutes to milliseconds
            RestockStores()
        end
    end)
    
    -- Update clothing condition for players
    CreateThread(function()
        while true do
            Wait(Config.ConditionUpdateInterval * 60 * 1000) -- Convert minutes to milliseconds
            UpdateClothingCondition()
        end
    end)
end

-- Register callbacks
function RegisterCallbacks()
    -- Get store inventory callback
    QBCore.Functions.CreateCallback('clothing-system:server:getStoreInventory', function(source, cb, storeType)
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
    
    -- Get player's clothing callback
    QBCore.Functions.CreateCallback('clothing-system:server:getPlayerClothing', function(source, cb)
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
    QBCore.Functions.CreateCallback('clothing-system:server:getDefaultOutfit', function(source, cb)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        
        if not Player then
            cb(nil)
            return
        end
        
        local citizenid = Player.PlayerData.citizenid
        
        local result = MySQL.Sync.fetchScalar('SELECT outfit FROM player_outfits WHERE citizenid = ? AND is_default = 1 LIMIT 1', {citizenid})
        
        if result then
            cb(json.decode(result))
        else
            cb(nil)
        end
    end)
    
    -- Get specific outfit by ID callback
    QBCore.Functions.CreateCallback('clothing-system:server:getOutfit', function(source, cb, outfitId)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        
        if not Player then
            cb(nil)
            return
        end
        
        local citizenid = Player.PlayerData.citizenid
        
        local result = MySQL.Sync.fetchScalar('SELECT outfit FROM player_outfits WHERE id = ? AND citizenid = ?', {outfitId, citizenid})
        
        if result then
            cb(json.decode(result))
        else
            cb(nil)
        end
    end)
    
    -- Get dirty clothing callback
    QBCore.Functions.CreateCallback('clothing-system:server:getDirtyClothing', function(source, cb)
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
                local isDirty = item.info and item.info.dirty
                
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
    QBCore.Functions.CreateCallback('clothing-system:server:getDamagedClothing', function(source, cb)
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
                
                if condition < 75 then
                    table.insert(damagedClothing, {
                        name = item.name,
                        label = QBCore.Shared.Items[item.name].label,
                        slot = item.slot,
                        metadata = item.info or {},
                        condition = condition
                    })
                end
            end
        end
        
        cb(damagedClothing)
    end)
    
    -- Check if player has an item callback
    QBCore.Functions.CreateCallback('clothing-system:server:hasItem', function(source, cb, itemName)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        
        if not Player then
            cb(false)
            return
        end
        
        local hasItem = Player.Functions.GetItemByName(itemName)
        cb(hasItem ~= nil)
    end)
end

-- Restock store inventories
function RestockStores()
    for storeType, storeData in pairs(Config.Stores) do
        local needsRestock = NeedsRestock[storeType] or false
        
        -- Check if it's time to restock based on last restock time or if force restock is needed
        if needsRestock then
            -- Restock all items
            for itemName, stockData in pairs(StoreStock[storeType]) do
                local rarity = stockData.rarity
                local restock = math.random(Config.Rarity[rarity].minRestock or 1, Config.Rarity[rarity].maxRestock or 3)
                
                -- Add to current stock, not exceeding max stock
                StoreStock[storeType][itemName].stock = math.min(stockData.stock + restock, stockData.maxStock)
                StoreStock[storeType][itemName].lastRestock = os.time()
            end
            
            NeedsRestock[storeType] = false
            
            -- Notify all players that the store has been restocked
            TriggerClientEvent('clothing-system:client:updateStores', -1)
        else
            -- Randomly check if we should restock
            if math.random() < 0.3 then -- 30% chance to restock when periodic check happens
                -- Loop items to see which ones need restocking
                local anyRestocked = false
                
                for itemName, stockData in pairs(StoreStock[storeType]) do
                    if stockData.stock < stockData.maxStock * 0.5 then -- Below 50% stock
                        local rarity = stockData.rarity
                        local restock = math.random(Config.Rarity[rarity].minRestock or 1, Config.Rarity[rarity].maxRestock or 3)
                        
                        -- Add to current stock, not exceeding max stock
                        StoreStock[storeType][itemName].stock = math.min(stockData.stock + restock, stockData.maxStock)
                        StoreStock[storeType][itemName].lastRestock = os.time()
                        anyRestocked = true
                    end
                end
                
                if anyRestocked then
                    -- Notify all players that the store has been restocked
                    TriggerClientEvent('clothing-system:client:updateStores', -1)
                end
            end
        end
    end
end

-- Update clothing condition for all active players
function UpdateClothingCondition()
    -- Loop through all connected players
    for _, serverId in ipairs(GetPlayers()) do
        local src = tonumber(serverId)
        local Player = QBCore.Functions.GetPlayer(src)
        
        if Player then
            -- Loop through all items in player's inventory
            for _, item in pairs(Player.PlayerData.items) do
                -- Check if it's a clothing item
                if item and item.name and QBCore.Shared.Items[item.name] and QBCore.Shared.Items[item.name].client and QBCore.Shared.Items[item.name].client.category then
                    -- Check if it's currently worn
                    local isWorn = false
                    
                    -- Get metadata
                    local metadata = item.info or {}
                    local condition = metadata.condition or 100
                    local lastWorn = metadata.lastWorn or 0
                    
                    -- Check if we have a player-specific degradation interval
                    local playerId = src
                    if not DegradationIntervals[playerId] then
                        DegradationIntervals[playerId] = {}
                    end
                    
                    if not DegradationIntervals[playerId][item.name] then
                        DegradationIntervals[playerId][item.name] = os.time() + math.random(Config.ConditionUpdateInterval * 60, Config.ConditionUpdateInterval * 120) -- Random interval between update interval and 2x that
                    end
                    
                    -- Check if it's time to degrade this item
                    if os.time() >= DegradationIntervals[playerId][item.name] then
                        -- Trigger callback to check if the item is worn by the player
                        TriggerClientEvent('clothing-system:client:checkIfWorn', src, item.name, function(worn)
                            isWorn = worn
                            
                            -- Degrade condition based on whether it's worn
                            local degradation = 0
                            
                            if isWorn then
                                -- Higher degradation for worn items
                                degradation = math.random(Config.WornDegradationMin, Config.WornDegradationMax)
                            else
                                -- Lower degradation for stored items
                                degradation = math.random(Config.StoredDegradationMin, Config.StoredDegradationMax)
                            end
                            
                            -- Apply degradation
                            local newCondition = math.max(0, condition - degradation)
                            
                            -- Update item metadata
                            metadata.condition = newCondition
                            
                            -- Check if the item should become dirty
                            if isWorn and math.random() < Config.DirtyChance then
                                metadata.dirty = true
                            end
                            
                            -- Update item in inventory
                            Player.Functions.SetItemMetaData(item.slot, metadata)
                            
                            -- Update last worn timestamp if the item is currently worn
                            if isWorn then
                                metadata.lastWorn = os.time()
                                
                                -- Update item in inventory again with the new lastWorn
                                Player.Functions.SetItemMetaData(item.slot, metadata)
                                
                                -- Notify player if condition is getting low
                                if newCondition < condition and (newCondition <= 25 or newCondition <= 10) then
                                    TriggerClientEvent('clothing-system:client:clothingDamaged', src, item.name, newCondition)
                                end
                            end
                            
                            -- Reset interval
                            DegradationIntervals[playerId][item.name] = os.time() + math.random(Config.ConditionUpdateInterval * 60, Config.ConditionUpdateInterval * 120)
                        end)
                    end
                end
            end
        end
    end
end

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
    TriggerClientEvent('clothing-system:client:itemPurchased', src, itemName, Config.Stores[storeType].label)
    
    return true, "Purchase successful"
end

-- Initialize on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Initialize()
end)

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