# Cikoko SmartApp V2513 — RT/RW otomatis berdasarkan pendaftaran warga

Status: **cabang pengembangan / perlu pengujian produksi sebelum rilis**. Version Flutter `2.5.13+2513`.

## Implementasi
- **Daftar Warga (Android/Flutter):** RT dan RW wajib diisi (angka 1–999), disimpan sebagai string 3 digit (`003`, `010`) di baris pengguna `portal_users`. Akun tetap berperan `warga`, tidak pernah menjadi `rt`/`rw` berdasarkan isian tersebut.
- **Profil:** nomor RT/RW dapat dilihat dan diperbarui warga, dengan password akun saat wilayah diubah. Aplikasi lama yang belum mengirim RT/RW tetap dapat menyimpan perubahan profil biasa. Warga lama harus melengkapi RT/RW di profil sebelum dapat mengajukan surat pengantar.
- **Penentuan tujuan surat:** API hanya mengambil RT/RW dari **profil warga yang sudah tersimpan di server**, tidak dari nilai RT/RW di permintaan surat. Proses mencari **tepat satu Ketua RT aktif** untuk pasangan RT+RW dan **tepat satu Ketua RW aktif** untuk RW tersebut. Jika belum ada/duplikat, permohonan gagal aman; tidak ada pengiriman salah wilayah.
- **Akun Ketua RT/RW:** dibuat dan diberi role petugas resmi sebagaimana sebelumnya. Menu `Wilayah Ketua RT/RW` di Admin Utama mengisi wilayah petugas **saja**, bukan menetapkan RT/RW warga. Semua penugasan wilayah petugas mempunyai audit database.
- **Verifikasi permohonan:** warga mengajukan, Ketua RT memverifikasi, lalu Ketua RW. Petugas hanya dapat bertindak atas permohonan yang menunjuk ID akunnya dan **wilayah tugasnya saat ini**; setiap keputusan memerlukan password petugas. Warga hanya melihat pengajuannya sendiri. RT dan RW menerima notifikasi bertahap. RT/RW dan pemohon pada permohonan tersimpan sebagai **snapshot** untuk mencegah pengalihan surat lama ketika warga mengubah alamatnya.
- Status: `menunggu_rt` → `menunggu_rw` → `terverifikasi`; penolakan menjadi `ditolak`.

## Yang *belum* termasuk
- **PDF sesuai contoh Surat Pengantar Kelurahan Cikoko, tanda tangan elektronik resmi dan stempel aman belum terimplementasi** di patch ini. `terverifikasi` bukan `ditandatangani` atau `surat resmi diterbitkan`.
- Integrasi pengajuan dari website publik (jika memakai formulir registrasi berbeda) dan LPJ RT/RW/LMK A/LMK B di luar patch RT/RW V2513 ini.
- Migrasi/penyesuaian permohonan lama yang sudah dalam proses bila akun Ketua RT/RW dialihkan ke petugas berbeda, memerlukan prosedur administratif.
- Belum dilakukan uji end-to-end pada cPanel produksi, basis data warga sesungguhnya, maupun perangkat Android.

## Penempatan cPanel (sebelum aplikasi V2513)
1. Cadangkan `portal_users`, berkas website, tabel MySQL, dan seluruh arsip pengajuan. Jangan menimpa `ahli-waris/config.php` atau mengunggah kredensial ke GitHub.
2. Perbarui **hanya** `mobile-api/index.php`, `mobile-api/v211.php`, lalu tambahkan `mobile-api/territory.php` dan `mobile-api/rt_rw_letters.php` ke path cPanel yang digunakan aplikasi.
3. Pastikan MySQL memiliki izin `CREATE TABLE` untuk `mobile_rt_rw_letters`, `mobile_rt_rw_letter_history`, dan `mobile_rt_rw_officer_audit`, atau minta DBA menjalankan SQL ekuivalen.
4. Login Admin Utama, buat/siapkan akun role RT/RW yang aktif dan atur wilayahnya melalui **Wilayah Ketua RT/RW**. Tidak perlu menetapkan warga mana pun ke akun tersebut.
5. Test registrasi warga, edit profil dengan/ tanpa password, surat warga RT 003/RW 010, verifikasi RT 003 lalu RW 010, penolakan, pergantian wilayah petugas, pengujian warga/RT/RW lain, akun nonaktif, dan dua petugas identik.
6. Setelah seluruh tes berhasil, build Flutter Android `2.5.13+2513`; workflow menghasilkan **APK debug dan AAB/APK release unsigned**, **bukan AAB signed siap Play Store**.

## API
- `index.php?action=register` POST: `name,username,password,confirm,address,phone,email,rt,rw`
- `index.php?action=me` GET: profil termasuk `rt,rw`
- `index.php?action=profile_update` POST & `v211.php?action=v211_profile_update` POST: RT/RW warga opsional dalam klien lama, disertai `current_password` bila berubah
- `index.php?action=rt_rw_submit` POST: `subject,notes`; wajib role warga
- `index.php?action=rt_rw_list` GET: terbatasi role dan ID akun
- `index.php?action=rt_rw_decide` POST: `id,decision=approve|reject,note,current_password`; wajib role RT/RW dan pemilik tahap
- `index.php?action=rt_rw_officers` GET & `rt_rw_officer_assign` POST: pengelolaan wilayah petugas hanya oleh Admin Utama.

Pengujian otomatis: `php qa/test_v2513_territory.php`, `php -l` seluruh PHP API, dan Flutter analyze/test pada workflow PR.
