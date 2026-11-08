# Cikoko SmartAPP 2.5.42 — Patch Chat dan Petunjuk Deploy cPanel

**Tujuan:** menambahkan tanda status pesan warga–admin (terkirim, tersampaikan, dibaca) serta memastikan pesan baru langsung dapat ditampilkan. Ini merupakan paket *overlay* PHP, bukan deployment otomatis.

## Berkas pembaruan
Folder `mobile-api/` pada ZIP harus dicocokkan dengan direktori `mobile-api` di hosting. Salin hanya enam file berikut setelah backup:
- `index.php` — mengaktifkan `chat_inbox`, mengembalikan ID pesan terkirim, dan menyampaikan progres status pesan.
- `release_core.php` — watermark privat per percakapan dan pencatatan tanda terima/read receipt.
- `governance_review.php` — Admin menandai dibaca ketika membuka thread yang tepat.
- `bootstrap.php` — membuat skema yang diperlukan untuk login dan pesan.
- `account_support.php` dan `waris_review.php` — dependensi sinkronisasi versi 2541 tetap dipertahankan.

## Persiapan wajib
1. Cadangkan database MySQL (terutama `mobile_chat`, `mobile_tokens`, data warga dan pengajuan), seluruh `public_html`, serta direktori foto privat. Pastikan file backup benar-benar dapat dipulihkan.
2. Bandingkan file yang aktif di hosting dengan isi ZIP sebelum menimpa. Jika ada perubahan khusus hosting yang tidak ada di GitHub, gabungkan secara selektif. Jangan hapus folder private, config, lampiran, ataupun proyek Firebase.
3. Pastikan user MySQL dapat membuat tabel `mobile_chat_receipts` dengan kolom `user_id` dan watermark status. Jika tidak, impor migrasi SQL setelah backup melalui phpMyAdmin. Skrip ini tidak menghapus pesan yang sudah ada.
4. Terapkan paket ke staging terlebih dahulu; uji login warga A, warga B dan Admin Kelurahan. Kirim pesan A, buka daftar chat admin (dua abu-abu), buka thread A (dua hijau). Pastikan akun B tidak memperoleh chat A.
5. Uji balasan admin yang baru masuk saat aplikasi warga terbuka: menampilkan delivered ketika aplikasi warga memanggil `chat_inbox`, dan read hanya ketika warga membuka chat.
6. Jika staging lulus, terapkan ke produksi pada jadwal pemeliharaan. Periksa `https://datawebs.my.id/mobile-api/index.php?action=health`: `version` harus `2542.rc1`, `ok` dan `ready` harus true, HTTP 200.
7. Uji pada perangkat Android 2.5.42 sebelum distribusi warga. Jangan anggap pemeriksaan sintaks dan health sebagai uji end-to-end.
8. Bila terjadi masalah, lakukan rollback enam PHP dari backup dan periksa error log; tabel tambahan dapat dibiarkan jika tidak mengganggu atau dikembalikan sesuai prosedur migrasi database.

## Batasan
GitHub menyimpan kode dan berkas ZIP; **tidak** mengunggah perubahan ke hosting cPanel. Perubahan ke backend produksi memerlukan tindakan dari pengelola hosting atau integrasi deployment yang sah.
