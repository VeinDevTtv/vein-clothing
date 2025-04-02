-- Create database tables for the Clothing System

-- Outfits table to store saved player outfits
CREATE TABLE IF NOT EXISTS `player_outfits` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `outfitname` varchar(50) NOT NULL,
  `outfit` longtext NOT NULL,
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
  KEY `citizenid` (`citizenid`)
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
  `citizenid` varchar(50) NOT NULL,
  `slot` varchar(50) NOT NULL,
  `item` varchar(100) NOT NULL,
  `condition` float NOT NULL DEFAULT 100.0,
  `last_worn` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizen_item` (`citizenid`, `slot`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Example data for clothing_stores
INSERT INTO `clothing_stores` (`store`, `item`, `stock`) VALUES
('suburban', 'tshirt_white', 15),
('suburban', 'tshirt_black', 15),
('suburban', 'jeans_blue', 10),
('suburban', 'sneakers_white', 12),
('suburban', 'cap_black', 8),
('ponsonbys', 'suit_black', 5),
('ponsonbys', 'dress_red', 5),
('ponsonbys', 'luxury_shoes', 8),
('ponsonbys', 'designer_watch', 3),
('ponsonbys', 'luxury_sunglasses', 6); 