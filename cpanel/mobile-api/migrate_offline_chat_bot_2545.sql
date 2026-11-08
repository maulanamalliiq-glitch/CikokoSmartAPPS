-- Cikoko SmartAPP 2.5.45 — balasan otomatis ketika petugas offline.
-- Jalankan pada database produksi yang BENAR setelah backup melalui phpMyAdmin.
-- Migrasi bersifat penambahan; tidak mengubah atau menghapus chat lama.
CREATE TABLE IF NOT EXISTS mobile_chat_presence (
 session_hash CHAR(64) NOT NULL PRIMARY KEY,
 user_id VARCHAR(80) NOT NULL,
 user_role VARCHAR(40) NOT NULL,
 last_seen_at DATETIME NOT NULL,
 INDEX idx_last_seen(last_seen_at,user_role),
 INDEX idx_account(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS mobile_chat_bot_state (
 user_id VARCHAR(80) NOT NULL PRIMARY KEY,
 last_bot_message_id BIGINT UNSIGNED NOT NULL DEFAULT 0,
 updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Hanya query baca untuk verifikasi skema, tanpa menampilkan isi chat:
SHOW COLUMNS FROM mobile_chat_presence;
SHOW COLUMNS FROM mobile_chat_bot_state;
SELECT COUNT(*) AS staff_sessions FROM mobile_chat_presence;
