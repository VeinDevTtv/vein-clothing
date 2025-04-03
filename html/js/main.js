// Main Vue instance for the clothing system
const app = new Vue({
    el: '#app',
    data: {
        visible: false,
        debug: false,
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
            let items = [...this.storeItems];
            
            // Apply category filter
            if (this.selectedCategory) {
                items = items.filter(item => item.category === this.selectedCategory);
            }
            
            // Apply subcategory filter
            if (this.selectedSubcategory && this.selectedCategory) {
                items = items.filter(item => item.subcategory === this.selectedSubcategory);
            }
            
            // Apply color filter
            if (this.selectedColor) {
                items = items.filter(item => item.color === this.selectedColor);
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
            let items = [...this.wardrobeItems];
            
            // Apply category filter
            if (this.selectedCategory) {
                items = items.filter(item => item.category === this.selectedCategory);
            }
            
            // Apply subcategory filter
            if (this.selectedSubcategory && this.selectedCategory) {
                items = items.filter(item => item.subcategory === this.selectedSubcategory);
            }
            
            // Apply color filter
            if (this.selectedColor) {
                items = items.filter(item => item.color === this.selectedColor);
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
                this.wishlistItems.push(item);
            }
            this.postNUI('toggleWishlist', {
                itemName: item.name
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
                this.wishlistItems = data.wishlistItems || [];
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
                this.wishlistItems = data.items;
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