-- Example clothing items for ox_inventory/data/items.lua
-- Copy and paste these items into your ox_inventory items configuration

-- TOPS
['tshirt_white'] = {
    label = 'White T-Shirt',
    weight = 250,
    stack = false,
    close = true,
    description = 'A simple white t-shirt',
    client = {
        category = 'tops',
        variation = 0,
        drawable = 5,
        texture = 0,
        gender = 'male',
        rarity = 'common',
        condition = 100,
        component = 11, -- PED component ID
        event = 'vein-clothing:client:wearItem'
    }
},

['tshirt_black'] = {
    label = 'Black T-Shirt',
    weight = 250,
    stack = false,
    close = true,
    description = 'A simple black t-shirt',
    client = {
        category = 'tops',
        variation = 0,
        drawable = 5,
        texture = 1,
        gender = 'male',
        rarity = 'common',
        condition = 100,
        component = 11,
        event = 'vein-clothing:client:wearItem'
    }
},

['hoodie_black'] = {
    label = 'Black Hoodie',
    weight = 350,
    stack = false,
    close = true,
    description = 'A warm black hoodie',
    client = {
        category = 'tops',
        variations = { -- Multiple variations of same item
            {label = 'Black', texture = 0},
            {label = 'Dark Gray', texture = 1},
            {label = 'Light Gray', texture = 2}
        },
        drawable = 10,
        texture = 0,
        gender = 'male',
        rarity = 'uncommon',
        condition = 100,
        component = 11,
        event = 'vein-clothing:client:wearItem'
    }
},

['suit_black'] = {
    label = 'Black Suit Jacket',
    weight = 450,
    stack = false,
    close = true,
    description = 'A stylish black suit jacket',
    client = {
        category = 'tops',
        drawable = 4,
        texture = 0,
        gender = 'male',
        rarity = 'rare',
        condition = 100,
        component = 11,
        event = 'vein-clothing:client:wearItem'
    }
},

-- PANTS
['jeans_blue'] = {
    label = 'Blue Jeans',
    weight = 300,
    stack = false,
    close = true,
    description = 'Classic blue denim jeans',
    client = {
        category = 'pants',
        drawable = 4,
        texture = 0,
        gender = 'male',
        rarity = 'common',
        condition = 100,
        component = 4,
        event = 'vein-clothing:client:wearItem'
    }
},

['jeans_black'] = {
    label = 'Black Jeans',
    weight = 300,
    stack = false,
    close = true,
    description = 'Sleek black denim jeans',
    client = {
        category = 'pants',
        drawable = 4,
        texture = 1,
        gender = 'male',
        rarity = 'common',
        condition = 100,
        component = 4,
        event = 'vein-clothing:client:wearItem'
    }
},

-- SHOES
['sneakers_white'] = {
    label = 'White Sneakers',
    weight = 200,
    stack = false,
    close = true,
    description = 'Clean white sneakers',
    client = {
        category = 'shoes',
        drawable = 1,
        texture = 0,
        gender = 'male',
        rarity = 'common',
        condition = 100,
        component = 6,
        event = 'vein-clothing:client:wearItem'
    }
},

['luxury_shoes_black'] = {
    label = 'Luxury Black Shoes',
    weight = 250,
    stack = false,
    close = true,
    description = 'Premium leather dress shoes',
    client = {
        category = 'shoes',
        drawable = 10,
        texture = 0,
        gender = 'male',
        rarity = 'rare',
        condition = 100,
        component = 6,
        event = 'vein-clothing:client:wearItem'
    }
},

-- ACCESSORIES
['cap_black'] = {
    label = 'Black Cap',
    weight = 100,
    stack = false,
    close = true,
    description = 'A simple black cap',
    client = {
        category = 'hats',
        drawable = 2,
        texture = 0,
        gender = 'male',
        rarity = 'common',
        condition = 100,
        component = 0, -- Prop component (hats are props)
        event = 'vein-clothing:client:wearProp'
    }
},

['luxury_sunglasses_black'] = {
    label = 'Luxury Sunglasses',
    weight = 50,
    stack = false,
    close = true,
    description = 'Designer sunglasses with UV protection',
    client = {
        category = 'glasses',
        drawable = 5,
        texture = 0,
        gender = 'male',
        rarity = 'exclusive',
        condition = 100,
        component = 1, -- Prop component (glasses are props)
        event = 'vein-clothing:client:wearProp'
    }
},

['designer_watch_gold'] = {
    label = 'Gold Designer Watch',
    weight = 75,
    stack = false,
    close = true,
    description = 'A luxurious gold watch that makes a statement',
    client = {
        category = 'watches',
        drawable = 1,
        texture = 0,
        gender = 'male',
        rarity = 'exclusive',
        condition = 100,
        component = 6, -- Prop component (watches are props)
        event = 'vein-clothing:client:wearProp'
    }
},

-- FEMALE CLOTHING EXAMPLES
['dress_red'] = {
    label = 'Red Dress',
    weight = 300,
    stack = false,
    close = true,
    description = 'An elegant red dress for formal occasions',
    client = {
        category = 'tops',
        drawable = 3,
        texture = 0,
        gender = 'female',
        rarity = 'rare',
        condition = 100,
        component = 11,
        event = 'vein-clothing:client:wearItem'
    }
},

['jeans_female_black'] = {
    label = 'Black Jeans (F)',
    weight = 300,
    stack = false,
    close = true,
    description = 'Stylish black jeans for women',
    client = {
        category = 'pants',
        drawable = 1,
        texture = 0,
        gender = 'female',
        rarity = 'common',
        condition = 100,
        component = 4,
        event = 'vein-clothing:client:wearItem'
    }
},

-- RARE/LIMITED ITEMS
['exclusive_chain_gold'] = {
    label = 'Gold Chain',
    weight = 100,
    stack = false,
    close = true,
    description = 'A flashy gold chain that shows your status',
    client = {
        category = 'accessories',
        drawable = 14,
        texture = 0,
        gender = 'male',
        rarity = 'exclusive',
        condition = 100,
        component = 7, -- Chains/accessories component
        event = 'vein-clothing:client:wearItem'
    }
},

['limited_sneakers_gold'] = {
    label = 'Gold Limited Edition Sneakers',
    weight = 250,
    stack = false,
    close = true,
    description = 'Ultra-rare gold sneakers, only 100 pairs exist',
    client = {
        category = 'shoes',
        drawable = 3,
        texture = 14,
        gender = 'male',
        rarity = 'limited',
        condition = 100,
        component = 6,
        event = 'vein-clothing:client:wearItem'
    }
}

-- Note: The component IDs refer to GTA's clothing components:
-- 0: Head (Props)
-- 1: Glasses (Props)
-- 2: Ears (Props)
-- 3: Watch (Props)
-- 4: Legs
-- 5: Parachute / Bag
-- 6: Shoes
-- 7: Accessories / Chain
-- 8: Shirts / Undershirt
-- 9: Body Armor
-- 10: Decals / Badges
-- 11: Tops / Jackets 