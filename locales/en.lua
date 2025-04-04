local Translations = {
    error = {
        not_enough_money = "You don't have enough money",
        item_not_found = "Item not found",
        inventory_full = "Your inventory is full",
        item_worn = "You can't do this while wearing this item",
        outfit_not_found = "Outfit not found",
        wash_not_needed = "This item doesn't need washing",
        repair_not_needed = "This item doesn't need repairing",
        at_laundromat = "You need to be at a laundromat",
        at_tailor = "You need to be at a tailor shop",
        missing_items = "Missing items: %s",
        invalid_outfit_name = "Invalid outfit name",
        outfit_limit = "You've reached the maximum number of outfits (%s)",
        transaction_failed = "Transaction failed",
        invalid_player = "Invalid player",
        invalid_price = "Invalid price",
        buyer_not_enough = "Buyer doesn't have enough money",
        offer_declined = "Offer declined",
        sale_failed = "Sale failed - %s",
        out_of_stock = "Item out of stock",
        invalid_data = "Invalid data received"
    },
    success = {
        purchased = "Purchased %s",
        outfit_applied = "Outfit applied",
        item_washed = "Washed %s",
        item_repaired = "Repaired %s",
        outfit_saved = "Outfit saved: %s",
        outfit_deleted = "Deleted outfit: %s",
        default_set = "Set %s as default outfit",
        item_given = "Item given to %s",
        item_received = "Received %s from %s",
        sold_item = "Sold %s for $%s",
        bought_item = "Bought %s for $%s",
        renamed_outfit = "Renamed outfit: %s -> %s"
    },
    info = {
        store_browsing = "Browsing %s",
        laundromat = "Using Laundromat",
        tailor = "Using Tailor Services",
        preview = "Previewing %s",
        item_condition = "Your %s is %s and %s",
        wardrobe = "Using Wardrobe",
        offer_received = "%s offers to sell you %s for $%s",
        wear_outfit_cmd = "Use: /outfit [name]"
    },
    condition = {
        severely_damaged = "severely damaged and needs repairs",
        damaged = "damaged and should be repaired",
        dirty = "dirty and could use a wash",
        good = "in good condition",
        new = "brand new"
    },
    commands = {
        wardrobe = "Open your personal wardrobe",
        outfit = "Wear a saved outfit",
        washclothes = "Wash your clothes (at laundromat)",
        repairclothes = "Repair your damaged clothes (at tailor)"
    },
    ui = {
        store = "Store",
        wishlist = "Wishlist",
        outfits = "Outfits",
        my_wardrobe = "My Wardrobe",
        laundromat = "Laundromat",
        tailor_shop = "Tailor Shop",
        try_on = "Try On",
        purchase = "Purchase",
        save_outfit = "Save Current Outfit",
        wear_outfit = "Wear Outfit",
        no_items = "No items found",
        wishlist_empty = "Your wishlist is empty",
        no_outfits = "You haven't saved any outfits yet",
        no_dirty = "You don't have any clothes that need washing",
        no_damaged = "You don't have any clothes that need repairs",
        close = "Close",
        repair = "Repair",
        wash = "Wash",
        category_all = "All Items",
        category_tops = "Tops",
        category_pants = "Pants",
        category_shoes = "Shoes",
        category_hats = "Hats",
        category_glasses = "Glasses",
        category_accessories = "Accessories",
        category_bags = "Bags",
        category_watches = "Watches",
        category_jewelry = "Jewelry",
        search = "Search items...",
        condition = "Condition",
        price = "Price",
        delete = "Delete",
        rename = "Rename",
        set_default = "Set as Default"
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
}) 