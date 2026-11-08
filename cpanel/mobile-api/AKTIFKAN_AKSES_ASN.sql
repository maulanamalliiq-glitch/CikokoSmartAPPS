-- Aktifkan fitur yang diminta untuk seluruh akun ASN / PNS.
-- Jalankan pada database aplikasi yang aktif setelah mencadangkan database.
CREATE TABLE IF NOT EXISTS mobile_role_permissions (
 role VARCHAR(50) NOT NULL, capability VARCHAR(70) NOT NULL,
 allowed TINYINT(1) NOT NULL,
 updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 PRIMARY KEY(role,capability)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT INTO mobile_role_permissions(role,capability,allowed) VALUES
 ('asn','reports:view',1),('asn','reports:verify',1),
 ('asn','waris:view',1),('asn','waris:verify',1),('asn','monitoring:view',1)
ON DUPLICATE KEY UPDATE allowed=VALUES(allowed);

-- Riwayat pemeriksaan laporan, PPSU, FKDM, dan verifikasi administratif LPJ.
CREATE TABLE IF NOT EXISTS mobile_officer_reviews (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 source VARCHAR(16) NOT NULL, report_id BIGINT UNSIGNED NOT NULL,
 status VARCHAR(20) NOT NULL, notes TEXT NOT NULL,
 actor_id VARCHAR(80) NOT NULL, revision INT UNSIGNED NOT NULL DEFAULT 0,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 INDEX idx_report(source,report_id,id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
