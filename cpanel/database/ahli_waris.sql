-- Modul Ahli Waris Cikoko v1.0; MySQL 5.7+/MariaDB 10.4+, utf8mb4
CREATE TABLE IF NOT EXISTS aw_applications (
 id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
 reference_no VARCHAR(40) NOT NULL UNIQUE,
 account_id VARCHAR(100) NOT NULL,
 applicant_name VARCHAR(200) NOT NULL,
 applicant_nik CHAR(16) NOT NULL,
 applicant_phone VARCHAR(30) NOT NULL,
 applicant_address TEXT NOT NULL,
 relationship VARCHAR(100) NOT NULL,
 deceased_name VARCHAR(200) NOT NULL,
 deceased_nik CHAR(16) NULL,
 deceased_kk VARCHAR(20) NULL,
 marital_status VARCHAR(30) NOT NULL,
 deceased_birthplace VARCHAR(160) NULL,
 deceased_birthdate DATE NULL,
 deceased_deathdate DATE NULL,
 deceased_marriage_date DATE NULL,
 heirs TEXT NOT NULL,
 children_json LONGTEXT NULL,
 status ENUM('masuk','proses','revisi','selesai','ditolak') NOT NULL DEFAULT 'masuk',
 staff_notes TEXT NULL,
 created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 INDEX idx_account (account_id), INDEX idx_status (status), INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS aw_attachments (
 id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
 application_id BIGINT UNSIGNED NOT NULL,
 requirement_code VARCHAR(40) NOT NULL,
 original_name VARCHAR(255) NOT NULL,
 storage_name VARCHAR(80) NOT NULL UNIQUE,
 mime_type VARCHAR(100) NOT NULL,
 size_bytes INT UNSIGNED NOT NULL,
 created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_aw_attachment_application FOREIGN KEY(application_id) REFERENCES aw_applications(id) ON DELETE CASCADE,
 INDEX idx_req (requirement_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS aw_history (
 id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
 application_id BIGINT UNSIGNED NOT NULL,
 previous_status VARCHAR(20) NULL,
 new_status VARCHAR(20) NOT NULL,
 actor_id VARCHAR(100) NOT NULL,
 notes TEXT NULL,
 created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_aw_history_application FOREIGN KEY(application_id) REFERENCES aw_applications(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
