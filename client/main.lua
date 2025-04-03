local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local currentStore = nil
local isInsideStore = false
local currentOutfit = {}
local inWardrobe = false
local clothingPeds = {}

-- Import PolyZone for zone creation
local CircleZone
if GetResourceState('PolyZone') ~= 'missing' then
    CircleZone = exports['PolyZone']:CircleZone
else
    -- Create a mock CircleZone implementation if real PolyZone is not available
    CircleZone = {}
    CircleZone.Create = function(coords, radius, options)
        local mockZone = {}
        mockZone.destroy = function() end
        mockZone.onPlayerInOut = function(cb) end
        return mockZone
    end
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

-- Add this near the top of the file, after QBCore initialization
local ClothingConfig = exports['vein-clothing']:GetClothingConfig()

-- Function to get clothing config for an item
function GetClothingConfig(itemName)
    return ClothingConfig[itemName] or nil
end

-- Add this safety function near the top of the file
local function SafePlayerPedId()
    local ped = PlayerPedId()
    if not ped or ped == 0 then
        Wait(100)  -- Wait a bit and try again
        ped = PlayerPedId()
    end
    return ped
end

-- Initialize player data
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    
    -- Load the core features
    LoadStores()
    LoadLaundromats()
    LoadTailors()
    LoadPlayerOutfit()
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

-- Create store clerk peds
function LoadPeds()
    for storeName, storeData in pairs(Config.Stores) do
        for _, location in ipairs(storeData.locations) do
            local ped = nil
            
            RequestModel(GetHashKey(storeData.clerk.model))
            while not HasModelLoaded(GetHashKey(storeData.clerk.model)) do
                Wait(1)
            end
            
            ped = CreatePed(4, GetHashKey(storeData.clerk.model), location.x, location.y, location.z - 1.0, location.w, false, true)
            
            SetEntityHeading(ped, location.w)
            FreezeEntityPosition(ped, true)
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            
            -- Set animation
            TaskStartScenarioInPlace(ped, storeData.clerk.scenario, 0, true)
            
            table.insert(clothingPeds, ped)
            
            -- Target interaction if enabled
            if Config.UseTarget then
                exports['qb-target']:AddTargetEntity(ped, {
                    options = {
                        {
                            type = "client",
                            event = "vein-clothing:client:openStore",
                            icon = "fas fa-tshirt",
                            label = "Browse " .. storeData.label,
                            args = {
                                store = storeName
                            }
                        }
                    },
                    distance = Config.PlayerInteraction.MaxDistance
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
    PlayerData = QBCore.Functions.GetPlayerData()
    
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
        if not exports['qb-target'] then
            print("^1[vein-clothing] ERROR: Config.UseTarget is enabled but qb-target resource is not available^7")
            print("^1[vein-clothing] Please ensure qb-target is started before this resource^7")
            Config.UseTarget = false
            print("^3[vein-clothing] Falling back to non-target mode^7")
        else
            print("^2[vein-clothing] qb-target detected, target integration enabled^7")
        end
    end
    
    -- Load various components in the correct order
    Citizen.CreateThread(function()
        -- Give the server a moment to initialize
        Citizen.Wait(1000)
        
        print("^3[vein-clothing] Loading stores...^7")
        LoadStores()       -- This creates store clerks with qb-target
        
        print("^3[vein-clothing] Loading laundromats...^7")
        LoadLaundromats()
        
        print("^3[vein-clothing] Loading tailors...^7")
        LoadTailors()
        
        print("^3[vein-clothing] Loading player outfit...^7")
        LoadPlayerOutfit()
        
        print("^3[vein-clothing] Starting condition monitoring...^7")
        StartConditionMonitoring()
    end)
    
    -- Export the config for other resources to use
    exports('GetClothingConfig', function()
        return Config
    end)
    
    if Config.Debug then
        print("^2[vein-clothing] Initialization complete!^7")
    end
end

-- Load player's saved outfit on spawn
function LoadPlayerOutfit()
    CreateThread(function()
        while not QBCore.Functions.GetPlayerData().citizenid do
            Wait(100)
        end
        
        QBCore.Functions.TriggerCallback('vein-clothing:server:getDefaultOutfit', function(outfit)
            if outfit and next(outfit) then
                WearOutfit(outfit)
                QBCore.Functions.Notify(Lang:t('info.default_outfit_loaded'), 'success')
            end
        end)
    end)
end

-- Create store blips on the map
function LoadStores()
    -- Debug log
    if Config.Debug then
        print("^3[vein-clothing] Loading stores...^7")
    end
    
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
        if zone and zone.destroy then
            zone:destroy()
        end
    end
    storeZones = {}
    
    -- Create new blips and NPCs
    for storeType, storeData in pairs(Config.Stores) do
        if Config.Debug then
            print("^3[vein-clothing] Setting up store: " .. storeType .. "^7")
        end
        
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
            local modelName = storeData.clerk.model
            local modelHash = GetHashKey(modelName)
            
            if Config.Debug then
                print("^3[vein-clothing] Attempting to load model: " .. modelName .. " (Hash: " .. modelHash .. ")^7")
            end
            
            RequestModel(modelHash)
            
            local timeout = 0
            -- Wait for model to load with timeout
            while not HasModelLoaded(modelHash) and timeout < 30 do
                Wait(100)
                timeout = timeout + 1
                if Config.Debug and timeout % 10 == 0 then
                    print("^3[vein-clothing] Still waiting for model to load: " .. modelName .. " (Attempt " .. timeout .. "/30)^7")
                end
            end
            
            if HasModelLoaded(modelHash) then
                if Config.Debug then
                    print("^3[vein-clothing] Model loaded successfully: " .. modelName .. "^7")
                end
                
                local npc = CreatePed(4, modelHash, location.x, location.y, location.z - 1.0, location.w, false, true)
                
                if DoesEntityExist(npc) then
                    if Config.Debug then
                        print("^3[vein-clothing] NPC created successfully at location: " .. 
                            location.x .. ", " .. location.y .. ", " .. location.z .. "^7")
                    end
                    
                    FreezeEntityPosition(npc, true)
                    SetEntityInvincible(npc, true)
                    SetBlockingOfNonTemporaryEvents(npc, true)
                    
                    -- Apply animation
                    TaskStartScenarioInPlace(npc, storeData.clerk.scenario, 0, true)
                    
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
                        
                        exports['qb-target']:AddTargetEntity(npc, {
                            options = {
                                {
                                    type = "client",
                                    event = "vein-clothing:client:openStore",
                                    icon = "fas fa-tshirt",
                                    label = "Browse " .. storeData.label,
                                    args = {
                                        store = storeType
                                    }
                                }
                            },
                            distance = Config.PlayerInteraction.MaxDistance
                        })
                    else
                        -- Create interaction zone if not using target
                        if CircleZone then
                            local zone = CircleZone:Create(
                                vector3(location.x, location.y, location.z), 
                                3.0, 
                                {
                                    name = storeType .. "_" .. i,
                                    debugPoly = Config.Debug,
                                    useZ = true
                                }
                            )
                            
                            zone:onPlayerInOut(function(isPointInside)
                                if isPointInside then
                                    isInClothingStore = true
                                    currentStore = storeType
                                    QBCore.Functions.Notify("Press [E] to browse " .. storeData.label, 'primary', 5000)
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
                else
                    if Config.Debug then
                        print("^1[vein-clothing] ERROR: Failed to create NPC for model: " .. modelName .. "^7")
                    end
                end
            else
                if Config.Debug then
                    print("^1[vein-clothing] ERROR: Failed to load model: " .. modelName .. "^7")
                end
            end
            
            -- Clean up model
            SetModelAsNoLongerNeeded(modelHash)
        end
    end
    
    if Config.Debug then
        print("^3[vein-clothing] Successfully loaded " .. #storeNPCs .. " store NPCs^7")
    end
end

-- Load laundromat locations
function LoadLaundromats()
    if Config.Debug then
        print("^3[vein-clothing] Loading laundromats...^7")
    end
    
    for i, location in ipairs(Config.Laundromats) do
        -- Create blip
        local blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
        SetBlipSprite(blip, location.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.7)
        SetBlipColour(blip, 3)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Laundromat")
        EndTextCommandSetBlipName(blip)
        
        -- Create laundromat NPC
        local model = GetHashKey("s_f_y_shop_mid")
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(1)
        end
        
        local npc = CreatePed(4, model, location.coords.x, location.coords.y, location.coords.z - 1.0, location.coords.w, false, true)
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
            exports['qb-target']:AddTargetEntity(npc, {
                options = {
                    {
                        type = "client",
                        event = "vein-clothing:client:openLaundromat",
                        icon = "fas fa-soap",
                        label = "Use Laundromat"
                    }
                },
                distance = Config.PlayerInteraction.MaxDistance
            })
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
    end
    
    if Config.Debug then
        print("^3[vein-clothing] Successfully loaded " .. #Config.Laundromats .. " laundromats^7")
    end
end

-- Load tailor shop locations
function LoadTailors()
    if Config.Debug then
        print("^3[vein-clothing] Loading tailors...^7")
    end
    
    for i, location in ipairs(Config.Tailors) do
        -- Create blip
        local blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
        SetBlipSprite(blip, location.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.7)
        SetBlipColour(blip, 4)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Tailor Shop")
        EndTextCommandSetBlipName(blip)
        
        -- Create tailor NPC
        local model = GetHashKey("s_m_m_tailor_01")
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(1)
        end
        
        local npc = CreatePed(4, model, location.coords.x, location.coords.y, location.coords.z - 1.0, location.coords.w, false, true)
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
            exports['qb-target']:AddTargetEntity(npc, {
                options = {
                    {
                        type = "client",
                        event = "vein-clothing:client:openTailor",
                        icon = "fas fa-cut",
                        label = "Use Tailor Services"
                    }
                },
                distance = Config.PlayerInteraction.MaxDistance
            })
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
    end
    
    if Config.Debug then
        print("^3[vein-clothing] Successfully loaded " .. #Config.Tailors .. " tailors^7")
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

-- Debug function to output values
function DebugPrint(message)
    if Config.Debug then
        print("^2[vein-clothing] DEBUG: " .. message .. "^7")
    end
end 