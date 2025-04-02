-- client.lua
local QBCore = exports['qb-core']:GetCoreObject()
local currentStore = nil

-- Function to open the clothing store UI
function OpenClothingStore(storeType)
    currentStore = storeType
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openStore",
        storeType = storeType,
        storeData = Config.Stores[storeType]
    })
end

-- NUI callback: when a player wants to purchase an item
RegisterNUICallback('purchaseItem', function(data, cb)
    local itemName = data.itemName
    local price = data.price
    TriggerServerEvent('advanced_clothing:purchase', { storeType = currentStore, itemName = itemName, price = price })
    cb({ status = "ok" })
end)

-- NUI callback: preview item (using FiveM natives)
RegisterNUICallback('previewItem', function(data, cb)
    local itemName = data.itemName
    local playerPed = PlayerPedId()
    -- Example: adjust the player’s clothing based on the item preview.
    -- (This is pseudocode; replace with actual component and drawable IDs.)
    if itemName == "tshirt_basic" then
        SetPedComponentVariation(playerPed, 8, 15, 0, 2)
    elseif itemName == "suit_luxury" then
        SetPedComponentVariation(playerPed, 11, 10, 0, 2)
    end
    cb({ status = "previewed" })
end)

-- Command for testing the UI
RegisterCommand("openstore", function(source, args)
    local storeType = args[1] or "Affordable"
    if Config.Stores[storeType] then
        OpenClothingStore(storeType)
    else
        QBCore.Functions.Notify("Store type not found!", "error")
    end
end, false)

-- NUI callback to close the UI
RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    cb({ status = "closed" })
end)

-- Periodic wear & tear: degrade clothing condition every 5 minutes
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300000) -- 300,000 ms = 5 minutes
        local playerItems = exports.ox_inventory:GetItems()
        for _, item in ipairs(playerItems) do
            if item.type == "clothing" then
                local currentCondition = item.metadata and item.metadata.condition or 100
                local newCondition = currentCondition - math.random(1, 5)
                if newCondition < 0 then newCondition = 0 end
                TriggerServerEvent('advanced_clothing:degrade', { itemName = item.name, condition = newCondition })
            end
        end
    end
end)
