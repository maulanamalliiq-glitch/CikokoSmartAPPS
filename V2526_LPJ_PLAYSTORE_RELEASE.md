# Cikoko SmartApp 2.5.26 (2526) — Kandidat Uji LPJ Play Store

## Identitas aplikasi
- Package tetap: `com.KelurahanCikoko.malik`
- versionCode: `2526`; versionName: `2.5.26`
- Target Android SDK: 36; minSdk 24
- Sumber: `feat/v2513-lpj-backend-20261027`, sudah mencakup perbaikan versi 2525 dan Flutter LPJ role-based.

## Menu
- RT: Laporan LPJ RT (bukan Laporan Kegiatan).
- RW: Laporan LPJ RW (bukan Laporan Kegiatan).
- LMK: Laporan LPJ LMK dengan Modul A dan Modul B.
- Akun lain: menu kegiatannya tetap sesuai role.
- LPJ memerlukan backend `civic_*`, penugasan petugas, dan PIN persetujuan yang benar.

## Keamanan build
- GitHub Actions menghentikan proses jika keystore atau password penandatanganan tidak tersedia/tidak sesuai.
- AAB dan APK wajib lolos pengecekan signature sebelum ditaruh di **draft privat** GitHub Release.
- Tidak ada AAB unsigned yang disediakan sebagai paket Play Store.
- Tidak ada layanan otomatis yang mengunggah ke Google Play atau menerbitkan ke Production.

## Sebelum distribusi
1. Cocokkan fingerprint SHA-256 sertifikat **upload key** pada `UPLOAD_CERT_SHA256.txt` dengan Play Console > App integrity.
2. Pastikan `civic_lpj_v2513.php` dan router API LPJ versi valid sudah deploy di cPanel; hasil sintaks PHP saja tidak membuktikan end-to-end.
3. Pastikan 4 tabel `cikoko_lpj_*` sudah dibuat, penugasan RT/RW/LMK dan hak akses benar; simpan audit. Jangan mengubah data produksi secara otomatis.
4. Uji RT (Bendahara/Ketua), RW (Bendahara/Ketua), LMK A dan B: buat LPJ, kirim, set PIN, setujui, kembalikan/revisi, dan PDF. Verifikasi akses lintas wilayah ditolak.
5. Upload AAB ke **Internal testing** Google Play dahulu. Periksa masalah UI, koneksi API dan signing. Baru pertimbangkan Production.
6. Jangan memasang APK debug di atas aplikasi Play Store; gunakan track testing untuk pembaruan resmi.

Catatan: PDF/PIN LPJ merupakan persetujuan internal, bukan tanda tangan elektronik tersertifikasi.
