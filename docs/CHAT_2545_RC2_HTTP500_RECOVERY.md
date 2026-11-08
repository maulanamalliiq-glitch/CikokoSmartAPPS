# PEMULIHAN DARURAT CHAT CIKOKO — SERVER HTTP 500 (API 2545.rc2)

Tanggal pemeriksaan: 8 November 2026. Uji publik (tanpa login) ke domain `datawebs.my.id` pada endpoint `health`, `chat`, `chat_threads`, dan `support_admin_thread` masing-masing mengembalikan HTTP **500**, Content-Type **text/html**, respons **kosong 0 byte**. Ini adalah kegagalan backend/hosting, bukan masalah riwayat chat di HP.

**Kemungkinan penting:** paket backend 2545 sebelumnya menggunakan ekspresi PHP `match` yang tidak dapat diparse di PHP 7.4. Jika versi PHP domain masih 7.x, `index.php` akan gagal **sebelum** menjalankan blok `health`. Hotfix mengubah ekspresi tersebut ke sintaks yang juga kompatibel dengan PHP 7.4. Namun, HTTP 500 dapat memiliki penyebab lain: baca `error_log` untuk memastikan sebelum menyimpulkan.

## Pilihan 1 — Pertama, periksa konfigurasi PHP
1. Login cPanel resmi, pilih **MultiPHP Manager** untuk domain `datawebs.my.id`. Gunakan versi PHP yang didukung hosting, idealnya PHP **8.2 atau 8.3** untuk seluruh backend; PHP 7.4 sudah EOL dan tidak dianjurkan jangka panjang. Jika Anda mengubah PHP, pastikan aplikasi website lain yang memakai domain ini masih berjalan.
2. Buka **Metrics > Errors** atau **File Manager > error_log** pada document root domain. Catat waktu error dan nama file/baris, tanpa mengirim password atau isi data warga.
3. Cari `Parse error: syntax error ... unexpected 'match'`, `unexpected token`, `Call to undefined function`, `Failed opening required`, atau `Permission denied`. Gejala persis dari live API hanya menunjukkan HTTP 500 kosong; versi PHP penyebabnya masih dugaan sampai log dilihat.

## Pilihan 2 — Pulihkan index.php tanpa mengubah database
1. **Backup terlebih dahulu.** Simpan salinan `mobile-api/index.php` saat ini dengan nama `index.php.bak-2545-before-hotfix` di tempat yang tidak dapat diakses publik, juga backup database MySQL.
2. Temukan **document root yang benar** dari `datawebs.my.id` lewat Domains. Jangan otomatis memilih `public_html`; bisa memakai subfolder domain sendiri.
3. Ekstrak `CIKOKO_CHAT_2545_RC2_HOTFIX_INDEX.zip` secara lokal. Isi `HOTFIX/mobile-api/index.php` adalah file pengganti. **Salin hanya file `index.php`** ke folder `mobile-api` pada document root domain API. Jangan menimpa file konfigurasi, `private`, maupun data chat.
4. Buka `https://datawebs.my.id/mobile-api/index.php?action=health`. **Hasil yang diharapkan:** JSON, HTTP 200, `version: "2545.rc2"`, `ready: true`. Ini memverifikasi parser dan berkas API, bukan fungsi database.
5. Jika health berubah ke **JSON HTTP 503**, berarti parser berjalan tetapi ada berkas dependensi yang belum lengkap: cari `checks` bernilai false. Cocokkan dengan paket lengkap `CIKOKO_BACKEND_CHAT_2545_RC2_FULL.zip` atau paket backend 2545 sebelumnya. Jangan hapus konfigurasi lama.
6. Jika health masih **HTTP 500 kosong**, cek log cPanel dan pilihan versi PHP. File log diperlukan untuk mengidentifikasi penyebab sebenarnya; jangan mengulang unggahan tanpa mengetahui error.
7. Jika health 200, uji login warga di HP lalu `Hubungi Admin`, kirim satu pesan aman; dari HP petugas (Admin Utama, Admin Kelurahan atau ASN) buka `Pesan Masuk`, balas, periksa riwayat. Pastikan tidak ada data warga lain yang tampil.
8. Bila ada masalah, rollback ke file cadangan setelah menemukan penyebab. Jangan menghapus tabel `mobile_chat` atau riwayat warga.

## Paket
- `CIKOKO_CHAT_2545_RC2_HOTFIX_INDEX.zip` — paling kecil, hanya penggantian `index.php`, panduan, checksum.
- `CIKOKO_BACKEND_CHAT_2545_RC2_FULL.zip` — seluruh file PHP API standar yang diperlukan, migrasi SQL tambahan, panduan, checksum. Pakai hanya ketika instalasi backend sebelumnya tidak lengkap atau sebagai overlay terkontrol di staging.
- Tidak ada kredensial, token, foto, arsip warga, data privat maupun konfigurasi hosting di dalam ZIP.

## Kapan dinyatakan normal?
1. Pemeriksaan health memberi HTTP 200 dan `2545.rc2`.
2. Chat warga dan petugas dapat menerima respons JSON, bukan HTTP 500.
3. Pesan benar-benar tersimpan di tabel `mobile_chat`, muncul di dua HP dan tetap tersedia setelah login ulang.
4. Status online/offline serta satu pesan bot saat semua petugas offline berjalan sesuai skenario.

Rilis di GitHub **tidak** memperbarui cPanel secara otomatis; pemasangan harus dilakukan oleh pengelola hosting yang memiliki izin.
