-- Cikoko v207: permintaan perbaikan dokumen dan tautan notifikasi; TIDAK menghapus data.
-- Back up database lebih dulu. Pilih database dari ahli-waris/config.php.
CREATE TABLE IF NOT EXISTS mobile_waris_corrections (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 application_id BIGINT UNSIGNED NOT NULL,
 requirement_code VARCHAR(40) NOT NULL,
 reason VARCHAR(1000) NOT NULL,
 requested_by VARCHAR(100) NOT NULL,
 requested_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 resolved_at DATETIME NULL,
 UNIQUE KEY uq_application_code(application_id,requirement_code),
 INDEX idx_pending(application_id,resolved_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS mobile_event_links (
 event_id BIGINT UNSIGNED NOT NULL PRIMARY KEY,
 object_type VARCHAR(20) NOT NULL,
 object_id BIGINT UNSIGNED NOT NULL,
 INDEX idx_object(object_type,object_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
