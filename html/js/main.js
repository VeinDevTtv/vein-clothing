// Main Vue instance for the clothing system
const app = new Vue({
    el: '#app',
    data: {
        visible: false,
        currentView: 'store',
        inStore: false,
        inLaundromat: false,
        inTailor: false,
        currentStore: null,
        playerMoney: 0,
        searchQuery: '',
        selectedCategory: null,
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
        filteredStoreItems() {
            let items = [...this.storeItems];
            
            // Apply category filter
            if (this.selectedCategory) {
                items = items.filter(item => item.category === this.selectedCategory);
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
            this.selectedRarity = null;
        },
        
        closeUI() {
            this.visible = false;
            $.post('https://vein-clothing/close', JSON.stringify({}));
        },
        
        // Item Management
        selectCategory(category) {
            this.selectedCategory = this.selectedCategory === category ? null : category;
        },
        
        selectRarity(rarity) {
            this.selectedRarity = this.selectedRarity === rarity ? null : rarity;
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
            $.post('https://vein-clothing/toggleWishlist', JSON.stringify({
                itemName: item.name
            }));
        },
        
        // Outfit Management
        saveCurrentOutfit() {
            this.showModal = true;
            this.modalType = 'saveOutfit';
            this.outfitName = '';
        },
        
        saveOutfit() {
            if (!this.outfitName) return;
            
            $.post('https://vein-clothing/saveOutfit', JSON.stringify({
                name: this.outfitName
            }));
            
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
            
            $.post('https://vein-clothing/renameOutfit', JSON.stringify({
                outfitId: this.selectedOutfit.id,
                newName: this.newOutfitName
            }));
            
            this.closeModal();
        },
        
        showDeleteOutfit(outfit) {
            this.selectedOutfit = outfit;
            this.showModal = true;
            this.modalType = 'deleteOutfit';
        },
        
        deleteOutfit() {
            $.post('https://vein-clothing/deleteOutfit', JSON.stringify({
                outfitId: this.selectedOutfit.id
            }));
            
            this.closeModal();
        },
        
        wearOutfit(outfitId) {
            $.post('https://vein-clothing/wearOutfit', JSON.stringify({
                outfitId: outfitId
            }));
        },
        
        setDefaultOutfit(outfitId) {
            $.post('https://vein-clothing/setDefaultOutfit', JSON.stringify({
                outfitId: outfitId
            }));
        },
        
        // Item Actions
        previewItem(item) {
            $.post('https://vein-clothing/previewItem', JSON.stringify({
                itemName: item.name,
                variation: this.selectedVariations[item.name] || 0
            }));
        },
        
        purchaseItem(item) {
            $.post('https://vein-clothing/purchaseItem', JSON.stringify({
                itemName: item.name,
                variation: this.selectedVariations[item.name] || 0
            }));
        },
        
        wearItem(item) {
            $.post('https://vein-clothing/wearItem', JSON.stringify({
                itemName: item.name,
                slot: item.slot,
                variation: item.metadata?.variation || 0
            }));
        },
        
        removeItem(item) {
            $.post('https://vein-clothing/removeItem', JSON.stringify({
                itemName: item.name,
                slot: item.slot
            }));
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
            
            $.post('https://vein-clothing/tradeItem', JSON.stringify({
                itemName: this.selectedItem.name,
                slot: this.selectedItem.slot,
                targetPlayer: this.selectedPlayer
            }));
            
            this.closeModal();
        },
        
        sellItem() {
            if (!this.selectedPlayer || !this.sellPrice) return;
            
            $.post('https://vein-clothing/sellItem', JSON.stringify({
                itemName: this.selectedItem.name,
                slot: this.selectedItem.slot,
                targetPlayer: this.selectedPlayer,
                price: this.sellPrice
            }));
            
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
            
            $.post('https://vein-clothing/washItems', JSON.stringify({
                items: this.selectedDirtyItems.map(item => ({
                    name: item.name,
                    slot: item.slot
                }))
            }));
            
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
            
            $.post('https://vein-clothing/repairItems', JSON.stringify({
                items: this.selectedDamagedItems.map(item => ({
                    name: item.name,
                    slot: item.slot
                }))
            }));
            
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
            $.post('https://vein-clothing/respondToOffer', JSON.stringify({
                accept: accept
            }));
            
            this.closeModal();
        }
    },
    mounted() {
        // Listen for messages from the server
        window.addEventListener('message', (event) => {
            const data = event.data;
            
            // Debug message
            console.log('Received NUI message:', data);
            
            switch (data.type) {
                case 'show':
                    this.visible = true;
                    this.inStore = data.inStore || false;
                    this.inLaundromat = data.inLaundromat || false;
                    this.inTailor = data.inTailor || false;
                    this.currentStore = data.store || null;
                    this.playerMoney = data.money || 0;
                    this.storeItems = data.storeItems || [];
                    this.wardrobeItems = data.wardrobeItems || [];
                    this.wishlistItems = data.wishlistItems || [];
                    this.outfits = data.outfits || [];
                    this.dirtyItems = data.dirtyItems || [];
                    this.damagedItems = data.damagedItems || [];
                    this.nearbyPlayers = data.nearbyPlayers || [];
                    break;
                
                // For backward compatibility with the old format
                case 'openStore':
                case 'action':
                    if (data.action === "openStore") {
                        this.visible = true;
                        this.inStore = true;
                        this.inLaundromat = false;
                        this.inTailor = false;
                        this.currentStore = data.store || data.storeData || null;
                        this.playerMoney = data.playerMoney || 0;
                        this.storeItems = data.inventory || [];
                        this.currentView = 'store';
                    } else if (data.action === "hide") {
                        this.visible = false;
                        this.showModal = false;
                        this.modalType = '';
                        this.currentView = 'store';
                        console.log('UI hidden by client request');
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
                    }
                    break;
                    
                case 'updateMoney':
                    this.playerMoney = data.money;
                    break;
                    
                case 'updateStoreItems':
                    this.storeItems = data.items;
                    break;
                    
                case 'updateWardrobeItems':
                    this.wardrobeItems = data.items;
                    break;
                    
                case 'updateWishlistItems':
                    this.wishlistItems = data.items;
                    break;
                    
                case 'updateOutfits':
                    this.outfits = data.outfits;
                    break;
                    
                case 'updateDirtyItems':
                    this.dirtyItems = data.items;
                    break;
                    
                case 'updateDamagedItems':
                    this.damagedItems = data.items;
                    break;
                    
                case 'updateNearbyPlayers':
                    this.nearbyPlayers = data.players;
                    break;
                    
                case 'showOffer':
                    this.showModal = true;
                    this.modalType = 'offerReceived';
                    this.offerData = data.offer;
                    break;
                    
                case 'notification':
                    this.addNotification(data.message, data.notificationType);
                    break;
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