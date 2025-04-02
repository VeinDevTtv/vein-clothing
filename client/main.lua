local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local currentStore = nil
local isInsideStore = false
local currentOutfit = {}
local inWardrobe = false
local clothingPeds = {}

-- Global variables for the clothing system
currentOutfit = {}
currentStore = nil
currentStoreBlip = nil
isInClothingStore = false
isPreviewing = false
isInWardrobe = false
isInLaundromat = false
isInTailor = false
storeNPCs = {}
storeZones = {}
previewCam = nil

-- Item category to component ID mapping
local clothingComponents = {
    tops = {component = 11, texture = 0},
    pants = {component = 4, texture = 0},
    shoes = {component = 6, texture = 0},
    masks = {component = 1, texture = 0},
    hats = {component = 0, prop = true, texture = 0},
    glasses = {component = 1, prop = true, texture = 0},
    ears = {component = 2, prop = true, texture = 0},
    watches = {component = 6, prop = true, texture = 0},
    bracelets = {component = 7, prop = true, texture = 0},
    torso = {component = 3, texture = 0},
    undershirt = {component = 8, texture = 0},
    vests = {component = 9, texture = 0},
    decals = {component = 10, texture = 0},
    accessories = {component = 7, texture = 0}
}

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

-- Initialize function (called on script start)
function Initialize()
    LoadStores()
    LoadLaundromats()
    LoadTailors()
    LoadPlayerOutfit()
    RegisterCommands()
    StartConditionMonitoring()
end

-- Load player's saved outfit on spawn
function LoadPlayerOutfit()
    CreateThread(function()
        while not QBCore.Functions.GetPlayerData().citizenid do
            Wait(100)
        end
        
        QBCore.Functions.TriggerCallback('clothing-system:server:getDefaultOutfit', function(outfit)
            if outfit and next(outfit) then
                WearOutfit(outfit)
                QBCore.Functions.Notify(Lang:t('info.default_outfit_loaded'), 'success')
            end
        end)
    end)
end

-- Create store blips on the map
function LoadStores()
    -- Remove existing blips first
    if currentStoreBlip then
        RemoveBlip(currentStoreBlip)
        currentStoreBlip = nil
    end
    
    -- Clear existing NPCs
    for _, npc in pairs(storeNPCs) do
        if DoesEntityExist(npc.handle) then
            DeleteEntity(npc.handle)
        end
    end
    storeNPCs = {}
    
    -- Clear existing zones
    for _, zone in pairs(storeZones) do
        zone:destroy()
    end
    storeZones = {}
    
    -- Create new blips and NPCs
    for storeType, storeData in pairs(Config.Stores) do
        for i, location in ipairs(storeData.locations) do
            -- Create blip
            local blip = AddBlipForCoord(location.x, location.y, location.z)
            SetBlipSprite(blip, storeData.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, storeData.blip.scale)
            SetBlipColour(blip, storeData.blip.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(storeData.label)
            EndTextCommandSetBlipName(blip)
            
            -- Create store clerk NPC
            CreateStoreClerk(storeType, location, i)
            
            -- Create interaction zone
            local zoneName = storeType .. "_" .. i
            local radius = 2.0
            local zone = CircleZone:Create(vector3(location.x, location.y, location.z), radius, {
                name = zoneName,
                debugPoly = Config.Debug,
                useZ = true
            })
            
            zone:onPlayerInOut(function(isPointInside)
                if isPointInside then
                    isInClothingStore = true
                    currentStore = storeType
                    QBCore.Functions.Notify(Lang:t('info.press_to_browse', {key = "~INPUT_CONTEXT~", store = storeData.label}), 'primary', 5000)
                else
                    if currentStore == storeType then
                        isInClothingStore = false
                        currentStore = nil
                    end
                end
            end)
            
            table.insert(storeZones, zone)
        end
    end
end

-- Create store clerk NPCs
function CreateStoreClerk(storeType, location, index)
    local storeData = Config.Stores[storeType]
    local clerk = {
        type = storeType,
        location = location,
        index = index,
        handle = nil
    }
    
    CreateThread(function()
        local model = GetHashKey(storeData.clerk.model)
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(0)
        end
        
        local npc = CreatePed(4, model, location.x, location.y, location.z - 1.0, location.w, false, true)
        FreezeEntityPosition(npc, true)
        SetEntityInvincible(npc, true)
        SetBlockingOfNonTemporaryEvents(npc, true)
        
        -- Apply animations
        if storeData.clerk.scenario then
            TaskStartScenarioInPlace(npc, storeData.clerk.scenario, 0, true)
        end
        
        clerk.handle = npc
        table.insert(storeNPCs, clerk)
        
        SetModelAsNoLongerNeeded(model)
    end)
end

-- Load laundromat locations
function LoadLaundromats()
    for i, location in ipairs(Config.Laundromats) do
        -- Create blip
        local blip = AddBlipForCoord(location.x, location.y, location.z)
        SetBlipSprite(blip, 362)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.7)
        SetBlipColour(blip, 3)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Lang:t('ui.laundromat'))
        EndTextCommandSetBlipName(blip)
        
        -- Create interaction zone
        local zoneName = "laundromat_" .. i
        local zone = CircleZone:Create(vector3(location.x, location.y, location.z), 2.0, {
            name = zoneName,
            debugPoly = Config.Debug,
            useZ = true
        })
        
        zone:onPlayerInOut(function(isPointInside)
            if isPointInside then
                isInLaundromat = true
                QBCore.Functions.Notify(Lang:t('info.press_to_access', {key = "~INPUT_CONTEXT~", place = Lang:t('ui.laundromat')}), 'primary', 5000)
            else
                isInLaundromat = false
            end
        end)
        
        table.insert(storeZones, zone) -- Reuse the same table
    end
end

-- Load tailor shop locations
function LoadTailors()
    for i, location in ipairs(Config.Tailors) do
        -- Create blip
        local blip = AddBlipForCoord(location.x, location.y, location.z)
        SetBlipSprite(blip, 366)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.7)
        SetBlipColour(blip, 21)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Lang:t('ui.tailor'))
        EndTextCommandSetBlipName(blip)
        
        -- Create tailor NPC
        local model = GetHashKey("s_m_m_tailor_01")
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(0)
        end
        
        local npc = CreatePed(4, model, location.x, location.y, location.z - 1.0, location.w, false, true)
        FreezeEntityPosition(npc, true)
        SetEntityInvincible(npc, true)
        SetBlockingOfNonTemporaryEvents(npc, true)
        TaskStartScenarioInPlace(npc, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)
        
        -- Create interaction zone
        local zoneName = "tailor_" .. i
        local zone = CircleZone:Create(vector3(location.x, location.y, location.z), 2.0, {
            name = zoneName,
            debugPoly = Config.Debug,
            useZ = true
        })
        
        zone:onPlayerInOut(function(isPointInside)
            if isPointInside then
                isInTailor = true
                QBCore.Functions.Notify(Lang:t('info.press_to_access', {key = "~INPUT_CONTEXT~", place = Lang:t('ui.tailor')}), 'primary', 5000)
            else
                isInTailor = false
            end
        end)
        
        table.insert(storeZones, zone) -- Reuse the same table
        table.insert(storeNPCs, {handle = npc, type = "tailor", index = i})
        
        SetModelAsNoLongerNeeded(model)
    end
end

-- Monitor the condition of clothing items and provide notifications
function StartConditionMonitoring()
    CreateThread(function()
        while true do
            Wait(60000) -- Check every minute
            
            -- Check worn items condition
            for _, item in pairs(currentOutfit) do
                if item.metadata and item.metadata.condition then
                    local condition = item.metadata.condition
                    
                    -- Notify player if any item is in poor condition
                    if condition <= 25 and condition > 10 then
                        QBCore.Functions.Notify(Lang:t('condition.poor', {item = item.label}), 'primary')
                    elseif condition <= 10 then
                        QBCore.Functions.Notify(Lang:t('condition.terrible', {item = item.label}), 'error')
                    end
                end
            end
        end
    end)
end

-- Wear an entire outfit
function WearOutfit(outfit)
    -- Reset appearance first
    ResetAppearance()
    
    -- Apply each clothing item
    for _, item in pairs(outfit) do
        ApplyClothing(item.name, item.metadata and item.metadata.variation or 0)
    end
    
    -- Save the current outfit globally
    currentOutfit = outfit
    
    -- Update the last worn timestamp for each item
    TriggerServerEvent('clothing-system:server:updateLastWorn', outfit)
end

-- Remove a specific clothing item
function RemoveClothing(itemName)
    -- Find the category of the item
    local item = QBCore.Shared.Items[itemName]
    if not item or not item.client or not item.client.category then
        QBCore.Functions.Notify(Lang:t('error.item_not_wearable'), 'error')
        return false
    end
    
    local category = item.client.category
    local componentInfo = clothingComponents[category]
    
    if not componentInfo then
        QBCore.Functions.Notify(Lang:t('error.unknown_category', {category = category}), 'error')
        return false
    end
    
    -- Remove the item from current outfit
    for i, outfitItem in pairs(currentOutfit) do
        if outfitItem.name == itemName then
            table.remove(currentOutfit, i)
            break
        end
    end
    
    -- Reset the specific component
    if componentInfo.prop then
        ClearPedProp(PlayerPedId(), componentInfo.component)
    else
        SetPedComponentVariation(PlayerPedId(), componentInfo.component, 0, 0, 2)
    end
    
    return true
end

-- Apply a specific clothing item
function ApplyClothing(itemName, variation)
    -- Find the item in the shared items list
    local item = QBCore.Shared.Items[itemName]
    if not item or not item.client or not item.client.category then
        QBCore.Functions.Notify(Lang:t('error.item_not_wearable'), 'error')
        return false
    end
    
    local category = item.client.category
    local componentInfo = clothingComponents[category]
    
    if not componentInfo then
        QBCore.Functions.Notify(Lang:t('error.unknown_category', {category = category}), 'error')
        return false
    end
    
    -- Get item variation data
    local variations = item.client.variations or {}
    local selectedVariation = variations[variation] or variations[1] or {drawable = 0, texture = 0}
    
    -- Apply the clothing item
    if componentInfo.prop then
        SetPedPropIndex(
            PlayerPedId(),
            componentInfo.component,
            selectedVariation.drawable or 0,
            selectedVariation.texture or 0,
            true
        )
    else
        SetPedComponentVariation(
            PlayerPedId(),
            componentInfo.component,
            selectedVariation.drawable or 0,
            selectedVariation.texture or 0,
            2
        )
    end
    
    return true
end

-- Reset player appearance to default
function ResetAppearance()
    local playerPed = PlayerPedId()
    
    -- Clear all props
    ClearAllPedProps(playerPed)
    
    -- Reset all components to default
    for category, componentInfo in pairs(clothingComponents) do
        if not componentInfo.prop then
            SetPedComponentVariation(playerPed, componentInfo.component, 0, 0, 2)
        end
    end
    
    -- Reset current outfit
    currentOutfit = {}
end

-- Preview a clothing item without adding it to inventory
function PreviewClothing(itemName, variation)
    -- Store current outfit for restoration later
    local previousOutfit = currentOutfit
    
    -- Apply the clothing item for preview
    local success = ApplyClothing(itemName, variation or 0)
    
    -- Start camera preview
    if not isPreviewing and success then
        StartPreviewCamera()
        isPreviewing = true
        
        -- Set a timeout to restore previous outfit
        CreateThread(function()
            local startTime = GetGameTimer()
            local previewDuration = 30000 -- 30 seconds
            
            while GetGameTimer() - startTime < previewDuration and isPreviewing do
                Wait(0)
                
                -- Show help text
                DisplayHelpTextThisFrame("preview_controls", false)
                
                -- Check for input to cancel preview
                if IsControlJustPressed(0, 194) then -- Backspace
                    break
                end
                
                -- Rotate player with keys
                if IsControlPressed(0, 108) then -- Numpad 4 (rotate left)
                    SetEntityHeading(playerPed, GetEntityHeading(playerPed) + 1.0)
                elseif IsControlPressed(0, 107) then -- Numpad 6 (rotate right)
                    SetEntityHeading(playerPed, GetEntityHeading(playerPed) - 1.0)
                end
            end
            
            -- Restore previous outfit
            WearOutfit(previousOutfit)
            StopPreviewCamera()
            isPreviewing = false
        end)
    end
    
    return success
end

-- Start camera for clothing preview
function StartPreviewCamera()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    -- Create a camera in front of the player
    previewCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    
    local offset = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 2.0, 0.0)
    SetCamCoord(previewCam, offset.x, offset.y, coords.z)
    PointCamAtCoord(previewCam, coords.x, coords.y, coords.z)
    
    SetCamActive(previewCam, true)
    RenderScriptCams(true, false, 0, true, false)
    
    -- Disable movement
    DisableControlActions(true)
end

-- Stop camera preview
function StopPreviewCamera()
    if previewCam then
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(previewCam, false)
        previewCam = nil
    end
    
    -- Re-enable movement
    DisableControlActions(false)
end

-- Helper function to disable control actions
function DisableControlActions(disable)
    CreateThread(function()
        while disable do
            DisableControlAction(0, 30, true) -- Movement
            DisableControlAction(0, 31, true) -- Movement
            DisableControlAction(0, 32, true) -- W
            DisableControlAction(0, 33, true) -- S
            DisableControlAction(0, 34, true) -- A
            DisableControlAction(0, 35, true) -- D
            DisableControlAction(0, 36, true) -- Crouch
            DisableControlAction(0, 44, true) -- Cover
            Wait(0)
        end
    end)
end

-- Main thread for input handling
CreateThread(function()
    while true do
        Wait(0)
        
        -- Store interaction
        if isInClothingStore and IsControlJustPressed(0, 38) then -- E key
            OpenClothingStore(currentStore)
        end
        
        -- Laundromat interaction
        if isInLaundromat and IsControlJustPressed(0, 38) then
            OpenLaundromat()
        end
        
        -- Tailor interaction
        if isInTailor and IsControlJustPressed(0, 38) then
            OpenTailor()
        end
    end
end)

-- Opens the clothing store UI
function OpenClothingStore(storeType)
    if not Config.Stores[storeType] then
        QBCore.Functions.Notify(Lang:t('error.store_not_found'), 'error')
        return
    end
    
    local storeData = Config.Stores[storeType]
    
    -- Get store inventory from server
    QBCore.Functions.TriggerCallback('clothing-system:server:getStoreInventory', function(inventory)
        if not inventory then
            QBCore.Functions.Notify(Lang:t('error.store_inventory_error'), 'error')
            return
        end
        
        -- Open the UI
        SendNUIMessage({
            action = "openStore",
            store = {
                type = storeType,
                label = storeData.label,
                inventory = inventory
            }
        })
        
        SetNuiFocus(true, true)
    end, storeType)
end

-- Opens the laundromat UI
function OpenLaundromat()
    -- Get player's dirty clothing
    QBCore.Functions.TriggerCallback('clothing-system:server:getDirtyClothing', function(dirtyClothing)
        if not dirtyClothing or #dirtyClothing == 0 then
            QBCore.Functions.Notify(Lang:t('info.no_dirty_clothing'), 'primary')
            return
        end
        
        -- Open the UI
        SendNUIMessage({
            action = "openLaundromat",
            clothes = dirtyClothing,
            price = Config.LaundryPrice
        })
        
        SetNuiFocus(true, true)
    end)
end

-- Opens the tailor UI
function OpenTailor()
    -- Get player's damaged clothing
    QBCore.Functions.TriggerCallback('clothing-system:server:getDamagedClothing', function(damagedClothing)
        if not damagedClothing or #damagedClothing == 0 then
            QBCore.Functions.Notify(Lang:t('info.no_damaged_clothing'), 'primary')
            return
        end
        
        -- Open the UI
        SendNUIMessage({
            action = "openTailor",
            clothes = damagedClothing,
            price = Config.RepairPrice
        })
        
        SetNuiFocus(true, true)
    end)
end

-- Export functions 
exports('openWardrobe', function()
    -- Get player's clothing and outfits
    QBCore.Functions.TriggerCallback('clothing-system:server:getPlayerClothing', function(clothing, outfits, wishlist)
        SendNUIMessage({
            action = "openWardrobe",
            data = {
                clothing = clothing,
                outfits = outfits,
                wishlist = wishlist,
                currentOutfit = currentOutfit
            }
        })
        
        SetNuiFocus(true, true)
        isInWardrobe = true
    end)
end)

exports('wearOutfit', WearOutfit)
exports('previewClothing', PreviewClothing)
exports('resetAppearance', ResetAppearance)

-- Initialize everything when resource starts
AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Initialize()
end)

-- Clean up when resource stops
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Clean up NPCs
    for _, npc in pairs(storeNPCs) do
        if DoesEntityExist(npc.handle) then
            DeleteEntity(npc.handle)
        end
    end
    
    -- Clean up zones
    for _, zone in pairs(storeZones) do
        zone:destroy()
    end
    
    -- Clean up camera
    if previewCam then
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(previewCam, false)
        previewCam = nil
    end
end) 