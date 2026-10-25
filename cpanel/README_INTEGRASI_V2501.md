# Integrasi Cikoko 2.5.1 / versionCode 2501

## Sumber data
Android mengakses https://datawebs.my.id/mobile-api/index.php dan v211.php. Website Inovasi: /inovasi.php, pengelolaan: /kelola-inovasi.php.
Konten publik tersimpan pada data/*.json, event/notifikasi pada tabel MySQL mobile_events, mobile_event_reads, mobile_devices.
Patch ini hanya overlay, BUKAN pengganti penuh website. Website lama perlu lib.php, roles-lib.php, config.php, dan ahli-waris/config.php yang kompatibel. Navigasi website utama di index.php yang sudah ada harus ditambahkan tautan /inovasi.php secara terpisah.

## Pembaruan tanpa menghapus data
1. Cadangkan seluruh public_html, data/, folder lampiran dan database MySQL. Uji hasil restore cadangan.
2. Jangan hapus/overwrite data/, ahli-waris/private/, mobile-api/private/ (kecuali file .htaccess pelindung), config.php atau ahli-waris/config.php.
3. Bandingkan versi website sebelum memasang overlay. Bila lib.php produksi berbeda, terapkan event hook mobile_emit pada proses simpan berita baru, jangan mengganti keseluruhan lib.php tanpa pengujian.
4. v211_migration.sql dan v2500_migration.sql hanya membuat tabel jika belum ada, tanpa DROP/DELETE.
5. Cek /mobile-api/index.php?action=health, /mobile-api/index.php?action=content, dan /mobile-api/v211.php?action=v211_innovations. Respons ok=true tidak membuktikan FCM sudah terkirim.

## Mengaktifkan notifikasi Firebase
1. Izinkan notifikasi pada HP Android; pastikan aplikasi login dan token FCM berhasil dicatat endpoint device.
2. Pastikan identitas package Android com.KelurahanCikoko.malik sesuai Firebase dan Google Play.
3. Letakkan Firebase service account JSON DI LUAR public_html, set environment CIKOKO_FIREBASE_SA lalu jalankan cron dispatcher setiap menit.
   Contoh cron (ganti USER/PATH sendiri):
   CIKOKO_FIREBASE_SA=/home/USER/private/firebase-service-account.json /usr/local/bin/php /home/USER/public_html/mobile-api/cron_dispatch.php
4. Dari Terminal cPanel (bukan URL publik) jalankan:
   CIKOKO_FIREBASE_SA=/home/USER/private/firebase-service-account.json php /home/USER/public_html/mobile-api/diagnose_cli.php
5. NO_REGISTERED_FCM_DEVICES berarti token belum tercatat; PENDING_FCM_EVENTS_CHECK_CRON berarti antrian belum diselesaikan. Periksa cron dan log saat menambah berita uji.
6. Uji foreground, background, aplikasi ditutup, admin membalas chat, lalu pastikan badge berkurang setelah notifikasi diketuk.

## Kompatibilitas Play Store dan penyimpanan
Rilis produksi pada tangkapan layar: versionCode 481 (4.8.1). Sumber cabang ini: 2501 (2.5.1), package tetap.
Sebelum rilis wajib periksa keystore, sertifikat upload dan signing Play App Signing. Paket debug dan unsigned tidak dapat dipakai sebagai rilis Play Store.
Update APK normal dengan package yang sama mempertahankan data aplikasi; cache berita dan inovasi terakhir pun dipertahankan bila API offline.
Uninstall, Hapus Data, migrasi domain tanpa membawa data, dan menghapus tabel/folder pada server tidak termasuk update aman.
CI yang lolos hanya memeriksa build/sintaks, bukan bukti pengujian notifikasi produksi di HP.
