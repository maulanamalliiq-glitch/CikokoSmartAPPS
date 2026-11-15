# Integrasi release 2557 ke aplikasi versi 2556

Dokumen ini adalah patch plan, bukan bukti bahwa build sudah berhasil.

## Navigasi Flutter
Di `flutter/lib/main.dart`, tambahkan:
```dart
import 'cikoko_pjlp_2557_page.dart';
```
Dalam `_page()`, sebelum `case 'Kinerja PPPK':`:
```dart
case 'PJLP 2557':
  return CikokoPjlp2557Page(api: api, role: role);
```

Di `flutter/lib/role_catalog.dart`, tambahkan fitur:
```dart
'pjlp_2557': RoleFeature('PJLP 2557','Absensi, pekerjaan dan monitoring','PJLP 2557'),
```
Tambahkan `pjlp_2557` ke menu role `pjlp`, `asn`, dan `admin`.
Halaman PJLP/ASN yang telah dibuat masih read-only. Jangan aktifkan absensi
atau persetujuan nilai sebelum validasi PHP API diterapkan.

## Workflow
Salin workflow v2556 ke `.github/workflows/android-v2557-firebase.yml`.
Ubah trigger branch ke `feat/pjlp-attendance-2557`, versi Android ke
`2557`, nama file keluaran ke `v2.5.57-2557`, dan tambahkan
`flutter test` setelah `flutter pub get`.
Pertahankan pemeriksaan sertifikat dan secret signing yang sama dengan v2556.

## API yang belum tersedia
`pjlp_self_dashboard` dan `pjlp_monitor_dashboard` adalah kontrak
yang dibutuhkan halaman baru, bukan endpoint yang telah diverifikasi.
Jangan menandai fitur produksi aktif sebelum server mendukungnya.

## Kriteria penerimaan
- Flutter analyze/test/build lulus di GitHub Actions.
- APK/AAB ditandatangani sertifikat v2556.
- Uji update terpasang di atas v2556 tanpa menghapus data.
- Uji role PJLP, ASN dan admin terhadap server sungguhan.
- Uji GPS, selfie, jadwal Rabu, audit, dan PDF setelah API terpasang.
