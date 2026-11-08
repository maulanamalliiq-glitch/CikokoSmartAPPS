-- Cikoko SmartAPP backend 2544: additive schema for chat + shared release.
-- RUN ONLY AFTER BACKING UP THE CURRENT DATABASE IN PHPMYADMIN.
-- No DELETE, DROP, TRUNCATE or UPDATE of resident messages.
-- CREATE TABLE IF NOT EXISTS DOES NOT repair existing inconsistent tables.
CREATE TABLE IF NOT EXISTS mobile_chat (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  user_id VARCHAR(80) NOT NULL,
  name VARCHAR(160) NOT NULL,
  sender VARCHAR(16) NOT NULL,
  message TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_thread(user_id,id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS mobile_chat_receipts (
  user_id VARCHAR(80) NOT NULL PRIMARY KEY,
  admin_delivered_id BIGINT UNSIGNED NOT NULL DEFAULT 0,
  admin_read_id BIGINT UNSIGNED NOT NULL DEFAULT 0,
  warga_delivered_id BIGINT UNSIGNED NOT NULL DEFAULT 0,
  warga_read_id BIGINT UNSIGNED NOT NULL DEFAULT 0,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS mobile_auth_limits (
  bucket CHAR(64) NOT NULL PRIMARY KEY,
  attempts INT NOT NULL DEFAULT 0,
  reset_at BIGINT NOT NULL,
  INDEX idx_reset(reset_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS mobile_account_requests (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  user_id VARCHAR(80) NOT NULL,
  kind VARCHAR(20) NOT NULL,
  contact VARCHAR(160) NOT NULL,
  notes VARCHAR(1000) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'pending',
  actor_id VARCHAR(80) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  closed_at DATETIME NULL,
  INDEX idx_status(status,id),
  INDEX idx_owner(user_id,id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS mobile_submission_areas (
  source VARCHAR(20) NOT NULL,
  report_id BIGINT UNSIGNED NOT NULL,
  rt VARCHAR(3) NOT NULL,
  rw VARCHAR(3) NOT NULL,
  captured_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(source,report_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS mobile_event_deletes (
  user_id VARCHAR(80) NOT NULL,
  event_id BIGINT UNSIGNED NOT NULL,
  deleted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(user_id,event_id),
  INDEX idx_deleted_event(event_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS mobile_role_permissions (
  role VARCHAR(50) NOT NULL,
  capability VARCHAR(70) NOT NULL,
  allowed TINYINT(1) NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY(role,capability)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Read-only checks. Expect id AUTO_INCREMENT and correct user_id/sender:
SHOW COLUMNS FROM mobile_chat;
SHOW INDEX FROM mobile_chat;
SELECT COUNT(*) AS total_messages,MAX(id) AS latest_message_id,MAX(created_at) AS last_message_at FROM mobile_chat;
