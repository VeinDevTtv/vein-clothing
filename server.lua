-- server.lua
local QBCore = exports['qb-core']:GetCoreObject()

-- Purchase clothing item event
RegisterNetEvent('advanced_clothing:purchase', function(data)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    local storeType = data.storeType
    local itemName = data.itemName
    local price = data.price

    if not Config.Stores[storeType] then
        TriggerClientEvent('QBCore:Notify', src, "Store not found!", "error")
        return
    end

    -- Verify the item exists in the store’s inventory
    local found = false
    for _, item in ipairs(Config.Stores[storeType].inventory) do
        if item == itemName then
            found = true
            break
        end
    end

    if not found then
        TriggerClientEvent('QBCore:Notify', src, "Item not available in this store!", "error")
        return
    end

    -- Remove money and add item (using ox_inventory)
    if xPlayer.Functions.RemoveMoney('cash', price) then
        exports.ox_inventory:AddItem(src, itemName, 1)
        TriggerClientEvent('QBCore:Notify', src, "Purchase successful!", "success")
    else
        TriggerClientEvent('QBCore:Notify', src, "Not enough money!", "error")
    end
end)

-- Event for degrading clothing over time
RegisterNetEvent('advanced_clothing:degrade', function(data)
    local src = source
    local itemName = data.itemName
    local condition = data.condition -- percentage (0-100)
    
    -- Pseudo-code: retrieve the item and update its metadata
    local item = exports.ox_inventory:GetItem(src, itemName)
    if item then
        item.metadata = item.metadata or {}
        item.metadata.condition = condition
        exports.ox_inventory:UpdateItem(src, itemName, item.metadata)
    end
end)
