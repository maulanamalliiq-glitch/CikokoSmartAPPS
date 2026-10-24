# Cikoko v205 — Flutter Native Role UI

Nama: **Cikoko** · Package: `com.KelurahanCikoko.malik` · Version code: **205** · Target API: **36**.

## Telah dibuat dalam source
- Native Flutter dengan bottom navigation 5 tab, dashboard kompak, menu cepat per role, berita/pengumuman, notifikasi, chat mengambang.
- Katalog 19 kode role: admin, admin_kelurahan, lurah, asn, pppk, pjlp, ptsp, dukcapil, rt, rw, fkdm, lmk, jumantik_rt, jumantik_rw, dasawisma, pkk, posyandu, ppsu, warga. (18 jenis struktur + PKK kompatibilitas.)
- Izin server untuk create laporan sesuai peran, verifikasi laporan, chat admin, unggah berita/pengumuman, catat arsip lama, kelola role. Hak akses disimpan pada tabel MySQL `mobile_role_permissions`. Akun warga langsung aktif dan tidak memperoleh hak admin.
- Admin Kelurahan dapat mengirim berita/pengumuman (tanpa foto) dan mencatat metadata arsip lama; lampiran tetap melalui panel cPanel.
- Unit test katalog role, pemeriksaan analyzer, build APK debug melalui GitHub Actions; signed APK/AAB bergantung pada konfigurasi Actions Secrets.

## Belum dibuat dan perlu backend tersendiri
- Kehadiran otomatis, jadwal piket, cuti, rapor kinerja, PROTAP, pengesahan Lurah, editor detail arsip dan upload lampiran arsip dari Flutter, laporan Jumantik khusus dengan checklist granular, lampiran tanda koordinat pada foto, hak akses cakupan per RT/RW. Menu tersebut diberi tanda **belum terintegrasi**, bukan dummy yang menyimpan data palsu.
- Firebase background push realtime memerlukan service account + cron server yang dikonfigurasi dan diuji di cPanel; kode Flutter saja bukan jaminan pengiriman.
- Pengujian MySQL produksi serta semua akun dan permission belum dilakukan.

## Deploy
1. Backup seluruh cPanel dan database.
2. Pastikan patch `cpanel/mobile-api/` versi sebelumnya telah terpasang. Dari revisi ini gunakan pembaruan `mobile-api/index.php`, `mobile-api/permissions.php`, dan `roles-lib.php`. **Jangan ekstrak seluruh folder sumber cpanel langsung di hosting** karena itu bisa menimpa perubahan website lainnya.
3. PHP harus mengizinkan CREATE TABLE untuk tabel hak akses; bisa juga impor SQL dari source sebelum API dibuka.
4. Verifikasi endpoint `mobile-api/index.php?action=health` dan uji login/token/izin berbagai role.
5. Jalankan GitHub Actions sampai APK debug berhasil. Signed AAB hanya jika keystore secrets tersedia dan fingerprint upload cert cocok. Jangan unggah keystore/password ke repo.

**Catatan privasi:** NIK, surat Ahli Waris dan arsip dibatasi aksesnya; untuk aplikasi layanan publik perlu uji penetrasi, audit unggah dan enkripsi sebelum penggunaan produksi.
