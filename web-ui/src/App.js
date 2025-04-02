import React, { useState, useEffect } from 'react';
import ItemCard from './components/ItemCard';

const App = () => {
  const [storeData, setStoreData] = useState(null);

  useEffect(() => {
    // Listen for NUI messages from the client
    window.addEventListener('message', (event) => {
      const data = event.data;
      if (data.action === "openStore") {
        setStoreData(data.storeData);
      }
    });
  }, []);

  const handlePurchase = (itemName, price) => {
    // Send a POST message to the client-side NUI callback endpoint
    fetch('http://your_resource_name/purchaseItem', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ itemName, price })
    });
  };

  const handlePreview = (itemName) => {
    fetch('http://your_resource_name/previewItem', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ itemName })
    });
  };

  const closeUI = () => {
    fetch('http://your_resource_name/closeUI', { method: 'POST' });
    setStoreData(null);
  };

  if (!storeData) {
    return <div className="app">Waiting for store data...</div>;
  }

  return (
    <div className="app">
      <header>
        <h1>{storeData.label}</h1>
        <button onClick={closeUI}>Close</button>
      </header>
      <div className="item-list">
        {storeData.inventory.map((item, index) => (
          <ItemCard
            key={index}
            item={item}
            onPurchase={handlePurchase}
            onPreview={handlePreview}
          />
        ))}
      </div>
    </div>
  );
};

export default App;
