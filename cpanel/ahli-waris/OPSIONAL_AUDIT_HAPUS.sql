-- Cikoko v208 — tabel catatan audit minimal, tanpa nama pemohon, NIK, atau isi surat.
-- Biasanya dibuat otomatis ketika admin melakukan Hapus Permanen.
-- Jika MySQL menolak CREATE TABLE dari kode PHP, impor melalui phpMyAdmin.
CREATE TABLE IF NOT EXISTS aw_deletion_audit (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  deleted_application_id BIGINT UNSIGNED NOT NULL,
  reference_sha256 CHAR(64) NOT NULL,
  deleted_by VARCHAR(100) NOT NULL,
  reason VARCHAR(300) NOT NULL,
  files_count INT UNSIGNED NOT NULL DEFAULT 0,
  deleted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
