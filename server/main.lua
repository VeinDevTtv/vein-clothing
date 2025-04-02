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
    QBCore.Functions.CreateCallback('clothing-system:server:restockStore', function(source, cb, storeType)
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

-- Restock all stores
function RestockStores()
    for storeType, _ in pairs(StoreStock) do
        RestockStore(storeType)
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
    TriggerClientEvent('clothing-system:client:itemPurchased', src, itemName, Config.Stores[storeType].label)
    
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
QBCore.Functions.CreateCallback('clothing-system:server:buyItem', function(source, cb, item, price, storeId)
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
RegisterNetEvent('clothing-system:server:degradeClothing', function(item, amount)
    local src = source
    if not item or not amount then return end
    
    -- Get player identifier
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Update clothing condition in database
    UpdateClothingCondition(citizenid, item, amount)
end) 