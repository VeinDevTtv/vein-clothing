-- Client script for handling PolyZone initialization
local CircleZone = nil

-- Will be set to true once PolyZone is loaded
local polyzoneLoaded = false

-- Mock CircleZone implementation that will be used if PolyZone is not available
local function CreateLocalCircleZone(center, radius, options)
    -- Validate all parameters to prevent null values
    if not center then
        print("^1[ERROR] Nil center in CreateLocalCircleZone. Using default vector3(0,0,0)^7")
        center = vector3(0.0, 0.0, 0.0)
    elseif type(center) ~= "vector3" then
        -- Try to create a vector3 from a table
        if type(center) == "table" and center.x ~= nil and center.y ~= nil then
            local x = tonumber(center.x) or 0.0
            local y = tonumber(center.y) or 0.0
            local z = tonumber(center.z) or 0.0
            center = vector3(x, y, z)
        else
            print("^1[ERROR] Invalid center in CreateLocalCircleZone. Using default vector3(0,0,0)^7")
            center = vector3(0.0, 0.0, 0.0)
        end
    end
    
    -- Ensure radius is valid
    if not radius or type(radius) ~= "number" or radius <= 0 then
        print("^1[ERROR] Invalid radius in CreateLocalCircleZone. Using default 1.0^7")
        radius = 1.0
    end
    
    -- Ensure options is a table
    options = options or {}
    if type(options) ~= "table" then
        options = {}
    end
    
    -- Create a basic zone structure with validated parameters
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
            -- Validate point to prevent null errors
            if not point then return false end
            
            -- Ensure point is vector3 or has x,y properties
            local px, py, pz
            if type(point) == "vector3" then
                px, py = point.x, point.y
            elseif type(point) == "table" and point.x ~= nil and point.y ~= nil then
                px, py = point.x, point.y
            else
                return false
            end
            
            -- Ensure center is valid before using it
            if not center or not center.x or not center.y then
                return false
            end
            
            -- Simple 2D distance check with null safety
            local dx = px - center.x
            local dy = py - center.y
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
        -- Try to access PolyZone directly (based on actual implementation)
        local success, result = pcall(function()
            -- Based on the provided CircleZone.lua code, we can see it uses CircleZone:new and then 
            -- has a CircleZone:Create method that calls new and initializes the debug
            
            -- Create our wrapper that matches how CircleZone works in PolyZone
            local wrapper = {
                Create = function(center, radius, options)
                    options = options or {}
                    
                    -- Try to use the actual PolyZone CircleZone function pattern
                    -- CircleZone.new creates a new zone directly
                    local newZoneSuccess, newZone = pcall(function()
                        return exports['PolyZone']:CircleZone(center, radius, options)
                    end)
                    
                    if newZoneSuccess and newZone then
                        return newZone
                    end
                    
                    -- Try fallback to different API pattern  
                    local altSuccess, altZone = pcall(function()
                        return exports['PolyZone']:NewCircleZone(center, radius, options)
                    end)
                    
                    if altSuccess and altZone then
                        return altZone
                    end
                    
                    -- As a last resort, create using generic :Create method
                    local createSuccess, createZone = pcall(function()
                        if type(center) ~= "vector3" then
                            center = vector3(center.x or 0, center.y or 0, center.z or 0)
                        end
                        
                        return exports['PolyZone']:Create({
                            points = {}, -- Empty for circle
                            center = center,
                            radius = radius,
                            useZ = options.useZ or false,
                            debugPoly = options.debugPoly or false,
                            name = options.name or "circle_zone"
                        }, "circle")
                    end)
                    
                    if createSuccess and createZone then
                        return createZone
                    end
                    
                    -- If all else fails, use the local implementation
                    print("^3[vein-clothing] All PolyZone CircleZone methods failed, using local implementation^7")
                    return CreateLocalCircleZone(center, radius, options)
                end
            }
            
            return wrapper
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

-- Create a safe CircleZone that handles errors gracefully
function CreateSafeCircleZone(coords, radius, options)
    -- Validate and sanitize coordinates
    if not coords or not AreValidCoords(coords.x, coords.y, coords.z) then
        print("^3[WARNING] Invalid coords in CreateSafeCircleZone. Using fallback coords.^7")
        coords = vector3(0.0, 0.0, 0.0)
    end
    
    -- Validate and sanitize radius
    if not radius or radius <= 0 then
        print("^3[WARNING] Invalid radius in CreateSafeCircleZone. Using fallback radius.^7")
        radius = 3.0 -- Default radius
    end
    
    -- Validate options
    options = options or {}
    
    -- Extract coordinates as numbers
    local x, y, z = coords.x, coords.y, coords.z
    
    -- Use pcall to safely create the zone
    local success, zone = pcall(function()
        if CircleZone.new then
            return CircleZone.new(coords, radius, options)
        elseif CircleZone then
            return CircleZone(coords, radius, options)
        else
            return nil
        end
    end)
    
    if success and zone then
        return zone
    end
    
    print("^3[WARNING] Failed to create CircleZone: " .. tostring(success) .. ". Using local implementation.^7")
    
    -- Fallback local implementation
    return {
        position = coords,
        radius = radius,
        options = options,
        isPointInside = function(self, point)
            if not point then return false end
            local distance = #(point - self.position)
            return distance <= self.radius
        end,
        destroy = function(self)
            -- Nothing to do in this implementation
        end
    }
end

-- Helper function to check if coordinates are valid
function AreValidCoords(x, y, z)
    -- Check if all values are numbers and not all zeros
    return type(x) == "number" and type(y) == "number" and type(z) == "number" and
           not (x == 0 and y == 0 and z == 0) -- Not all zeros
end

-- Export the function with more robust error handling
exports('CreateSafeCircleZone', function(coords, radius, options)
    -- Simplified export with direct parameters to avoid the issue with "..." unpacking
    local success, result = pcall(function()
        return CreateSafeCircleZone(coords, radius, options)
    end)
    
    if success then
        return result
    else
        print("^1[ERROR] Exception in CreateSafeCircleZone: " .. tostring(result) .. "^7")
        return CreateLocalCircleZone(vector3(0, 0, 0), 1.0, {name = "error_zone"})
    end
end) 