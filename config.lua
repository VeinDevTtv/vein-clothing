-- config.lua
Config = {}

Config.Stores = {
    Affordable = {
        label = "Affordable Store",
        inventory = {
            "tshirt_basic",
            "pants_basic",
            "shoes_basic",
        },
        location = vector3(100.0, 200.0, 30.0),
        priceMultiplier = 1.0,
    },
    Luxury = {
        label = "Luxury & Designer Store",
        inventory = {
            "suit_luxury",
            "dress_luxury",
            "shoes_luxury",
        },
        location = vector3(150.0, 250.0, 35.0),
        priceMultiplier = 2.0,
    },
    Streetwear = {
        label = "Streetwear Store",
        inventory = {
            "hoodie_trendy",
            "jeans_trendy",
            "sneakers_trendy",
        },
        location = vector3(200.0, 300.0, 40.0),
        priceMultiplier = 1.5,
    },
    BlackMarket = {
        label = "Underground/Black Market",
        inventory = {
            "jacket_exclusive",
            "pants_exclusive",
            "sneakers_exclusive",
        },
        location = vector3(250.0, 350.0, 45.0),
        priceMultiplier = 3.0,
    },
}
