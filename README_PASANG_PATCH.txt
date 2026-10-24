CIKOKO v207 - PATCH RIWAYAT/NOTIFIKASI + REVISI DOKUMEN AHLI WARIS

1. BACKUP WEBSITE DAN DATABASE MySQL sebelum mengubah file.
2. Ekstrak PATCH_CIKOKO_V207_CPANEL.zip pada document root domain datawebs.my.id (sejajar dengan admin.php). File /mobile-api dan /ahli-waris/admin.php akan tertimpa.
3. Di phpMyAdmin pilih database yang dipakai ahli-waris/config.php; impor mobile-api/migrate_waris_v207.sql jika user database tidak memiliki izin CREATE TABLE. Tabel dibuat otomatis bila ada izin.
4. Jangan menghapus tabel aw_applications, aw_history, aw_attachments, mobile_events, atau folder ahli-waris/private/uploads.
5. Flutter: source ditambahkan ke repository folder flutter/ (file baru lib/document_detail.dart) dan jalankan Flutter build. VersionCode 207, bukan APK v206 yang terpasang.
6. Dari akun warga, ketuk item Riwayat untuk melihat detail/progres; jika admin menandai dokumen kurang, hanya berkas tersebut yang dapat diunggah ulang.
7. Dari admin, buka Verifikasi Laporan lalu ketuk item Ahli Waris untuk meminta perbaikan. Dari admin website, gunakan tombol Minta Warga Melengkapi Dokumen.
8. Notifikasi baru terkait perubahan dokumen menunjuk ke detail. Notifikasi lama tanpa relasi menunjuk ke daftar Riwayat, karena sebelumnya tidak menyimpan ID objek.
9. Tidak menyertakan keystore, password, konfigurasi DB, maupun data pribadi dari website.
10. Upload ulang membutuhkan koneksi API yang sama dengan aplikasi, sehingga setelah patch terpasang endpoint mobile-api mesti aktif.

Build source tidak sama dengan APK siap diinstal. Jangan gunakan AAB lama untuk fitur v207; build versionCode 207 dan verifikasi terlebih dahulu.
