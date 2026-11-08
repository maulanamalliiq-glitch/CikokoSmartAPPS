# Pembaruan Cikoko SmartAPP — Bot Penunggu Saat Petugas Offline (Backend 2545)

## Fungsi yang diberikan
Warga mengirim pesan ke **Hubungi Admin** seperti biasa. Ketika tidak ada Admin Utama, Admin Kelurahan ataupun ASN berwenang yang aktif di aplikasi, sistem menambahkan **satu pesan otomatis**:
> 🤖 Asisten Otomatis Cikoko: Pesan Anda telah diterima. Saat ini Admin Utama, Admin Kelurahan, dan ASN sedang tidak online. Mohon menunggu tanggapan dari petugas. Pesan Anda tersimpan dan akan dapat dibaca saat petugas kembali aktif.

Bot ini **tidak menjalankan AI**, tidak menjawab persoalan warga, tidak memeriksa NIK, tidak mengubah status layanan, dan tidak mengambil alih hak petugas. Balasan staf tetap disimpan pada thread yang sama.

## Siapa yang dapat membalas?
- **Admin Utama**: hak chat bawaan.
- **Admin Kelurahan**: hak chat bawaan.
- **ASN**: mendapatkan hak `chat:reply` bawaan pada backend versi ini.
- Role lainnya tidak otomatis diberi hak balas.

Jika Admin Utama pernah menyimpan kebijakan `mobile_role_permissions` yang menolak `chat:reply` untuk ASN, **kebijakan tersebut tetap berlaku**; tinjau lewat panel pengaturan peran dan aktifkan bila memang diinginkan. Jangan memberikan izin dengan cara menonaktifkan autentikasi.

## Kapan dianggap online?
Petugas dianggap online berdasarkan sesi perangkat autentik yang memperbarui `events`, chat inbox atau `chat_presence` dalam 90 detik terakhir. Aplikasi foreground memuat informasi secara berkala (sekitar 3–30 detik). Saat app background / logout, status offline dikirim dari aplikasi terbaru, dan kedaluwarsa 90 detik menjadi cadangan bila jaringan putus. Sesi online per perangkat sehingga logout di satu perangkat tidak membuat perangkat lain otomatis offline.

**Batasan:** online dari web cPanel belum dihitung; yang dihitung adalah sesi aplikasi Android. Status ini adalah indikator aktivitas aplikasi, bukan jaminan petugas sedang melihat percakapan.

## Anti-spam
Bot hanya mengirim satu pemberitahuan selama warga belum mendapat balasan manusia. Pesan kedua, ketiga, dan seterusnya dari warga **tidak** menambah pesan bot berulang. Setelah staf membalas, bot boleh mengirim satu pemberitahuan baru pada pesan berikutnya apabila semua petugas kembali offline.

## Langkah instalasi
1. Backup penuh database, data warga, lampiran, konfigurasi rahasia serta root website; simpan di luar direktori publik.
2. Pastikan domain API benar: `https://datawebs.my.id/mobile-api/index.php`. Jika `?action=health` masih menunjukkan `205.1`, sebelumnya backend produksi belum pernah disinkronkan. Gunakan paket API lengkap, bukan hanya dua file bot.
3. Uji pada staging dahulu; gabungkan perubahan khusus hosting yang mungkin berbeda dari GitHub.
4. Impor `mobile-api/migrate_offline_chat_bot_2545.sql` di phpMyAdmin database yang benar setelah backup. SQL hanya menambahkan dua tabel.
5. Salin file PHP overlay paket ke folder `mobile-api` yang sudah ada pada document root domain API, **jangan menghapus** file konfigurasi, folder `private`, foto, maupun lampiran.
6. Verifikasi `?action=health`: HTTP 200, `version=2545.rc1`, `ready=true`, serta `checks.api_offline_chat_bot=true`. Health hanya menguji file yang terpasang.
7. Dengan dua HP, satu Warga dan satu Admin Utama/Admin Kelurahan/ASN: saat petugas offline, kirim satu pesan warga, pastikan muncul satu balasan bot. Kirim pesan kedua, pastikan **bot tidak menduplikasi**. Buka aplikasi petugas dan masuk ke **Pesan Masuk**, kemudian balas. Pastikan warga menerima balasan manusia. Selama petugas aktif, kirim pesan warga berikutnya dan pastikan **bot tidak membalas**.
8. Uji ketiga role staf dan satu warga lain: warga lain **tidak boleh** melihat isi thread. Uji status terkirim/tersampaikan/dibaca; bot tidak boleh dianggap telah dibaca manusia.
9. Setelah semua lulus di staging, pasang ke produksi dan ulangi pengujian dengan akun uji. Pantau error_log dan backup untuk rollback.

## File yang disertakan
Paket berisi modul PHP API yang relevan, `migrate_offline_chat_bot_2545.sql`, petunjuk ini, dan checksum SHA-256. Paket tidak memuat `config.php`, kata sandi, token, arsip pribadi, maupun file `private`.

**Penting:** GitHub Actions hanya menguji dan menerbitkan paket, tidak memiliki akses langsung ke cPanel. Instalasi di produksi dilakukan oleh pemilik akses hosting resmi. Jangan membagikan password atau token ke percakapan.
