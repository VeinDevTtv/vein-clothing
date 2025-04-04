local QBCore = exports['qb-core']:GetCoreObject()

-- Debug function to help track NUI issues
function DebugNUI(message)
    if Config and Config.Debug then
        print("^5[vein-clothing:NUI] " .. message .. "^7")
    end
end

-- Add SafePlayerPedId at the top of the file
local function SafePlayerPedId()
    local ped = PlayerPedId()
    if not ped or ped == 0 then
        Wait(100)  -- Wait a bit and try again
        ped = PlayerPedId()
    end
    return ped
end

-- NUI callback to check if an item is being worn
RegisterNUICallback('checkIfWorn', function(data, cb)
    local itemName = data.item
    local isWorn = false
    
    for _, outfitItem in pairs(currentOutfit) do
        if outfitItem.name == itemName then
            isWorn = true
            break
        end
    end
    
    cb({isWorn = isWorn})
end)

-- Client event to check if an item is being worn (used by server)
RegisterNetEvent('vein-clothing:client:checkIfWorn', function(itemName, callback)
    local isWorn = false
    
    for _, outfitItem in pairs(currentOutfit) do
        if outfitItem.name == itemName then
            isWorn = true
            break
        end
    end
    
    callback(isWorn)
end)

-- Receive offer request
RegisterNetEvent('vein-clothing:client:receiveOfferRequest', function(sellerId, itemName, price, callback)
    local itemLabel = QBCore.Shared.Items[itemName].label
    local sellerName = ""
    
    QBCore.Functions.TriggerCallback('vein-clothing:server:getPlayerName', function(name)
        sellerName = name
        
        -- Show notification of offer
        QBCore.Functions.Notify(Lang:t('info.offer_received', {sellerName, itemLabel, price}), "primary", 10000)
        
        -- Create prompt UI
        SendNUIMessage({
            action = "showPrompt",
            data = {
                title = "Purchase Offer",
                message = Lang:t('info.offer_received', {sellerName, itemLabel, price}),
                accept = Lang:t('ui.purchase'),
                decline = Lang:t('ui.close')
            }
        })
        
        -- Set NUI focus
        SetNuiFocus(true, true)
        
        -- Handle NUI callback for prompt response
        RegisterNUICallback('promptResponse', function(data, promptCb)
            SetNuiFocus(false, false)
            callback(data.accepted)
            promptCb({})
        end)
    end, sellerId)
end)

-- NUI callback for wishlist toggle
RegisterNUICallback('toggleWishlist', function(data, cb)
    local itemName = data.itemName
    local itemData = data.itemData or {}
    
    -- Check if item is already in wishlist
    QBCore.Functions.TriggerCallback('vein-clothing:server:isItemWishlisted', function(isWishlisted)
        if isWishlisted then
            -- Remove from wishlist
            TriggerServerEvent('vein-clothing:server:removeFromWishlist', itemName)
            QBCore.Functions.Notify(Lang:t('success.wishlist_removed', {QBCore.Shared.Items[itemName].label}), "success")
        else
            -- Add to wishlist
            TriggerServerEvent('vein-clothing:server:addToWishlist', itemName, itemData)
            QBCore.Functions.Notify(Lang:t('success.wishlist_added', {QBCore.Shared.Items[itemName].label}), "success")
        end
        
        cb({success = true, isWishlisted = not isWishlisted})
    end, itemName)
end)

-- NUI callback for getting item details
RegisterNUICallback('getItemDetails', function(data, cb)
    local itemName = data.item
    local item = QBCore.Shared.Items[itemName]
    
    if not item then
        cb({success = false})
        return
    end
    
    -- Get additional details from server if needed
    QBCore.Functions.TriggerCallback('vein-clothing:server:getItemDetails', function(details)
        cb({
            success = true,
            item = {
                name = itemName,
                label = item.label,
                description = item.description,
                category = item.client and item.client.category or "unknown",
                rarity = item.client and item.client.rarity or "common",
                variations = item.client and item.client.variations or {},
                condition = details and details.condition or 100,
                lastWorn = details and details.lastWorn or nil
            }
        })
    end, itemName)
end)

-- NUI callback for trade item
RegisterNUICallback('tradeItem', function(data, cb)
    local targetId = data.targetId
    local itemName = data.item
    local slot = data.slot
    
    if not targetId or not itemName or not slot then
        cb({success = false, message = Lang:t('error.invalid_data')})
        return
    end
    
    TriggerServerEvent('vein-clothing:server:tradeItem', targetId, itemName, slot)
    cb({success = true})
end)

-- NUI callback for selling item
RegisterNUICallback('sellItem', function(data, cb)
    local targetId = data.targetId
    local itemName = data.item
    local slot = data.slot
    local price = data.price
    
    if not targetId or not itemName or not slot or not price then
        cb({success = false, message = Lang:t('error.invalid_data')})
        return
    end
    
    TriggerServerEvent('vein-clothing:server:sellItem', targetId, itemName, slot, price)
    cb({success = true})
end)

-- NUI callback for deleting outfit
RegisterNUICallback('deleteOutfit', function(data, cb)
    local outfitId = data.outfitId
    
    if not outfitId then
        cb({success = false, message = Lang:t('error.invalid_data')})
        return
    end
    
    TriggerServerEvent('vein-clothing:server:deleteOutfit', outfitId)
    cb({success = true})
end)

-- NUI callback for renaming outfit
RegisterNUICallback('renameOutfit', function(data, cb)
    local outfitId = data.outfitId
    local newName = data.newName
    
    if not outfitId or not newName then
        cb({success = false, message = Lang:t('error.invalid_data')})
        return
    end
    
    TriggerServerEvent('vein-clothing:server:renameOutfit', outfitId, newName)
    cb({success = true})
end)

-- NUI callback for setting default outfit
RegisterNUICallback('setDefaultOutfit', function(data, cb)
    local outfitId = data.outfitId
    
    if not outfitId then
        cb({success = false, message = Lang:t('error.invalid_data')})
        return
    end
    
    TriggerServerEvent('vein-clothing:server:setDefaultOutfit', outfitId)
    cb({success = true})
end)

-- NUI callback for getting nearby players
RegisterNUICallback('getNearbyPlayers', function(data, cb)
    local nearbyPlayers = {}
    local playerPed = SafePlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Get list of all players
    local players = QBCore.Functions.GetPlayers()
    
    -- Check if we actually got valid players
    if not players or #players == 0 then
        cb({players = {}})
        return
    end
    
    for _, playerId in ipairs(players) do
        -- Don't include self
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            if DoesEntityExist(targetPed) then
                local targetCoords = GetEntityCoords(targetPed)
                local distance = #(playerCoords - targetCoords)
                
                -- Only include players within 3 meters
                if distance <= 3.0 then
                    local targetServerId = GetPlayerServerId(playerId)
                    
                    QBCore.Functions.TriggerCallback('vein-clothing:server:getPlayerName', function(name)
                        table.insert(nearbyPlayers, {
                            id = targetServerId,
                            name = name,
                            distance = math.floor(distance * 10) / 10
                        })
                        
                        -- Send the callback when we've processed all nearby players
                        if #nearbyPlayers == #players - 1 then
                            cb({players = nearbyPlayers})
                        end
                    end, targetServerId)
                end
            end
        end
    end
    
    -- If no nearby players found or all checks failed
    if #nearbyPlayers == 0 then
        cb({players = {}})
    end
end)

-- Register additional NUI callbacks as needed
RegisterNUICallback('refreshInventory', function(data, cb)
    -- Trigger server to send updated inventory data
    QBCore.Functions.TriggerCallback('vein-clothing:server:getPlayerClothing', function(clothing, outfits, wishlist)
        cb({
            success = true,
            clothing = clothing,
            outfits = outfits,
            wishlist = wishlist
        })
    end)
end)

-- Camera control functions for clothing preview
local previewCam = nil
local previewingClothes = false

RegisterNUICallback('startPreviewMode', function(data, cb)
    if previewingClothes then
        cb({success = false, message = "Already in preview mode"})
        return
    end
    
    StartPreviewCam()
    previewingClothes = true
    cb({success = true})
end)

RegisterNUICallback('stopPreviewMode', function(data, cb)
    if not previewingClothes then
        cb({success = false, message = "Not in preview mode"})
        return
    end
    
    EndPreviewCam()
    previewingClothes = false
    cb({success = true})
end)

RegisterNUICallback('rotatePreview', function(data, cb)
    local direction = data.direction or "right"
    local amount = data.amount or 45.0
    
    local ped = SafePlayerPedId()
    
    if direction == "right" then
        SetEntityHeading(ped, GetEntityHeading(ped) - amount)
    else
        SetEntityHeading(ped, GetEntityHeading(ped) + amount)
    end
    
    cb({success = true})
end)

function StartPreviewCam()
    local playerPed = SafePlayerPedId()
    if not playerPed or playerPed == 0 then return end
    
    local coords = GetEntityCoords(playerPed)
    if not coords then return end
    
    -- Create camera
    previewCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    
    -- Set camera position (in front of player)
    local heading = GetEntityHeading(playerPed)
    local forward = vector3(-math.sin(math.rad(heading)), math.cos(math.rad(heading)), 0.0)
    local camPos = coords + forward * 1.5 + vector3(0.0, 0.0, 0.5)
    
    SetCamCoord(previewCam, camPos.x, camPos.y, camPos.z)
    PointCamAtCoord(previewCam, coords.x, coords.y, coords.z + 0.5)
    
    -- Transition to scripted camera
    SetCamActive(previewCam, true)
    RenderScriptCams(true, true, 1000, true, false)
    
    -- Disable player movement
    FreezeEntityPosition(playerPed, true)
end

function EndPreviewCam()
    local playerPed = SafePlayerPedId()
    
    -- Transition back to game camera
    RenderScriptCams(false, true, 1000, true, false)
    
    -- Destroy camera
    if previewCam then
        DestroyCam(previewCam, false)
        previewCam = nil
    end
    
    -- Enable player movement (only if we have a valid ped)
    if playerPed and playerPed > 0 then
        FreezeEntityPosition(playerPed, false)
    end
end

-- Clean up on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if previewingClothes then
        EndPreviewCam()
    end
end)

-- Add a refresh wardrobe function
RegisterNUICallback('refreshWardrobe', function(data, cb)
    QBCore.Functions.TriggerCallback('vein-clothing:server:getPlayerClothing', function(clothing, outfits, wishlist)
        cb({
            success = true,
            wardrobeItems = clothing,
            outfits = outfits,
            wishlistItems = wishlist
        })
    end)
end) 