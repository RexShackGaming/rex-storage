CREATE TABLE `rex_storage` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) DEFAULT NULL,
    `properties` text NOT NULL,
    `propid` varchar(100) NOT NULL,
    `proptype` varchar(50) DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_propid` (`propid`),
    KEY `idx_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `rex_storage_guests` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `propid` varchar(255) NOT NULL,
  `owner_citizenid` varchar(50) NOT NULL,
  `guest_citizenid` varchar(50) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_guest_storage` (`propid`, `guest_citizenid`),
  KEY `propid` (`propid`),
  KEY `guest_citizenid` (`guest_citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
