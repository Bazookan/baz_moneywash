USE essentialmode;

CREATE TABLE IF NOT EXISTS `moneywash` (
  `id` text,
  `amount` bigint(20) DEFAULT NULL,
  `cooldown` bigint(20) DEFAULT NULL,
  `timestamp` bigint(20) DEFAULT NULL
)