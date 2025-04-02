local QBCore = exports['qb-core']:GetCoreObject()

-- Listen for outfit application event from server
RegisterNetEvent('clothing-system:client:applyOutfit', function(outfitItems)
    if not outfitItems or #outfitItems == 0 then return end
    
    -- Reset current outfit tracking
    currentOutfit = {}
    
    -- Start with default appearance (clean slate)
    ResetPedComponents()
    
    -- Apply each item in the outfit
    for _, item in ipairs(outfitItems) do
        -- Set outfit piece based on component type
        if item.event == "clothing-system:client:wearItem" then
            SetPedComponentVariation(PlayerPedId(), item.component, item.drawable, item.texture, 0)
        elseif item.event == "clothing-system:client:wearProp" then
            SetPedPropIndex(PlayerPedId(), item.component, item.drawable, item.texture, true)
        end
        
        -- Track in current outfit
        currentOutfit[item.component] = {
            name = item.name,
            drawable = item.drawable,
            texture = item.texture,
            variation = item.variation or 0
        }
        
        -- Degrade condition slightly when wearing
        TriggerServerEvent('clothing-system:server:degradeClothing', item.name, Config.Condition.degradePerUse / 2)
    end
    
    QBCore.Functions.Notify("Outfit applied", "success")
end)

-- Reset player appearance to default (used when applying full outfits)
function ResetPedComponents()
    -- Reset clothing components
    SetPedComponentVariation(PlayerPedId(), 0, 0, 0, 0)  -- Face
    SetPedComponentVariation(PlayerPedId(), 1, 0, 0, 0)  -- Mask
    SetPedComponentVariation(PlayerPedId(), 2, 0, 0, 0)  -- Hair
    SetPedComponentVariation(PlayerPedId(), 3, 0, 0, 0)  -- Torso
    SetPedComponentVariation(PlayerPedId(), 4, 0, 0, 0)  -- Pants
    SetPedComponentVariation(PlayerPedId(), 5, 0, 0, 0)  -- Parachute / Bag
    SetPedComponentVariation(PlayerPedId(), 6, 0, 0, 0)  -- Shoes
    SetPedComponentVariation(PlayerPedId(), 7, 0, 0, 0)  -- Accessories
    SetPedComponentVariation(PlayerPedId(), 8, 0, 0, 0)  -- Undershirt
    SetPedComponentVariation(PlayerPedId(), 9, 0, 0, 0)  -- Body Armor
    SetPedComponentVariation(PlayerPedId(), 10, 0, 0, 0) -- Decals
    SetPedComponentVariation(PlayerPedId(), 11, 0, 0, 0) -- Jacket
    
    -- Reset prop components
    ClearPedProp(PlayerPedId(), 0) -- Hat
    ClearPedProp(PlayerPedId(), 1) -- Glasses
    ClearPedProp(PlayerPedId(), 2) -- Ear accessories
    ClearPedProp(PlayerPedId(), 6) -- Watch
    ClearPedProp(PlayerPedId(), 7) -- Bracelet
end

-- Automatically re-apply current outfit after player model changes
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    -- Small delay to ensure player model is fully loaded
    Wait(1000)
    
    -- Request and apply saved default outfit
    QBCore.Functions.TriggerCallback('clothing-system:server:getDefaultOutfit', function(outfit)
        if outfit and next(outfit) then
            TriggerEvent('clothing-system:client:applyOutfit', outfit)
        end
    end)
end)

-- Create export to open wardrobe
exports('openWardrobe', function()
    TriggerEvent('clothing-system:client:openWardrobe')
end)

-- Create export to wear outfit
exports('wearOutfit', function(outfitId)
    QBCore.Functions.TriggerCallback('clothing-system:server:getOutfitById', function(outfit)
        if outfit then
            TriggerEvent('clothing-system:client:applyOutfit', outfit.items)
        else
            QBCore.Functions.Notify("Outfit not found", "error")
        end
    end, outfitId)
end)

-- Create export to preview clothing
exports('previewClothing', function(itemName, variation)
    local item = QBCore.Shared.Items[itemName]
    
    if not item or not item.client then
        QBCore.Functions.Notify("Invalid clothing item", "error")
        return
    end
    
    local component = item.client.component
    local drawable = item.client.drawable
    local texture = item.client.texture
    
    if variation and item.client.variations and item.client.variations[variation + 1] then
        texture = item.client.variations[variation + 1].texture
    end
    
    -- Apply the clothing item to player
    if item.client.event == "clothing-system:client:wearItem" then
        SetPedComponentVariation(PlayerPedId(), component, drawable, texture, 0)
    elseif item.client.event == "clothing-system:client:wearProp" then
        SetPedPropIndex(PlayerPedId(), component, drawable, texture, true)
    end
    
    QBCore.Functions.Notify("Previewing " .. item.label, "primary")
end)

-- Event to synchronize player clothing with server/inventory on respawn
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    -- Wait a moment to ensure other systems are loaded
    Wait(2000)
    
    -- Sync clothing with inventory items
    QBCore.Functions.TriggerCallback('clothing-system:server:getSyncedClothing', function(clothingItems)
        if clothingItems and #clothingItems > 0 then
            -- Reset current appearance
            ResetPedComponents()
            
            -- Apply each currently worn item
            for _, item in ipairs(clothingItems) do
                if item.event == "clothing-system:client:wearItem" then
                    SetPedComponentVariation(PlayerPedId(), item.component, item.drawable, item.texture, 0)
                elseif item.event == "clothing-system:client:wearProp" then
                    SetPedPropIndex(PlayerPedId(), item.component, item.drawable, item.texture, true)
                end
                
                -- Track in current outfit
                currentOutfit[item.component] = {
                    name = item.name,
                    drawable = item.drawable,
                    texture = item.texture,
                    variation = item.variation or 0
                }
            end
        end
    end)
end)

-- Update currently worn clothing when inventory updates
RegisterNetEvent('inventory:client:ItemBox', function(data, type)
    if not data or not data.name then return end
    
    -- Get item data
    local item = QBCore.Shared.Items[data.name]
    
    -- Check if it's a clothing item
    if not item or not item.client or not item.client.category then return end
    
    if type == "add" then
        -- Item added - no auto-wear
    elseif type == "remove" then
        -- Item removed - check if it's currently worn and remove if so
        for component, outfitItem in pairs(currentOutfit) do
            if outfitItem.name == data.name then
                -- Remove from player model
                if item.client.event == "clothing-system:client:wearItem" then
                    SetPedComponentVariation(PlayerPedId(), component, 0, 0, 0)
                elseif item.client.event == "clothing-system:client:wearProp" then
                    ClearPedProp(PlayerPedId(), component)
                end
                
                -- Remove from tracked outfit
                currentOutfit[component] = nil
                break
            end
        end
    end
end) 