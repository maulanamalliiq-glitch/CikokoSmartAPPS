-- Cikoko: status baca notifikasi. Aman dijalankan ulang dan tidak menghapus data.
CREATE TABLE IF NOT EXISTS mobile_event_reads (
 user_id VARCHAR(80) NOT NULL,event_id BIGINT UNSIGNED NOT NULL,
 read_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY (user_id,event_id),
 INDEX idx_event(event_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
