# Profil Pimpinan, Foto, dan QR Unik — CikokoSmartAPPS

## Alur
1. Admin membuka **Kelola Cuti PPSU → QR Pejabat** pada aplikasi Android, memilih akun pejabat, mengisi nama, jabatan, NIP, unit kerja, dan memilih foto.
2. API menyimpan foto di folder private dan membuat **token acak 192-bit** serta QR unik otomatis saat profil pertama disimpan. QR menyimpan **URL profil saja**, bukan nama atau NIP.
3. QR yang sama dipakai di surat cuti A4 pada bagian VI (atasan langsung) dan VII (Lurah). Setelah data profil diperbarui, URL dan QR tetap, tetapi informasi hasil scan ikut berubah.
4. Pemindaian QR membuka halaman publik `https://datawebs.my.id/mobile-api/pjlp_profile.php?id=<token>` dengan foto, nama, jabatan, NIP, unit kerja, dan keterangan status.
5. QR profil **bukan TTE**, bukan bukti bahwa pejabat menyetujui suatu surat, dan tidak memverifikasi isi surat.

## Langkah instalasi hosting (WAJIB)
1. Backup database MySQL dan file PHP yang lama.
2. Jika modul cuti belum pernah dipasang, impor `cpanel/mobile-api/migrate_pjlp_leave.sql` terlebih dahulu.
3. **Setelah itu** impor `cpanel/mobile-api/migrate_pjlp_official_profiles.sql` melalui phpMyAdmin, **sekali saja**. Jangan jalankan migrasi ALTER kedua kali.
4. Unggah pembaruan `cpanel/mobile-api/pjlp_leave.php` dan `cpanel/mobile-api/pjlp_profile.php` ke `public_html/mobile-api/`; pertahankan file `pjlp_leave_pdf.php`, `index.php`, dan `bootstrap.php` yang telah terintegrasi.
5. Pastikan PHP memiliki cURL, GD, PDO MySQL dan izin tulis pada `mobile-api/private/pjlp/`. Batasi akses web ke folder `private` melalui konfigurasi hosting.
6. Pastikan domain `https://datawebs.my.id` memang menjadi domain API produksi. Jika domain berubah, ubah URL profil di API dan Flutter.
7. Masuk admin, simpan ulang setiap profil pejabat lama **sekali** untuk membuat token/QR unik, kemudian unggah fotonya.
8. Uji pemindaian QR dengan HP **tanpa login**. Halaman profil tidak menyediakan fitur edit.
9. Uji surat A4 yang sudah disetujui; QR profil pejabat muncul sesuai bagian VI dan VII.

## Catatan penting
- Server membuat PNG QR dengan layanan `https://quickchart.io/qr`; yang dikirim ke layanan hanya URL publik dengan token acak, bukan data pribadi. Koneksi HTTPS keluar dan cURL diperlukan. Bila layanan tidak tersedia, penyimpanan profil baru dapat gagal sampai layanan pulih. Untuk deployment tanpa layanan eksternal, ganti dengan generator QR lokal.
- NIP, nama, jabatan, unit kerja dan foto menjadi informasi **publik** bila profil disimpan dengan `is_public=true`. Pastikan pejabat dan pengelola informasi menyetujui publikasinya sesuai kebijakan instansi.
- Profil tidak dapat dicari melalui daftar publik dan halaman memakai header `noindex`; tetapi **siapa pun yang memiliki QR atau URL tetap dapat melihatnya**.
- Untuk menonaktifkan halaman publik, ubah `is_public=0` pada tabel `pjlp_officials` (UI pengaturan publikasi lebih lanjut dapat ditambahkan).
- File PNG QR dan foto disimpan dengan nama acak; jangan membagikan isi folder private.
- Belum ada mekanisme pencabutan/rotasi QR dari aplikasi; lakukan secara terkontrol melalui admin database jika diperlukan.
- Penggunaan QR profil pada dokumen **tidak otomatis menjadi persetujuan atasan langsung atau Lurah**. Jika surat memerlukan pengesahan oleh mereka, terapkan proses otorisasi yang sesuai.

## Pemeriksaan penerimaan
- Admin membuat profil + foto → URL profil unik, QR terlihat pada Android.
- QR dipindai → halaman menampilkan data terbaru + foto tanpa login.
- Admin mengubah nama/jabatan/foto → URL QR tetap dan data berubah.
- QR profil orang lain tidak bisa dipakai untuk melihat folder private.
- Dokumen cuti A4 final menampilkan dua QR profil pejabat yang benar.
- Admin masih menjadi pemutus pengajuan cuti PPSU sesuai alur yang diminta.
