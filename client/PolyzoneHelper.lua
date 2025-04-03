-- Client script for handling PolyZone initialization
local CircleZone = nil

-- Will be set to true once PolyZone is loaded
local polyzoneLoaded = false

-- Mock CircleZone implementation that will be used if PolyZone is not available
local function CreateLocalCircleZone(center, radius, options)
    options = options or {}
    
    -- Create a basic zone structure
    local zone = {
        name = options.name or "mock_circle",
        center = center,
        radius = radius,
        
        -- Basic methods
        destroy = function() return true end,
        
        onPlayerInOut = function(self, cb)
            -- Just store the callback but don't actually use it
            self.callback = cb
            return self
        end,
        
        isPointInside = function(self, point)
            -- Simple 2D distance check
            if not point then return false end
            local dx = point.x - center.x
            local dy = point.y - center.y
            return (dx * dx + dy * dy) <= (radius * radius)
        end
    }
    
    return zone
end

-- Safely attempt to load PolyZone
Citizen.CreateThread(function()
    -- Wait a moment for all resources to load
    Citizen.Wait(1000)
    
    print("^2[vein-clothing] Attempting to initialize PolyZone...^7")
    
    -- Check if PolyZone is available
    if GetResourceState('PolyZone') ~= 'missing' then
        -- Based on looking at the provided CircleZone.lua code
        local success, result = pcall(function()
            -- First method: Direct call to CircleZone.Create, which is the most common approach
            local directTest = function()
                local center = vector3(0, 0, 0)
                local radius = 1.0
                local options = {name = "test", debugPoly = false}
                
                -- In the CircleZone.lua file, there's a CircleZone:Create method
                -- Try to call it in one of several ways
                local zone = nil
                
                -- Try direct CircleZone:Create from PolyZone
                local createSuccess, createResult = pcall(function()
                    return exports['PolyZone'].CircleZone.Create(center, radius, options)
                end)
                
                if createSuccess and createResult then
                    return {
                        Create = function(center, radius, options)
                            options = options or {}
                            return exports['PolyZone'].CircleZone.Create(center, radius, options)
                        end
                    }
                end
                
                -- Try another common approach
                createSuccess, createResult = pcall(function()
                    return exports['PolyZone']:CircleZone:Create(center, radius, options)
                end)
                
                if createSuccess and createResult then
                    return {
                        Create = function(center, radius, options)
                            options = options or {}
                            return exports['PolyZone']:CircleZone:Create(center, radius, options)
                        end
                    }
                end
                
                -- Try the method where CircleZone is exposed globally
                createSuccess, createResult = pcall(function()
                    -- Check if CircleZone is available as a global
                    if _G.CircleZone and _G.CircleZone.Create then
                        return {
                            Create = function(center, radius, options)
                                options = options or {}
                                return _G.CircleZone.Create(center, radius, options)
                            end
                        }
                    end
                    return nil
                end)
                
                if createSuccess and createResult then
                    return createResult
                end
                
                -- If we got here, we couldn't find CircleZone.Create
                
                -- Try the direct CreateCircleZone export
                createSuccess, createResult = pcall(function()
                    local testZone = exports['PolyZone']:CreateCircleZone(center, radius, options)
                    
                    if testZone then
                        if testZone.destroy then testZone:destroy() end
                        return {
                            Create = function(center, radius, options)
                                options = options or {}
                                return exports['PolyZone']:CreateCircleZone(center, radius, options)
                            end
                        }
                    end
                    return nil
                end)
                
                if createSuccess and createResult then
                    return createResult
                end
                
                -- Last attempt - try with the new PolyZone API
                createSuccess, createResult = pcall(function()
                    local data = {
                        center = center,
                        radius = radius,
                        name = "test",
                        minZ = center.z - 1.0,
                        maxZ = center.z + 1.0
                    }
                    
                    local testZone = exports['PolyZone']:AddCircleZone("test", center, radius, data)
                    
                    if testZone then
                        return {
                            Create = function(center, radius, options)
                                options = options or {}
                                return exports['PolyZone']:AddCircleZone(
                                    options.name or "circle", 
                                    center, 
                                    radius, 
                                    {
                                        name = options.name or "circle",
                                        minZ = options.minZ or center.z - 1.0,
                                        maxZ = options.maxZ or center.z + 1.0,
                                        debugPoly = options.debugPoly or false
                                    }
                                )
                            end
                        }
                    end
                    return nil
                end)
                
                if createSuccess and createResult then
                    return createResult
                end
                
                -- If we got here, create our own wrapper around the raw PolyZone export
                return {
                    Create = function(center, radius, options)
                        options = options or {}
                        
                        -- Create our own CircleZone implementation
                        return CreateLocalCircleZone(center, radius, options)
                    end
                }
            end
            
            -- Try the direct test
            local wrapper = directTest()
            if wrapper then return wrapper end
            
            -- If all attempts failed, throw error
            error("Could not find any compatible PolyZone CircleZone method - check PolyZone version")
        end)
        
        if success and result then
            -- Successfully created our wrapper
            CircleZone = result
            polyzoneLoaded = true
            print("^2[vein-clothing] Successfully initialized PolyZone compatibility layer^7")
        else
            -- Failed to create zones, use mock implementation
            print("^3[vein-clothing] Failed to initialize PolyZone: " .. tostring(result) .. "^7")
            CircleZone = {
                Create = CreateLocalCircleZone
            }
            polyzoneLoaded = true
        end
    else
        -- PolyZone is not available, use mock implementation
        print("^3[vein-clothing] PolyZone resource not found, using mock implementation^7")
        CircleZone = {
            Create = CreateLocalCircleZone
        }
        polyzoneLoaded = true
    end
end)

-- Get the CircleZone object (waits until it's ready)
function GetCircleZone()
    -- If PolyZone is already loaded, return immediately
    if polyzoneLoaded and CircleZone then
        return CircleZone
    end
    
    -- Otherwise, wait for it to load with timeout
    local attempts = 0
    while not polyzoneLoaded and attempts < 50 do -- 5 second timeout
        Citizen.Wait(100)
        attempts = attempts + 1
    end
    
    -- If still not loaded, create mock implementation
    if not polyzoneLoaded or not CircleZone then
        print("^1[ERROR] Failed to get CircleZone after waiting. Using mock implementation.^7")
        return {
            Create = CreateLocalCircleZone
        }
    end
    
    return CircleZone
end

-- Create a circle zone with automatic fallback
function CreateSafeCircleZone(coords, radius, options)
    -- Validate input parameters
    if not coords then
        print("^3[WARNING] Nil coords in CreateSafeCircleZone. Using fallback coords.^7")
        coords = vector3(0.0, 0.0, 0.0)
    elseif type(coords) ~= "vector3" then
        -- Try to convert to vector3 if it's a table with x,y,z
        if type(coords) == "table" and coords.x and coords.y and coords.z then
            coords = vector3(coords.x, coords.y, coords.z)
        else
            print("^3[WARNING] Invalid coords in CreateSafeCircleZone. Using fallback coords.^7")
            coords = vector3(0.0, 0.0, 0.0)
        end
    end
    
    -- Ensure radius is a number
    if not radius or type(radius) ~= "number" then
        print("^3[WARNING] Invalid radius in CreateSafeCircleZone. Using fallback radius.^7")
        radius = 1.0
    elseif radius <= 0 then
        print("^3[WARNING] Radius must be positive in CreateSafeCircleZone. Using fallback radius.^7")
        radius = 1.0
    end
    
    -- Ensure options is a table
    if not options then options = {} end
    if type(options) ~= "table" then
        print("^3[WARNING] Invalid options in CreateSafeCircleZone. Using empty options.^7")
        options = {}
    end
    
    -- Get the zone API and handle potential errors
    local zoneAPI = GetCircleZone()
    if not zoneAPI or not zoneAPI.Create then
        print("^1[ERROR] Failed to get CircleZone API. Using local implementation.^7")
        return CreateLocalCircleZone(coords, radius, options)
    end
    
    -- Safely create the zone
    local zone
    local success, result = pcall(function()
        return zoneAPI.Create(coords, radius, options)
    end)
    
    if success and result then
        zone = result
    else
        print("^1[ERROR] Failed to create zone: " .. tostring(result) .. ". Using local implementation.^7")
        zone = CreateLocalCircleZone(coords, radius, options)
    end
    
    return zone
end

-- Export the function with more robust error handling
exports('CreateSafeCircleZone', function(...)
    local success, result = pcall(CreateSafeCircleZone, ...)
    if success then
        return result
    else
        print("^1[ERROR] Exception in CreateSafeCircleZone: " .. tostring(result) .. "^7")
        return CreateLocalCircleZone(vector3(0, 0, 0), 1.0, {name = "error_zone"})
    end
end) 