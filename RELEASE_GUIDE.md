# Cikoko APK/AAB — Langkah Pengujian dan Rilis

Aplikasi Android Flutter **native**, bukan WebView. Nama aplikasi **Cikoko**; package Android `com.KelurahanCikoko.malik`, versionCode **204**, target Android API **36**.

## Download APK pengujian

1. Buka [Actions](https://github.com/maulanamalliiq-glitch/CikokoSmartAPPS/actions) dan pilih run terbaru berstatus hijau.
2. Pada **Artifacts**, download `Cikoko-v204-TEST-APK`.
3. Ekstrak ZIP dan pasang `app-debug.apk` pada Android untuk uji fitur. Ini **bukan** APK/AAB untuk diunggah ke Play Store.

## Aktifkan AAB signed di GitHub Actions

Karena keystore dan password signing **tidak boleh disimpan sebagai file repository**, admin repository perlu menambahkan tiga Actions Secrets di Settings → Secrets and variables → Actions:

- `CIKOKO_KEYSTORE_B64` — isi base64 dari file keystore lama, dalam satu baris. Di macOS: `base64 -i "/path/to/android.keystore" | tr -d '\n'`.
- `CIKOKO_STORE_PASSWORD` — password keystore.
- `CIKOKO_KEY_PASSWORD` — password private key alias `androidkey`.

Jangan mengunggah keystore, password, atau service account ke README, issue, atau source GitHub.

Setelah menyimpan secrets: buka **Actions → Cikoko Android APK dan AAB → Run workflow**. Jika build hijau, unduh `Cikoko-v204-SIGNED-APK-AAB`. ZIP tersebut memuat **app-release.apk** dan **app-release.aab**.

Workflow menghentikan signed build apabila fingerprint sertifikat keystore tidak cocok dengan versi sebelumnya. Pastikan juga Play Console masih menggunakan versionCode kurang dari 204.

## Backend dan notifikasi

APK mengakses `https://datawebs.my.id/mobile-api/index.php`. Source API/chat tersedia di direktori `cpanel/` repo sebagai **patch**, bukan salinan website lengkap. Sebelum menguji login/chat/surat di HP, backup dan deploy patch ke cPanel, periksa database dan endpoint `?action=health`, lalu verifikasi hak akses.

Push Firebase ketika aplikasi tertutup memerlukan **service-account Firebase di server** dan **cron dispatcher** pada cPanel; file `google-services.json` saja tidak cukup. Tanpa konfigurasi server tersebut, aplikasi hanya polling notifikasi ketika terbuka. Jangan mengirim NIK atau lampiran identitas lewat payload FCM.

## Pemeriksaan sebelum Play Store

- Login warga, admin, dan petugas berbagai role
- Kirim laporan dengan kamera/galeri dan periksa database
- Surat Ahli Waris lengkap termasuk dokumen dan hak akses
- Chat masuk, balasan admin, dan jam kerja
- Push foreground/background/tertutup
- Android 16 (API 36), permission notifikasi, dan stabilitas sesi
- Nomor versi, upload certificate, privacy policy, backup database, dan Play Console review

**Jangan menganggap source code sebagai jaminan semua uji di perangkat/produksi telah lulus.**
