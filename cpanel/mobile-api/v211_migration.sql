-- Cikoko v211: migrasi tambahan aman (tidak menghapus data).
-- Backup database dahulu. CREATE TABLE IF NOT EXISTS dapat dijalankan berulang.
CREATE TABLE IF NOT EXISTS aw_archive_details (
 archive_id BIGINT UNSIGNED PRIMARY KEY,
 details_json LONGTEXT NULL,
 files_json LONGTEXT NULL,
 updated_by VARCHAR(80) NOT NULL,
 updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS mobile_news_comments (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 news_id VARCHAR(80) NOT NULL,
 user_id VARCHAR(80) NOT NULL,
 display_name VARCHAR(160) NOT NULL,
 parent_id BIGINT UNSIGNED NULL,
 body TEXT NOT NULL,
 hidden TINYINT(1) NOT NULL DEFAULT 0,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 INDEX idx_news(news_id,id),
 INDEX idx_user(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS mobile_ppsu_reports (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 user_id VARCHAR(80) NOT NULL,
 name VARCHAR(180) NOT NULL,
 team VARCHAR(30) NOT NULL,
 work_date DATE NOT NULL,
 activity TEXT NOT NULL,
 photos_json LONGTEXT NOT NULL,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 INDEX idx_user(user_id),
 INDEX idx_date(work_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
