# Perbaikan Chat Produksi Cikoko SmartAPP — Backend 2544

**Status penting:** pemeriksaan publik pada 8 November 2026 menunjukkan
`https://datawebs.my.id/mobile-api/index.php?action=health` masih merespons
`version: 205.1`. File di GitHub **tidak** otomatis memperbarui hosting.
Unduh paket ini dan jalankan pemasangan dengan pengelola cPanel resmi.

## A. Ruang lingkup paket
- Semua modul PHP di folder `mobile-api/` (API lengkap untuk kompatibilitas antara modul chat dan fitur aplikasi).
- `mobile-api/migrate_chat_2544.sql`: migrasi tambahan MySQL dan query audit; tidak menghapus pesan.
- `MULAI_DI_SINI_CHAT_2544.md`: petunjuk ini.
- `SHA256SUMS.txt`: integritas berkas PHP dan SQL.
- **Tidak berisi:** `config.php`, kredensial, database warga, file foto, folder private, atau file lama pada hosting.

JANGAN menimpa direktori `private/`, `data/`, `assets/`, file `.htaccess` yang aktif, atau kredensial Firebase. Jangan mengunggah seluruh ZIP sebagai satu file ke root website: ekstrak dan tempatkan isi folder `mobile-api/` ke direktori `mobile-api/` milik domain API sebenarnya. Folder yang benar harus sama dengan tempat `index.php?action=health` dijalankan.

## B. Sebelum mengubah hosting (wajib)
1. Cadangkan **seluruh database MySQL**, file website, `public_html/mobile-api/`, konfigurasi dan lampiran privat. Simpan backup di luar direktori publik dan pastikan bisa dipulihkan.
2. Catat direktori document root domain **datawebs.my.id** pada Domains di cPanel. Jangan berasumsi selalu `public_html`.
3. Cocokkan konfigurasi database yang digunakan **website aktif** dan file `ahli-waris/config.php`, tanpa membagikan password atau tangkapan layar kredensial.
4. Bandingkan file API yang aktif di hosting dengan file ZIP. Jika ada kustomisasi yang belum ada di GitHub, gabungkan perubahan tersebut secara selektif.
5. Uji pemasangan pada staging dengan salinan database yang telah menghilangkan data pribadi. Gunakan PHP 8.2+ dan ekstensi `pdo_mysql`, `mbstring`, `fileinfo`. Jika server tidak mendukung, hentikan sebelum menimpa produksi.

## C. Migrasi database
1. Buka phpMyAdmin pada database yang **benar-benar terhubung ke domain API**, bukan database pengembangan.
2. Impor `mobile-api/migrate_chat_2544.sql` setelah backup. Semua `CREATE TABLE` menggunakan `IF NOT EXISTS`, jadi tidak menimpa pesan yang sudah tersimpan.
3. Periksa hasil query `SHOW COLUMNS FROM mobile_chat`: `id` harus bertipe integer auto-increment, `user_id` dan `sender` tersedia, dan `message` serta `created_at` tersedia.
4. Jika tabel lama sudah ada tetapi kolom `id` bukan auto-increment, indeks atau tipe tidak sesuai, **jangan menjalankan ALTER otomatis**; harus dilakukan migrasi spesifik berdasarkan backup dan struktur tabel saat ini.
5. Jika MySQL user PHP tidak memiliki izin `CREATE TABLE` yang dibutuhkan modul lain, siapkan tabel terkait melalui migration yang sesuai atau perbaiki izin akun database dengan admin server.

## D. Pemasangan backend
1. Siapkan folder API pada staging (jangan menghapus `private`).
2. Unggah semua file PHP dari folder `mobile-api/` pada ZIP ke direktori `mobile-api/` staging, dengan struktur nama yang sama.
3. Periksa respons `?action=health`: harus HTTP 200, `version=2544.rc1`, `ready=true` dan `checks.api_chat_storage=true`. PENTING: health memverifikasi file saja, bukan kinerja database.
4. Login akun uji warga A, warga B, dan Admin. Pastikan masing-masing benar-benar akun berbeda dengan role yang sesuai.
5. Kirim pesan teks unik warga A. Catat ID yang diberikan API dan pastikan baris tersebut ada di `mobile_chat`, dengan `user_id` milik warga A. Jika API tidak memberikan ID atau `stored=true`, backend yang terpasang bukan versi ini.
6. Di **Pesan Masuk** Admin, buka percakapan A. Pesan harus terlihat. Balas dari Admin; `stored=true` dan ID harus ada. Pada HP warga A, buka chat dan pastikan balasan muncul.
7. Pastikan HP warga B **tidak** melihat pesan A. Jangan menafsirkan percakapan akun lain sebagai riwayat A.
8. Uji notifikasi foreground/background secara terpisah dari penyimpanan chat. Warna dua titik hijau hanya setelah penerima membuka thread; dua titik abu-abu setelah aplikasi penerima memuat daftar inbox.
9. Jika semua langkah staging berhasil, ulangi pemasangan ke produksi dalam jadwal pemeliharaan dengan backup terverifikasi.
10. Buka `https://datawebs.my.id/mobile-api/index.php?action=health`, pastikan `2544.rc1`. Lakukan uji dua HP di produksi menggunakan pesan uji tanpa data pribadi. Lalu periksa chat real-time/polling selama beberapa pembaruan.
11. Bila gagal, hentikan distribusi APK dan pulihkan file PHP yang dicadangkan. Tabel tambahan dapat tetap ada karena bersifat penambahan, tetapi keputusan rollback database harus mengikuti backup serta hasil pemeriksaan DBA.

## E. Diagnosis jika pesan belum muncul
- Jika health masih `205.1`: salah document root atau patch **belum terpasang**.
- Jika health sudah `2544.rc1` tetapi send gagal: cek error log PHP, izin koneksi MySQL, dan kolom `mobile_chat`; jangan mengirim kredensial.
- Jika send mengembalikan `stored=true` tetapi Admin tidak melihatnya: periksa `thread_user_id` dari hasil send dan `user_id` pada daftar Admin. Gunakan `chat_diagnostics` **hanya dengan akun yang berhak**, tanpa memberikan bearer token ke pihak lain.
- Jika balasan Admin tercatat tetapi tidak terlihat pada warga: pastikan warga login sebagai ID yang sama, lalu periksa API `chat`, bukan hanya notifikasi.
- Jika balasan muncul tetapi dua titik tetap abu-abu: periksa apakah kedua HP menjalankan app terbaru dan backend dapat menulis `mobile_chat_receipts`.

## Batasan dan privasi
CI menguji sintaks, MySQL terisolasi, respons penulisan/read-back, dan pemisahan akun. CI **tidak dapat memverifikasi database atau 2 perangkat nyata milik warga** tanpa akses server dan sesi pengujian. Kode di GitHub tidak sama dengan deployment cPanel. Jangan bagikan token login, kata sandi, NIK, atau isi chat pribadi ketika meminta bantuan.
