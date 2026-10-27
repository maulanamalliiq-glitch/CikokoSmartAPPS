-- Cikoko SmartApp v2513 LPJ RT/RW/LMK A/B. Run after full backup, once.
-- Does not ALTER existing civic_documents, civic_approvals, civic_audit or civic_officers.
-- Important: replace schema only if hosting uses a different database than datd1747_smartapp.
CREATE TABLE IF NOT EXISTS datd1747_smartapp.cikoko_lpj_docs (
 id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
 kind VARCHAR(20) NOT NULL,
 period CHAR(7) NOT NULL,
 rt CHAR(3) NOT NULL DEFAULT '',
 rw CHAR(3) NOT NULL DEFAULT '',
 owner_id VARCHAR(80) NOT NULL,
 owner_name VARCHAR(160) NOT NULL,
 status VARCHAR(30) NOT NULL,
 revision INT UNSIGNED NOT NULL DEFAULT 1,
 payload_json LONGTEXT NOT NULL,
 payload_hash CHAR(64) NOT NULL,
 submitted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 finalized_at DATETIME NULL,
 UNIQUE KEY uniq_period_owner(kind,period,rt,rw,owner_id),
 INDEX idx_lpj_region(kind,rw,rt,status),
 INDEX idx_lpj_owner(owner_id,id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS datd1747_smartapp.cikoko_lpj_approvals (
 id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
 document_id BIGINT UNSIGNED NOT NULL,
 revision INT UNSIGNED NOT NULL,
 duty VARCHAR(32) NOT NULL,
 officer_user_id VARCHAR(80) NOT NULL,
 officer_name VARCHAR(160) NOT NULL,
 action VARCHAR(16) NOT NULL,
 notes VARCHAR(500) NOT NULL DEFAULT '',
 payload_hash CHAR(64) NOT NULL,
 recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 UNIQUE KEY uniq_lpj_step(document_id,revision,duty),
 INDEX idx_lpj_approval_document(document_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS datd1747_smartapp.cikoko_lpj_pins (
 user_id VARCHAR(80) NOT NULL PRIMARY KEY,
 pin_hash VARCHAR(255) NOT NULL,
 failed_attempts INT UNSIGNED NOT NULL DEFAULT 0,
 locked_until DATETIME NULL,
 updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS datd1747_smartapp.cikoko_lpj_audit (
 id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
 document_id BIGINT UNSIGNED NOT NULL,
 revision INT UNSIGNED NOT NULL,
 actor_id VARCHAR(80) NOT NULL,
 action VARCHAR(24) NOT NULL,
 status_after VARCHAR(30) NOT NULL,
 notes VARCHAR(500) NOT NULL DEFAULT '',
 payload_hash CHAR(64) NOT NULL,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 INDEX idx_lpj_audit_document(document_id,revision,id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Verification: only read after import.
SELECT TABLE_NAME, TABLE_ROWS
FROM information_schema.TABLES
WHERE TABLE_SCHEMA='datd1747_smartapp'
  AND TABLE_NAME IN ('cikoko_lpj_docs','cikoko_lpj_approvals','cikoko_lpj_pins','cikoko_lpj_audit')
ORDER BY TABLE_NAME;
