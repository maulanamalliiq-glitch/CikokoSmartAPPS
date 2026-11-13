-- Jalankan sekali sesudah migrate_pjlp_leave.sql.
ALTER TABLE pjlp_officials
 ADD COLUMN public_token CHAR(48) NULL UNIQUE,
 ADD COLUMN photo_file VARCHAR(255) NULL,
 ADD COLUMN work_unit VARCHAR(160) NOT NULL DEFAULT 'Kelurahan Cikoko',
 ADD COLUMN is_public TINYINT(1) NOT NULL DEFAULT 1;
-- QR lama tetap tersimpan; admin harus menyimpan ulang profil untuk membuat QR unik.
