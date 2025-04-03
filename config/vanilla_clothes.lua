Config = Config or {}
Config.VanillaClothes = {
    male = {
        tops = {
            {name = "white_tshirt", label = "White T-Shirt", drawable = 0, texture = 0, component = 11, category = "shirts", price = 100, rarity = "common", description = "A simple white t-shirt"},
            {name = "black_tshirt", label = "Black T-Shirt", drawable = 0, texture = 1, component = 11, category = "shirts", price = 100, rarity = "common", description = "A simple black t-shirt"},
            {name = "red_tshirt", label = "Red T-Shirt", drawable = 0, texture = 3, component = 11, category = "shirts", price = 100, rarity = "common", description = "A simple red t-shirt"},
            {name = "suit_black", label = "Black Suit Jacket", drawable = 4, texture = 0, component = 11, category = "shirts", price = 300, rarity = "uncommon", description = "A stylish black suit jacket"},
            {name = "suit_blue", label = "Blue Suit Jacket", drawable = 4, texture = 1, component = 11, category = "shirts", price = 300, rarity = "uncommon", description = "A stylish blue suit jacket"},
            {name = "leather_jacket", label = "Leather Jacket", drawable = 7, texture = 0, component = 11, category = "jackets", price = 500, rarity = "rare", description = "A classic leather jacket"},
            {name = "polo_blue", label = "Blue Polo Shirt", drawable = 13, texture = 0, component = 11, category = "shirts", price = 150, rarity = "common", description = "A casual blue polo shirt"},
            {name = "polo_white", label = "White Polo Shirt", drawable = 13, texture = 1, component = 11, category = "shirts", price = 150, rarity = "common", description = "A casual white polo shirt"},
            {name = "hoodie_black", label = "Black Hoodie", drawable = 10, texture = 0, component = 11, category = "shirts", price = 200, rarity = "common", description = "A black hoodie to keep you warm"},
            {name = "hoodie_gray", label = "Gray Hoodie", drawable = 10, texture = 2, component = 11, category = "shirts", price = 200, rarity = "common", description = "A gray hoodie to keep you warm"},
        },
        
        pants = {
            {name = "jeans_blue", label = "Blue Jeans", drawable = 0, texture = 0, component = 4, category = "pants", price = 150, rarity = "common", description = "Classic blue jeans"},
            {name = "jeans_black", label = "Black Jeans", drawable = 0, texture = 1, component = 4, category = "pants", price = 150, rarity = "common", description = "Stylish black jeans"},
            {name = "suit_pants_black", label = "Black Suit Pants", drawable = 4, texture = 0, component = 4, category = "pants", price = 250, rarity = "uncommon", description = "Black dress pants for formal occasions"},
            {name = "suit_pants_blue", label = "Blue Suit Pants", drawable = 4, texture = 1, component = 4, category = "pants", price = 250, rarity = "uncommon", description = "Blue dress pants for formal occasions"},
            {name = "shorts_tan", label = "Tan Shorts", drawable = 5, texture = 0, component = 4, category = "pants", price = 100, rarity = "common", description = "Casual tan shorts for hot weather"},
            {name = "sweatpants_gray", label = "Gray Sweatpants", drawable = 3, texture = 0, component = 4, category = "pants", price = 120, rarity = "common", description = "Comfortable gray sweatpants"},
        },
        
        shoes = {
            {name = "sneakers_white", label = "White Sneakers", drawable = 1, texture = 0, component = 6, category = "shoes", price = 100, rarity = "common", description = "Basic white sneakers"},
            {name = "sneakers_black", label = "Black Sneakers", drawable = 1, texture = 1, component = 6, category = "shoes", price = 100, rarity = "common", description = "Basic black sneakers"},
            {name = "dress_shoes_black", label = "Black Dress Shoes", drawable = 10, texture = 0, component = 6, category = "shoes", price = 250, rarity = "uncommon", description = "Formal black leather shoes"},
            {name = "dress_shoes_brown", label = "Brown Dress Shoes", drawable = 10, texture = 1, component = 6, category = "shoes", price = 250, rarity = "uncommon", description = "Formal brown leather shoes"},
            {name = "boots_brown", label = "Brown Boots", drawable = 12, texture = 0, component = 6, category = "shoes", price = 300, rarity = "uncommon", description = "Stylish brown boots"},
            {name = "boots_black", label = "Black Boots", drawable = 12, texture = 3, component = 6, category = "shoes", price = 300, rarity = "uncommon", description = "Durable black boots"},
        },
        
        accessories = {
            {name = "watch_classic", label = "Classic Watch", drawable = 0, texture = 0, component = 6, category = "accessories", price = 400, rarity = "uncommon", type = "prop", description = "A timeless classic watch"},
            {name = "watch_sport", label = "Sport Watch", drawable = 1, texture = 0, component = 6, category = "accessories", price = 300, rarity = "uncommon", type = "prop", description = "A sporty digital watch"},
            {name = "chain_gold", label = "Gold Chain", drawable = 1, texture = 0, component = 7, category = "accessories", price = 800, rarity = "rare", description = "A flashy gold chain"},
            {name = "chain_silver", label = "Silver Chain", drawable = 1, texture = 1, component = 7, category = "accessories", price = 600, rarity = "rare", description = "A stylish silver chain"},
        },
        
        hats = {
            {name = "cap_black", label = "Black Cap", drawable = 2, texture = 0, component = 0, category = "hats", price = 100, rarity = "common", type = "prop", description = "A simple black cap"},
            {name = "cap_blue", label = "Blue Cap", drawable = 2, texture = 2, component = 0, category = "hats", price = 100, rarity = "common", type = "prop", description = "A simple blue cap"},
            {name = "beanie_black", label = "Black Beanie", drawable = 7, texture = 0, component = 0, category = "hats", price = 80, rarity = "common", type = "prop", description = "A warm black beanie"},
            {name = "beanie_gray", label = "Gray Beanie", drawable = 7, texture = 3, component = 0, category = "hats", price = 80, rarity = "common", type = "prop", description = "A warm gray beanie"},
            {name = "cowboy_hat", label = "Cowboy Hat", drawable = 19, texture = 0, component = 0, category = "hats", price = 500, rarity = "rare", type = "prop", description = "A classic cowboy hat"},
        },
        
        glasses = {
            {name = "sunglasses_black", label = "Black Sunglasses", drawable = 4, texture = 0, component = 1, category = "glasses", price = 150, rarity = "common", type = "prop", description = "Stylish black sunglasses"},
            {name = "sunglasses_red", label = "Red Sunglasses", drawable = 4, texture = 3, component = 1, category = "glasses", price = 150, rarity = "common", type = "prop", description = "Trendy red sunglasses"},
            {name = "glasses_square", label = "Square Glasses", drawable = 6, texture = 0, component = 1, category = "glasses", price = 120, rarity = "common", type = "prop", description = "Sleek square-framed glasses"},
            {name = "glasses_round", label = "Round Glasses", drawable = 5, texture = 0, component = 1, category = "glasses", price = 120, rarity = "common", type = "prop", description = "Classic round-framed glasses"},
        },
    },
    
    female = {
        tops = {
            {name = "white_tanktop", label = "White Tank Top", drawable = 5, texture = 0, component = 11, category = "shirts", price = 100, rarity = "common", description = "A basic white tank top"},
            {name = "black_tanktop", label = "Black Tank Top", drawable = 5, texture = 1, component = 11, category = "shirts", price = 100, rarity = "common", description = "A basic black tank top"},
            {name = "tshirt_white_f", label = "White T-Shirt", drawable = 0, texture = 0, component = 11, category = "shirts", price = 100, rarity = "common", description = "A simple white t-shirt"},
            {name = "tshirt_black_f", label = "Black T-Shirt", drawable = 0, texture = 1, component = 11, category = "shirts", price = 100, rarity = "common", description = "A simple black t-shirt"},
            {name = "blouse_white", label = "White Blouse", drawable = 6, texture = 0, component = 11, category = "shirts", price = 150, rarity = "common", description = "An elegant white blouse"},
            {name = "suit_jacket_f", label = "Female Suit Jacket", drawable = 29, texture = 0, component = 11, category = "shirts", price = 300, rarity = "uncommon", description = "A tailored suit jacket for women"},
            {name = "leather_jacket_f", label = "Leather Jacket", drawable = 7, texture = 0, component = 11, category = "jackets", price = 500, rarity = "rare", description = "A sleek leather jacket for women"},
            {name = "sweater_gray", label = "Gray Sweater", drawable = 24, texture = 1, component = 11, category = "shirts", price = 200, rarity = "common", description = "A cozy gray sweater"},
        },
        
        pants = {
            {name = "jeans_blue_f", label = "Blue Jeans", drawable = 0, texture = 0, component = 4, category = "pants", price = 150, rarity = "common", description = "Classic blue jeans for women"},
            {name = "jeans_black_f", label = "Black Jeans", drawable = 0, texture = 1, component = 4, category = "pants", price = 150, rarity = "common", description = "Stylish black jeans for women"},
            {name = "suit_pants_f", label = "Suit Pants", drawable = 37, texture = 0, component = 4, category = "pants", price = 250, rarity = "uncommon", description = "Elegant suit pants for women"},
            {name = "shorts_f", label = "Shorts", drawable = 13, texture = 0, component = 4, category = "pants", price = 100, rarity = "common", description = "Casual shorts for women"},
            {name = "skirt_black", label = "Black Skirt", drawable = 3, texture = 0, component = 4, category = "pants", price = 200, rarity = "common", description = "A stylish black skirt"},
            {name = "leggings_black", label = "Black Leggings", drawable = 8, texture = 0, component = 4, category = "pants", price = 120, rarity = "common", description = "Comfortable black leggings"},
        },
        
        shoes = {
            {name = "heels_black", label = "Black Heels", drawable = 3, texture = 0, component = 6, category = "shoes", price = 200, rarity = "common", description = "Elegant black heels"},
            {name = "sneakers_white_f", label = "White Sneakers", drawable = 1, texture = 0, component = 6, category = "shoes", price = 100, rarity = "common", description = "Comfortable white sneakers"},
            {name = "boots_black_f", label = "Black Boots", drawable = 26, texture = 0, component = 6, category = "shoes", price = 300, rarity = "uncommon", description = "Stylish black boots for women"},
            {name = "sandals_black", label = "Black Sandals", drawable = 5, texture = 0, component = 6, category = "shoes", price = 80, rarity = "common", description = "Simple black sandals"},
            {name = "flats_black", label = "Black Flats", drawable = 7, texture = 0, component = 6, category = "shoes", price = 150, rarity = "common", description = "Comfortable black flat shoes"},
        },
        
        accessories = {
            {name = "necklace_pearl", label = "Pearl Necklace", drawable = 9, texture = 0, component = 7, category = "accessories", price = 500, rarity = "rare", description = "An elegant pearl necklace"},
            {name = "bracelet_silver", label = "Silver Bracelet", drawable = 3, texture = 0, component = 6, category = "accessories", price = 300, rarity = "uncommon", type = "prop", description = "A delicate silver bracelet"},
            {name = "earrings_diamond", label = "Diamond Earrings", drawable = 11, texture = 0, component = 2, category = "accessories", price = 800, rarity = "rare", type = "prop", description = "Sparkling diamond earrings"},
            {name = "watch_gold_f", label = "Gold Watch", drawable = 7, texture = 0, component = 6, category = "accessories", price = 600, rarity = "rare", type = "prop", description = "An elegant gold watch for women"},
        },
        
        hats = {
            {name = "cap_pink", label = "Pink Cap", drawable = 4, texture = 0, component = 0, category = "hats", price = 100, rarity = "common", type = "prop", description = "A cute pink cap"},
            {name = "hat_sun", label = "Sun Hat", drawable = 24, texture = 0, component = 0, category = "hats", price = 200, rarity = "common", type = "prop", description = "A wide-brimmed sun hat"},
            {name = "beanie_f", label = "Beanie", drawable = 7, texture = 0, component = 0, category = "hats", price = 80, rarity = "common", type = "prop", description = "A cozy beanie"},
            {name = "beret_black", label = "Black Beret", drawable = 29, texture = 0, component = 0, category = "hats", price = 150, rarity = "uncommon", type = "prop", description = "A stylish black beret"},
        },
        
        glasses = {
            {name = "sunglasses_cat", label = "Cat Eye Sunglasses", drawable = 11, texture = 0, component = 1, category = "glasses", price = 180, rarity = "uncommon", type = "prop", description = "Fashionable cat eye sunglasses"},
            {name = "glasses_red", label = "Red Glasses", drawable = 16, texture = 2, component = 1, category = "glasses", price = 150, rarity = "common", type = "prop", description = "Cute red-framed glasses"},
            {name = "sunglasses_aviator", label = "Aviator Sunglasses", drawable = 1, texture = 0, component = 1, category = "glasses", price = 220, rarity = "uncommon", type = "prop", description = "Classic aviator sunglasses"},
        },
    }
} 