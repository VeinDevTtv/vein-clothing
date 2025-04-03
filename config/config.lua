-- Import vanilla clothes config
local VanillaClothes = {}
if GetResourceState('vein-clothing') ~= 'missing' then
    VanillaClothes = exports['vein-clothing']:GetVanillaClothes()
else
    -- Fallback to require if export isn't available
    VanillaClothes = Config.VanillaClothes or {}
end

-- Store configurations
Config.Stores = {
    -- Suburban locations
    ['suburban_1'] = {
        label = "Suburban",
        coords = vector3(127.23, -223.39, 54.56),
        blipSprite = 73,
        blipColor = 0,
        blipScale = 0.7,
        inventory = {
            -- Male clothing items
            "white_tshirt", "black_tshirt", "red_tshirt", "hoodie_black", "hoodie_gray",
            "polo_blue", "polo_white", "jeans_blue", "jeans_black", "sneakers_white",
            "sneakers_black", "cap_black", "cap_blue",
            
            -- Female clothing items
            "white_tanktop", "black_tanktop", "tshirt_white_f", "tshirt_black_f", 
            "jeans_blue_f", "jeans_black_f", "shorts_f", "sneakers_white_f", "cap_pink"
        },
        priceMultiplier = 1.0,
        npc = {
            model = "s_f_y_shop_mid",
            coords = vector4(127.23, -223.39, 53.56, 70.0),
            scenario = "WORLD_HUMAN_STAND_IMPATIENT"
        }
    },
    
    -- Ponsonbys locations 
    ['ponsonbys_1'] = {
        label = "Ponsonbys",
        coords = vector3(-164.16, -302.56, 39.73),
        blipSprite = 73,
        blipColor = 0,
        blipScale = 0.7,
        inventory = {
            -- High-end male clothing
            "suit_black", "suit_blue", "suit_pants_black", "suit_pants_blue",
            "dress_shoes_black", "dress_shoes_brown",
            
            -- High-end female clothing
            "suit_jacket_f", "suit_pants_f", "blouse_white", "heels_black", "flats_black"
        },
        priceMultiplier = 1.5,
        npc = {
            model = "a_f_y_business_02",
            coords = vector4(-164.16, -302.56, 38.73, 250.0),
            scenario = "WORLD_HUMAN_STAND_IMPATIENT"
        }
    },
    
    -- Binco locations
    ['binco_1'] = {
        label = "Binco",
        coords = vector3(-822.47, -1074.25, 11.33),
        blipSprite = 73,
        blipColor = 0,
        blipScale = 0.7,
        inventory = {
            -- Budget-friendly items
            "white_tshirt", "black_tshirt", "jeans_blue", "jeans_black",
            "sneakers_white", "sneakers_black", "shorts_tan", "sweatpants_gray",
            
            -- Female budget items
            "white_tanktop", "tshirt_white_f", "jeans_blue_f", "leggings_black",
            "sneakers_white_f", "sandals_black"
        },
        priceMultiplier = 0.8,
        npc = {
            model = "mp_f_shopkeep_01",
            coords = vector4(-822.47, -1074.25, 10.33, 120.0),
            scenario = "WORLD_HUMAN_STAND_IMPATIENT"
        }
    },
    
    -- Accessories store
    ['accessories_1'] = {
        label = "Accessories",
        coords = vector3(-1193.16, -767.58, 17.32),
        blipSprite = 73,
        blipColor = 0,
        blipScale = 0.7,
        inventory = {
            -- Accessories for everyone
            "watch_classic", "watch_sport", "chain_gold", "chain_silver",
            "sunglasses_black", "sunglasses_red", "glasses_square", "glasses_round",
            
            -- Female accessories
            "necklace_pearl", "bracelet_silver", "earrings_diamond", "watch_gold_f",
            "sunglasses_cat", "glasses_red", "sunglasses_aviator"
        },
        priceMultiplier = 1.2,
        npc = {
            model = "a_f_y_hipster_01",
            coords = vector4(-1193.16, -767.58, 16.32, 220.0),
            scenario = "WORLD_HUMAN_STAND_IMPATIENT"
        }
    }
} 