-- Create database tables for the Vein Clothing System

-- Outfits table to store saved player outfits
CREATE TABLE IF NOT EXISTS `player_outfits` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `outfitname` varchar(50) NOT NULL,
  `outfit` longtext NOT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Wishlist table to store player wishlisted items
CREATE TABLE IF NOT EXISTS `player_wishlist` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `item` varchar(100) NOT NULL,
  `added_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`),
  UNIQUE KEY `citizen_item` (`citizenid`, `item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Clothing stores table for tracking store inventory and restocks
CREATE TABLE IF NOT EXISTS `clothing_stores` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `store` varchar(50) NOT NULL,
  `item` varchar(100) NOT NULL,
  `stock` int(11) NOT NULL DEFAULT 10,
  `last_restock` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `store_item` (`store`, `item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Clothing conditions table to track player item conditions
CREATE TABLE IF NOT EXISTS `player_clothing_condition` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) DEFAULT NULL,
  `item` varchar(50) DEFAULT NULL,
  `condition` int(11) DEFAULT 100,
  `is_dirty` tinyint(1) DEFAULT 0,
  `is_damaged` tinyint(1) DEFAULT 0,
  `last_worn` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `citizenid_item` (`citizenid`, `item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Store inventory table for tracking store inventory with advanced details
CREATE TABLE IF NOT EXISTS `store_inventory` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `store` varchar(50) DEFAULT NULL,
  `item` varchar(50) DEFAULT NULL,
  `stock` int(11) DEFAULT 0,
  `last_restock` timestamp NULL DEFAULT NULL,
  `category` varchar(50) DEFAULT 'clothes',
  `subcategory` varchar(50) DEFAULT NULL,
  `color` varchar(30) DEFAULT NULL,
  `component` int(11) DEFAULT 11,
  `drawable` int(11) DEFAULT 0,
  `texture` int(11) DEFAULT 0,
  `rarity` varchar(30) DEFAULT 'common',
  `price` int(11) DEFAULT 100,
  `label` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `store_item` (`store`, `item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Player trades table for tracking clothing trades between players
CREATE TABLE IF NOT EXISTS `player_trades` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `sender_id` varchar(50) NOT NULL,
  `receiver_id` varchar(50) NOT NULL,
  `item` varchar(100) NOT NULL,
  `price` int(11) DEFAULT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `completed_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `sender_id` (`sender_id`),
  KEY `receiver_id` (`receiver_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert example stores with all vanilla clothing items
INSERT INTO `store_inventory` (`store`, `item`, `stock`, `category`, `subcategory`, `color`, `component`, `drawable`, `texture`, `rarity`, `price`, `label`) VALUES
-- Male items for Suburban
('suburban', 'white_tshirt', 15, 'shirts', 'tshirt', 'white', 11, 0, 0, 'common', 100, 'White T-Shirt'),
('suburban', 'black_tshirt', 15, 'shirts', 'tshirt', 'black', 11, 0, 1, 'common', 100, 'Black T-Shirt'),
('suburban', 'jeans_blue', 10, 'pants', 'jeans', 'blue', 4, 0, 0, 'common', 150, 'Blue Jeans'),
('suburban', 'sneakers_white', 12, 'shoes', 'sneakers', 'white', 6, 1, 0, 'common', 100, 'White Sneakers'),
('suburban', 'cap_black', 8, 'hats', 'cap', 'black', 0, 2, 0, 'common', 100, 'Black Cap'),
-- Female items for Suburban
('suburban', 'white_tanktop', 15, 'shirts', 'tank_top', 'white', 11, 5, 0, 'common', 100, 'White Tank Top'),
('suburban', 'jeans_blue_f', 10, 'pants', 'jeans', 'blue', 4, 0, 0, 'common', 150, 'Blue Jeans'),
('suburban', 'sneakers_white_f', 12, 'shoes', 'sneakers', 'white', 6, 1, 0, 'common', 100, 'White Sneakers'),
-- Male items for Ponsonbys
('ponsonbys', 'suit_black', 5, 'shirts', 'dress_shirt', 'black', 11, 4, 0, 'uncommon', 300, 'Black Suit Jacket'),
('ponsonbys', 'suit_pants_black', 5, 'pants', 'slacks', 'black', 4, 4, 0, 'uncommon', 250, 'Black Suit Pants'),
('ponsonbys', 'dress_shoes_black', 8, 'shoes', 'dress_shoes', 'black', 6, 10, 0, 'uncommon', 250, 'Black Dress Shoes'),
-- Female items for Ponsonbys
('ponsonbys', 'suit_jacket_f', 5, 'shirts', 'dress_shirt', 'black', 11, 29, 0, 'uncommon', 300, 'Female Suit Jacket'),
('ponsonbys', 'suit_pants_f', 5, 'pants', 'slacks', 'black', 4, 37, 0, 'uncommon', 250, 'Female Suit Pants'),
('ponsonbys', 'heels_black', 8, 'shoes', 'heels', 'black', 6, 3, 0, 'common', 200, 'Black Heels'),
-- Accessories for all stores
('accessories', 'necklace_pearl', 3, 'accessories', 'necklace', 'white', 7, 9, 0, 'rare', 500, 'Pearl Necklace'),
('accessories', 'watch_classic', 6, 'accessories', 'watch', 'black', 6, 0, 0, 'uncommon', 400, 'Classic Watch'),
('accessories', 'sunglasses_black', 8, 'glasses', 'sunglasses', 'black', 1, 4, 0, 'common', 150, 'Black Sunglasses');

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_store_inventory_store ON store_inventory (store);
CREATE INDEX IF NOT EXISTS idx_store_inventory_category ON store_inventory (category);
CREATE INDEX IF NOT EXISTS idx_store_inventory_subcategory ON store_inventory (subcategory);
CREATE INDEX IF NOT EXISTS idx_store_inventory_color ON store_inventory (color);
CREATE INDEX IF NOT EXISTS idx_store_inventory_rarity ON store_inventory (rarity); 