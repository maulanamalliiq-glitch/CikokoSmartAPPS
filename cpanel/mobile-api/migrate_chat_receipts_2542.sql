-- Cikoko SmartAPP 2.5.42 chat receipts. Additive migration, no message deletion.
-- Apply after a verified MySQL backup when the PHP user lacks CREATE TABLE privilege.
CREATE TABLE IF NOT EXISTS mobile_chat_receipts (
  user_id VARCHAR(80) NOT NULL PRIMARY KEY,
  admin_delivered_id BIGINT UNSIGNED NOT NULL DEFAULT 0,
  admin_read_id BIGINT UNSIGNED NOT NULL DEFAULT 0,
  warga_delivered_id BIGINT UNSIGNED NOT NULL DEFAULT 0,
  warga_read_id BIGINT UNSIGNED NOT NULL DEFAULT 0,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
