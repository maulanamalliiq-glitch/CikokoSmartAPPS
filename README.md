# Cikoko SmartApp — Flutter Native (bukan WebView)

**Identitas**: `Cikoko`, `com.KelurahanCikoko.malik`, versionCode **204**, target SDK **36**.

## Paket

- `flutter/` — seluruh source Flutter native, Firebase Messaging, login multiperan, berita, layanan, galeri, formulir Ahli Waris, laporan dan chat.
- `cpanel/` — API REST PHP/MySQL dan widget chat publik; **hanya file baru/perubahan**, tidak menimpa data produksi.
- `.github/workflows/android-release.yml` — job APK/AAB signed; memerlukan GitHub Actions Secrets.
- `qa/` — bukti pemeriksaan sintaks dan pengujian API lokal.

## Deploy backend ke cPanel

1. Backup seluruh file, `data/`, `ahli-waris/private/` dan database MySQL.
2. Upload isi direktori `cpanel/` ke folder website (yang berisi `lib.php` dan `admin.php`). Sebelum overwrite, bandingkan `admin.php`, `lib.php`, `kelurahan-admin.php`, `ahli-waris/bootstrap.php`, `ahli-waris/admin.php`, `ahli-waris/index.php` jika website berubah setelah ZIP *Cikoko MAster* yang diberikan.
3. Pastikan `ahli-waris/config.php` di hosting menunjuk database MySQL; **jangan upload file ini ke GitHub**.
4. Periksa `https://datawebs.my.id/mobile-api/index.php?action=health`; perlu menghasilkan JSON ok=true.
5. Login dengan akun warga/petugas untuk memeriksa `/mobile-api/index.php?action=login` dan perubahan dalam dashboard. Tabel baru otomatis dibuat **jika hak akses CREATE TABLE tersedia**.
6. Chat mengambang tampil pada website. Kelola melalui Admin Utama → **Hubungi Kami · Chat**. Admin Kelurahan dapat membuka panel chat dari menu `kelurahan-admin.php`.

## FCM push ketika aplikasi ditutup

`google-services.json` hanya konfigurasi **klien**, bukan kunci pengirim server. Agar push benar-benar dikirim ke HP ketika aplikasi ditutup, diperlukan service account JSON Firebase dengan izin mengirim FCM HTTP v1 dari proyek yang benar, disimpan **di luar public_html**, dan cron tiap menit:

```
CIKOKO_FIREBASE_SA=/home/CPANEL_USER/private/firebase-service-account.json /usr/local/bin/php /home/CPANEL_USER/public_html/mobile-api/cron_dispatch.php
```

Tanpa service account/cron, aplikasi tetap menarik notifikasi dari database tiap ~15 detik **saat terbuka**, tetapi **tidak ada jaminan push pada aplikasi tertutup**. Mengirim notifikasi hanya berdasarkan kategori publik/petugas; NIK/dokumen tidak disebarkan melalui FCM.

## Build di GitHub Actions

1. Upload seluruh direktori `flutter/` dan `.github/workflows/android-release.yml` ke repository GitHub, jangan unggah keystore, password atau PHP private database.
2. Pada Settings → Secrets and variables → Actions, siapkan tiga secret: `CIKOKO_KEYSTORE_B64` (keystore dalam base64), `CIKOKO_STORE_PASSWORD`, dan `CIKOKO_KEY_PASSWORD`.
3. Actions → Cikoko Android Signed Release → Run workflow. Ambil dua hasil signed dari artifact.
4. Fingerprint sertifikat dibandingkan dengan keystore yang disertakan pengguna. VersionCode 204 harus **lebih tinggi** dari rilis aktif Play Store; sesuaikan jika Play Console menunjukkan versi ≥204.

**Keamanan**: Jangan memasukkan kunci signing, password, service-account Firebase, NIK, dan database warga dalam repository GitHub. Rotasi password DB sebelumnya telah dibagikan di percakapan.

## Status QA dan keterbatasan

PHP syntax & local API GET/invalid auth dapat diuji tanpa database. **Belum ada Flutter/Android SDK di lingkungan saat ZIP ini disusun**, sehingga Dart/Gradle build, uji di perangkat, koneksi cPanel/MySQL produksi, dan pengiriman FCM langsung **belum diverifikasi**. Jangan label APK/AAB *siap publish* sampai workflow berhasil dan tes end-to-end selesai.

Tampilan adalah widget native Flutter, **bukan WebView**. Foto kamera/galeri diperkecil dan dikompresi ketika perlu. Proses kompresi lossy tidak dapat menjamin kualitas pixel sama persis dengan gambar asli; selalu periksa keterbacaan dokumen.
