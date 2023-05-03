CREATE SCHEMA IF NOT EXISTS `monitor_hist`;

USE `monitor_hist`;


CREATE TABLE IF NOT EXISTS `monitor_history` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `tick` timestamp NOT NULL DEFAULT current_timestamp(),
  `hostname` varchar(128) DEFAULT NULL,
  `mariadbd_cpu_pct` decimal(5,2) DEFAULT NULL,
  `redo_log_occupancy` decimal(5,2) DEFAULT NULL,
  `threads_running` int(11) DEFAULT NULL,
  `handler_read_rnd_next` bigint(20) DEFAULT NULL,
  `com_select` bigint(20) DEFAULT NULL,
  `com_dml` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


