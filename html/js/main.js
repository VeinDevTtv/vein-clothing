// Main Vue instance for the clothing system
const app = new Vue({
    el: '#app',
    data: {
        visible: false,
        debug: true,
        currentView: 'store',
        inStore: false,
        inLaundromat: false,
        inTailor: false,
        currentStore: null,
        playerMoney: {
            cash: 0,
            bank: 0
        },
        paymentMethod: 'cash', // Default payment method
        searchQuery: '',
        selectedCategory: null,
        selectedSubcategory: null,
        selectedColor: null,
        selectedRarity: null,
        priceRange: 10000,
        selectedVariations: {},
        outfits: [],
        outfitName: '',
        newOutfitName: '',
        selectedOutfit: null,
        showModal: false,
        modalType: '',
        selectedItem: null,
        selectedPlayer: null,
        sellPrice: 0,
        interactionItem: null,
        offerData: null,
        notifications: [],
        nearbyPlayers: [],
        selectedDirtyItems: [],
        selectedDamagedItems: [],
        laundryPrice: 50,
        repairPrice: 100,
        defaultImage: 'https://via.placeholder.com/100',
        locales: {
            ui: {
                store: 'Store',
                wardrobe: 'Wardrobe',
                outfits: 'Outfits',
                wishlist: 'Wishlist',
                laundry: 'Laundry',
                repair: 'Repair',
                search: 'Search...',
                categories: 'Categories',
                subcategories: 'Sub-Categories',
                colors: 'Colors',
                rarity: 'Rarity',
                price_range: 'Price Range',
                in_stock: 'In Stock',
                sold_out: 'Sold Out',
                try_on: 'Try On',
                buy: 'Buy',
                preview: 'Preview',
                wear: 'Wear',
                remove: 'Remove',
                trade: 'Trade',
                sell: 'Sell',
                save_current_outfit: 'Save Current Outfit',
                save_outfit: 'Save Outfit',
                outfit_name: 'Outfit Name',
                enter_outfit_name: 'Enter outfit name',
                cancel: 'Cancel',
                save: 'Save',
                rename_outfit: 'Rename Outfit',
                new_outfit_name: 'New Outfit Name',
                enter_new_name: 'Enter new name',
                rename: 'Rename',
                delete_outfit: 'Delete Outfit',
                delete_outfit_confirm: 'Are you sure you want to delete the outfit "{name}"?',
                delete: 'Delete',
                sell_item: 'Sell Item',
                selling_item: 'You are selling: {item}',
                price: 'Price',
                enter_price: 'Enter price',
                select_player: 'Select Player',
                trade_item: 'Trade Item',
                trading_item: 'You are trading: {item}',
                your_clothing: 'Your Clothing',
                sort_by: 'Sort By',
                nothing_wishlisted: 'Nothing in your wishlist',
                available_at: 'Available at',
                not_available: 'Not available in any store',
                laundromat: 'Laundromat',
                wash_price: 'Wash Price',
                laundry_info: 'Select dirty items to wash them',
                wash_selected: 'Wash Selected',
                total_cost: 'Total Cost',
                no_dirty_items: 'No dirty items to wash',
                tailor: 'Tailor',
                base_repair_price: 'Base Repair Price',
                repair_info: 'Select damaged items to repair them',
                repair_selected: 'Repair Selected',
                repair_cost: 'Repair Cost',
                no_damaged_items: 'No damaged items to repair',
                no_items_found: 'No items found',
                no_saved_outfits: 'No saved outfits',
                default: 'Default'
            }
        },
        categories: [
            { id: 'hats', label: 'Hats', icon: 'fas fa-hat-cowboy' },
            { id: 'masks', label: 'Masks', icon: 'fas fa-mask' },
            { id: 'glasses', label: 'Glasses', icon: 'fas fa-glasses' },
            { id: 'shirts', label: 'Shirts', icon: 'fas fa-tshirt' },
            { id: 'pants', label: 'Pants', icon: 'fas fa-socks' },
            { id: 'shoes', label: 'Shoes', icon: 'fas fa-shoe-prints' },
            { id: 'accessories', label: 'Accessories', icon: 'fas fa-ring' }
        ],
        subcategories: {
            hats: [
                { id: 'beanie', label: 'Beanie' },
                { id: 'cap', label: 'Cap' },
                { id: 'cowboy', label: 'Cowboy Hat' }
            ],
            masks: [
                { id: 'skull', label: 'Skull Mask' },
                { id: 'bandana', label: 'Bandana' },
                { id: 'medical', label: 'Medical Mask' }
            ],
            shirts: [
                { id: 'tshirt', label: 'T-Shirt' },
                { id: 'polo', label: 'Polo' },
                { id: 'dress_shirt', label: 'Dress Shirt' },
                { id: 'hoodie', label: 'Hoodie' }
            ],
            pants: [
                { id: 'jeans', label: 'Jeans' },
                { id: 'slacks', label: 'Slacks' },
                { id: 'shorts', label: 'Shorts' }
            ],
            shoes: [
                { id: 'sneakers', label: 'Sneakers' },
                { id: 'boots', label: 'Boots' },
                { id: 'dress_shoes', label: 'Dress Shoes' }
            ],
            accessories: [
                { id: 'necklace', label: 'Necklace' },
                { id: 'watch', label: 'Watch' },
                { id: 'bracelet', label: 'Bracelet' },
                { id: 'earrings', label: 'Earrings' }
            ],
            glasses: [
                { id: 'sunglasses', label: 'Sunglasses' },
                { id: 'reading', label: 'Reading Glasses' },
                { id: 'sports', label: 'Sports Glasses' }
            ]
        },
        colors: [
            { id: 'black', label: 'Black', hex: '#000000' },
            { id: 'white', label: 'White', hex: '#FFFFFF' },
            { id: 'red', label: 'Red', hex: '#FF0000' },
            { id: 'blue', label: 'Blue', hex: '#0000FF' },
            { id: 'green', label: 'Green', hex: '#00FF00' },
            { id: 'yellow', label: 'Yellow', hex: '#FFFF00' },
            { id: 'purple', label: 'Purple', hex: '#800080' },
            { id: 'pink', label: 'Pink', hex: '#FFC0CB' },
            { id: 'brown', label: 'Brown', hex: '#964B00' },
            { id: 'gray', label: 'Gray', hex: '#808080' }
        ],
        rarities: [
            { id: 'common', label: 'Common' },
            { id: 'uncommon', label: 'Uncommon' },
            { id: 'rare', label: 'Rare' },
            { id: 'exclusive', label: 'Exclusive' },
            { id: 'limited', label: 'Limited' }
        ],
        sortOptions: [
            { id: 'name', label: 'Name', icon: 'fas fa-sort-alpha-down' },
            { id: 'price', label: 'Price', icon: 'fas fa-sort-numeric-down' },
            { id: 'rarity', label: 'Rarity', icon: 'fas fa-star' },
            { id: 'condition', label: 'Condition', icon: 'fas fa-heart' }
        ],
        sortBy: 'name',
        storeItems: [],
        wardrobeItems: [],
        wishlistItems: [],
        dirtyItems: [],
        damagedItems: []
    },
    computed: {
        availableSubcategories() {
            if (!this.selectedCategory || !this.subcategories[this.selectedCategory]) {
                return [];
            }
            return this.subcategories[this.selectedCategory];
        },
        
        availableColors() {
            return this.colors;
        },
        
        filteredStoreItems() {
            // Debug the items we're working with
            console.log("Filtering store items:", 
                "Total items:", this.storeItems.length, 
                "Category:", this.selectedCategory,
                "Subcategory:", this.selectedSubcategory, 
                "Color:", this.selectedColor);
            
            if (this.debug) {
                // Log some sample items to check their properties
                const sampleItems = this.storeItems.slice(0, 3);
                console.log("Sample items for debugging:", sampleItems);
            }
            
            let items = [...this.storeItems];
            
            // Apply category filter
            if (this.selectedCategory) {
                items = items.filter(item => {
                    // Get the category from the item
                    const itemCategory = String(item.category || "").toLowerCase();
                    const selectedCategory = String(this.selectedCategory).toLowerCase();
                    const itemName = String(item.name || "").toLowerCase();
                    const itemLabel = String(item.label || "").toLowerCase();
                    
                    // Exact match has priority
                    if (itemCategory === selectedCategory) {
                        console.log(`Item matched by exact category: ${item.name} - category: ${itemCategory}`);
                        return true;
                    }
                    
                    // Check name-based category detection
                    // Match shoes
                    if (selectedCategory === "shoes" && 
                        (itemName.includes("shoe") || itemName.includes("boot") || 
                         itemName.includes("sneaker") || itemLabel.includes("shoe") || 
                         itemName.includes("footwear"))) {
                        console.log(`Item matched by name for shoes category: ${item.name}`);
                        return true;
                    }
                    
                    // Match shirts/tops
                    if (selectedCategory === "shirts" && 
                        (itemName.includes("shirt") || itemName.includes("top") || 
                         itemName.includes("jacket") || itemName.includes("hoodie") || 
                         itemName.includes("sweater") || itemName.includes("tshirt") || 
                         itemName.includes("t-shirt") || itemName.includes("t_shirt") || 
                         itemLabel.includes("shirt"))) {
                        console.log(`Item matched by name for shirts category: ${item.name}`);
                        return true;
                    }
                    
                    // Match pants
                    if (selectedCategory === "pants" && 
                        (itemName.includes("pant") || itemName.includes("jean") || 
                         itemName.includes("trouser") || itemName.includes("short") || 
                         itemName.includes("skirt") || itemLabel.includes("pant"))) {
                        console.log(`Item matched by name for pants category: ${item.name}`);
                        return true;
                    }
                    
                    // Match hats
                    if (selectedCategory === "hats" && 
                        (itemName.includes("hat") || itemName.includes("cap") || 
                         itemName.includes("beanie") || itemName.includes("helmet") || 
                         itemLabel.includes("hat"))) {
                        console.log(`Item matched by name for hats category: ${item.name}`);
                        return true;
                    }
                    
                    // Match accessories
                    if (selectedCategory === "accessories" && 
                        (itemName.includes("necklace") || itemName.includes("chain") || 
                         itemName.includes("watch") || itemName.includes("bracelet") || 
                         itemName.includes("earring") || itemName.includes("ring") || 
                         itemLabel.includes("accessory") || itemLabel.includes("necklace"))) {
                        console.log(`Item matched by name for accessories category: ${item.name}`);
                        return true;
                    }
                    
                    // Match masks
                    if (selectedCategory === "masks" && 
                        (itemName.includes("mask") || itemName.includes("bandana") || 
                         itemName.includes("balaclava") || itemLabel.includes("mask"))) {
                        console.log(`Item matched by name for masks category: ${item.name}`);
                        return true;
                    }
                    
                    // Match glasses
                    if (selectedCategory === "glasses" && 
                        (itemName.includes("glass") || itemName.includes("eyewear") || 
                         itemName.includes("sunglass") || itemLabel.includes("glass"))) {
                        console.log(`Item matched by name for glasses category: ${item.name}`);
                        return true;
                    }
                    
                    // Check if item's category partly contains or is contained by the selected category
                    if (itemCategory.includes(selectedCategory) || selectedCategory.includes(itemCategory)) {
                        console.log(`Item matched by partial category: ${item.name} - ${itemCategory} vs ${selectedCategory}`);
                        return true;
                    }
                    
                    // No match found
                    return false;
                });
                console.log(`After category filter (${this.selectedCategory}):`, items.length);
                
                // Additional debugging for subcategory matching
                if (this.debug && items.length > 0) {
                    console.log("Category filtered items (sample):", items.slice(0, 3));
                }
            }
            
            // Apply subcategory filter
            if (this.selectedSubcategory && this.selectedCategory) {
                // Log items before filtering to debug
                if (this.debug) {
                    console.log("Items before subcategory filter:", items.map(item => ({
                        name: item.name,
                        label: item.label,
                        subcategory: item.subcategory,
                        nameContainsTshirt: item.name.toLowerCase().includes('tshirt') || item.name.toLowerCase().includes('t-shirt') || item.name.toLowerCase().includes('t_shirt')
                    })));
                }
                
                items = items.filter(item => {
                    // Get the subcategory from the item
                    let itemSubcat = String(item.subcategory || "").toLowerCase();
                    const selectedSubcat = String(this.selectedSubcategory).toLowerCase();
                    const itemName = String(item.name || "").toLowerCase();
                    const itemLabel = String(item.label || "").toLowerCase();
                    
                    // Special case for tshirts - check if the name contains tshirt variants
                    if (selectedSubcat === "tshirt" && 
                        (itemName.includes('tshirt') || 
                         itemName.includes('t-shirt') || 
                         itemName.includes('t_shirt') ||
                         itemLabel.includes('t-shirt') || 
                         itemLabel.includes('tshirt') || 
                         itemLabel.includes('t shirt'))) {
                        console.log(`Item matched by name/label as tshirt: ${item.name}`);
                        return true;
                    }
                    
                    // Check if item's name contains the subcategory (e.g., "jeans_blue" for subcategory "jeans")
                    if (selectedSubcat !== "tshirt" && itemName.includes(selectedSubcat)) {
                        console.log(`Item matched by name for subcategory: ${item.name} - ${selectedSubcat}`);
                        return true;
                    }
                    
                    // Regular subcategory match
                    const match = itemSubcat === selectedSubcat || 
                                  itemSubcat.includes(selectedSubcat) || 
                                  selectedSubcat.includes(itemSubcat);
                                  
                    if (match) {
                        console.log(`Item matched by subcategory field: ${item.name} - ${itemSubcat}`);
                    }
                    
                    return match;
                });
                console.log(`After subcategory filter (${this.selectedSubcategory}):`, items.length);
                
                // Additional debugging for subcategory result
                if (this.debug && items.length > 0) {
                    console.log("Subcategory filtered items (sample):", items.slice(0, 3));
                }
            }
            
            // Apply color filter
            if (this.selectedColor) {
                // Log items before filtering to debug
                if (this.debug) {
                    console.log("Items before color filter:", items.map(item => ({
                        name: item.name,
                        label: item.label,
                        color: item.color,
                        nameContainsColor: item.name.toLowerCase().includes(this.selectedColor.toLowerCase())
                    })));
                }
                
                items = items.filter(item => {
                    // Get the color from the item
                    const itemColor = String(item.color || "").toLowerCase();
                    const selectedColor = String(this.selectedColor).toLowerCase();
                    const itemName = String(item.name || "").toLowerCase();
                    const itemLabel = String(item.label || "").toLowerCase();
                    
                    // Check if item's name contains the color (e.g., "jeans_blue" for color "blue")
                    if (itemName.includes(selectedColor)) {
                        console.log(`Item matched by name for color: ${item.name} - ${selectedColor}`);
                        return true;
                    }
                    
                    // Check if item's label contains the color 
                    if (itemLabel.includes(selectedColor)) {
                        console.log(`Item matched by label for color: ${item.name} - ${selectedColor}`);
                        return true;
                    }
                    
                    // Regular color match
                    const match = itemColor === selectedColor || 
                                  itemColor.includes(selectedColor) || 
                                  selectedColor.includes(itemColor);
                                  
                    if (match) {
                        console.log(`Item matched by color field: ${item.name} - ${itemColor}`);
                    }
                    
                    return match;
                });
                console.log(`After color filter (${this.selectedColor}):`, items.length);
                
                // Additional debugging for color result
                if (this.debug && items.length > 0) {
                    console.log("Color filtered items (sample):", items.slice(0, 3));
                }
            }
            
            // Apply rarity filter
            if (this.selectedRarity) {
                items = items.filter(item => item.rarity === this.selectedRarity);
            }
            
            // Apply price filter
            items = items.filter(item => item.price <= this.priceRange);
            
            // Apply search filter
            if (this.searchQuery) {
                const query = this.searchQuery.toLowerCase();
                items = items.filter(item => 
                    item.label.toLowerCase().includes(query) ||
                    item.description.toLowerCase().includes(query)
                );
            }
            
            // Apply sorting
            switch (this.sortBy) {
                case 'name':
                    items.sort((a, b) => a.label.localeCompare(b.label));
                    break;
                case 'price':
                    items.sort((a, b) => a.price - b.price);
                    break;
                case 'rarity':
                    const rarityOrder = ['common', 'uncommon', 'rare', 'exclusive', 'limited'];
                    items.sort((a, b) => rarityOrder.indexOf(a.rarity) - rarityOrder.indexOf(b.rarity));
                    break;
            }
            
            return items;
        },
        filteredWardrobeItems() {
            // Debug the items we're working with
            console.log("Filtering wardrobe items:", 
                "Total items:", this.wardrobeItems.length, 
                "Category:", this.selectedCategory,
                "Subcategory:", this.selectedSubcategory, 
                "Color:", this.selectedColor);
            
            if (this.debug) {
                // Log some sample items to check their properties
                const sampleItems = this.wardrobeItems.slice(0, 3);
                console.log("Sample wardrobe items for debugging:", sampleItems);
            }
            
            let items = [...this.wardrobeItems];
            
            // Apply category filter
            if (this.selectedCategory) {
                items = items.filter(item => {
                    // Get the category from the item
                    const itemCategory = String(item.category || "").toLowerCase();
                    const selectedCategory = String(this.selectedCategory).toLowerCase();
                    const itemName = String(item.name || "").toLowerCase();
                    const itemLabel = String(item.label || "").toLowerCase();
                    
                    // Exact match has priority
                    if (itemCategory === selectedCategory) {
                        console.log(`Wardrobe item matched by exact category: ${item.name} - category: ${itemCategory}`);
                        return true;
                    }
                    
                    // Check name-based category detection
                    // Match shoes
                    if (selectedCategory === "shoes" && 
                        (itemName.includes("shoe") || itemName.includes("boot") || 
                         itemName.includes("sneaker") || itemLabel.includes("shoe") || 
                         itemName.includes("footwear"))) {
                        console.log(`Wardrobe item matched by name for shoes category: ${item.name}`);
                        return true;
                    }
                    
                    // Match shirts/tops
                    if (selectedCategory === "shirts" && 
                        (itemName.includes("shirt") || itemName.includes("top") || 
                         itemName.includes("jacket") || itemName.includes("hoodie") || 
                         itemName.includes("sweater") || itemName.includes("tshirt") || 
                         itemName.includes("t-shirt") || itemName.includes("t_shirt") || 
                         itemLabel.includes("shirt"))) {
                        console.log(`Wardrobe item matched by name for shirts category: ${item.name}`);
                        return true;
                    }
                    
                    // Match pants
                    if (selectedCategory === "pants" && 
                        (itemName.includes("pant") || itemName.includes("jean") || 
                         itemName.includes("trouser") || itemName.includes("short") || 
                         itemName.includes("skirt") || itemLabel.includes("pant"))) {
                        console.log(`Wardrobe item matched by name for pants category: ${item.name}`);
                        return true;
                    }
                    
                    // Match hats
                    if (selectedCategory === "hats" && 
                        (itemName.includes("hat") || itemName.includes("cap") || 
                         itemName.includes("beanie") || itemName.includes("helmet") || 
                         itemLabel.includes("hat"))) {
                        console.log(`Wardrobe item matched by name for hats category: ${item.name}`);
                        return true;
                    }
                    
                    // Match accessories
                    if (selectedCategory === "accessories" && 
                        (itemName.includes("necklace") || itemName.includes("chain") || 
                         itemName.includes("watch") || itemName.includes("bracelet") || 
                         itemName.includes("earring") || itemName.includes("ring") || 
                         itemLabel.includes("accessory") || itemLabel.includes("necklace"))) {
                        console.log(`Wardrobe item matched by name for accessories category: ${item.name}`);
                        return true;
                    }
                    
                    // Match masks
                    if (selectedCategory === "masks" && 
                        (itemName.includes("mask") || itemName.includes("bandana") || 
                         itemName.includes("balaclava") || itemLabel.includes("mask"))) {
                        console.log(`Wardrobe item matched by name for masks category: ${item.name}`);
                        return true;
                    }
                    
                    // Match glasses
                    if (selectedCategory === "glasses" && 
                        (itemName.includes("glass") || itemName.includes("eyewear") || 
                         itemName.includes("sunglass") || itemLabel.includes("glass"))) {
                        console.log(`Wardrobe item matched by name for glasses category: ${item.name}`);
                        return true;
                    }
                    
                    // Check if item's category partly contains or is contained by the selected category
                    if (itemCategory.includes(selectedCategory) || selectedCategory.includes(itemCategory)) {
                        console.log(`Wardrobe item matched by partial category: ${item.name} - ${itemCategory} vs ${selectedCategory}`);
                        return true;
                    }
                    
                    // No match found
                    return false;
                });
                console.log(`After wardrobe category filter (${this.selectedCategory}):`, items.length);
                
                // Additional debugging for subcategory matching
                if (this.debug && items.length > 0) {
                    console.log("Category filtered wardrobe items (sample):", items.slice(0, 3));
                }
            }
            
            // Apply subcategory filter
            if (this.selectedSubcategory && this.selectedCategory) {
                // Log items before filtering to debug
                if (this.debug) {
                    console.log("Wardrobe items before subcategory filter:", items.map(item => ({
                        name: item.name,
                        label: item.label,
                        subcategory: item.subcategory,
                        nameContainsTshirt: item.name.toLowerCase().includes('tshirt') || item.name.toLowerCase().includes('t-shirt') || item.name.toLowerCase().includes('t_shirt')
                    })));
                }
                
                items = items.filter(item => {
                    // Get the subcategory from the item
                    let itemSubcat = String(item.subcategory || "").toLowerCase();
                    const selectedSubcat = String(this.selectedSubcategory).toLowerCase();
                    const itemName = String(item.name || "").toLowerCase();
                    const itemLabel = String(item.label || "").toLowerCase();
                    
                    // Special case for tshirts - check if the name contains tshirt variants
                    if (selectedSubcat === "tshirt" && 
                        (itemName.includes('tshirt') || 
                         itemName.includes('t-shirt') || 
                         itemName.includes('t_shirt') ||
                         itemLabel.includes('t-shirt') || 
                         itemLabel.includes('tshirt') || 
                         itemLabel.includes('t shirt'))) {
                        console.log(`Wardrobe item matched by name/label as tshirt: ${item.name}`);
                        return true;
                    }
                    
                    // Check if item's name contains the subcategory (e.g., "jeans_blue" for subcategory "jeans")
                    if (selectedSubcat !== "tshirt" && itemName.includes(selectedSubcat)) {
                        console.log(`Wardrobe item matched by name for subcategory: ${item.name} - ${selectedSubcat}`);
                        return true;
                    }
                    
                    // Regular subcategory match
                    const match = itemSubcat === selectedSubcat || 
                                  itemSubcat.includes(selectedSubcat) || 
                                  selectedSubcat.includes(itemSubcat);
                                  
                    if (match) {
                        console.log(`Wardrobe item matched by subcategory field: ${item.name} - ${itemSubcat}`);
                    }
                    
                    return match;
                });
                console.log(`After wardrobe subcategory filter (${this.selectedSubcategory}):`, items.length);
                
                // Additional debugging for subcategory result
                if (this.debug && items.length > 0) {
                    console.log("Subcategory filtered wardrobe items (sample):", items.slice(0, 3));
                }
            }
            
            // Apply color filter
            if (this.selectedColor) {
                // Log items before filtering to debug
                if (this.debug) {
                    console.log("Wardrobe items before color filter:", items.map(item => ({
                        name: item.name,
                        label: item.label,
                        color: item.color,
                        nameContainsColor: item.name.toLowerCase().includes(this.selectedColor.toLowerCase())
                    })));
                }
                
                items = items.filter(item => {
                    // Get the color from the item
                    const itemColor = String(item.color || "").toLowerCase();
                    const selectedColor = String(this.selectedColor).toLowerCase();
                    const itemName = String(item.name || "").toLowerCase();
                    const itemLabel = String(item.label || "").toLowerCase();
                    
                    // Check if item's name contains the color (e.g., "jeans_blue" for color "blue")
                    if (itemName.includes(selectedColor)) {
                        console.log(`Wardrobe item matched by name for color: ${item.name} - ${selectedColor}`);
                        return true;
                    }
                    
                    // Check if item's label contains the color
                    if (itemLabel.includes(selectedColor)) {
                        console.log(`Wardrobe item matched by label for color: ${item.name} - ${selectedColor}`);
                        return true;
                    }
                    
                    // Regular color match
                    const match = itemColor === selectedColor || 
                                  itemColor.includes(selectedColor) || 
                                  selectedColor.includes(itemColor);
                                  
                    if (match) {
                        console.log(`Wardrobe item matched by color field: ${item.name} - ${itemColor}`);
                    }
                    
                    return match;
                });
                console.log(`After wardrobe color filter (${this.selectedColor}):`, items.length);
                
                // Additional debugging for color result
                if (this.debug && items.length > 0) {
                    console.log("Color filtered wardrobe items (sample):", items.slice(0, 3));
                }
            }
            
            // Apply search filter
            if (this.searchQuery) {
                const query = this.searchQuery.toLowerCase();
                items = items.filter(item => 
                    item.label.toLowerCase().includes(query) ||
                    item.description.toLowerCase().includes(query)
                );
            }
            
            // Apply sorting
            switch (this.sortBy) {
                case 'name':
                    items.sort((a, b) => a.label.localeCompare(b.label));
                    break;
                case 'condition':
                    items.sort((a, b) => {
                        const aCondition = this.getConditionValue(a);
                        const bCondition = this.getConditionValue(b);
                        return bCondition - aCondition;
                    });
                    break;
            }
            
            return items;
        }
    },
    methods: {
        // View Management
        switchView(view) {
            this.currentView = view;
            this.searchQuery = '';
            this.selectedCategory = null;
            this.selectedSubcategory = null;
            this.selectedColor = null;
            this.selectedRarity = null;
        },
        
        closeUI() {
            this.visible = false;
            // Replace jQuery with vanilla JS with error handling
            try {
                fetch('https://vein-clothing/close', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json; charset=UTF-8',
                    },
                    body: JSON.stringify({})
                })
                .catch(error => {
                    console.error('Error posting to close:', error);
                    // Try fallback
                    return fetch('nui://vein-clothing/https//close', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json; charset=UTF-8',
                        },
                        body: JSON.stringify({})
                    });
                });
                
                // Also try the other endpoint for compatibility
                fetch('https://vein-clothing/closeUI', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json; charset=UTF-8',
                    },
                    body: JSON.stringify({})
                })
                .catch(error => {
                    console.error('Error posting to closeUI:', error);
                    // Try fallback
                    return fetch('nui://vein-clothing/https//closeUI', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json; charset=UTF-8',
                        },
                        body: JSON.stringify({})
                    });
                });
            } catch (error) {
                console.error('Exception in closeUI:', error);
            }
        },
        
        // Item Management
        selectCategory(category) {
            if (this.selectedCategory === category) {
                this.selectedCategory = null;
                this.selectedSubcategory = null;
            } else {
                this.selectedCategory = category;
                this.selectedSubcategory = null;
            }
        },
        
        selectSubcategory(subcategory) {
            this.selectedSubcategory = this.selectedSubcategory === subcategory ? null : subcategory;
        },
        
        selectColor(color) {
            this.selectedColor = this.selectedColor === color ? null : color;
        },
        
        selectRarity(rarity) {
            this.selectedRarity = this.selectedRarity === rarity ? null : rarity;
        },
        
        setSortBy(sortOption) {
            this.sortBy = sortOption;
        },
        
        selectVariation(itemName, variationIndex) {
            this.$set(this.selectedVariations, itemName, variationIndex);
        },
        
        isWishlisted(itemName) {
            return this.wishlistItems.some(item => item.name === itemName);
        },
        
        toggleWishlist(item) {
            if (this.isWishlisted(item.name)) {
                this.wishlistItems = this.wishlistItems.filter(i => i.name !== item.name);
            } else {
                // Add store information to the wishlisted item
                const wishlistItem = { ...item };
                
                // If we're in a store, add current store to availability
                if (this.inStore && this.currentStore) {
                    wishlistItem.availability = [this.currentStore.name || this.currentStore.label];
                    wishlistItem.stock = item.stock;
                }
                
                this.wishlistItems.push(wishlistItem);
                
                // Debug info
                if (this.debug) {
                    console.log("Added item to wishlist:", wishlistItem);
                    console.log("Current store:", this.currentStore);
                    console.log("In store:", this.inStore);
                }
            }
            
            this.postNUI('toggleWishlist', {
                itemName: item.name,
                // Send full item data to server for better wishlist tracking
                itemData: item
            });
        },
        
        // Outfit Management
        saveCurrentOutfit() {
            this.showModal = true;
            this.modalType = 'saveOutfit';
            this.outfitName = '';
        },
        
        saveOutfit() {
            if (!this.outfitName) return;
            
            this.postNUI('saveOutfit', {
                name: this.outfitName
            });
            
            this.closeModal();
        },
        
        showRenameOutfit(outfit) {
            this.selectedOutfit = outfit;
            this.newOutfitName = outfit.name;
            this.showModal = true;
            this.modalType = 'renameOutfit';
        },
        
        renameOutfit() {
            if (!this.newOutfitName) return;
            
            this.postNUI('renameOutfit', {
                outfitId: this.selectedOutfit.id,
                newName: this.newOutfitName
            });
            
            this.closeModal();
        },
        
        showDeleteOutfit(outfit) {
            this.selectedOutfit = outfit;
            this.showModal = true;
            this.modalType = 'deleteOutfit';
        },
        
        deleteOutfit() {
            this.postNUI('deleteOutfit', {
                outfitId: this.selectedOutfit.id
            });
            
            this.closeModal();
        },
        
        wearOutfit(outfitId) {
            this.postNUI('wearOutfit', {
                outfitId: outfitId
            });
        },
        
        setDefaultOutfit(outfitId) {
            this.postNUI('setDefaultOutfit', {
                outfitId: outfitId
            });
        },
        
        // Item Actions
        previewItem(item) {
            this.postNUI('previewItem', {
                itemName: item.name,
                variation: this.selectedVariations[item.name] || 0
            });
        },
        
        purchaseItem(item) {
            this.postNUI('purchaseItem', {
                itemName: item.name,
                variation: this.selectedVariations[item.name] || 0,
                paymentMethod: this.paymentMethod
            });
        },
        
        wearItem(item) {
            this.postNUI('wearItem', {
                itemName: item.name,
                slot: item.slot,
                variation: item.metadata?.variation || 0
            });
        },
        
        removeItem(item) {
            this.postNUI('removeItem', {
                itemName: item.name,
                slot: item.slot
            });
        },
        
        isWorn(itemName) {
            return this.wardrobeItems.some(item => item.name === itemName && item.worn);
        },
        
        // Player Interaction
        toggleInteractionMenu(item) {
            this.interactionItem = this.interactionItem === item.name + item.slot ? null : item.name + item.slot;
        },
        
        showTradeMenu(item) {
            this.selectedItem = item;
            this.showModal = true;
            this.modalType = 'tradeItem';
            this.interactionItem = null;
        },
        
        showSellMenu(item) {
            this.selectedItem = item;
            this.sellPrice = 0;
            this.showModal = true;
            this.modalType = 'sellItem';
            this.interactionItem = null;
        },
        
        selectPlayer(playerId) {
            this.selectedPlayer = playerId;
        },
        
        tradeItem() {
            if (!this.selectedPlayer) return;
            
            this.postNUI('tradeItem', {
                itemName: this.selectedItem.name,
                slot: this.selectedItem.slot,
                targetPlayer: this.selectedPlayer
            });
            
            this.closeModal();
        },
        
        sellItem() {
            if (!this.selectedPlayer || !this.sellPrice) return;
            
            this.postNUI('sellItem', {
                itemName: this.selectedItem.name,
                slot: this.selectedItem.slot,
                targetPlayer: this.selectedPlayer,
                price: this.sellPrice
            });
            
            this.closeModal();
        },
        
        // Laundry & Repair
        toggleDirtyItemSelection(item) {
            const index = this.selectedDirtyItems.findIndex(i => i.name === item.name && i.slot === item.slot);
            if (index === -1) {
                this.selectedDirtyItems.push(item);
            } else {
                this.selectedDirtyItems.splice(index, 1);
            }
        },
        
        isDirtyItemSelected(item) {
            return this.selectedDirtyItems.some(i => i.name === item.name && i.slot === item.slot);
        },
        
        toggleDamagedItemSelection(item) {
            const index = this.selectedDamagedItems.findIndex(i => i.name === item.name && i.slot === item.slot);
            if (index === -1) {
                this.selectedDamagedItems.push(item);
            } else {
                this.selectedDamagedItems.splice(index, 1);
            }
        },
        
        isDamagedItemSelected(item) {
            return this.selectedDamagedItems.some(i => i.name === item.name && i.slot === item.slot);
        },
        
        washSelectedItems() {
            if (this.selectedDirtyItems.length === 0) return;
            
            this.postNUI('washItems', {
                items: this.selectedDirtyItems.map(item => ({
                    name: item.name,
                    slot: item.slot
                }))
            });
            
            this.selectedDirtyItems = [];
        },
        
        getRepairTotalCost() {
            return this.selectedDamagedItems.reduce((total, item) => {
                return total + this.getItemRepairCost(item);
            }, 0);
        },
        
        getItemRepairCost(item) {
            const condition = this.getConditionValue(item);
            const damage = 100 - condition;
            return Math.ceil(this.repairPrice * (damage / 100));
        },
        
        repairSelectedItems() {
            if (this.selectedDamagedItems.length === 0) return;
            
            this.postNUI('repairItems', {
                items: this.selectedDamagedItems.map(item => ({
                    name: item.name,
                    slot: item.slot
                }))
            });
            
            this.selectedDamagedItems = [];
        },
        
        // Condition Management
        getConditionValue(item) {
            if (!item.metadata || !item.metadata.condition) return 100;
            return item.metadata.condition;
        },
        
        getConditionWidth(item) {
            return this.getConditionValue(item);
        },
        
        getConditionColor(item) {
            const condition = this.getConditionValue(item);
            if (condition >= 80) return 'var(--condition-excellent)';
            if (condition >= 60) return 'var(--condition-good)';
            if (condition >= 40) return 'var(--condition-poor)';
            return 'var(--condition-terrible)';
        },
        
        getConditionLabel(item) {
            const condition = this.getConditionValue(item);
            if (condition >= 80) return 'Excellent';
            if (condition >= 60) return 'Good';
            if (condition >= 40) return 'Poor';
            return 'Terrible';
        },
        
        // Modal Management
        closeModal() {
            this.showModal = false;
            this.modalType = '';
            this.selectedItem = null;
            this.selectedPlayer = null;
            this.sellPrice = 0;
            this.outfitName = '';
            this.newOutfitName = '';
            this.selectedOutfit = null;
            this.offerData = null;
        },
        
        // Notification Management
        addNotification(message, type = 'info') {
            this.notifications.push({
                message,
                type
            });
            
            setTimeout(() => {
                this.notifications.shift();
            }, 5000);
        },
        
        getNotificationIcon(type) {
            switch (type) {
                case 'success':
                    return 'fas fa-check-circle';
                case 'error':
                    return 'fas fa-exclamation-circle';
                case 'warning':
                    return 'fas fa-exclamation-triangle';
                default:
                    return 'fas fa-info-circle';
            }
        },
        
        // Event Handlers
        respondToOffer(accept) {
            this.postNUI('respondToOffer', {
                accept: accept
            });
            
            this.closeModal();
        },
        
        // Toggle payment method between cash and bank
        togglePaymentMethod() {
            this.paymentMethod = this.paymentMethod === 'cash' ? 'bank' : 'cash';
            this.addNotification(`Payment method switched to ${this.paymentMethod}`, 'info');
        },
        
        // Check if player can afford item with current payment method
        canAfford(price) {
            if (this.paymentMethod === 'cash') {
                return this.playerMoney.cash >= price;
            } else {
                return this.playerMoney.bank >= price;
            }
        },
        
        // Helper function to replace $.post
        postNUI(eventName, data) {
            try {
                fetch(`https://vein-clothing/${eventName}`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json; charset=UTF-8',
                    },
                    body: JSON.stringify(data || {})
                })
                .catch(error => {
                    console.error(`UI error posting to ${eventName}:`, error);
                    // Try fallback to alternate path format
                    return fetch(`nui://vein-clothing/https//${eventName}`, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json; charset=UTF-8',
                        },
                        body: JSON.stringify(data || {})
                    });
                })
                .catch(error => {
                    console.error(`UI error with fallback post to ${eventName}:`, error);
                });
            } catch (error) {
                console.error(`UI exception in postNUI for ${eventName}:`, error);
            }
        },
        
        // Add a refreshWardrobe method to the Vue app
        refreshWardrobe() {
            fetch('https://vein-clothing/refreshWardrobe', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({})
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    this.wardrobeItems = data.wardrobeItems;
                    this.outfits = data.outfits;
                    this.wishlistItems = data.wishlistItems;
                    console.log('Wardrobe refreshed:', this.wardrobeItems.length, 'items found');
                }
            })
            .catch(error => {
                console.error('Error refreshing wardrobe:', error);
            });
        },
        
        // Update the showWardrobe method to call refreshWardrobe
        showWardrobe() {
            this.refreshWardrobe(); // Refresh wardrobe data when showing wardrobe
            this.currentView = 'wardrobe';
            this.selectedCategory = 'all';
            this.searchQuery = '';
            this.inStore = false;
            this.inWardrobe = true;
            // Additional wardrobe setup...
        }
    },
    mounted() {
        // Listen for messages from the server
        window.addEventListener('message', (event) => {
            const data = event.data;
            
            // Debug message
            console.log('Received NUI message:', data);
            
            if (data.type === "show") {
                // New show format
                this.visible = true;
                this.inStore = data.inStore || false;
                this.inLaundromat = data.inLaundromat || false;
                this.inTailor = data.inTailor || false;
                this.currentStore = data.store || null;
                
                // Handle money - either as object or single value for backwards compatibility
                if (typeof data.money === 'object') {
                    this.playerMoney = data.money;
                } else {
                    this.playerMoney = {
                        cash: data.money || 0,
                        bank: 0
                    };
                }
                
                this.storeItems = data.storeItems || [];
                this.wardrobeItems = data.wardrobeItems || [];
                
                // Update wishlist items with availability data
                if (data.wishlistItems) {
                    // Process wishlist items to check availability in current store
                    if (this.inStore && this.currentStore && this.storeItems.length > 0) {
                        data.wishlistItems.forEach(wishItem => {
                            // Find corresponding item in store
                            const storeItem = this.storeItems.find(item => item.name === wishItem.name);
                            
                            if (storeItem) {
                                // Item is available in current store
                                if (!wishItem.availability) {
                                    wishItem.availability = [];
                                }
                                
                                // Add current store to availability if not already included
                                const storeName = this.currentStore.name || this.currentStore.label;
                                if (!wishItem.availability.includes(storeName)) {
                                    wishItem.availability.push(storeName);
                                }
                                
                                // Update stock information
                                wishItem.stock = storeItem.stock;
                            }
                        });
                    }
                    
                    this.wishlistItems = data.wishlistItems;
                }
                
                this.outfits = data.outfits || [];
                this.dirtyItems = data.dirtyItems || [];
                this.damagedItems = data.damagedItems || [];
                this.nearbyPlayers = data.nearbyPlayers || [];
                this.debug = data.debug || false;
                this.currentView = this.inStore ? 'store' : (this.inLaundromat ? 'laundry' : (this.inTailor ? 'repair' : 'wardrobe'));
                console.log('UI visible:', this.visible, 'Current view:', this.currentView);
                
                // Handle case where store opened but no items received
                if (this.inStore && this.storeItems.length === 0) {
                    console.warn('Store opened but no items received');
                    this.addNotification('No items available at this store', 'warning');
                }
            } else if (data.type === "hide") {
                // New hide format
                this.visible = false;
                this.showModal = false;
                this.modalType = '';
                console.log('UI hidden by client type:hide request');
            } else if (data.action === "openStore") {
                // Legacy format
                this.visible = true;
                this.inStore = true;
                this.inLaundromat = false;
                this.inTailor = false;
                this.currentStore = data.store || data.storeData || null;
                this.playerMoney = data.playerMoney || 0;
                this.storeItems = data.inventory || [];
                this.debug = data.debug || false;
                this.currentView = 'store';
                console.log('UI visible (legacy format):', this.visible, 'Current view:', this.currentView);
            } else if (data.action === "hide") {
                // Legacy hide format
                this.visible = false;
                this.showModal = false;
                this.modalType = '';
                this.currentView = 'store';
                console.log('UI hidden by client action:hide request');
            } else if (data.action === "initialize") {
                // Initialize default UI state
                this.visible = false;
                this.inStore = false;
                this.inLaundromat = false;
                this.inTailor = false;
                this.currentStore = null;
                this.currentView = 'store';
                this.debug = data.debug || false;
                console.log('UI initialized with debug mode:', this.debug);
            } else if (data.type === 'updateMoney') {
                // Update money amounts
                if (typeof data.money === 'object') {
                    this.playerMoney = data.money;
                } else {
                    this.playerMoney.cash = data.money || 0;
                }
                console.log('Money updated:', this.playerMoney);
            } else if (data.type === 'updateStoreItems') {
                this.storeItems = data.items;
            } else if (data.type === 'updateWardrobeItems') {
                this.wardrobeItems = data.items;
            } else if (data.type === 'updateWishlistItems') {
                this.wishlistItems = data.items || [];
                
                // Add debugging information
                if (this.debug) {
                    console.log("Updated wishlist items:", this.wishlistItems);
                    if (this.wishlistItems.length > 0) {
                        console.log("Sample wishlist item:", this.wishlistItems[0]);
                    }
                }
                
                // If we're in a store, check for availability in the current store
                if (this.inStore && this.currentStore && this.storeItems.length > 0) {
                    this.wishlistItems.forEach(wishItem => {
                        // Find item in current store
                        const storeItem = this.storeItems.find(item => item.name === wishItem.name);
                        if (storeItem) {
                            // Update availability information
                            if (!wishItem.availability) {
                                wishItem.availability = [];
                            }
                            
                            // Add current store to availability if not included
                            const storeName = this.currentStore.name || this.currentStore.label;
                            if (!wishItem.availability.includes(storeName)) {
                                wishItem.availability.push(storeName);
                            }
                            
                            // Update stock
                            wishItem.stock = storeItem.stock;
                        }
                    });
                }
            } else if (data.type === 'updateOutfits') {
                this.outfits = data.outfits;
            } else if (data.type === 'updateDirtyItems') {
                this.dirtyItems = data.items;
            } else if (data.type === 'updateDamagedItems') {
                this.damagedItems = data.items;
            } else if (data.type === 'updateNearbyPlayers') {
                this.nearbyPlayers = data.players;
            } else if (data.type === 'showOffer') {
                this.showModal = true;
                this.modalType = 'offerReceived';
                this.offerData = data.offer;
            } else if (data.type === 'notification') {
                this.addNotification(data.message, data.notificationType);
            }
        });
        
        // Listen for key events
        document.addEventListener('keyup', (event) => {
            if (event.key === 'Escape' && this.visible) {
                this.closeUI();
            }
        });
    }
}); 