# Cikoko SmartApp — Staging Backend LPJ v2513

## Perubahan
- Rute authenticated civic_catalog / civic_list / civic_submit / civic_detail / civic_review / civic_pdf, plus civic_pin_set.
- Empat LPJ terpisah: RT, RW, LMK A (biaya operasional), LMK B (biaya kegiatan sesuai tugas).
- Saldo awal, penerimaan, rincian pengeluaran, jumlah, dan sisa otomatis divalidasi di SERVER.
- Bendahara RT/RW mengirim -> Bendahara menyetujui memakai PIN -> Ketua RT/RW menyetujui memakai PIN. Persetujuan dari wilayah lain ditolak.
- LPJ LMK: anggota LMK membuat dan menyetujui dengan PIN.
- PIN dienkripsi melalui password_hash dan dibatasi 5 percobaan salah/15 menit; pengaturan PIN wajib mengonfirmasi password akun portal.
- PDF A4 dibuat server-side dengan status jelas, nama pejabat yang menyetujui dan riwayat per revisi. **PDF ini bukan TTE bersertifikat, dan tidak secara otomatis menempel gambar tanda tangan/stempel.**
- Status dokumen: menunggu_bendahara, menunggu_ketua, menunggu_lmk, dikembalikan, disahkan.
- Saat dikembalikan, pengiriman ulang meningkat ke revisi baru, tanpa menghapus riwayat lama.
- User wilayah lain tidak dapat melihat PDF, detail, atau menyetujui LPJ; admin/lurah dapat membaca untuk monitoring.

## Dasar format asli (bukan ketentuan nominal permanen)
Empat PDF contoh:
1. LPJ RT: Uang Penyelenggaraan Tugas dan Fungsi RT/RW; contoh Januari 2026 Rp2.500.000.
2. LPJ RW: Uang Penyelenggaraan Tugas dan Fungsi RT/RW; contoh Januari 2026 Rp3.125.000.
3. LMK A: Laporan Penggunaan Biaya Operasional LMK; contoh Januari 2026 Rp1.000.000.
4. LMK B: Laporan Penggunaan Biaya Kegiatan Sesuai Tugas LMK; contoh Januari 2026 Rp1.500.000.
Angka contoh tersebut bukan nilai default wajib. PDF saat ini menampilkan unsur pokok; tata letak resmi 1:1 dan tanda tangan/stempel masih memerlukan QA.

## Rencana deploy STAGING (belum otomatis terpasang di hosting!)
1. Backup penuh database datd1747_smartapp dan salin direktori public_html/mobile-api.
2. Jalankan 20261027_lpj_check_readonly.sql untuk memastikan civic_officers ada dan punya kolom user_id,duty,rt,rw,active. Periksa tipe duty (VARCHAR atau ENUM yang mengizinkan bendahara_rt,bendahara_rw,lmk).
3. Jalankan 20261027_lpj_backend.sql sekali via phpMyAdmin database yang benar. Skrip membuat empat tabel baru; tidak menyentuh civic_documents/civic_approvals/civic_audit/civic_officers.
4. Upload civic_lpj_v2513.php ke public_html/mobile-api/ dan perbarui satu baris router civic_* pada index.php. Ambil hanya patch router dari diff, jangan ganti file index.php produksi bila versi cPanel lebih baru.
5. Pastikan penugasan petugas dilakukan melalui ADMIN resmi (bukan dari permintaan aplikasi):
   - Ketua RT: civic_officers.duty='rt', wilayah RT dan RW, akun portal_users.role='rt'.
   - Bendahara RT: duty='bendahara_rt', RT dan RW yang sama, role='rt'.
   - Ketua RW: duty='rw', wilayah RW, role='rw'.
   - Bendahara RW: duty='bendahara_rw', RW yang sama, role='rw'.
   - LMK: portal_users.role='lmk', profil RW ditetapkan admin (atau civic_officers.duty='lmk').
   - Jangan memasukkan kredensial, PIN, NIK atau gambar tanda tangan ke SQL / GitHub.
6. Sebelum uji tanda tangan: buka LPJ dari masing-masing akun berwenang, pilih 'Atur/Ganti PIN', masukkan password akun, lalu PIN baru 6 angka.
7. Uji dengan satu bulan dan rekening contoh TERPISAH pada staging untuk setiap jenis:
   - Bendahara RT -> create -> approve PIN -> Ketua RT approve PIN -> PDF.
   - Bendahara RW -> create -> approve PIN -> Ketua RW approve PIN -> PDF.
   - LMK A dan B -> create -> approve PIN -> PDF.
   - Return -> resubmit -> revisi naik -> persetujuan sebelumnya tidak berlaku pada revisi baru.
   - Cross-area access/view/PDF/approve harus ditolak.
8. Setelah QA staging dan persetujuan, barulah rencanakan deploy produksi dan AAB Play Store. Jangan merge PR draft sebelum tes end-to-end.

## PENTING untuk pengguna
- Flutter belum otomatis terbarui melalui Play Store. Backend di GitHub belum otomatis disalin ke cPanel.
- Migrasi database lama civic_* milik Anda tetap ada dan tidak dikonversi otomatis; versi ini menggunakan tabel baru cikoko_lpj_* supaya tidak menyentuh modul aktif.
- Kunci Firebase/keystore tidak diperlukan oleh migrasi LPJ ini.
- Jika akun petugas belum diatur, scope null dan form tidak dapat dikirim, sebagai pengaman.
- Tanda tangan PIN di sini hanyalah persetujuan internal yang tercatat dengan hash payload, belum TTE tersertifikasi PSrE.
- Kewenangan penandatangan dan standar penggunaan stempel harus divalidasi dengan kebijakan Kelurahan sebelum PDF dipakai resmi.

## Rollback
Sebelum ada dokumen baru, kembalikan routing index.php dan file backend. Jangan DROP tabel lama/baru tanpa inventarisasi data; tabel baru menyimpan audit dan revisi yang wajib dipertahankan.
