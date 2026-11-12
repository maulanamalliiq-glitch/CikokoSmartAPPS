# Integrasi Foto Header Website → Android CikokoSmartAPPS v2.5.49

Repo aplikasi yang benar: `maulanamalliiq-glitch/CikokoSmartAPPS`.

## Identitas tetap sama

- Flutter tetap berada di direktori `flutter/`.
- Package ID tetap `com.KelurahanCikoko.malik` (tidak membuat aplikasi Android baru).
- Versi dinaikkan dari `2.5.48+2548` menjadi `2.5.49+2549` agar Play Store dapat menerima update.
- Workflow `.github/workflows/android-release.yml` tetap memakai *upload signing certificate* lama melalui secrets `CIKOKO_KEYSTORE_B64`, `CIKOKO_STORE_PASSWORD` dan `CIKOKO_KEY_PASSWORD`, dengan alias `androidkey`; tidak ada file keystore atau password dalam GitHub.

## Perubahan

1. `cpanel/mobile-api/index.php` menambahkan **GET `?action=appearance_public`**. Endpoint publik read-only ini mengembalikan data pengaturan foto header dari `appearance.hero`.
2. Untuk keamanan, foto diizinkan hanya jika berada dalam `assets/images/` pada domain resmi `datawebs.my.id`, berformat JPG/PNG/WebP, dan berkasnya ada di server.
3. `flutter/lib/main.dart` mengambil foto saat aplikasi dibuka, refresh beranda, dan saat pembaruan informasi dipanggil; tidak perlu menyimpan salinan gambar ke APK.
4. `flutter/lib/cikoko_v6_showcase.dart` menampilkan URL foto website di bagian kanan header, sambil mempertahankan tata letak V6, chat, notifikasi, layanan, navigasi dan foto bawaan sebagai fallback.
5. Penyesuaian fit dan posisi foto (x/y) ikut diterapkan. Saat tidak ada server atau foto gagal dimuat, `assets/kantor-cikoko.jpg` tetap dipakai.
6. Pengaturan zoom dan file SVG belum disamakan; file SVG akan tetap memakai foto bawaan Android.

## Pemasangan server cPanel wajib

GitHub repository **bukan cPanel live**. Agar fitur berfungsi, pasang perubahan `cpanel/mobile-api/index.php` melalui proses deploy yang sudah ada setelah melakukan backup dan membandingkan versi file di hosting. **Jangan overwrite file API live yang memiliki perbaikan lebih baru tanpa merge!**

Setelah backend terpasang, tes alamat:

`https://datawebs.my.id/mobile-api/index.php?action=appearance_public`

Respons ketika foto tersedia harus berupa JSON seperti:

`{"ok":true,"hero":{"image_url":"https://datawebs.my.id/assets/images/visual-...jpg","fit":"cover","x":50,"y":50}}`

Jika `image_url` kosong, periksa apakah foto diunggah melalui menu Website Admin → Pengaturan Tampilan → Foto Header / Banner, serta apakah file masih ada dalam `assets/images/`.

## Sebelum menyatukan PR dan merilis AAB

- Jalankan Flutter Analyze + semua widget tests, serta `php -l` untuk perubahan Mobile API.
- Uji foto header diganti oleh Admin website kemudian tarik untuk refresh (pull-to-refresh) pada Android; pengunjung yang belum login juga harus melihat pembaruan.
- Uji offline dan file gambar yang terhapus: foto bawaan tampil, tanpa crash.
- Uji chat, foto, Firebase push, menu RT/RW, dan izin pengguna (modul yang sudah ada tidak boleh rusak).
- Verifikasi package ID, versionCode 2549, dan SHA-256 sertifikat yang sama dengan Google Play Console → App integrity → Upload key certificate.
- Build signed APK/AAB dari workflow asli **hanya sesudah signing secrets tersedia dan CI lulus**. Jangan mengunggah debug APK ke Google Play atau menghapus aplikasi lama agar install berhasil.
- Jangan merge/unggah Play Store secara otomatis sebelum User Acceptance Testing.

Perubahan pada repo lain `cikokosmarthome-ctrl/SmartCikoko` adalah aplikasi berbeda dan **tidak boleh dijadikan update** aplikasi ini.
