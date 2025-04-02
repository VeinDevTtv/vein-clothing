local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local currentStore = nil
local isInsideStore = false
local currentOutfit = {}
local inWardrobe = false
local clothingPeds = {}

-- Initialize player data
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    LoadClothingBlips()
    LoadPeds()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    currentOutfit = {}
    DestroyPeds()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

-- Create store blips on map
function LoadClothingBlips()
    if not Config.EnableBlips then return end
    
    for storeName, storeData in pairs(Config.Stores) do
        if storeData.blip then
            for _, location in ipairs(storeData.locations) do
                local blip = AddBlipForCoord(location.x, location.y, location.z)
                SetBlipSprite(blip, storeData.blip.sprite)
                SetBlipColour(blip, storeData.blip.color)
                SetBlipScale(blip, storeData.blip.scale)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(storeData.label)
                EndTextCommandSetBlipName(blip)
            end
        end
    end
    
    -- Create laundromat blips
    for _, location in ipairs(Config.Laundromats) do
        local blip = AddBlipForCoord(location.x, location.y, location.z)
        SetBlipSprite(blip, 362)  -- Laundromat sprite
        SetBlipColour(blip, 17)   -- Blue color
        SetBlipScale(blip, 0.6)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Laundromat")
        EndTextCommandSetBlipName(blip)
    end
    
    -- Create tailor blips
    for _, location in ipairs(Config.TailorShops) do
        local blip = AddBlipForCoord(location.x, location.y, location.z)
        SetBlipSprite(blip, 366)  -- Scissors sprite
        SetBlipColour(blip, 4)    -- Red color
        SetBlipScale(blip, 0.6)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Tailor Shop")
        EndTextCommandSetBlipName(blip)
    end
end

-- Create store clerk peds
function LoadPeds()
    local pedModels = {
        ["suburban"] = "s_f_y_shop_mid",
        ["ponsonbys"] = "s_m_y_shop_high",
        ["binco"] = "s_f_y_shop_low",
        ["underground"] = "a_m_y_hipster_02"
    }
    
    for storeName, storeData in pairs(Config.Stores) do
        local model = pedModels[storeName] or "s_f_y_shop_mid"
        
        for _, location in ipairs(storeData.locations) do
            local ped = nil
            
            RequestModel(GetHashKey(model))
            while not HasModelLoaded(GetHashKey(model)) do
                Wait(1)
            end
            
            ped = CreatePed(4, GetHashKey(model), location.x, location.y, location.z - 1.0, 0.0, false, true)
            
            SetEntityHeading(ped, location.w or 0.0)
            FreezeEntityPosition(ped, true)
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            
            -- Set animation
            TaskStartScenarioInPlace(ped, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)
            
            table.insert(clothingPeds, ped)
            
            -- Target interaction if enabled
            if Config.UseTarget then
                exports['qb-target']:AddTargetEntity(ped, {
                    options = {
                        {
                            type = "client",
                            event = "clothing-system:client:openStore",
                            icon = "fas fa-tshirt",
                            label = "Browse " .. storeData.label,
                            store = storeName
                        }
                    },
                    distance = 3.0
                })
            end
        end
    end
end

-- Cleanup peds when resource stops
function DestroyPeds()
    for _, ped in ipairs(clothingPeds) do
        DeletePed(ped)
    end
    clothingPeds = {}
end

-- Non-target zone interaction logic
CreateThread(function()
    if Config.UseTarget then return end
    
    while true do
        local sleep = 1000
        local pos = GetEntityCoords(PlayerPedId())
        isInsideStore = false
        
        for storeName, storeData in pairs(Config.Stores) do
            for _, location in ipairs(storeData.locations) do
                local dist = #(pos - vector3(location.x, location.y, location.z))
                
                if dist < 3.0 then
                    sleep = 0
                    isInsideStore = true
                    currentStore = storeName
                    
                    if dist < 1.5 then
                        QBCore.Functions.DrawText3D(location.x, location.y, location.z, "[E] Browse " .. storeData.label)
                        
                        if IsControlJustPressed(0, Config.DefaultInteractKey) then
                            TriggerEvent("clothing-system:client:openStore", {store = storeName})
                        end
                    end
                    
                    break
                end
            end
            
            if isInsideStore then break end
        end
        
        -- Check for laundromats and tailor shops (similar logic)
        if not isInsideStore then
            for _, location in ipairs(Config.Laundromats) do
                local dist = #(pos - vector3(location.x, location.y, location.z))
                
                if dist < 3.0 then
                    sleep = 0
                    
                    if dist < 1.5 then
                        QBCore.Functions.DrawText3D(location.x, location.y, location.z, "[E] Use Laundromat")
                        
                        if IsControlJustPressed(0, Config.DefaultInteractKey) then
                            TriggerEvent("clothing-system:client:openLaundromat")
                        end
                    end
                    
                    break
                end
            end
            
            for _, location in ipairs(Config.TailorShops) do
                local dist = #(pos - vector3(location.x, location.y, location.z))
                
                if dist < 3.0 then
                    sleep = 0
                    
                    if dist < 1.5 then
                        QBCore.Functions.DrawText3D(location.x, location.y, location.z, "[E] Use Tailor Services")
                        
                        if IsControlJustPressed(0, Config.DefaultInteractKey) then
                            TriggerEvent("clothing-system:client:openTailor")
                        end
                    end
                    
                    break
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- Open clothing store UI
RegisterNetEvent('clothing-system:client:openStore', function(data)
    if inWardrobe then return end
    
    local storeName = data.store
    local storeData = Config.Stores[storeName]
    
    if not storeData then
        QBCore.Functions.Notify("Invalid store data", "error")
        return
    end
    
    -- Get store inventory from server
    QBCore.Functions.TriggerCallback('clothing-system:server:getStoreInventory', function(inventory)
        if not inventory then
            QBCore.Functions.Notify("Failed to load store inventory", "error")
            return
        end
        
        -- Process inventory data
        local processedInventory = {}
        for _, itemName in ipairs(inventory) do
            local item = QBCore.Shared.Items[itemName]
            
            if item then
                -- Add needed properties from item metadata
                local itemData = {
                    name = itemName,
                    label = item.label,
                    description = item.description,
                    price = GetItemPrice(itemName, storeName),
                    rarity = item.client and item.client.rarity or "common",
                    category = item.client and item.client.category or "tops",
                    variations = item.client and item.client.variations or {},
                    gender = item.client and item.client.gender or "male"
                }
                
                -- Only show items that match player's gender or are unisex
                local playerGender = GetPlayerGender()
                if itemData.gender == playerGender or itemData.gender == "unisex" then
                    table.insert(processedInventory, itemData)
                end
            end
        end
        
        -- Open NUI with processed store data
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "openStore",
            storeData = {
                label = storeData.label,
                description = storeData.description,
                inventory = processedInventory
            }
        })
        
        -- Save currently open store
        currentStore = storeName
    end, storeName)
end)

-- Calculate item price based on rarity and store
function GetItemPrice(itemName, storeName)
    local item = QBCore.Shared.Items[itemName]
    if not item or not item.client or not item.client.rarity then
        return 100 -- Default price if no rarity data
    end
    
    local rarity = item.client.rarity
    local rarityData = Config.Rarity[rarity] or Config.Rarity["common"]
    local storeData = Config.Stores[storeName]
    
    -- Base price from rarity range
    local basePrice = math.random(rarityData.minPrice, rarityData.maxPrice)
    
    -- Apply store-specific price multiplier if available
    local multiplier = storeData.priceMultiplier or 1.0
    
    return math.floor(basePrice * multiplier)
end

-- Get player gender
function GetPlayerGender()
    local model = GetEntityModel(PlayerPedId())
    
    if model == GetHashKey("mp_f_freemode_01") then
        return "female"
    else
        return "male"
    end
end

-- Preview clothing item
RegisterNUICallback('previewItem', function(data, cb)
    local itemName = data.item
    local variation = data.variation or 0
    
    local item = QBCore.Shared.Items[itemName]
    if not item or not item.client then
        cb({success = false})
        return
    end
    
    local component = item.client.component
    local drawable = item.client.drawable
    local texture = item.client.texture
    
    if item.client.variations and item.client.variations[variation + 1] then
        texture = item.client.variations[variation + 1].texture
    end
    
    -- Record item in current outfit for tracking
    currentOutfit[component] = {
        name = itemName,
        drawable = drawable,
        texture = texture,
        variation = variation
    }
    
    -- Apply clothing to player ped
    if item.client.event == "clothing-system:client:wearItem" then
        -- Component-based clothing
        SetPedComponentVariation(PlayerPedId(), component, drawable, texture, 0)
    elseif item.client.event == "clothing-system:client:wearProp" then
        -- Prop-based item (hats, glasses, etc)
        SetPedPropIndex(PlayerPedId(), component, drawable, texture, true)
    end
    
    cb({success = true})
end)

-- Purchase clothing item
RegisterNUICallback('purchaseItem', function(data, cb)
    local itemName = data.item
    local price = data.price
    local variation = data.variation or 0
    
    QBCore.Functions.TriggerCallback('clothing-system:server:purchaseItem', function(success, reason)
        if success then
            QBCore.Functions.Notify("Purchased " .. QBCore.Shared.Items[itemName].label, "success")
            
            -- Update the item in current outfit
            local item = QBCore.Shared.Items[itemName]
            if item and item.client and item.client.component then
                local component = item.client.component
                currentOutfit[component] = {
                    name = itemName,
                    drawable = item.client.drawable,
                    texture = variation == 0 and item.client.texture or item.client.variations[variation + 1].texture,
                    variation = variation
                }
            end
        else
            QBCore.Functions.Notify(reason, "error")
        end
        
        cb({success = success})
    end, itemName, price, variation, currentStore)
end)

-- Update wishlist
RegisterNUICallback('updateWishlist', function(data, cb)
    local wishlist = data.wishlist
    
    TriggerServerEvent('clothing-system:server:updateWishlist', wishlist)
    
    cb({success = true})
end)

-- Save outfit
RegisterNUICallback('saveOutfit', function(data, cb)
    local outfit = data.outfit
    
    TriggerServerEvent('clothing-system:server:saveOutfit', outfit)
    
    cb({success = true})
end)

-- Close UI
RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    cb({success = true})
end)

-- Wear/remove clothing item (used when items are used from inventory)
RegisterNetEvent('clothing-system:client:wearItem', function(itemData)
    if not itemData or not itemData.client then return end
    
    local component = itemData.client.component
    local drawable = itemData.client.drawable
    local texture = itemData.client.texture
    
    -- Check if removing or wearing
    if currentOutfit[component] and currentOutfit[component].name == itemData.name then
        -- Remove item - set to default clothing
        SetPedComponentVariation(PlayerPedId(), component, 0, 0, 0)
        currentOutfit[component] = nil
        
        -- Degrade condition slightly when removing (implementation detail)
        TriggerServerEvent('clothing-system:server:degradeClothing', itemData.name, 0.1)
    else
        -- Wear item
        SetPedComponentVariation(PlayerPedId(), component, drawable, texture, 0)
        
        -- Update current outfit
        currentOutfit[component] = {
            name = itemData.name,
            drawable = drawable,
            texture = texture,
            variation = 0
        }
        
        -- Degrade condition when wearing
        TriggerServerEvent('clothing-system:server:degradeClothing', itemData.name, Config.Condition.degradePerUse)
    end
end)

-- Wear/remove prop item (hats, glasses, etc.)
RegisterNetEvent('clothing-system:client:wearProp', function(itemData)
    if not itemData or not itemData.client then return end
    
    local component = itemData.client.component
    local drawable = itemData.client.drawable
    local texture = itemData.client.texture
    
    -- Check if removing or wearing
    if currentOutfit[component] and currentOutfit[component].name == itemData.name then
        -- Remove prop
        ClearPedProp(PlayerPedId(), component)
        currentOutfit[component] = nil
        
        -- Degrade condition slightly when removing
        TriggerServerEvent('clothing-system:server:degradeClothing', itemData.name, 0.1)
    else
        -- Wear prop
        SetPedPropIndex(PlayerPedId(), component, drawable, texture, true)
        
        -- Update current outfit
        currentOutfit[component] = {
            name = itemData.name,
            drawable = drawable,
            texture = texture,
            variation = 0
        }
        
        -- Degrade condition when wearing
        TriggerServerEvent('clothing-system:server:degradeClothing', itemData.name, Config.Condition.degradePerUse)
    end
end)

-- Open personal wardrobe
RegisterNetEvent('clothing-system:client:openWardrobe', function()
    if inWardrobe then return end
    inWardrobe = true
    
    -- Get player's owned clothing and saved outfits
    QBCore.Functions.TriggerCallback('clothing-system:server:getPlayerClothing', function(clothing, outfits, wishlist)
        if not clothing then
            QBCore.Functions.Notify("Failed to load wardrobe", "error")
            inWardrobe = false
            return
        end
        
        -- Open NUI with wardrobe data
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "openWardrobe",
            wardrobeData = {
                label = "My Wardrobe",
                inventory = clothing,
                outfits = outfits,
                wishlist = wishlist
            }
        })
    end)
end)

-- Open laundromat
RegisterNetEvent('clothing-system:client:openLaundromat', function()
    -- Get player's dirty clothing
    QBCore.Functions.TriggerCallback('clothing-system:server:getDirtyClothing', function(clothing)
        if not clothing or #clothing == 0 then
            QBCore.Functions.Notify("You don't have any clothes that need washing", "error")
            return
        end
        
        -- Open NUI with laundromat data
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "openLaundromat",
            laundromatData = {
                label = "Laundromat",
                clothing = clothing,
                washCost = Config.Condition.washCost
            }
        })
    end)
end)

-- Open tailor shop
RegisterNetEvent('clothing-system:client:openTailor', function()
    -- Get player's damaged clothing
    QBCore.Functions.TriggerCallback('clothing-system:server:getDamagedClothing', function(clothing)
        if not clothing or #clothing == 0 then
            QBCore.Functions.Notify("You don't have any clothes that need repairs", "error")
            return
        end
        
        -- Open NUI with tailor data
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "openTailor",
            tailorData = {
                label = "Tailor Shop",
                clothing = clothing,
                repairCosts = Config.Condition.repairCosts
            }
        })
    end)
end)

-- Wash clothing
RegisterNUICallback('washClothing', function(data, cb)
    local itemName = data.item
    
    QBCore.Functions.TriggerCallback('clothing-system:server:washClothing', function(success, reason)
        if success then
            QBCore.Functions.Notify("Washed " .. QBCore.Shared.Items[itemName].label, "success")
        else
            QBCore.Functions.Notify(reason, "error")
        end
        
        cb({success = success})
    end, itemName)
end)

-- Repair clothing
RegisterNUICallback('repairClothing', function(data, cb)
    local itemName = data.item
    
    QBCore.Functions.TriggerCallback('clothing-system:server:repairClothing', function(success, reason)
        if success then
            QBCore.Functions.Notify("Repaired " .. QBCore.Shared.Items[itemName].label, "success")
        else
            QBCore.Functions.Notify(reason, "error")
        end
        
        cb({success = success})
    end, itemName)
end)

-- Resource cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    DestroyPeds()
    SetNuiFocus(false, false)
end)

-- Player commands
RegisterCommand(Config.WardrobeCommand, function()
    TriggerEvent('clothing-system:client:openWardrobe')
end, false)

RegisterCommand(Config.OutfitCommand, function(source, args)
    if #args < 1 then
        QBCore.Functions.Notify("Please specify an outfit name", "error")
        return
    end
    
    local outfitName = args[1]
    TriggerServerEvent('clothing-system:server:wearOutfit', outfitName)
end, false)

RegisterCommand('washclothes', function()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local nearLaundromat = false
    
    for _, location in ipairs(Config.Laundromats) do
        if #(playerCoords - vector3(location.x, location.y, location.z)) < 3.0 then
            nearLaundromat = true
            break
        end
    end
    
    if nearLaundromat then
        TriggerEvent('clothing-system:client:openLaundromat')
    else
        QBCore.Functions.Notify("You need to be at a laundromat", "error")
    end
end, false)

RegisterCommand('repairclothes', function()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local nearTailor = false
    
    for _, location in ipairs(Config.TailorShops) do
        if #(playerCoords - vector3(location.x, location.y, location.z)) < 3.0 then
            nearTailor = true
            break
        end
    end
    
    if nearTailor then
        TriggerEvent('clothing-system:client:openTailor')
    else
        QBCore.Functions.Notify("You need to be at a tailor shop", "error")
    end
end, false) 