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
RegisterNetEvent('inventory:client:ItemBox', function(itemData, type)
    if not itemData then return end
    
    -- Check if it's a clothing item
    if type == 'add' and itemData.name and QBCore.Shared.Items[itemData.name] and QBCore.Shared.Items[itemData.name].client and QBCore.Shared.Items[itemData.name].client.category then
        -- Notify player about new clothing
        QBCore.Functions.Notify(Lang:t('info.new_clothing_item', {item = itemData.label}), 'primary')
        
        -- Suggestion to try it on
        if not isPreviewing then
            QBCore.Functions.Notify(Lang:t('info.try_on_suggestion', {command = "/try " .. itemData.name}), 'primary')
        end
    elseif type == "remove" then
        -- Item removed - check if it's currently worn and remove if so
        for component, outfitItem in pairs(currentOutfit) do
            if outfitItem.name == itemData.name then
                -- Remove from player model
                if itemData.event == "clothing-system:client:wearItem" then
                    SetPedComponentVariation(PlayerPedId(), component, 0, 0, 0)
                elseif itemData.event == "clothing-system:client:wearProp" then
                    ClearPedProp(PlayerPedId(), component)
                end
                
                -- Remove from tracked outfit
                currentOutfit[component] = nil
                break
            end
        end
    end
end)

-- Player bought an item from a clothing store
RegisterNetEvent('clothing-system:client:itemPurchased', function(itemName, storeName)
    if not itemName or not storeName then return end
    
    local item = QBCore.Shared.Items[itemName]
    if not item then return end
    
    -- Notify of purchase
    QBCore.Functions.Notify(Lang:t('success.purchased', {itemName = item.label, store = storeName}), 'success')
    
    -- Ask if player wants to try it on
    SendNUIMessage({
        action = "showPrompt",
        data = {
            title = Lang:t('ui.try_on_title'),
            message = Lang:t('ui.try_on_message', {itemName = item.label}),
            accept = Lang:t('ui.try_on'),
            decline = Lang:t('ui.no_thanks')
        }
    })
    
    SetNuiFocus(true, true)
    
    RegisterNUICallback('promptResponse', function(data, cb)
        SetNuiFocus(false, false)
        
        if data.accepted then
            -- Preview the item
            PreviewClothing(itemName)
        end
        
        cb({})
    end)
end)

-- Event when player clothing is damaged
RegisterNetEvent('clothing-system:client:clothingDamaged', function(itemName, newCondition)
    if not itemName or not newCondition then return end
    
    -- Only notify if it's a significant decrease or if it reached a threshold
    if newCondition <= 25 and newCondition > 10 then
        QBCore.Functions.Notify(Lang:t('condition.poor', {item = QBCore.Shared.Items[itemName].label}), 'primary')
    elseif newCondition <= 10 then
        QBCore.Functions.Notify(Lang:t('condition.terrible', {item = QBCore.Shared.Items[itemName].label}), 'error')
    end
    
    -- Update the current outfit if the item is worn
    for i, item in pairs(currentOutfit) do
        if item.name == itemName then
            currentOutfit[i].metadata = currentOutfit[i].metadata or {}
            currentOutfit[i].metadata.condition = newCondition
            break
        end
    end
end)

-- Event when player clothing is cleaned
RegisterNetEvent('clothing-system:client:clothingCleaned', function(itemName)
    if not itemName then return end
    
    QBCore.Functions.Notify(Lang:t('success.cleaned', {item = QBCore.Shared.Items[itemName].label}), 'success')
    
    -- Update the current outfit if the item is worn
    for i, item in pairs(currentOutfit) do
        if item.name == itemName then
            currentOutfit[i].metadata = currentOutfit[i].metadata or {}
            currentOutfit[i].metadata.dirty = false
            break
        end
    end
end)

-- Event when player clothing is repaired
RegisterNetEvent('clothing-system:client:clothingRepaired', function(itemName, newCondition)
    if not itemName or not newCondition then return end
    
    QBCore.Functions.Notify(Lang:t('success.repaired', {item = QBCore.Shared.Items[itemName].label}), 'success')
    
    -- Update the current outfit if the item is worn
    for i, item in pairs(currentOutfit) do
        if item.name == itemName then
            currentOutfit[i].metadata = currentOutfit[i].metadata or {}
            currentOutfit[i].metadata.condition = newCondition
            break
        end
    end
end)

-- Event for setting up player's outfit
RegisterNetEvent('clothing-system:client:setOutfit', function(outfit)
    if not outfit then return end
    
    WearOutfit(outfit)
end)

-- Event for resetting player's appearance
RegisterNetEvent('clothing-system:client:resetAppearance', function()
    ResetAppearance()
end)

-- Event for updating NPC locations
RegisterNetEvent('clothing-system:client:updateNPCs', function()
    LoadStores()
    LoadLaundromats()
    LoadTailors()
end)

-- Event for updating store stock
RegisterNetEvent('clothing-system:client:updateStores', function()
    -- If player is in a store, refresh the UI
    if isInClothingStore and currentStore then
        OpenClothingStore(currentStore)
    end
end)

-- Event when an outfits gets created
RegisterNetEvent('clothing-system:client:outfitCreated', function(outfitId, outfitName)
    if not outfitId or not outfitName then return end
    
    QBCore.Functions.Notify(Lang:t('success.outfit_created', {name = outfitName}), 'success')
end)

-- Event when an outfit gets deleted
RegisterNetEvent('clothing-system:client:outfitDeleted', function(outfitId, outfitName)
    if not outfitId then return end
    
    QBCore.Functions.Notify(Lang:t('success.outfit_deleted', {name = outfitName or "Outfit"}), 'success')
end)

-- Event when an outfit gets renamed
RegisterNetEvent('clothing-system:client:outfitRenamed', function(outfitId, oldName, newName)
    if not outfitId or not newName then return end
    
    QBCore.Functions.Notify(Lang:t('success.outfit_renamed', {oldName = oldName or "Outfit", newName = newName}), 'success')
end)

-- Event when an outfit is set as default
RegisterNetEvent('clothing-system:client:outfitSetDefault', function(outfitId, outfitName)
    if not outfitId then return end
    
    QBCore.Functions.Notify(Lang:t('success.outfit_set_default', {name = outfitName or "Outfit"}), 'success')
end)

-- Add NUI callbacks

-- NUI: Close interface
RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    isPreviewing = false
    isInWardrobe = false
    
    cb({})
end)

-- NUI: Purchase item
RegisterNUICallback('purchaseItem', function(data, cb)
    local itemName = data.item
    local storeType = data.store
    
    if not itemName or not storeType then
        cb({success = false, message = Lang:t('error.invalid_data')})
        return
    end
    
    TriggerServerEvent('clothing-system:server:purchaseItem', itemName, storeType)
    cb({success = true})
end)

-- NUI: Wear item
RegisterNUICallback('wearItem', function(data, cb)
    local itemName = data.item
    local slot = data.slot
    
    if not itemName then
        cb({success = false, message = Lang:t('error.invalid_data')})
        return
    end
    
    TriggerServerEvent('clothing-system:server:wearItem', itemName, slot)
    cb({success = true})
end)

-- NUI: Remove item
RegisterNUICallback('removeItem', function(data, cb)
    local itemName = data.item
    
    if not itemName then
        cb({success = false, message = Lang:t('error.invalid_data')})
        return
    end
    
    local success = RemoveClothing(itemName)
    cb({success = success})
    
    if success then
        TriggerServerEvent('clothing-system:server:removeWornItem', itemName)
    end
end)

-- NUI: Create outfit
RegisterNUICallback('createOutfit', function(data, cb)
    local outfitName = data.name
    
    if not outfitName then
        cb({success = false, message = Lang:t('error.invalid_name')})
        return
    end
    
    if not currentOutfit or not next(currentOutfit) then
        cb({success = false, message = Lang:t('error.no_outfit')})
        return
    end
    
    TriggerServerEvent('clothing-system:server:createOutfit', outfitName, currentOutfit)
    cb({success = true})
end)

-- NUI: Wear outfit
RegisterNUICallback('wearOutfit', function(data, cb)
    local outfitId = data.outfitId
    
    if not outfitId then
        cb({success = false, message = Lang:t('error.invalid_data')})
        return
    end
    
    QBCore.Functions.TriggerCallback('clothing-system:server:getOutfit', function(outfit)
        if not outfit or not next(outfit) then
            cb({success = false, message = Lang:t('error.outfit_not_found')})
            return
        end
        
        WearOutfit(outfit)
        cb({success = true})
    end, outfitId)
end)

-- NUI: Wash clothing items
RegisterNUICallback('washItems', function(data, cb)
    local items = data.items
    
    if not items or not next(items) then
        cb({success = false, message = Lang:t('error.no_items_selected')})
        return
    end
    
    TriggerServerEvent('clothing-system:server:washItems', items)
    cb({success = true})
end)

-- NUI: Repair clothing items
RegisterNUICallback('repairItems', function(data, cb)
    local items = data.items
    
    if not items or not next(items) then
        cb({success = false, message = Lang:t('error.no_items_selected')})
        return
    end
    
    TriggerServerEvent('clothing-system:server:repairItems', items)
    cb({success = true})
end)

-- Event for handling commands

-- RegisterCommand for /try (try on clothing item)
RegisterCommand('try', function(source, args)
    local itemName = args[1]
    
    if not itemName then
        QBCore.Functions.Notify(Lang:t('error.specify_item'), 'error')
        return
    end
    
    -- Check if player has the item
    QBCore.Functions.TriggerCallback('clothing-system:server:hasItem', function(hasItem)
        if not hasItem then
            QBCore.Functions.Notify(Lang:t('error.item_not_owned'), 'error')
            return
        end
        
        PreviewClothing(itemName)
    end, itemName)
end, false)

-- RegisterCommand for /outfits (open outfit menu)
RegisterCommand('outfits', function()
    exports['clothing-system']:openWardrobe()
end, false)

-- Register all commands
function RegisterCommands()
    -- Already registered above
end 