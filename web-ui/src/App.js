import React, { useState, useEffect } from 'react';
import ItemCard from './components/ItemCard';
import './App.css';

const App = () => {
  const [storeData, setStoreData] = useState(null);
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [wishlist, setWishlist] = useState([]);
  const [viewMode, setViewMode] = useState('store'); // 'store', 'wishlist', 'outfits'
  const [savedOutfits, setSavedOutfits] = useState([]);
  const [currentOutfit, setCurrentOutfit] = useState([]);
  const [notification, setNotification] = useState(null);

  // Categories for clothing
  const categories = [
    { id: 'all', label: 'All Items' },
    { id: 'tops', label: 'Tops' },
    { id: 'pants', label: 'Pants' },
    { id: 'shoes', label: 'Shoes' },
    { id: 'hats', label: 'Hats' },
    { id: 'glasses', label: 'Glasses' },
    { id: 'accessories', label: 'Accessories' }
  ];

  useEffect(() => {
    // Listen for NUI messages from the client
    window.addEventListener('message', (event) => {
      const data = event.data;
      
      if (data.action === "openStore") {
        setStoreData(data.storeData);
        setViewMode('store');
      } else if (data.action === "setWishlist") {
        setWishlist(data.wishlist || []);
      } else if (data.action === "setSavedOutfits") {
        setSavedOutfits(data.outfits || []);
      } else if (data.action === "setCurrentOutfit") {
        setCurrentOutfit(data.outfit || []);
      } else if (data.action === "notification") {
        showNotification(data.message, data.type || 'info');
      }
    });

    // Load saved data from localStorage (for development)
    const savedWishlist = localStorage.getItem('clothing_wishlist');
    if (savedWishlist) {
      setWishlist(JSON.parse(savedWishlist));
    }
    
    const savedOutfits = localStorage.getItem('clothing_outfits');
    if (savedOutfits) {
      setSavedOutfits(JSON.parse(savedOutfits));
    }
  }, []);

  // Save wishlist to localStorage whenever it changes (for development)
  useEffect(() => {
    if (wishlist.length > 0) {
      localStorage.setItem('clothing_wishlist', JSON.stringify(wishlist));
    }
  }, [wishlist]);

  // Save outfits to localStorage whenever they change (for development)
  useEffect(() => {
    if (savedOutfits.length > 0) {
      localStorage.setItem('clothing_outfits', JSON.stringify(savedOutfits));
    }
  }, [savedOutfits]);

  const handlePurchase = (item, variationIndex = 0) => {
    // Send a POST message to the client-side NUI callback endpoint
    fetch('http://clothing-system/purchaseItem', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ 
        item: item.name || item,
        price: item.price,
        variation: variationIndex
      })
    });
    
    showNotification(`Purchased ${item.label || item.name || item}!`, 'success');
  };

  const handlePreview = (item, variationIndex = 0) => {
    fetch('http://clothing-system/previewItem', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ 
        item: item.name || item,
        variation: variationIndex
      })
    });
    
    // Add to current outfit for tracking
    const itemInOutfit = currentOutfit.findIndex(i => i.slot === item.slot);
    
    if (itemInOutfit >= 0) {
      const newOutfit = [...currentOutfit];
      newOutfit[itemInOutfit] = { 
        ...item, 
        selectedVariation: variationIndex 
      };
      setCurrentOutfit(newOutfit);
    } else {
      setCurrentOutfit([
        ...currentOutfit, 
        { ...item, selectedVariation: variationIndex }
      ]);
    }
  };

  const toggleWishlist = (item) => {
    const itemIndex = wishlist.findIndex(i => i.name === item.name);
    
    if (itemIndex >= 0) {
      // Remove from wishlist
      setWishlist(wishlist.filter(i => i.name !== item.name));
      showNotification(`Removed from wishlist!`, 'info');
    } else {
      // Add to wishlist
      setWishlist([...wishlist, item]);
      showNotification(`Added to wishlist!`, 'success');
    }
    
    // Sync with client
    fetch('http://clothing-system/updateWishlist', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ wishlist: [...wishlist, item] })
    });
  };

  const saveCurrentOutfit = () => {
    if (currentOutfit.length === 0) {
      showNotification('No items in current outfit!', 'error');
      return;
    }
    
    const outfitName = prompt('Enter a name for this outfit:');
    if (!outfitName) return;
    
    const newOutfit = {
      id: Date.now().toString(),
      name: outfitName,
      items: currentOutfit
    };
    
    setSavedOutfits([...savedOutfits, newOutfit]);
    showNotification(`Outfit "${outfitName}" saved!`, 'success');
    
    // Sync with client
    fetch('http://clothing-system/saveOutfit', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ outfit: newOutfit })
    });
  };

  const wearSavedOutfit = (outfit) => {
    // Apply each item in the outfit
    outfit.items.forEach(item => {
      handlePreview(item, item.selectedVariation || 0);
    });
    
    showNotification(`Wearing outfit "${outfit.name}"`, 'success');
  };

  const closeUI = () => {
    fetch('http://clothing-system/closeUI', { method: 'POST' });
    setStoreData(null);
  };

  const showNotification = (message, type = 'info') => {
    setNotification({ message, type });
    setTimeout(() => setNotification(null), 3000);
  };

  // Filter items based on category and search
  const getFilteredItems = () => {
    if (!storeData || !storeData.inventory) return [];
    
    return storeData.inventory.filter(item => {
      const matchesCategory = selectedCategory === 'all' || item.category === selectedCategory;
      const matchesSearch = !searchQuery || 
        (item.name && item.name.toLowerCase().includes(searchQuery.toLowerCase())) || 
        (item.label && item.label.toLowerCase().includes(searchQuery.toLowerCase())) ||
        (item.description && item.description.toLowerCase().includes(searchQuery.toLowerCase()));
      
      return matchesCategory && matchesSearch;
    });
  };

  if (!storeData) {
    return <div className="app loading">Waiting for store data...</div>;
  }

  return (
    <div className="app">
      {/* Notification */}
      {notification && (
        <div className={`notification notification-${notification.type}`}>
          {notification.message}
        </div>
      )}
      
      {/* Header */}
      <header className="store-header">
        <div className="store-info">
          <h1>{storeData.label}</h1>
          <p className="store-description">{storeData.description || 'Shop for clothing items'}</p>
        </div>
        
        <div className="view-controls">
          <button 
            className={`view-btn ${viewMode === 'store' ? 'active' : ''}`}
            onClick={() => setViewMode('store')}
          >
            Store
          </button>
          <button 
            className={`view-btn ${viewMode === 'wishlist' ? 'active' : ''}`}
            onClick={() => setViewMode('wishlist')}
          >
            Wishlist ({wishlist.length})
          </button>
          <button 
            className={`view-btn ${viewMode === 'outfits' ? 'active' : ''}`}
            onClick={() => setViewMode('outfits')}
          >
            Outfits
          </button>
          <button className="close-btn" onClick={closeUI}>Close</button>
        </div>
      </header>
      
      {/* Store View */}
      {viewMode === 'store' && (
        <>
          {/* Filter controls */}
          <div className="filter-controls">
            <div className="category-filters">
              {categories.map(category => (
                <button 
                  key={category.id}
                  className={`category-btn ${selectedCategory === category.id ? 'active' : ''}`}
                  onClick={() => setSelectedCategory(category.id)}
                >
                  {category.label}
                </button>
              ))}
            </div>
            
            <div className="search-bar">
              <input 
                type="text" 
                placeholder="Search items..." 
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
          </div>
          
          {/* Item list */}
          <div className="item-list">
            {getFilteredItems().map((item, index) => (
              <ItemCard
                key={index}
                item={item}
                onPurchase={handlePurchase}
                onPreview={handlePreview}
                onWishlist={() => toggleWishlist(item)}
                isWishlisted={wishlist.some(w => w.name === item.name)}
              />
            ))}
            
            {getFilteredItems().length === 0 && (
              <div className="no-items">No items found matching your criteria.</div>
            )}
          </div>
        </>
      )}
      
      {/* Wishlist View */}
      {viewMode === 'wishlist' && (
        <div className="wishlist-view">
          <h2>My Wishlist</h2>
          
          {wishlist.length === 0 ? (
            <div className="no-items">Your wishlist is empty.</div>
          ) : (
            <div className="item-list">
              {wishlist.map((item, index) => (
                <ItemCard
                  key={index}
                  item={item}
                  onPurchase={handlePurchase}
                  onPreview={handlePreview}
                  onWishlist={() => toggleWishlist(item)}
                  isWishlisted={true}
                />
              ))}
            </div>
          )}
        </div>
      )}
      
      {/* Outfits View */}
      {viewMode === 'outfits' && (
        <div className="outfits-view">
          <div className="outfits-controls">
            <h2>My Outfits</h2>
            <button className="save-outfit-btn" onClick={saveCurrentOutfit}>
              Save Current Outfit
            </button>
          </div>
          
          {savedOutfits.length === 0 ? (
            <div className="no-items">You haven't saved any outfits yet.</div>
          ) : (
            <div className="outfits-list">
              {savedOutfits.map(outfit => (
                <div key={outfit.id} className="outfit-card">
                  <h3>{outfit.name}</h3>
                  <p>{outfit.items.length} items</p>
                  <button onClick={() => wearSavedOutfit(outfit)}>Wear Outfit</button>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default App;
