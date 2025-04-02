-- shared/items.lua
-- This file contains the clothing item configurations for vein-clothing

-- Export clothing configurations for use in the script
exports('GetClothingConfig', function()
    return {
        -- T-shirts/Tops
        ['tshirt_white'] = {
            category = 'torso2',
            component = 11,
            drawable = 0,
            texture = 0,
            rarity = 'common'
        },
        ['tshirt_black'] = {
            category = 'torso2',
            component = 11,
            drawable = 0,
            texture = 1,
            rarity = 'common'
        },
        ['hoodie_gray'] = {
            category = 'torso2',
            component = 11,
            drawable = 7,
            texture = 0,
            rarity = 'uncommon'
        },
        
        -- Pants/Jeans
        ['jeans_blue'] = {
            category = 'legs',
            component = 4,
            drawable = 0,
            texture = 0,
            rarity = 'common'
        },
        ['jeans_black'] = {
            category = 'legs',
            component = 4,
            drawable = 0,
            texture = 1,
            rarity = 'common'
        },
        
        -- Shoes
        ['sneakers_white'] = {
            category = 'shoes',
            component = 6,
            drawable = 1,
            texture = 0,
            rarity = 'common'
        },
        ['dress_shoes_black'] = {
            category = 'shoes',
            component = 6,
            drawable = 10,
            texture = 0,
            rarity = 'uncommon'
        },
        ['dress_shoes_brown'] = {
            category = 'shoes',
            component = 6,
            drawable = 10,
            texture = 1,
            rarity = 'uncommon'
        },
        
        -- Hats/Accessories
        ['cap_black'] = {
            category = 'hat',
            type = 'prop',
            drawable = 2,
            texture = 0,
            rarity = 'common'
        },
        ['designer_glasses'] = {
            category = 'glasses',
            type = 'prop',
            drawable = 4,
            texture = 1,
            rarity = 'rare'
        },
        ['luxury_watch'] = {
            category = 'watch',
            type = 'prop',
            drawable = 1,
            texture = 0,
            rarity = 'rare'
        },
        
        -- Full outfits
        ['suit_black'] = {
            category = 'torso2',
            component = 11,
            drawable = 4,
            texture = 0,
            rarity = 'rare'
        },
        ['suit_navy'] = {
            category = 'torso2',
            component = 11,
            drawable = 4,
            texture = 2,
            rarity = 'rare'
        }
    }
end) 