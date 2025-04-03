-- SQL script to fix the store_inventory table structure
-- Run this if you're getting the error "#1054 - Unknown column 'category' in 'field list'"

-- Add the missing columns to store_inventory table
ALTER TABLE `store_inventory` 
ADD COLUMN `category` varchar(50) DEFAULT 'clothes',
ADD COLUMN `subcategory` varchar(50) DEFAULT NULL,
ADD COLUMN `color` varchar(30) DEFAULT NULL,
ADD COLUMN `component` int(11) DEFAULT 11,
ADD COLUMN `drawable` int(11) DEFAULT 0,
ADD COLUMN `texture` int(11) DEFAULT 0,
ADD COLUMN `rarity` varchar(30) DEFAULT 'common',
ADD COLUMN `price` int(11) DEFAULT 100,
ADD COLUMN `label` varchar(100) DEFAULT NULL;

-- Add indexes for performance
CREATE INDEX idx_store_inventory_store ON store_inventory (store);
CREATE INDEX idx_store_inventory_category ON store_inventory (category);
CREATE INDEX idx_store_inventory_subcategory ON store_inventory (subcategory);
CREATE INDEX idx_store_inventory_color ON store_inventory (color);
CREATE INDEX idx_store_inventory_rarity ON store_inventory (rarity);

-- Note: After running this script, restart your server to apply the changes. 