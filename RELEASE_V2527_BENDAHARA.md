# Cikoko SmartApp 2.5.27 (2527) — Bendahara & Kelola Akun Petugas

Status: **release candidate / staging**. Tidak otomatis diterapkan ke cPanel atau Google Play.

## Perubahan
- Role terpisah: Ketua RT, Ketua RW, Bendahara RT, Bendahara RW, LMK dan petugas lainnya.
- Menu **Kelola Akun Petugas**, hanya untuk **Admin Utama** (role `admin`), bukan `admin_kelurahan`.
- API `accounts_list` (GET) dan `accounts_create` (POST); wajib bearer token Admin Utama.
- Akun baru disimpan di `portal_users.json` agar dipakai bersama oleh website dan Android.
- Akun Ketua/Bendahara RT/RW dibuat sekaligus dengan penugasan resmi `civic_officers`; penugasan ganda wilayah ditolak.
- Peran baru Bendahara memiliki akses LPJ sesuai jabatannya, tidak mendapat hak kelola admin.
- Kompatibilitas akun lama: `role=rt`+`duty=bendahara_rt`, atau `role=rw`+`duty=bendahara_rw` masih dikenali pada modul LPJ.

## Pra-deploy di cPanel
1. **Backup terlebih dahulu**: database `datd1747_smartapp`, `public_html/data/portal_users.json`, seluruh `public_html/mobile-api/`, dan `public_html/roles-lib.php`.
2. **Jangan langsung overwrite `index.php` produksi** dengan salinan GitHub: versi produksi mungkin sudah memiliki patch yang lebih baru. Gabungkan hanya route `accounts_list`/`accounts_create` tepat setelah `$u=mobile_auth();$db=mobile_db();...`. Jangan membuat route publik sebelum autentikasi.
3. Upload `cpanel/mobile-api/admin_accounts.php` ke `public_html/mobile-api/admin_accounts.php`.
4. Gabungkan penambahan `bendahara_rt` dan `bendahara_rw` dari `cpanel/mobile-api/permissions.php` serta `cpanel/roles-lib.php` ke file yang sama di server.
5. Gabungkan pemeriksaan peran Bendahara dari `cpanel/mobile-api/civic_lpj_v2513.php` ke server, **setelah** backup; jangan hilangkan patch perbaikan syntax PHP yang sudah dipasang pada server live.
6. Konfirmasi `civic_officers` memiliki `user_id`, `duty`, `rt`, `rw`, `display_name`, dan `active`, serta `duty` menerima `rt`, `rw`, `bendahara_rt`, `bendahara_rw`. Pengaturan akun tidak melakukan migrasi tabel otomatis. Jika tabel tidak cocok, sesuaikan secara terencana setelah backup; jangan coba dengan menghapus tabel.
7. Pastikan file `portal_users.json` dapat ditulis oleh proses PHP dan ada pembatasan akses publik ke folder data.

## Pemeriksaan SQL hanya-baca
```sql
SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_KEY
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA='datd1747_smartapp'
 AND TABLE_NAME='civic_officers'
ORDER BY ORDINAL_POSITION;

SELECT duty, rt, rw, active, COUNT(*) AS jumlah
FROM datd1747_smartapp.civic_officers
GROUP BY duty, rt, rw, active
ORDER BY rw, rt, duty;
```

## Uji coba Admin Utama (internal)
1. Gunakan akun Admin Utama, buka **Menu Cikoko → Kelola Akun Petugas → Tambah Akun**.
2. Buat akun **Bendahara RT** dengan wilayah RT/RW percobaan yang **belum memiliki petugas aktif**. Password awal minimal 8 karakter; jangan kirim kredensial melalui kanal publik.
3. Masuk sebagai Bendahara RT, buka **Laporan LPJ RT**. Pastikan hanya LPJ wilayahnya yang tampil; buat dokumen percobaan di lingkungan staging, daftarkan PIN persetujuan.
4. Uji Ketua RT akun berbeda untuk persetujuan lanjutan. Lakukan urutan yang sama untuk Bendahara RW/Ketua RW.
5. Uji dengan akun warga / ASN bahwa GET `accounts_list` dan POST `accounts_create` memberikan HTTP 403; pastikan role bukan `admin` tidak dapat membuat akun lain.
6. Pastikan pendaftaran warga biasa (`register`) tetap menghasilkan `role=warga`.
7. Pastikan menu Bendahara tidak memuat Surat Wilayah, pengaturan hak admin, atau daftar akun lainnya.
8. **Jangan uji memakai LPJ keuangan riil** sebelum QA dan persetujuan berwenang.

## Android AAB
- Version name: `2.5.27`; version code: `2527`.
- Package identity tetap `com.KelurahanCikoko.malik`.
- Workflow: `.github/workflows/bendahara-v2527-playstore.yml`.
- Signed AAB dan APK akan disimpan ke **draft GitHub Release** saat workflow berhasil, bukan otomatis dikirim ke Google Play.
- Cek tanda tangan upload certificate, lakukan Play Internal Testing sebelum produksi.
- Wajib memasang backend cPanel yang sesuai sebelum menguji fungsi Kelola Akun.

## Rollback
- Pulihkan berkas PHP hasil backup, jangan menghapus/menulis ulang `portal_users.json` tanpa merekonsiliasi akun baru.
- Pertahankan `civic_officers`, jejak LPJ serta audit persetujuan. Jangan menghapus data dengan `DROP` atau `DELETE` massal.
- Jika hanya APK/AAB belum dipublikasikan, cukup hentikan promosi ke track produksi.
