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

## Perbaikan Admin Native (tambahan v2549)

- Login **mata buka/tutup** berlaku untuk kata sandi login, kata sandi registrasi, dan konfirmasi registrasi.
- Tombol **Kelola Semua Halaman** tidak lagi membuka `https://datawebs.my.id/admin/...`. Setiap tile menggunakan halaman edit Flutter yang berbeda, bukan WebView.
- **Ganti Foto Header** memakai langsung `home_slides` (GET), `home_slide_upload` (POST foto) dan `home_slides_save` (POST JSON). API yang sama menjadi sumber slideshow pada `cpanel/index.php` dan gambar hero pada `flutter/lib/main.dart`. Android mengambil **foto pertama** dari daftar, sementara website menampilkan maksimal lima foto dalam slideshow. Bisa pakai kamera/galeri, urutan dan hapus dari daftar. Aksi penghapusan daftar tidak menghapus file asli secara fisik.
- Berita, pengumuman, galeri kegiatan dan daftar konten layanan menggunakan JSON website yang sama melalui `cms_content_list`, `cms_content_save`, `cms_content_delete` dan `cms_media_upload`. Perubahan tampil setelah API publik `content` di-refresh.
- Pengaturan tampilan (logo/slot foto/posisi/fit) menggunakan JSON website `appearance` melalui `cms_appearance_list` dan `cms_appearance_save`.
- Inovasi menggunakan API lama `v211_innovations` / `v211_innovations_update`.
- Editor judul/isi **CMS Halaman, PPID, agenda, pimpinan, wilayah, kontak dan laporan publik** saat ini menyimpan ke `cikoko_pages_cms` melalui `cms_page_list` / `cms_page_save`. **Penyimpanan belum membuktikan bahwa template setiap halaman website live membaca nilai tersebut**; integrasi dengan template `page.php`/CMS spesifik perlu divalidasi pada cPanel sebelum klaim sinkronisasi semua halaman.
- Penulisan CMS hanya untuk **Admin Utama** yang berhasil login dengan token Bearer; server memverifikasi role kembali pada setiap request.

## Persyaratan Deployment CMS

- Endpoint `home_slides` sudah terdapat pada source sebelumnya; sinkronisasi header Android dapat memakai endpoint itu tanpa menunggu `appearance_public`.
- Editor native untuk CRUD konten dan tampilan **perlu deploy** `cpanel/mobile-api/app_cms.php` dan penambahan routing pada `cpanel/mobile-api/index.php`. Menyalin APK saja tidak akan memasang perubahan PHP di hosting. Backup dan **merge** dengan mobile-api terbaru di cPanel, jangan menimpa patch live.
- Uji login Admin Utama → **Kelola Semua Halaman → Ganti Foto Header** → Galeri/Kamera → Simpan → reload website dan tarik-untuk-refresh halaman Beranda Android.
- Uji hak akses akun bukan admin, unggah foto JPG/PNG/WebP maksimum 4 MB, berita, pengumuman, galeri, layanan, perubahan logo website, dan kesalahan jaringan.
- UAT signed build ada pada workflow `.github/workflows/android-uat-2549.yml` dan tag prerelease `v2.5.49-uat2549` setelah berhasil. GitHub Secrets signing asli tetap digunakan; keystore tidak dimasukkan ke source.
- **Jangan menghapus aplikasi Play Store yang sudah terpasang.** APK yang ditandatangani upload key mungkin berbeda dari app signing key Google Play; untuk pengguna Play Store gunakan jalur update melalui Play Internal Testing.
