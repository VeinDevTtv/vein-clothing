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
        -- Try to get CircleZone from PolyZone in different ways
        local success, result = pcall(function()
            -- Try using the CircleZone directly from the PolyZone resource
            return exports['PolyZone']:CircleZone()
        end)
        
        if not success or not result then
            -- First attempt failed, try alternative method
            success, result = pcall(function()
                -- Try again with specific CircleZone function
                return {
                    Create = function(coords, radius, options)
                        -- Match the signature from CircleZone.lua
                        return exports['PolyZone']:CircleZone(coords, radius, options or {})
                    end
                }
            end)
        end
        
        if not success or not result then
            -- Try one more approach based on the actual CircleZone.lua implementation
            success, result = pcall(function()
                return {
                    Create = function(coords, radius, options)
                        options = options or {}
                        return exports['PolyZone']:Create({
                            center = coords,
                            radius = radius,
                            useZ = options.useZ or false,
                            debugPoly = options.debugPoly or false,
                            name = options.name or "circle_zone"
                        }, "circle")
                    end
                }
            end)
        end
        
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
    
    return zoneAPI.Create(coords, radius, options)
end

-- Export the function
exports('CreateSafeCircleZone', CreateSafeCircleZone) 