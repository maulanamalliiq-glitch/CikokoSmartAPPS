# Cikoko V2514 — Surat Pengantar RT/RW sesuai PDF contoh

## Perubahan
- Form Surat Pengantar memuat seluruh data pada contoh PDF: Nama, Tempat/Tgl Lahir, No. KTP/KK, Agama, Kewarganegaraan, Pendidikan, Jenis Kelamin, Status, Pekerjaan, Alamat, Maksud/Keperluan.
- Nama, alamat, dan NIK/KK (jika ada) diisi awal dari profil, boleh diperiksa dan dikoreksi untuk formulir. Data formulir disimpan sebagai snapshot pada permohonan.
- Profil warga menampilkan label RT / RW saja. Nomor 2 dan 5 ditampilkan RT 02 / RW 05. Data lama 002/005 tetap dapat dibaca.
- Endpoint Surat Pengantar disediakan pada mobile-api/index.php?action=rt_rw_*. Riwayat diakses oleh pemohon atau akun RT/RW penerima resmi.
- Konfigurasi Android: versionCode 2514, versionName 2.5.14.

## Pemasangan cPanel tanpa Terminal
1. Backup folder public_html/mobile-api dan database sebelum memasang.
2. Buka File Manager cPanel pada document root **datawebs.my.id**. Pastikan aplikasi Flutter mengarah ke https://datawebs.my.id/mobile-api/index.php.
3. Ekstrak ZIP patch yang berisi **mobile-api/index.php**, **mobile-api/v211.php**, **mobile-api/territory.php**, **mobile-api/rt_rw_letters.php**. Periksa struktur, jangan sampai menjadi mobile-api/mobile-api/.
4. Karena index.php dapat berisi kustomisasi hosting, bandingkan file lama dengan patch sebelum menimpa. Jangan hapus folder data, konfigurasi DB, atau file di luar daftar patch.
5. Buka https://datawebs.my.id/mobile-api/index.php?action=health — versi harus **2.5.14** dan checks api_rt_rw / api_territory harus true. Ini uji berkas saja, bukan bukti pengajuan sudah bekerja.
6. Akun **Ketua RT** dan **Ketua RW** wilayah terkait harus aktif dan memiliki penugasan benar. Warga memilih domisili sendiri di Profil, admin hanya mengatur akun ketua.
7. Pengiriman pertama otomatis menambahkan kolom MySQL form_json pada tabel mobile_rt_rw_letters. Pengguna database perlu izin ALTER TABLE; alternatif admin database dapat membuat kolom LONGTEXT NULL secara manual melalui phpMyAdmin.
8. Uji menggunakan akun dummy: warga RT 02 RW 05 -> Ketua RT 02/RW 05 -> Ketua RW 05. Periksa data surat, status, dan riwayat dengan akun yang relevan.

## Penting
- Patch **belum otomatis terpasang** di server hanya karena GitHub diperbarui.
- Tampilan PDF sesuai acuan hanya dipakai sebagai **referensi kolom formulir**. Penerbitan PDF resmi, tanda tangan elektronik, dan stempel digital belum diaktifkan.
- Jangan langsung rilis Play Store sebelum API terpasang dan tes end-to-end.
- Data PII (KTP/KK, tanggal lahir) jangan disertakan dalam laporan kesalahan atau log publik.
