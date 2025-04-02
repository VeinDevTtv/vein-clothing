-- This is a compatibility file to ensure scripts that import the resource directly still work
-- All functionality is organized in the client/ folder

-- Forward any exported functions from the client folder to the main resource
local function ExposeExports()
    -- Expose the exports defined in client/events.lua
    exports('openWardrobe', function()
        return exports[GetCurrentResourceName()]:openWardrobe()
    end)
    
    exports('wearOutfit', function(outfitId)
        return exports[GetCurrentResourceName()]:wearOutfit(outfitId)
    end)
    
    exports('previewClothing', function(itemName, variation)
        return exports[GetCurrentResourceName()]:previewClothing(itemName, variation)
    end)

    -- Additional exports
    exports('getWornItems', function()
        return currentOutfit
    end)
    
    exports('isItemWorn', function(itemName)
        for _, item in pairs(currentOutfit) do
            if item.name == itemName then
                return true
            end
        end
        return false
    end)
    
    exports('removeAllClothing', function()
        TriggerEvent('clothing-system:client:resetAppearance')
    end)
end

CreateThread(function()
    -- Wait for resource to fully start
    Wait(500)
    ExposeExports()
    
    -- Log message indicating that this file is deprecated
    print('^3[clothing-system]^7 Warning: Loading from root client.lua is deprecated. Please use the new folder structure.')
end)
