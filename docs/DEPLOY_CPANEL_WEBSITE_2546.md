# Cikoko SmartAPP 2.5.46 — Website dan cPanel: Instalasi Aman

Dokumen ini hanya untuk pengelola hosting yang memiliki izin akses.

## Masalah yang ditangani
- Screenshot desktop menunjukkan HTTP **403 Forbidden**: "Server unable to read htaccess file, denying access to be safe". File `.htaccess` dari salinan ZIP sebelumnya bermode **0600**. Apache umumnya memerlukan izin baca; root dan direktori induk juga memerlukan izin traverse.
- Halaman beranda pada arsip sebelumnya hanya mengalihkan ke `informasi.php`. Versi 2546 memberikan beranda baru responsif, bernuansa biru, menu bawah ponsel, 5 foto bergeser otomatis dari pengaturan aplikasi, informasi dan layanan dari CMS yang sudah ada.
- Laporan foto di aplikasi sebelumnya menampilkan pesan error umum jika server membalas HTML 403/500 atau terjadi kesalahan saat menyimpan. API baru memverifikasi ID MySQL melalui transaksi dan memastikan hanya foto baru yang gagal yang dibersihkan.
- Widget chat Flutter versi 2546 menoleransi array kosong `receipt_updates: []` dari PHP lama agar riwayat tidak menghilang.

## Isi ZIP kode-only
- `public_html/index.php` — halaman utama pengganti redirect sementara.
- `public_html/assets/cikoko-smartapp-home-2546.css` dan `.js` — desain beranda dan pergantian foto otomatis.
- `public_html/mobile-api/index.php` dan `report_integrity_2546.php` — API laporan yang terverifikasi (`2546.rc1`).
- `PANDUAN/CEK_DAN_PERBAIKI_PERMISSION_CPANEL.sh` — periksa hak akses; default hanya membaca, `--apply` untuk perbaikan eksplisit setelah backup.
- `PANDUAN/DB_READ_ONLY_2546.sql` — SQL pemeriksaan struktur database, tanpa perubahan.
- **Tidak termasuk** database, password, konfigurasi, `private/`, foto warga, dokumen Ahli Waris, atau data akun.

## Langkah pasang dan rollback
1. **Backup seluruh root website dan database**, folder `data/`, `private/`, `mobile-api/private/`, `ahli-waris/private/`, serta file konfigurasi. Simpan backup di luar akses web; uji dapat dibuka/dipulihkan.
2. Di cPanel > Domains, periksa document root tepat untuk domain `datawebs.my.id`. Jangan menebak lokasi `public_html`.
3. Periksa `public_html/.htaccess` dan semua parent folder. **Jangan ganti isi/handler PHP** sebelum memastikan. File `.htaccess` pada root, `mobile-api`, dan `ahli-waris` perlu bisa dibaca server (umumnya mode `0644`); direktori publik `0755`. File rahasia tetap `0600` atau mode ketat sesuai PHP handler; jangan `0777`.
4. Jika memiliki Terminal cPanel, jalankan `bash CEK_DAN_PERBAIKI_PERMISSION_CPANEL.sh /home/USER/public_html --check` dahulu. Setelah melihat path benar dan backup siap, gunakan `--apply` bila perlu. Skrip tidak menyentuh berkas privat. Jika 403 tetap muncul, mintalah penyedia hosting memeriksa ownership dan traverse direktori induk.
5. Uji kode di folder staging yang terhubung ke **salinan teranonimkan** database. Jangan menimpa folder aktif dari ZIP lengkap yang menyimpan data privat.
6. Gabungkan overlay kode `public_html/` ke document root yang benar (bukan membuat `public_html/public_html`). **Jangan timpa** `.htaccess`, `config.php`, `ahli-waris/config.php`, `data/`, `private/` atau lampiran warga.
7. Jalankan hardcheck respons: `/` = HTTP 200 HTML dan menampilkan Cikoko SmartAPP; `/assets/cikoko-smartapp-home-2546.css` = HTTP 200; `/mobile-api/index.php?action=health` = HTTP 200 JSON dengan `version:2546.rc1` dan `ready:true` jika semua dependensi terpasang.
8. Jalankan **SQL read-only** untuk memeriksa kolom/index `mobile_reports`, `mobile_chat` dan tabel receipt; query ini tidak mengubah data. Jika primary key `mobile_reports.id` bukan AUTO_INCREMENT, **jangan menambal otomatis** tanpa memeriksa struktur database asli dan backup.
9. Uji akun Warga dan ASN/Admin pada dua HP: autentikasi, chat, notifikasi sesuai akun, laporan foto JPG/PNG/WebP, daftar riwayat, perubahan status, izin peran, Ahli Waris, dan slider beranda. Catat nomor laporan, pastikan baris MySQL benar-benar terbentuk dan tidak bocor ke akun lain.
10. Jika staging berhasil, jadwalkan deploy ke produksi, ulangi tes endpoint dan perangkat nyata. Jika gagal, rollback **berkas kode** ke backup; data warga tetap berada di database asli. Jangan menghapus tabel hanya karena sebuah tes gagal.

## Penting
- Tidak ada alat cPanel/SSH yang tersambung ke percakapan ini, jadi paket ini **belum dipasang** ke server produksi.
- Status hijau GitHub Actions membuktikan tes pada **database uji**, bukan otomatis membuktikan semua data produksi sehat.
- APK/AAB 2.5.46 adalah kandidat pengujian internal, bukan izin langsung untuk rilis Play Store publik.
- ZIP lengkap dari unggahan pemilik mungkin berisi **data pribadi dan konfigurasi**. File tersebut **tidak boleh** diunggah ke GitHub publik; gunakan paket kode-only untuk kolaborasi.
