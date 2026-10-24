-- Cikoko v206: aman dijalankan berulang di database yang sudah ada.
-- Jalankan di database Ahli Waris saat traffic sepi; backup terlebih dahulu.
SET @db_name = DATABASE();
SELECT COUNT(*) INTO @has_marriage FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db_name AND TABLE_NAME='aw_applications' AND COLUMN_NAME='deceased_marriage_date';
SET @sql = IF(@has_marriage=0,'ALTER TABLE aw_applications ADD COLUMN deceased_marriage_date DATE NULL AFTER deceased_birthdate','SELECT ''deceased_marriage_date sudah ada''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SELECT COUNT(*) INTO @has_children FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db_name AND TABLE_NAME='aw_applications' AND COLUMN_NAME='children_json';
SET @sql = IF(@has_children=0,'ALTER TABLE aw_applications ADD COLUMN children_json LONGTEXT NULL AFTER heirs','SELECT ''children_json sudah ada''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SHOW COLUMNS FROM aw_applications LIKE 'deceased_marriage_date';
SHOW COLUMNS FROM aw_applications LIKE 'children_json';
