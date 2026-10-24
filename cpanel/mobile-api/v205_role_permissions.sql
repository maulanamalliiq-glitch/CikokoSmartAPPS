-- Jalankan hanya setelah backup MySQL. Kompatibel dengan tabel yang dibuat otomatis pada API v205.
CREATE TABLE IF NOT EXISTS mobile_role_permissions (
  role VARCHAR(50) NOT NULL,
  capability VARCHAR(70) NOT NULL,
  allowed TINYINT(1) NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY(role, capability)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS aw_archives (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  archive_year SMALLINT UNSIGNED NOT NULL,
  reference_no VARCHAR(100) NOT NULL,
  applicant_name VARCHAR(200) NOT NULL,
  deceased_name VARCHAR(200) NOT NULL,
  notes TEXT,
  attachment VARCHAR(120) NULL,
  created_by VARCHAR(100) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_year(archive_year)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
