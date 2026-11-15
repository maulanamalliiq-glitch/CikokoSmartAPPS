# Rilis Cikoko v2.5.57 (2557)

Gunakan aplikasi Android yang sama dengan v2.5.56 (2556). Package ID adalah `com.KelurahanCikoko.malik`. Workflow Android v2557 memeriksa fingerprint upload key yang digunakan workflow 2556 dan mengunggah APK arm64 serta AAB sebagai artefak.

## cPanel

1. Cadangkan basis data dan berkas mobile API di staging. Konfirmasi tabel profil pegawai dan hari libur dari `migrate_pjlp_leave.sql` tersedia, lalu impor `migrate_pjlp_2557.sql`. Gunakan skema ini untuk instalasi pertama modul 2557. Jika sebelumnya sudah memasang skema dari ZIP pengembangan, siapkan migrasi data dari skema lama sebelum mengganti handler.
2. Pasang `cpanel/mobile-api/pjlp_attendance_2557.php` dan integrasikan rute 2557 sebelum dispatcher cuti PJLP di `cpanel/mobile-api/index.php`. Pertahankan perubahan khusus pada salinan server.
3. Masuk sebagai Admin Utama untuk memasukkan koordinat kantor, radius GPS, dan mengesahkan bobot penilaian. Pakai data profil PJLP yang sudah memiliki ASN pembina di modul cuti.
4. Gunakan satu akun PJLP, ASN pembina, dan Admin Utama untuk uji absensi masuk/pulang, akses foto, urutan bukti 0/50/100, pembatasan ASN, pengesahan bulan yang sudah berakhir, dan pengunduhan PDF per pegawai.
5. Uji pembaruan 2556 ke 2557 melalui Play Internal Testing. Periksa login yang sudah tersimpan, QR pimpinan, notifikasi, dan fitur 2557 sebelum peluncuran produksi.

Penilaian menggunakan hari dengan pasangan masuk/pulang, pekerjaan selesai, dan kelengkapan bukti. Hari libur dari kalender PJLP dikeluarkan dari perhitungan. Periode resmi memakai bobot yang tercatat ketika Admin Utama mengesahkannya. PDF memakai snapshot rekap yang disahkan. Foto disimpan dalam tabel dan hanya dapat diminta melalui API dengan akun yang berwenang.
