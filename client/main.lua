local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local currentStore = nil
local isInsideStore = false
local currentOutfit = {}
local inWardrobe = false
local clothingPeds = {}
local storeNPCs = {}
local storeZones = {}

-- Replace forward declarations with better implementation
-- Instead of creating placeholder functions, we'll explicitly validate that functions
-- exist before calling them in the Initialize function
local loadStoresFn
local loadLaundromatsFn
local loadTailorsFn
local loadPlayerOutfitFn

-- Ensure Config exists
if not Config then
    Config = {}
    print("^1[ERROR] Config not found. Make sure config.lua is loaded before this file.^7")
end

-- Create mock functions for CircleZone if PolyZone is not available
local mockDestroy = function() end
local mockOnPlayerInOut = function(cb) end

-- Mock CircleZone implementation for when PolyZone is not available
local MockCircleZone = {}
MockCircleZone.__index = MockCircleZone

-- Import PolyZone for zone creation if available
local CircleZone = nil

-- Safely attempt to load PolyZone
Citizen.CreateThread(function()
    -- Wait a moment for all resources to load
    Citizen.Wait(500)
    
    -- Check if PolyZone is available
    if GetResourceState('PolyZone') ~= 'missing' then
        -- Try to fetch the CircleZone from PolyZone
        local success, result = pcall(function()
            return exports['PolyZone']:GetCircleZone()
        end)
        
        if success and result then
            -- Successfully got CircleZone from PolyZone
            CircleZone = result
            print("^2[vein-clothing] Successfully loaded CircleZone from PolyZone^7")
        else
            -- Try alternative export method
            success, result = pcall(function()
                -- Create a test zone to verify the export works
                local testZone = exports['PolyZone']:CreateCircleZone(
                    vector3(0, 0, 0),  -- Far away test location
                    1.0,                -- Small radius
                    { name = "test_zone" }
                )
                testZone:destroy()     -- Clean up test zone
                
                -- Return a wrapper that uses the exports directly
                return {
                    Create = function(coords, radius, options)
                        return exports['PolyZone']:CreateCircleZone(coords, radius, options)
                    end
                }
            end)
            
            if success and result then
                CircleZone = result
                print("^2[vein-clothing] Successfully created CircleZone wrapper for PolyZone^7")
            else
                -- Use mock implementation as fallback
                print("^3[vein-clothing] PolyZone found but could not access CircleZone, using fallback implementation^7")
                CircleZone = CreateMockCircleZone()
            end
        end
    else
        -- PolyZone not available, use mock implementation
        print("^3[vein-clothing] PolyZone resource not found, using fallback zone implementation^7")
        CircleZone = CreateMockCircleZone()
    end
end)

-- Creates a mock implementation of CircleZone that does nothing but prevents errors
function CreateMockCircleZone()
    local MockCircleZone = {}
    
    -- Constructor function that returns a mock zone object
    MockCircleZone.Create = function(coords, radius, options)
        local mockZone = {
            -- Store the creation parameters
            coords = coords,
            radius = radius,
            options = options or {},
            
            -- Callbacks storage
            callbacks = {},
            
            -- Mock destroy method
            destroy = function(self)
                -- Clear any references to allow proper garbage collection
                self.callbacks = {}
                return true
            end,
            
            -- Mock onPlayerInOut method
            onPlayerInOut = function(self, cb)
                if type(cb) == "function" then
                    table.insert(self.callbacks, cb)
                end
                return self
            end
        }
        
        return mockZone
    end
    
    return MockCircleZone
end

-- Global variables for the clothing system
currentOutfit = {}
currentStore = nil
currentStoreBlip = nil
isInClothingStore = false
isPreviewing = false
isInWardrobe = false
isInLaundromat = false
isInTailor = false
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

-- Add this near the top of the file, after QBCore initialization
-- local ClothingConfig = exports['vein-clothing']:GetClothingConfig()
local ClothingConfig = {}

-- Function to get clothing config for an item
function GetClothingConfig(itemName)
    -- Use QBCore.Shared.Items directly instead of a possibly circular reference
    local item = QBCore.Shared.Items[itemName]
    if item and item.client then
        return item.client
    end
    return nil
end

-- Add this safety function near the top of the file
local function SafePlayerPedId()
    local ped = PlayerPedId()
    local attempts = 0
    
    -- Try multiple times to get a valid ped ID
    while (not ped or ped == 0) and attempts < 10 do
        Citizen.Wait(100)
        ped = PlayerPedId()
        attempts = attempts + 1
        
        -- If debugging is enabled, log the attempts
        if Config and Config.Debug then
            print("^3[vein-clothing] Attempting to get player ped ID, attempt " .. attempts .. "^7")
        end
    end
    
    -- Log warning if we couldn't get a valid ped after multiple attempts
    if not ped or ped == 0 then
        print("^1[ERROR] Failed to get a valid PlayerPedId after " .. attempts .. " attempts^7")
    end
    
    return ped or 0  -- Return 0 as fallback if ped is still nil
end

-- Initialize player data
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    
    -- Skip loading stores/tailors/laundromats here since the Initialize function will handle it
    print("^2[vein-clothing] Player loaded event received, updating player data...^7")
    
    -- Wait for resource to be fully ready before loading player outfit
    Citizen.CreateThread(function()
        -- Add a delay to let other handlers finish
        Citizen.Wait(5000)
        
        -- Only load the outfit, don't reload the stores
        -- Make sure we have the function reference by now
        if type(loadPlayerOutfitFn) == "function" then
            pcall(function()
                loadPlayerOutfitFn()
            end)
        else
            -- Try to get the function directly
            if type(LoadPlayerOutfit) == "function" then
                pcall(function()
                    LoadPlayerOutfit()
                end)
            else
                print("^1[ERROR] LoadPlayerOutfit function still not available in OnPlayerLoaded event.^7")
            end
        end
    end)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    currentOutfit = {}
    
    -- Clean up resources
    for _, npc in pairs(storeNPCs) do
        if DoesEntityExist(npc.handle) then
            DeleteEntity(npc.handle)
        end
    end
    storeNPCs = {}
    
    for _, zone in pairs(storeZones) do
        if zone and zone.destroy then
            zone:destroy()
        end
    end
    storeZones = {}
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

-- Create store blips on map
function LoadClothingBlips()
    for storeName, storeData in pairs(Config.Stores) do
        if storeData.blip then
            for _, location in ipairs(storeData.locations) do
                local blip = AddBlipForCoord(location.x, location.y, location.z)
                SetBlipSprite(blip, storeData.blip.sprite)
                SetBlipColour(blip, storeData.blip.color)
                SetBlipScale(blip, storeData.blip.scale)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(storeData.blip.label)
                EndTextCommandSetBlipName(blip)
            end
        end
    end
    
    -- Create laundromat blips
    for _, location in ipairs(Config.Laundromats) do
        local blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
        SetBlipSprite(blip, location.blip.sprite)
        SetBlipColour(blip, location.blip.color)
        SetBlipScale(blip, location.blip.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(location.blip.label)
        EndTextCommandSetBlipName(blip)
    end
    
    -- Create tailor blips
    for _, location in ipairs(Config.Tailors) do
        local blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
        SetBlipSprite(blip, location.blip.sprite)
        SetBlipColour(blip, location.blip.color)
        SetBlipScale(blip, location.blip.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(location.blip.label)
        EndTextCommandSetBlipName(blip)
    end
end

-- DO NOT USE: This function is deprecated, use LoadStores() instead
-- Keeping the function signature to avoid breaking existing code references
function LoadPeds()
    print("^3[vein-clothing] WARNING: LoadPeds() is deprecated. Using LoadStores() instead.^7")
    return LoadStores()
end

-- Cleanup peds when resource stops
function DestroyPeds()
    for _, npc in pairs(storeNPCs) do
        if DoesEntityExist(npc.handle) then
            DeleteEntity(npc.handle)
        end
    end
    storeNPCs = {}
    
    -- For backwards compatibility
    clothingPeds = {}
end

-- Non-target zone interaction logic
CreateThread(function()
    if Config.UseTarget then return end
    
    while true do
        local sleep = 1000
        local pos = GetEntityCoords(SafePlayerPedId())
        isInsideStore = false
        
        for storeName, storeData in pairs(Config.Stores) do
            for _, location in ipairs(storeData.locations) do
                local dist = #(pos - vector3(location.x, location.y, location.z))
                
                if dist < Config.PlayerInteraction.MaxDistance then
                    sleep = 0
                    isInsideStore = true
                    currentStore = storeName
                    
                    if dist < 1.5 then
                        QBCore.Functions.DrawText3D(location.x, location.y, location.z, "[E] Browse " .. storeData.label)
                        
                        if IsControlJustPressed(0, 38) then -- E key
                            TriggerEvent("vein-clothing:client:openStore", {store = storeName})
                        end
                    end
                    
                    break
                end
            end
            
            if isInsideStore then break end
        end
        
        -- Check for laundromats and tailor shops
        if not isInsideStore then
            for _, location in ipairs(Config.Laundromats) do
                local dist = #(pos - vector3(location.coords.x, location.coords.y, location.coords.z))
                
                if dist < Config.PlayerInteraction.MaxDistance then
                    sleep = 0
                    
                    if dist < 1.5 then
                        QBCore.Functions.DrawText3D(location.coords.x, location.coords.y, location.coords.z, "[E] Use Laundromat")
                        
                        if IsControlJustPressed(0, 38) then -- E key
                            TriggerEvent("vein-clothing:client:openLaundromat")
                        end
                    end
                    
                    break
                end
            end
            
            for _, location in ipairs(Config.Tailors) do
                local dist = #(pos - vector3(location.coords.x, location.coords.y, location.coords.z))
                
                if dist < Config.PlayerInteraction.MaxDistance then
                    sleep = 0
                    
                    if dist < 1.5 then
                        QBCore.Functions.DrawText3D(location.coords.x, location.coords.y, location.coords.z, "[E] Use Tailor Services")
                        
                        if IsControlJustPressed(0, 38) then -- E key
                            TriggerEvent("vein-clothing:client:openTailor")
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
RegisterNetEvent('vein-clothing:client:openStore', function(data)
    if inWardrobe then return end
    
    -- Debug log in verbose mode
    if Config and Config.Debug then
        print("^3[vein-clothing] openStore event received^7")
    end
    
    -- Handle different data structures from target vs direct event calls
    local storeName
    
    -- Direct format
    if data and data.store then
        storeName = data.store
    -- qb-target format (args parameter)
    elseif data and data.args and data.args.store then
        storeName = data.args.store
    end
    
    -- Fallback to global variable if we couldn't extract from data
    if not storeName and currentStore then
        storeName = currentStore
        if Config and Config.Debug then
            print("^3[vein-clothing] Using fallback currentStore: " .. storeName .. "^7")
        end
    end
    
    if not storeName then
        QBCore.Functions.Notify("Could not determine which store to open", "error")
        return
    end
    
    if Config and Config.Debug then
        print("^3[vein-clothing] Opening store: " .. storeName .. "^7")
    end
    
    -- Call the OpenClothingStore function directly instead of doing everything here
    OpenClothingStore(storeName)
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
    local model = GetEntityModel(SafePlayerPedId())
    
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
    if item.client.event == "vein-clothing:client:wearItem" then
        -- Component-based clothing
        SetPedComponentVariation(SafePlayerPedId(), component, drawable, texture, 0)
    elseif item.client.event == "vein-clothing:client:wearProp" then
        -- Prop-based item (hats, glasses, etc)
        SetPedPropIndex(SafePlayerPedId(), component, drawable, texture, true)
    end
    
    cb({success = true})
end)

-- Purchase clothing item
RegisterNUICallback('purchaseItem', function(data, cb)
    local itemName = data.item
    local price = data.price
    local variation = data.variation or 0
    
    QBCore.Functions.TriggerCallback('vein-clothing:server:purchaseItem', function(success, reason)
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
    
    TriggerServerEvent('vein-clothing:server:updateWishlist', wishlist)
    
    cb({success = true})
end)

-- Save outfit
RegisterNUICallback('saveOutfit', function(data, cb)
    local outfit = data.outfit
    
    TriggerServerEvent('vein-clothing:server:saveOutfit', outfit)
    
    cb({success = true})
end)

-- Close UI
RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    cb({success = true})
end)

-- Function to handle inventory interactions based on config
function HandleInventory(action, ...)
    local args = {...}
    local inventoryType = Config.Inventory.Type
    
    if action == 'notification' then
        local item, type, qty = args[1], args[2], args[3] or 1
        if inventoryType == 'qb-inventory' then
            TriggerEvent('inventory:client:ItemBox', QBCore.Shared.Items[item], type, qty)
        elseif inventoryType == 'ox_inventory' then
            local title = type == 'add' and 'Item Added' or 'Item Removed'
            exports.ox_inventory:notify({
                title = title,
                description = QBCore.Shared.Items[item].label .. ' x' .. qty,
                type = type == 'add' and 'success' or 'error'
            })
        elseif inventoryType == 'custom' then
            -- Custom inventory notification
            TriggerEvent(Config.Inventory.Custom.TriggerEvent, item, type, qty)
        end
    elseif action == 'hasItem' then
        local item, amount = args[1], args[2] or 1
        if inventoryType == 'qb-inventory' then
            return QBCore.Functions.HasItem(item, amount)
        elseif inventoryType == 'ox_inventory' then
            return exports.ox_inventory:GetItemCount(item) >= amount
        elseif inventoryType == 'custom' then
            -- Custom inventory check
            return exports[Config.Inventory.Custom.ResourceName][Config.Inventory.Custom.HasItem](item, amount)
        end
    end
end

-- Function to show notifications based on config
function ShowNotification(message, type, duration)
    local notifType = Config.Notifications.Type
    duration = duration or Config.Notifications.Duration
    
    if not Config.Notifications.Enable then return end
    
    if notifType == 'qb' then
        QBCore.Functions.Notify(message, type, duration)
    elseif notifType == 'ox' then
        lib.notify({
            title = type == 'success' and 'Success' or (type == 'error' and 'Error' or 'Info'),
            description = message,
            type = type,
            position = Config.Notifications.Position,
            duration = duration
        })
    elseif notifType == 'custom' then
        -- Add support for custom notification systems
        TriggerEvent('your-custom-notification', message, type, duration)
    end
end

-- Helper function to get component ID from category
function GetComponentIdFromCategory(category)
    local componentMap = {
        ['mask'] = 1,
        ['hair'] = 2,
        ['torso'] = 3,
        ['legs'] = 4,
        ['bag'] = 5,
        ['shoes'] = 6,
        ['accessory'] = 7,
        ['undershirt'] = 8,
        ['kevlar'] = 9,
        ['badge'] = 10,
        ['torso2'] = 11
    }
    return componentMap[category]
end

-- Helper function to get prop ID from category
function GetPropIdFromCategory(category)
    local propMap = {
        ['hat'] = 0,
        ['glasses'] = 1,
        ['ear'] = 2,
        ['watch'] = 6,
        ['bracelet'] = 7
    }
    return propMap[category]
end

-- Function to check if addon clothing is loaded
function HasAddonClothingLoaded(model)
    return HasModelLoaded(model)
end

-- Function to check if addon prop is loaded
function HasPropLoaded(model)
    return HasModelLoaded(model)
end

-- Function to handle any type of clothing item
local function HandleClothingItem(itemData)
    if not itemData then return false end
    
    -- Get the clothing config
    local config = GetClothingConfig(itemData.name)
    if not config then
        if Config.Debug then
            print("^1[ERROR] No clothing configuration found for item: " .. itemData.name .. "^7")
        end
        return false
    end
    
    -- Get the component ID based on the category
    local componentId = GetComponentIdFromCategory(config.category)
    if not componentId and config.type ~= 'prop' then 
        if Config.Debug then
            print("^1[ERROR] Invalid category for item: " .. itemData.name .. "^7")
        end
        return false 
    end
    
    -- Handle different types of clothing
    if config.type == 'prop' then
        -- Handle props (hats, glasses, etc.)
        local propId = GetPropIdFromCategory(config.category)
        if not propId then 
            if Config.Debug then
                print("^1[ERROR] Invalid prop category for item: " .. itemData.name .. "^7")
            end
            return false 
        end
        
        -- Check if the prop exists in the addon
        if config.isAddon and not HasPropLoaded(config.model) then
            -- Load the addon prop if needed
            RequestModel(config.model)
            while not HasModelLoaded(config.model) do
                Wait(0)
            end
        end
        
        -- Apply the prop
        SetPedPropIndex(SafePlayerPedId(), propId, config.drawable, config.texture, true)
    else
        -- Handle regular clothing components
        if config.isAddon then
            -- Handle addon clothing
            if not HasAddonClothingLoaded(config.model) then
                -- Load the addon clothing if needed
                RequestModel(config.model)
                while not HasModelLoaded(config.model) do
                    Wait(0)
                end
            end
            
            -- Apply addon clothing
            SetPedComponentVariation(SafePlayerPedId(), componentId, config.drawable, config.texture, 0)
        else
            -- Handle default GTA clothing
            SetPedComponentVariation(SafePlayerPedId(), componentId, config.drawable, config.texture, 0)
        end
    end
    
    return true
end

-- Update existing code to use the new functions
RegisterNetEvent('vein-clothing:client:wearItem', function(itemData)
    if not itemData then return end
    
    local success = HandleClothingItem(itemData)
    if success then
        -- Update the current outfit
        currentOutfit[itemData.client.category] = itemData
        
        -- Trigger degradation
        TriggerServerEvent('vein-clothing:server:degradeClothing', itemData.name, Config.Condition.WornDegradationMin)
        
        -- Show notification
        ShowNotification('You are now wearing ' .. itemData.label, 'success')
        HandleInventory('notification', itemData.name, 'remove', 1)
    else
        ShowNotification('Failed to wear ' .. itemData.label, 'error')
    end
end)

-- Wear/remove prop item (hats, glasses, etc.)
RegisterNetEvent('vein-clothing:client:wearProp', function(itemData)
    if not itemData or not itemData.client then return end
    
    local component = itemData.client.component
    local drawable = itemData.client.drawable
    local texture = itemData.client.texture
    
    -- Check if removing or wearing
    if currentOutfit[component] and currentOutfit[component].name == itemData.name then
        -- Remove prop
        ClearPedProp(SafePlayerPedId(), component)
        currentOutfit[component] = nil
        
        -- Degrade condition slightly when removing
        TriggerServerEvent('vein-clothing:server:degradeClothing', itemData.name, 0.1)
    else
        -- Wear prop
        SetPedPropIndex(SafePlayerPedId(), component, drawable, texture, true)
        
        -- Update current outfit
        currentOutfit[component] = {
            name = itemData.name,
            drawable = drawable,
            texture = texture,
            variation = 0
        }
        
        -- Degrade condition when wearing
        TriggerServerEvent('vein-clothing:server:degradeClothing', itemData.name, Config.Condition.degradePerUse)
    end
end)

-- Open personal wardrobe
RegisterNetEvent('vein-clothing:client:openWardrobe', function()
    if inWardrobe then return end
    inWardrobe = true
    
    -- Get player's owned clothing and saved outfits
    QBCore.Functions.TriggerCallback('vein-clothing:server:getPlayerClothing', function(clothing, outfits, wishlist)
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
RegisterNetEvent('vein-clothing:client:openLaundromat', function()
    -- Get player's dirty clothing
    QBCore.Functions.TriggerCallback('vein-clothing:server:getDirtyClothing', function(clothing)
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
RegisterNetEvent('vein-clothing:client:openTailor', function()
    -- Get player's damaged clothing
    QBCore.Functions.TriggerCallback('vein-clothing:server:getDamagedClothing', function(clothing)
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
    
    QBCore.Functions.TriggerCallback('vein-clothing:server:washClothing', function(success, reason)
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
    
    QBCore.Functions.TriggerCallback('vein-clothing:server:repairClothing', function(success, reason)
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
    TriggerEvent('vein-clothing:client:openWardrobe')
end, false)

RegisterCommand(Config.OutfitCommand, function(source, args)
    if #args < 1 then
        QBCore.Functions.Notify("Please specify an outfit name", "error")
        return
    end
    
    local outfitName = args[1]
    TriggerServerEvent('vein-clothing:server:wearOutfit', outfitName)
end, false)

RegisterCommand('washclothes', function()
    local playerCoords = GetEntityCoords(SafePlayerPedId())
    local nearLaundromat = false
    
    for _, location in ipairs(Config.Laundromats) do
        if #(playerCoords - vector3(location.coords.x, location.coords.y, location.coords.z)) < 3.0 then
            nearLaundromat = true
            break
        end
    end
    
    if nearLaundromat then
        TriggerEvent('vein-clothing:client:openLaundromat')
    else
        QBCore.Functions.Notify("You need to be at a laundromat", "error")
    end
end, false)

RegisterCommand('repairclothes', function()
    local playerCoords = GetEntityCoords(SafePlayerPedId())
    local nearTailor = false
    
    for _, location in ipairs(Config.Tailors) do
        if #(playerCoords - vector3(location.coords.x, location.coords.y, location.coords.z)) < 3.0 then
            nearTailor = true
            break
        end
    end
    
    if nearTailor then
        TriggerEvent('vein-clothing:client:openTailor')
    else
        QBCore.Functions.Notify("You need to be at a tailor shop", "error")
    end
end, false)

-- Initialize function (called on script start)
function Initialize()
    -- Print debug message for initialization start
    print("^2[vein-clothing] Starting initialization process...^7")
    
    -- Set up local references to functions now that they should be defined
    loadStoresFn = LoadStores
    loadLaundromatsFn = LoadLaundromats
    loadTailorsFn = LoadTailors
    loadPlayerOutfitFn = LoadPlayerOutfit
    
    -- Validate function references
    if type(loadStoresFn) ~= "function" then
        print("^1[ERROR] LoadStores function not defined. Store NPCs won't be loaded.^7")
        loadStoresFn = function() return false end
    end
    
    if type(loadLaundromatsFn) ~= "function" then
        print("^1[ERROR] LoadLaundromats function not defined. Laundromat NPCs won't be loaded.^7")
        loadLaundromatsFn = function() return false end
    end
    
    if type(loadTailorsFn) ~= "function" then
        print("^1[ERROR] LoadTailors function not defined. Tailor NPCs won't be loaded.^7")
        loadTailorsFn = function() return false end
    end
    
    if type(loadPlayerOutfitFn) ~= "function" then
        print("^1[ERROR] LoadPlayerOutfit function not defined. Player outfits won't be loaded.^7")
        loadPlayerOutfitFn = function() return false end
    end
    
    -- Wait for QBCore to be fully initialized
    local qbCoreAttempts = 0
    while not QBCore do
        if qbCoreAttempts > 50 then  -- 5 seconds timeout
            print("^1[ERROR] Failed to get QBCore after 5 seconds. Aborting initialization.^7")
            return
        end
        
        Citizen.Wait(100)
        qbCoreAttempts = qbCoreAttempts + 1
        QBCore = exports['qb-core']:GetCoreObject()
    end
    
    print("^2[vein-clothing] QBCore initialized, waiting for player data...^7")
    
    -- Wait for PlayerData to be available - with timeout
    local playerDataAttempts = 0
    local playerData = nil
    
    while playerDataAttempts < 150 do  -- 15 second timeout
        Citizen.Wait(100)
        playerDataAttempts = playerDataAttempts + 1
        
        -- Try to get player data
        pcall(function()
            playerData = QBCore.Functions.GetPlayerData()
        end)
        
        -- Check if we have valid player data
        if playerData and playerData.citizenid then
            break
        end
        
        -- Log progress every second
        if playerDataAttempts % 10 == 0 and Config and Config.Debug then
            print("^3[vein-clothing] Waiting for player data... Attempt " .. playerDataAttempts .. "/150^7")
        end
    end
    
    if not playerData or not playerData.citizenid then
        print("^1[ERROR] Failed to get player data after 15 seconds. Continuing with partial initialization.^7")
    else
        PlayerData = playerData
        print("^2[vein-clothing] Player data loaded successfully.^7")
    end
    
    -- Initialize ClothingConfig locally to prevent circular references
    if next(ClothingConfig) == nil then
        ClothingConfig = Config.Items or {} -- Use built-in config if available
    end
    
    -- Debug config message
    if Config.Debug then
        print("^2[vein-clothing] Initializing with config: ^7")
        for k, v in pairs(Config) do
            if type(v) ~= "table" then
                print("  " .. k .. ": " .. tostring(v))
            else
                print("  " .. k .. ": table")
            end
        end
    end
    
    -- Check if qb-target is available when UseTarget is enabled
    if Config.UseTarget then
        if GetResourceState('qb-target') == 'missing' then
            print("^1[vein-clothing] ERROR: Config.UseTarget is enabled but qb-target resource is not available^7")
            print("^1[vein-clothing] Please ensure qb-target is started before this resource^7")
            Config.UseTarget = false
            print("^3[vein-clothing] Falling back to non-target mode^7")
        else
            print("^2[vein-clothing] qb-target detected, target integration enabled^7")
        end
    end
    
    -- Export the config for other resources to use
    exports('GetClothingConfig', function()
        return Config.Items or Config -- Return the clothing configuration
    end)
    
    -- Give the resource more time to fully initialize before loading stores
    Citizen.CreateThread(function()
        -- Add a longer delay to ensure all resources and functions are loaded
        Citizen.Wait(3000)
        
        print("^2[vein-clothing] Initialization delay complete, setting up world objects now...^7")
        
        -- Load various components in the correct order with proper error handling
        print("^3[vein-clothing] Loading stores...^7")
        local storesLoaded = false
        
        -- Safely call LoadStores with error handling
        pcall(function()
            storesLoaded = loadStoresFn()
        end)
        
        if not storesLoaded then
            print("^1[vein-clothing] ERROR: Failed to load stores. Continuing with minimal initialization.^7")
        end
        
        print("^3[vein-clothing] Loading laundromats...^7")
        local laundromatsLoaded = false
        
        -- Safely call LoadLaundromats with error handling
        pcall(function()
            laundromatsLoaded = loadLaundromatsFn()
        end)
        
        if not laundromatsLoaded then
            print("^1[vein-clothing] ERROR: Failed to load laundromats. Continuing with partial initialization.^7")
        end
        
        print("^3[vein-clothing] Loading tailors...^7")
        local tailorsLoaded = false
        
        -- Safely call LoadTailors with error handling
        pcall(function()
            tailorsLoaded = loadTailorsFn()
        end)
        
        if not tailorsLoaded then
            print("^1[vein-clothing] ERROR: Failed to load tailors. Continuing with partial initialization.^7")
        end
        
        print("^3[vein-clothing] Loading player outfit...^7")
        local outfitLoaded = false
        
        -- Safely call LoadPlayerOutfit with error handling
        pcall(function()
            loadPlayerOutfitFn()
            outfitLoaded = true
        end)
        
        if not outfitLoaded then
            print("^1[vein-clothing] ERROR: Failed to load player outfit. Continuing without outfit.^7")
        end
        
        print("^3[vein-clothing] Starting condition monitoring...^7")
        local monitoringStarted = false
        
        -- Safely start condition monitoring with error handling
        pcall(function()
            StartConditionMonitoring()
            monitoringStarted = true
        end)
        
        if not monitoringStarted then
            print("^1[vein-clothing] ERROR: Failed to start condition monitoring.^7")
        end
        
        print("^2[vein-clothing] Initialization complete!^7")
    end)
end

-- Load player's saved outfit on spawn
function LoadPlayerOutfit()
    -- Debug log
    if Config and Config.Debug then
        print("^3[vein-clothing] Attempting to load player outfit...^7")
    end
    
    -- Wrap in a CreateThread to avoid blocking
    CreateThread(function()
        -- Initialize local variables for tracking
        local loadAttempts = 0
        local citizenid = nil
        local maxAttempts = 100  -- 10 second timeout
        
        -- Wait until we have a valid citizenid or timeout
        while loadAttempts < maxAttempts do
            -- Safe attempt to get player data
            local success, playerData = pcall(function()
                return QBCore.Functions.GetPlayerData()
            end)
            
            -- Check if we got valid player data
            if success and playerData and playerData.citizenid then
                citizenid = playerData.citizenid
                break
            end
            
            -- Wait before trying again
            Wait(100)
            loadAttempts = loadAttempts + 1
            
            -- Debug logging of attempts
            if Config and Config.Debug and loadAttempts % 10 == 0 then
                print("^3[vein-clothing] Waiting for citizenid... Attempt " .. loadAttempts .. "/" .. maxAttempts .. "^7")
            end
        end
        
        -- If we couldn't get a citizenid, log error and stop
        if not citizenid then
            print("^1[ERROR] Failed to get citizenid after " .. loadAttempts .. " attempts. Outfit loading aborted.^7")
            return
        end
        
        if Config and Config.Debug then
            print("^3[vein-clothing] Got citizenid: " .. citizenid .. ". Loading default outfit...^7")
        end
        
        -- Attempt to get the default outfit from server
        local outfitLoaded = false
        
        QBCore.Functions.TriggerCallback('vein-clothing:server:getDefaultOutfit', function(outfit)
            -- Check if we received a valid outfit
            if outfit and type(outfit) == "table" and next(outfit) then
                if Config and Config.Debug then
                    print("^3[vein-clothing] Default outfit received from server. Applying...^7")
                    
                    -- Print outfit details in debug mode
                    for category, itemData in pairs(outfit) do
                        print("  " .. category .. ": " .. (itemData.name or "unknown"))
                    end
                end
                
                -- Safe attempt to wear the outfit
                local wearSuccess = pcall(function()
                    WearOutfit(outfit)
                end)
                
                if wearSuccess then
                    -- Successfully applied outfit
                    outfitLoaded = true
                    
                    -- Only show notification if Config and QBCore are valid
                    if Config and Config.Notifications and Config.Notifications.Enable then
                        -- Use pcall to safely show notification
                        pcall(function()
                            QBCore.Functions.Notify(Lang:t('info.default_outfit_loaded'), 'success', Config.Notifications.Duration)
                        end)
                    end
                    
                    if Config and Config.Debug then
                        print("^2[vein-clothing] Default outfit applied successfully^7")
                    end
                else
                    print("^1[ERROR] Failed to apply default outfit^7")
                end
            else
                if Config and Config.Debug then
                    print("^3[vein-clothing] No default outfit found or received invalid outfit data^7")
                end
            end
        end)
        
        -- Wait for the callback to complete
        local callbackWait = 0
        while not outfitLoaded and callbackWait < 50 do
            Wait(100)
            callbackWait = callbackWait + 1
        end
        
        if not outfitLoaded and Config and Config.Debug then
            print("^3[vein-clothing] No outfit was loaded after waiting " .. callbackWait * 100 .. "ms^7")
        end
    end)
    
    return true
end

-- Create store blips on the map
function LoadStores()
    -- Debug log
    if Config.Debug then
        print("^3[vein-clothing] Loading stores...^7")
    end
    
    -- Check if Config is loaded
    if not Config then
        print("^1[ERROR] Config not found. Make sure config.lua is loaded before client/main.lua^7")
        return false
    end
    
    -- Check if Config.Stores exists
    if not Config.Stores then
        print("^1[ERROR] Config.Stores not found. Make sure config.lua is properly configured.^7")
        return false
    end
    
    -- Remove existing blips first
    if currentStoreBlip then
        RemoveBlip(currentStoreBlip)
        currentStoreBlip = nil
    end
    
    -- Clear existing NPCs
    if storeNPCs then
        for _, npc in pairs(storeNPCs) do
            if DoesEntityExist(npc.handle) then
                DeleteEntity(npc.handle)
            end
        end
    end
    storeNPCs = storeNPCs or {}
    
    -- Clear existing zones
    if storeZones then
        for _, zone in pairs(storeZones) do
            if zone and zone.destroy then
                zone:destroy()
            end
        end
    end
    storeZones = storeZones or {}
    
    local storesCount = 0
    local npcCount = 0
    
    -- Create new blips and NPCs
    for storeType, storeData in pairs(Config.Stores) do
        if Config.Debug then
            print("^3[vein-clothing] Setting up store: " .. storeType .. "^7")
        end
        
        -- Skip if store data is invalid
        if not storeData or not storeData.locations then
            print("^1[ERROR] Invalid store data for " .. storeType .. "^7")
            goto continue
        end
        
        for i, location in ipairs(storeData.locations) do
            storesCount = storesCount + 1
            
            -- Verify location data
            if not location or not location.x or not location.y or not location.z then
                print("^1[ERROR] Invalid location data for " .. storeType .. " at index " .. i .. "^7")
                goto continue_location
            end
            
            -- Create blip
            local blip = AddBlipForCoord(location.x, location.y, location.z)
            SetBlipSprite(blip, storeData.blip and storeData.blip.sprite or 73)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, storeData.blip and storeData.blip.scale or 0.7)
            SetBlipColour(blip, storeData.blip and storeData.blip.color or 0)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(storeData.label or "Clothing Store")
            EndTextCommandSetBlipName(blip)
            
            -- Create store clerk NPC
            local modelName = storeData.clerk and storeData.clerk.model or "a_f_y_business_01"
            local modelHash = GetHashKey(modelName)
            
            if Config.Debug then
                print("^3[vein-clothing] Attempting to load model: " .. modelName .. " (Hash: " .. modelHash .. ")^7")
            end
            
            -- Request model with proper error handling
            RequestModel(modelHash)
            
            local timeout = 0
            local modelLoaded = false
            
            -- Wait for model to load with timeout
            while not HasModelLoaded(modelHash) and timeout < 30 do
                Wait(100)
                timeout = timeout + 1
                if Config.Debug and timeout % 10 == 0 then
                    print("^3[vein-clothing] Still waiting for model to load: " .. modelName .. " (Attempt " .. timeout .. "/30)^7")
                end
            end
            
            modelLoaded = HasModelLoaded(modelHash)
            
            if not modelLoaded then
                print("^1[ERROR] Failed to load model " .. modelName .. " after 30 attempts. Using fallback model.^7")
                
                -- Try fallback model
                modelName = "a_f_y_business_01"  -- Fallback to a common model
                modelHash = GetHashKey(modelName)
                RequestModel(modelHash)
                
                timeout = 0
                while not HasModelLoaded(modelHash) and timeout < 30 do
                    Wait(100)
                    timeout = timeout + 1
                end
                
                modelLoaded = HasModelLoaded(modelHash)
                
                if not modelLoaded then
                    print("^1[ERROR] Failed to load fallback model. Skipping NPC creation for this store.^7")
                    goto continue_location
                end
            end
            
            if Config.Debug then
                print("^3[vein-clothing] Model loaded successfully: " .. modelName .. "^7")
            end
            
            -- Safety check for position
            local safeX, safeY, safeZ = location.x, location.y, location.z - 1.0
            local safeW = location.w or 0.0
            
            local npc = CreatePed(4, modelHash, safeX, safeY, safeZ, safeW, false, true)
            
            if DoesEntityExist(npc) then
                npcCount = npcCount + 1
                
                if Config.Debug then
                    print("^3[vein-clothing] NPC created successfully at location: " .. 
                        safeX .. ", " .. safeY .. ", " .. safeZ .. "^7")
                end
                
                -- Make sure the NPC is properly configured
                if not IsEntityDead(npc) then
                    FreezeEntityPosition(npc, true)
                    SetEntityInvincible(npc, true)
                    SetBlockingOfNonTemporaryEvents(npc, true)
                    
                    -- Apply animation with a safe default
                    local scenario = "WORLD_HUMAN_STAND_IMPATIENT"
                    if storeData.clerk and storeData.clerk.scenario then
                        scenario = storeData.clerk.scenario
                    end
                    
                    -- Use pcall to handle any scenario errors
                    local scenarioSuccess = pcall(function()
                        TaskStartScenarioInPlace(npc, scenario, 0, true)
                    end)
                    
                    if not scenarioSuccess and Config.Debug then
                        print("^3[WARNING] Failed to start scenario " .. scenario .. " for NPC. Using default.^7")
                        TaskStartScenarioInPlace(npc, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)
                    end
                    
                    -- Store reference to NPC
                    table.insert(storeNPCs, {
                        handle = npc, 
                        type = storeType, 
                        index = i,
                        location = location
                    })
                    
                    -- Add target interaction if enabled
                    if Config.UseTarget then
                        if Config.Debug then
                            print("^3[vein-clothing] Adding qb-target to clerk NPC^7")
                        end
                        
                        if GetResourceState('qb-target') ~= 'missing' then
                            -- Use pcall to avoid crashing if target export fails
                            pcall(function()
                                exports['qb-target']:AddTargetEntity(npc, {
                                    options = {
                                        {
                                            type = "client",
                                            event = "vein-clothing:client:openStore",
                                            icon = "fas fa-tshirt",
                                            label = "Browse " .. (storeData.label or "Clothing Store"),
                                            args = {
                                                store = storeType
                                            }
                                        }
                                    },
                                    distance = Config.PlayerInteraction and Config.PlayerInteraction.MaxDistance or 3.0
                                })
                            end)
                        else
                            print("^3[WARNING] qb-target not found, disabling targeting for store clerks^7")
                        end
                    else
                        -- Create interaction zone if PolyZone is available
                        if CircleZone then
                            -- Use pcall to avoid crashing if zone creation fails
                            pcall(function() 
                                local zone = CircleZone.Create(
                                    vector3(location.x, location.y, location.z), 
                                    2.0, 
                                    {
                                        name = storeType .. "_" .. i,
                                        debugPoly = Config.Debug,
                                        useZ = true
                                    }
                                )
                                
                                zone:onPlayerInOut(function(isPointInside)
                                    if isPointInside then
                                        currentStore = storeType
                                        inStore = true
                                        QBCore.Functions.Notify("Press [E] to browse " .. (storeData.label or "Clothing Store"), "primary", 5000)
                                    else
                                        inStore = false
                                        currentStore = nil
                                    end
                                end)
                                
                                table.insert(storeZones, zone)
                            end)
                        end
                    end
                else
                    if Config.Debug then
                        print("^1[ERROR] NPC was created but is dead. Deleting entity.^7")
                    end
                    DeleteEntity(npc)
                end
            else
                print("^1[ERROR] Failed to create NPC at location " .. 
                    safeX .. ", " .. safeY .. ", " .. safeZ .. "^7")
            end
            
            -- Free model regardless of success
            SetModelAsNoLongerNeeded(modelHash)
            
            ::continue_location::
        end
        
        ::continue::
    end
    
    if Config.Debug then
        print("^3[vein-clothing] Successfully loaded " .. npcCount .. " store NPCs out of " .. storesCount .. " configured locations^7")
    end
    
    return true
end

-- Load laundromat locations
function LoadLaundromats()
    if Config.Debug then
        print("^3[vein-clothing] Loading laundromats...^7")
    end
    
    -- Check if Config.Laundromats exists
    if not Config.Laundromats then
        print("^1[ERROR] Config.Laundromats not found. Make sure config.lua is properly configured.^7")
        return false
    end
    
    for i, location in ipairs(Config.Laundromats) do
        -- Skip if location data is invalid
        if not location or not location.coords then
            print("^1[ERROR] Invalid laundromat data at index " .. i .. "^7")
            goto continue
        end
        
        -- Create blip
        local blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
        local blipData = location.blip or {}
        SetBlipSprite(blip, blipData.sprite or 73)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, blipData.scale or 0.7)
        SetBlipColour(blip, blipData.color or 3)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(blipData.label or "Laundromat")
        EndTextCommandSetBlipName(blip)
        
        -- Create laundromat NPC
        local model = GetHashKey("s_f_y_shop_mid")
        RequestModel(model)
        
        local timeout = 0
        while not HasModelLoaded(model) and timeout < 50 do
            Wait(100)
            timeout = timeout + 1
        end
        
        if not HasModelLoaded(model) then
            print("^1[ERROR] Failed to load model for laundromat at index " .. i .. "^7")
            goto continue
        end
        
        local npc = CreatePed(4, model, location.coords.x, location.coords.y, location.coords.z - 1.0, location.coords.w or 0.0, false, true)
        
        if not DoesEntityExist(npc) then
            print("^1[ERROR] Failed to create ped for laundromat at index " .. i .. "^7")
            goto continue
        end
        
        FreezeEntityPosition(npc, true)
        SetEntityInvincible(npc, true)
        SetBlockingOfNonTemporaryEvents(npc, true)
        TaskStartScenarioInPlace(npc, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)
        
        table.insert(storeNPCs, {
            handle = npc, 
            type = "laundromat", 
            index = i,
            location = location.coords
        })
        
        -- Add target interaction
        if Config.UseTarget then
            if GetResourceState('qb-target') ~= 'missing' then
                exports['qb-target']:AddTargetEntity(npc, {
                    options = {
                        {
                            type = "client",
                            event = "vein-clothing:client:openLaundromat",
                            icon = "fas fa-soap",
                            label = "Use Laundromat"
                        }
                    },
                    distance = Config.PlayerInteraction and Config.PlayerInteraction.MaxDistance or 3.0
                })
            else
                print("^3[WARNING] qb-target not found, disabling targeting for laundromat NPCs^7")
            end
        else
            -- Create interaction zone
            if CircleZone then
                local zone = CircleZone:Create(
                    vector3(location.coords.x, location.coords.y, location.coords.z), 
                    2.0, 
                    {
                        name = "laundromat_" .. i,
                        debugPoly = Config.Debug,
                        useZ = true
                    }
                )
                
                zone:onPlayerInOut(function(isPointInside)
                    if isPointInside then
                        isInLaundromat = true
                        QBCore.Functions.Notify("Press [E] to use the laundromat", "primary", 5000)
                    else
                        isInLaundromat = false
                    end
                end)
                
                table.insert(storeZones, zone)
            end
        end
        
        SetModelAsNoLongerNeeded(model)
        
        ::continue::
    end
    
    if Config.Debug then
        local count = 0
        for _, npc in pairs(storeNPCs) do
            if npc.type == "laundromat" then
                count = count + 1
            end
        end
        print("^3[vein-clothing] Successfully loaded " .. count .. " laundromats^7")
    end
    
    return true
end

-- Load tailor shop locations
function LoadTailors()
    if Config.Debug then
        print("^3[vein-clothing] Loading tailors...^7")
    end
    
    -- Check if Config.Tailors exists
    if not Config.Tailors then
        print("^1[ERROR] Config.Tailors not found. Make sure config.lua is properly configured.^7")
        return false
    end
    
    for i, location in ipairs(Config.Tailors) do
        -- Skip if location data is invalid
        if not location or not location.coords then
            print("^1[ERROR] Invalid tailor data at index " .. i .. "^7")
            goto continue
        end
        
        -- Create blip
        local blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
        local blipData = location.blip or {}
        SetBlipSprite(blip, blipData.sprite or 73)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, blipData.scale or 0.7)
        SetBlipColour(blip, blipData.color or 4)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(blipData.label or "Tailor Shop")
        EndTextCommandSetBlipName(blip)
        
        -- Create tailor NPC
        local model = GetHashKey("s_m_m_tailor_01")
        RequestModel(model)
        
        local timeout = 0
        while not HasModelLoaded(model) and timeout < 50 do
            Wait(100)
            timeout = timeout + 1
        end
        
        if not HasModelLoaded(model) then
            print("^1[ERROR] Failed to load model for tailor at index " .. i .. "^7")
            goto continue
        end
        
        local npc = CreatePed(4, model, location.coords.x, location.coords.y, location.coords.z - 1.0, location.coords.w or 0.0, false, true)
        
        if not DoesEntityExist(npc) then
            print("^1[ERROR] Failed to create ped for tailor at index " .. i .. "^7")
            goto continue
        end
        
        FreezeEntityPosition(npc, true)
        SetEntityInvincible(npc, true)
        SetBlockingOfNonTemporaryEvents(npc, true)
        TaskStartScenarioInPlace(npc, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)
        
        table.insert(storeNPCs, {
            handle = npc, 
            type = "tailor", 
            index = i,
            location = location.coords
        })
        
        -- Add target interaction
        if Config.UseTarget then
            if GetResourceState('qb-target') ~= 'missing' then
                exports['qb-target']:AddTargetEntity(npc, {
                    options = {
                        {
                            type = "client",
                            event = "vein-clothing:client:openTailor",
                            icon = "fas fa-cut",
                            label = "Use Tailor Services"
                        }
                    },
                    distance = Config.PlayerInteraction and Config.PlayerInteraction.MaxDistance or 3.0
                })
            else
                print("^3[WARNING] qb-target not found, disabling targeting for tailor NPCs^7")
            end
        else
            -- Create interaction zone
            if CircleZone then
                local zone = CircleZone:Create(
                    vector3(location.coords.x, location.coords.y, location.coords.z), 
                    2.0, 
                    {
                        name = "tailor_" .. i,
                        debugPoly = Config.Debug,
                        useZ = true
                    }
                )
                
                zone:onPlayerInOut(function(isPointInside)
                    if isPointInside then
                        isInTailor = true
                        QBCore.Functions.Notify("Press [E] to use tailor services", "primary", 5000)
                    else
                        isInTailor = false
                    end
                end)
                
                table.insert(storeZones, zone)
            end
        end
        
        SetModelAsNoLongerNeeded(model)
        
        ::continue::
    end
    
    if Config.Debug then
        local count = 0
        for _, npc in pairs(storeNPCs) do
            if npc.type == "tailor" then
                count = count + 1
            end
        end
        print("^3[vein-clothing] Successfully loaded " .. count .. " tailors^7")
    end
    
    return true
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
    TriggerServerEvent('vein-clothing:server:updateLastWorn', outfit)
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
        ClearPedProp(SafePlayerPedId(), componentInfo.component)
    else
        SetPedComponentVariation(SafePlayerPedId(), componentInfo.component, 0, 0, 2)
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
            SafePlayerPedId(),
            componentInfo.component,
            selectedVariation.drawable or 0,
            selectedVariation.texture or 0,
            true
        )
    else
        SetPedComponentVariation(
            SafePlayerPedId(),
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
    local playerPed = SafePlayerPedId()
    
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
    local playerPed = SafePlayerPedId()
    if not playerPed or playerPed == 0 then return end
    
    local coords = GetEntityCoords(playerPed)
    if not coords then return end
    
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
    local playerPed = SafePlayerPedId()
    
    -- Transition back to game camera
    RenderScriptCams(false, false, 0, true, false)
    
    -- Destroy camera
    if previewCam then
        DestroyCam(previewCam, false)
        previewCam = nil
    end
    
    -- Enable movement (only if we have a valid ped)
    if playerPed and playerPed > 0 then
        DisableControlActions(false)
    end
end

-- Helper function to disable control actions
function DisableControlActions(disable)
    -- Store the state in a variable that can be accessed from the thread
    previewControlsDisabled = disable
    
    if disable then
        CreateThread(function()
            while previewControlsDisabled do
                DisableControlAction(0, 30, true) -- Movement
                DisableControlAction(0, 31, true) -- Movement
                DisableControlAction(0, 32, true) -- W
                DisableControlAction(0, 33, true) -- S
                DisableControlAction(0, 34, true) -- A
                DisableControlAction(0, 35, true) -- D
                DisableControlAction(0, 36, true) -- Crouch
                DisableControlAction(0, 44, true) -- Cover
                Wait(0)
                
                -- Safety check in case the thread runs too long
                if not previewControlsDisabled then
                    break
                end
            end
        end)
    end
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
    
    if Config.Debug then
        print("^3[vein-clothing] Opening store: " .. storeType .. "^7")
        print("^3[vein-clothing] Store data: ^7")
        for k, v in pairs(storeData) do
            if type(v) ~= "table" then
                print("  " .. k .. ": " .. tostring(v))
            else
                print("  " .. k .. ": table")
            end
        end
    end
    
    -- Get store inventory from server
    QBCore.Functions.TriggerCallback('vein-clothing:server:getStoreInventory', function(inventory)
        if not inventory then
            QBCore.Functions.Notify(Lang:t('error.store_inventory_error'), 'error')
            return
        end
        
        if Config.Debug then
            print("^3[vein-clothing] Got inventory with " .. #inventory .. " items^7")
        end
        
        -- Get player's clothing and outfits for wardrobe tab
        QBCore.Functions.TriggerCallback('vein-clothing:server:getPlayerClothing', function(clothing, outfits, wishlist)
            if Config.Debug then
                print("^3[vein-clothing] Opening UI^7")
            end
            
            -- Open the UI with the correct format matching the nui.js expectations
            SetNuiFocus(true, true)
            SendNUIMessage({
                type = "show",
                inStore = true,
                inLaundromat = false,
                inTailor = false,
                store = storeData,
                money = PlayerData.money and PlayerData.money.cash or 0,
                storeItems = inventory,
                wardrobeItems = clothing or {},
                wishlistItems = wishlist or {},
                outfits = outfits or {}
            })
        end)
    end, storeType)
end

-- Opens the laundromat UI
function OpenLaundromat()
    -- Get player's dirty clothing
    QBCore.Functions.TriggerCallback('vein-clothing:server:getDirtyClothing', function(dirtyClothing)
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
    QBCore.Functions.TriggerCallback('vein-clothing:server:getDamagedClothing', function(damagedClothing)
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
    QBCore.Functions.TriggerCallback('vein-clothing:server:getPlayerClothing', function(clothing, outfits, wishlist)
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
    
    print("^2[vein-clothing] Resource started, beginning initialization...^7")
    
    -- Wait a moment for the config to be fully loaded before initializing
    Citizen.CreateThread(function()
        -- Wait longer to ensure all script functions are fully defined
        Citizen.Wait(5000)
        
        print("^2[vein-clothing] Starting core initialization process...^7")
        Initialize()
    end)
end)

-- Clean up when resource stops
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    print("^2[vein-clothing] Resource stopping, cleaning up...^7")
    
    -- Clean up NPCs
    for _, npc in pairs(storeNPCs) do
        if DoesEntityExist(npc.handle) then
            DeleteEntity(npc.handle)
        end
    end
    
    -- Clean up zones
    for _, zone in pairs(storeZones) do
        if zone and zone.destroy then
            zone:destroy()
        end
    end
    
    -- Clean up camera
    if previewCam then
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(previewCam, false)
        previewCam = nil
    end
end)

-- Debug function to output values
function DebugPrint(message)
    if Config.Debug then
        print("^2[vein-clothing] DEBUG: " .. message .. "^7")
    end
end 