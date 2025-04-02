import React, { useState } from 'react';
import './ItemCard.css'; // We'll need to create this CSS file

const ItemCard = ({ item, onPurchase, onPreview }) => {
  const [selectedVariation, setSelectedVariation] = useState(0);
  
  // Extract item properties (in a real implementation, these would come from the item object)
  const { 
    name, 
    label,
    price, 
    rarity = 'common', 
    variations = [], 
    condition = 100, 
    category = 'tops',
    description = 'A stylish clothing item'
  } = item;
  
  // Define rarity classes for styling
  const rarityClasses = {
    common: 'rarity-common',
    uncommon: 'rarity-uncommon',
    rare: 'rarity-rare',
    exclusive: 'rarity-exclusive',
    limited: 'rarity-limited'
  };
  
  // Calculate condition display
  const getConditionLabel = () => {
    if (condition > 90) return 'New';
    if (condition > 70) return 'Good';
    if (condition > 50) return 'Worn';
    if (condition > 30) return 'Damaged';
    return 'Poor';
  };
  
  // Handle variation changes
  const handleVariationChange = (index) => {
    setSelectedVariation(index);
    onPreview(item, index); // Preview the selected variation
  };
  
  // Format price with currency
  const formattedPrice = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0
  }).format(price);

  return (
    <div className={`item-card ${rarityClasses[rarity]}`}>
      <div className="item-image">
        {/* This would be an actual image in implementation */}
        <div className="placeholder-image">
          {category.charAt(0).toUpperCase()}
        </div>
        {rarity !== 'common' && (
          <div className="item-badge">{rarity}</div>
        )}
      </div>
      
      <div className="item-details">
        <h3 className="item-name">{label || name}</h3>
        <p className="item-description">{description}</p>
        
        <div className="item-meta">
          <span className="item-price">{formattedPrice}</span>
          <span className={`item-condition condition-${getConditionLabel().toLowerCase()}`}>
            {getConditionLabel()}
          </span>
        </div>
        
        {variations.length > 0 && (
          <div className="item-variations">
            {variations.map((variation, index) => (
              <button 
                key={index}
                className={`variation-btn ${selectedVariation === index ? 'selected' : ''}`}
                style={{ backgroundColor: variation.color || '#ccc' }}
                onClick={() => handleVariationChange(index)}
                title={variation.label || `Variation ${index + 1}`}
              />
            ))}
          </div>
        )}
        
        <div className="item-actions">
          <button 
            className="preview-btn" 
            onClick={() => onPreview(item, selectedVariation)}
          >
            Try On
          </button>
          <button 
            className="purchase-btn" 
            onClick={() => onPurchase(item, selectedVariation)}
          >
            Purchase
          </button>
        </div>
      </div>
    </div>
  );
};

export default ItemCard;
