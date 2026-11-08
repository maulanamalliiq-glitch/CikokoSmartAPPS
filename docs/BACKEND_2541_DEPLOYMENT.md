# Cikoko SmartAPP 2.5.41 — Panduan Sinkronisasi Backend cPanel

**Status:** Overlay kode telah disiapkan dan diuji secara otomatis. Paket ZIP tidak mengubah hosting dengan sendirinya.

## Ruang lingkup
Salin **hanya** enam berkas dalam folder `mobile-api/` ini ke folder `public_html/mobile-api/` (atau direktori setara di domain aktif):
- `index.php` — tetap menjaga action RT/RW, LPJ, waris, verifikasi, monitoring, notifikasi dan layanan terpadu. Menambah bantuan akun, pembatasan percobaan login, pembacaan chat berhalaman.
- `bootstrap.php` — memastikan schema tambahan, audit wilayah pengajuan, dan penghapusan notifikasi pribadi yang diizinkan.
- `release_core.php` — tiga tabel tambahan, throttling, cursor chat, serta snapshot RT/RW saat pengajuan.
- `account_support.php` — pemulihan/penghapusan akun melalui verifikasi Admin Utama, tanpa membocorkan keberadaan akun saat permintaan.
- `governance_review.php` — area monitoring dari data saat dikirim, bukan profil warga yang dapat berubah; chat per pengguna berhalaman.
- `waris_review.php` — identifikasi pengajuan berdasarkan nomor atau referensi legacy; hak akses tetap diperiksa.

**Jangan** menimpa berkas lain, folder `private`, foto, atau `config.php`. Versi backend lain tidak boleh diganti dengan source pengujian `NewAppsCikoko/qa/release-api/index.php` karena bisa menghapus rute produksi yang sudah berfungsi.

## Syarat sebelum penerapan
1. Backup penuh database MySQL, `public_html`, folder data akun, foto/lampiran privat dan konfigurasi. Pastikan salinan bisa dipulihkan.
2. Periksa 6 berkas PHP lama dan lakukan diff: jika hosting sudah memiliki perubahan yang tidak ada di GitHub, gabungkan perubahan secara selektif sebelum unggah.
3. Gunakan staging terlebih dahulu, dengan salinan database tersanitasi dan akun uji. Pastikan user database memiliki izin untuk membuat 3 tabel `mobile_auth_limits`, `mobile_account_requests`, dan `mobile_submission_areas`; atau jalankan SQL migrasi yang setara lewat phpMyAdmin oleh pengelola database.
4. Backup juga pengaturan Firebase, jadwal cron dan log kesalahan. Tidak perlu memperbarui kredensial; jangan mengunggah kunci/rahasia ke GitHub.
5. Unggah overlay ke staging, verifikasi sintaks PHP, lalu login dan uji tindakan dengan minimal dua akun warga terpisah, satu ASN, Ketua RT, Ketua RW dan Admin Utama.
6. Uji tindakan spesifik: akun baru/masuk, gagal login berulang (429), bantuan akun, chat warga-admin, notifikasi pribadi, laporan, peninjauan ASN, Ahli Waris dengan referensi, monitoring RT/RW, LPJ, pengunggahan dokumen, serta akun berbeda pada perangkat yang sama.
7. Setelah lulus di staging, terapkan pada produksi pada waktu pemeliharaan, lalu buka `https://datawebs.my.id/mobile-api/index.php?action=health`: balasan harus JSON, HTTP 200, `version=2541.rc1`, `ready=true` serta seluruh pemeriksaan file bernilai true. Catatan: health hanya menguji keberadaan berkas, **bukan** seluruh koneksi atau pengujian transaksi end-to-end.
8. Pastikan UI Android 2.5.41 benar-benar dapat login, mengirim, menerima dan menampilkan data sesuai hak akses sebelum publikasi Play Store.
9. Bila pengujian gagal, segera pulihkan 6 berkas PHP hasil backup dan database bila terdapat migrasi tak kompatibel, serta hentikan distribusi APK ke warga sampai dipastikan aman.

## Batasan
GitHub Actions menghasilkan ZIP dan menguji di MySQL terisolasi, **tidak menerapkan langsung ke cPanel**. Perlu sesi hosting sah atau admin cPanel untuk memasang paket. Hindari deploy langsung tanpa backup.
