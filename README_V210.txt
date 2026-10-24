CIKOKO v210 — WEBSITE-STYLE FLUTTER NATIVE

Identitas:
- Nama aplikasi: Cikoko
- Package: com.KelurahanCikoko.malik
- versionCode: 210
- Android target API: 36

Perubahan desain:
- Banner Kantor Kelurahan Cikoko mengikuti website, tanpa ucapan sambutan pribadi besar.
- Enam kategori layanan website dipetakan ke navigasi Flutter native.
- Menu cepat berupa kartu 2 kolom, status surat berdasarkan API, berita ringkas dengan foto.
- AppBar memakai logo dan identitas Kelurahan Cikoko.
- Modul login, form surat, laporan, notifikasi, chat, dan semua role tetap dipertahankan.

Paket:
- AAB release untuk Play Store: seluruh ABI disiapkan Google Play (setelah signed).
- APK ARM64 untuk HP modern: lebih ringan daripada universal, tidak kompatibel dengan HP ARM32/x86 saja.
- Signing key dan password tidak boleh dimasukkan ke repository GitHub.

Pengujian:
- Pastikan build dan flutter test lulus.
- Uji navigasi tanpa login, login multi-role, formulir Ahli Waris, lampiran, histori, perbaikan dokumen, chat, dan FCM.
- AAB signed tidak otomatis membuktikan Play Console menerima rilis; uji internal dahulu.
