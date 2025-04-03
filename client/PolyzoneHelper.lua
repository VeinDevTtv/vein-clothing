-- Client script for handling PolyZone initialization
local CircleZone = nil

-- Will be set to true once PolyZone is loaded
local polyzoneLoaded = false

-- Safely attempt to load PolyZone
Citizen.CreateThread(function()
    -- Wait a moment for all resources to load
    Citizen.Wait(1000)
    
    print("^2[vein-clothing] Attempting to initialize PolyZone...^7")
    
    -- Check if PolyZone is available
    if GetResourceState('PolyZone') ~= 'missing' then
        -- Initialize a wrapper around the CircleZone functionality
        local success, result = pcall(function()
            -- First approach: Try to use the native CreateCircleZone export (newer versions)
            local zone = nil
            
            -- Create a test function to see if CreateCircleZone exists
            local testFunc = function()
                local testCenter = vector3(0, 0, 0)
                local testRadius = 1.0
                zone = exports['PolyZone']:CreateCircleZone(testCenter, testRadius, {name = "test"})
                return zone ~= nil
            end
            
            -- Try the test function, but catch any errors
            local testSuccess, hasCreateCircleZone = pcall(testFunc)
            
            -- If the test succeeded and we got a zone, clean it up
            if testSuccess and hasCreateCircleZone and zone and zone.destroy then
                zone:destroy()
                zone = nil
                
                -- Return a wrapper around CreateCircleZone
                return {
                    Create = function(center, radius, options)
                        options = options or {}
                        -- Directly use the export
                        return exports['PolyZone']:CreateCircleZone(center, radius, options)
                    end
                }
            end
            
            -- Second approach: Try to access the global CircleZone.Create method (older versions)
            testFunc = function()
                local testCenter = vector3(0, 0, 0)
                local testRadius = 1.0
                local testOptions = {name = "test"}
                -- Try to create a zone using the exports
                zone = exports['PolyZone']:CircleZone(testCenter, testRadius, testOptions)
                return zone ~= nil
            end
            
            -- Try the second test function
            testSuccess, _ = pcall(testFunc)
            
            -- Clean up test zone if created
            if zone and zone.destroy then
                zone:destroy()
                zone = nil
            end
            
            if testSuccess then
                -- Return a wrapper around the CircleZone export
                return {
                    Create = function(center, radius, options)
                        options = options or {}
                        return exports['PolyZone']:CircleZone(center, radius, options)
                    end
                }
            end
            
            -- Final approach: Try to create a generic zone and specify 'circle' as type
            testFunc = function()
                local data = {
                    center = vector3(0, 0, 0),
                    radius = 1.0,
                    name = "test",
                    debugPoly = false
                }
                zone = exports['PolyZone']:Create(data, 'circle')
                return zone ~= nil
            end
            
            -- Try the final test function
            testSuccess, _ = pcall(testFunc)
            
            -- Clean up test zone if created
            if zone and zone.destroy then
                zone:destroy()
                zone = nil
            end
            
            if testSuccess then
                -- Return a wrapper around Create with 'circle' type
                return {
                    Create = function(center, radius, options)
                        options = options or {}
                        return exports['PolyZone']:Create({
                            center = center,
                            radius = radius,
                            name = options.name or "circle_zone",
                            useZ = options.useZ or false,
                            debugPoly = options.debugPoly or false
                        }, 'circle')
                    end
                }
            end
            
            -- If all approaches failed, throw error
            error("Could not find any compatible PolyZone CircleZone method")
        end)
        
        if success and result then
            -- Successfully created our wrapper
            CircleZone = result
            polyzoneLoaded = true
            print("^2[vein-clothing] Successfully initialized PolyZone compatibility layer^7")
        else
            -- Failed to create zones, use mock implementation
            print("^3[vein-clothing] Failed to initialize PolyZone: " .. tostring(result) .. "^7")
            CircleZone = CreateMockCircleZone()
            polyzoneLoaded = true
        end
    else
        -- PolyZone is not available, use mock implementation
        print("^3[vein-clothing] PolyZone resource not found, using mock implementation^7")
        CircleZone = CreateMockCircleZone()
        polyzoneLoaded = true
    end
end)

-- Creates a mock implementation of CircleZone that does nothing but prevents errors
function CreateMockCircleZone()
    local MockZone = {}
    
    -- Create function - returns a mock zone object
    MockZone.Create = function(coords, radius, options)
        local zone = {
            coords = coords,
            radius = radius,
            options = options or {},
            
            -- Mock destroy method
            destroy = function(self)
                return true
            end,
            
            -- Mock onPlayerInOut method
            onPlayerInOut = function(self, cb)
                -- Store callback but don't actually call it
                self.callback = cb
                return self
            end
        }
        
        return zone
    end
    
    return MockZone
end

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
        return CreateMockCircleZone()
    end
    
    return CircleZone
end

-- Create a circle zone with automatic fallback
function CreateSafeCircleZone(coords, radius, options)
    local zoneAPI = GetCircleZone()
    
    if not zoneAPI then
        print("^1[ERROR] Failed to get CircleZone API. Using empty zone.^7")
        return {
            destroy = function() end,
            onPlayerInOut = function() return {} end
        }
    end
    
    -- Ensure coords is a valid vector
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
    
    -- Create zone with validated parameters
    local zone = nil
    
    -- Safely create the zone
    local success, result = pcall(function()
        return zoneAPI.Create(coords, radius, options)
    end)
    
    if success and result then
        zone = result
    else
        print("^1[ERROR] Failed to create zone: " .. tostring(result) .. ". Using mock zone.^7")
        zone = {
            destroy = function() return true end,
            onPlayerInOut = function(cb) return {} end
        }
    end
    
    return zone
end

-- Export the function
exports('CreateSafeCircleZone', CreateSafeCircleZone) 