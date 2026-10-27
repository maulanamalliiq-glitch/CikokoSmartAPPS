// Cikoko v205: katalog tampilan role. Izin final selalu divalidasi oleh PHP API.
class RoleFeature {
  final String title, description, route;
  final String? capability;
  final bool connected;
  const RoleFeature(this.title, this.description, this.route, {this.capability, this.connected = true});
}
const roleNames = <String,String>{
  'admin': 'Admin Utama', 'admin_kelurahan': 'Admin Kelurahan',
  'lurah': 'Lurah', 'asn': 'ASN / PNS', 'pppk': 'PPPK', 'pjlp': 'PJLP',
  'ptsp': 'PTSP', 'dukcapil': 'Dukcapil', 'rt': 'RT', 'rw': 'RW',
  'fkdm': 'FKDM', 'lmk': 'LMK', 'jumantik_rt': 'Jumantik RT',
  'jumantik_rw': 'Jumantik RW', 'dasawisma': 'Dasawisma', 'pkk': 'PKK',
  'posyandu': 'Posyandu', 'ppsu': 'PPSU', 'warga': 'Warga',
};
const roleFeatures = <String,RoleFeature>{
  'news': RoleFeature('Berita & Kegiatan','Informasi dan kegiatan kelurahan','Berita & Kegiatan'),
  'announcements': RoleFeature('Pengumuman','Informasi resmi pelayanan dan warga','Pengumuman'),
  'services': RoleFeature('Layanan Masyarakat','Pilih pelayanan yang dibutuhkan','Layanan Online'),
  'gallery': RoleFeature('Galeri','Dokumentasi kegiatan Cikoko','Galeri'),
  'waris': RoleFeature('Surat Ahli Waris','Ajukan surat secara daring','Surat Ahli Waris',capability:'waris:create'),
  'surat_pengantar': RoleFeature('Surat Pengantar RT/RW','Pengajuan otomatis sesuai RT/RW profil','Surat Pengantar RT/RW'),
  'ttd_stempel': RoleFeature('TTD & Stempel','Unggah tanda tangan dan cap petugas yang berwenang','TTD & Stempel'),
  'surat_wilayah': RoleFeature('Surat Wilayah','Verifikasi permohonan dari wilayah tugas','Surat Wilayah'),
  'wilayah_ketua': RoleFeature('Wilayah Ketua RT/RW','Tetapkan wilayah akun Ketua RT/RW resmi','Wilayah Ketua RT/RW',capability:'role:manage'),
  'history': RoleFeature('Riwayat Pengajuan','Status surat dan laporan Anda','Riwayat'),
  'jumantik': RoleFeature('Laporan Jumantik','Upload foto pemeriksaan lingkungan','Laporan Jumantik',capability:'report:jumantik'),
  'kegiatan': RoleFeature('Laporan Kegiatan','Kirim laporan dan foto kegiatan','Laporan Kegiatan',capability:'report:kegiatan'),
  'lpj_rt': RoleFeature('Laporan LPJ RT','Keuangan, persetujuan Ketua dan Bendahara RT','Laporan LPJ RT'),
  'lpj_rw': RoleFeature('Laporan LPJ RW','Keuangan, persetujuan Ketua dan Bendahara RW','Laporan LPJ RW'),
  'lpj_lmk': RoleFeature('Laporan LPJ LMK','Dua pilihan: LPJ LMK Modul A dan Modul B','Laporan LPJ LMK'),
  'fkdm': RoleFeature('Laporan FKDM','Kewaspadaan dini dan dokumentasi','Laporan FKDM',capability:'report:fkdm'),
  'lmk': RoleFeature('Laporan LMK','Musyawarah dan aspirasi warga','Laporan LMK',capability:'report:lmk'),
  'posyandu': RoleFeature('Laporan Posyandu','Dokumentasi kegiatan pelayanan','Laporan Posyandu',capability:'report:posyandu'),
  'dasawisma': RoleFeature('Laporan Dasawisma','Kegiatan dan pendataan keluarga','Laporan Dasawisma',capability:'report:pkk'),
  'ppsu': RoleFeature('Laporan PPSU','Foto kegiatan kebersihan dan pekerjaan','Laporan PPSU',capability:'report:ppsu'),
  'bakti': RoleFeature('Kerja Bakti','Dokumentasi kerja bakti wilayah','Laporan Kerja Bakti',capability:'report:kerja_bakti'),
  'verify': RoleFeature('Verifikasi Laporan','Tinjau dan ubah status permohonan','Verifikasi Laporan',capability:'reports:view'),
  'chat_admin': RoleFeature('Pesan Masuk','Balas percakapan warga','Pesan Masuk',capability:'chat:reply'),
  'news_add': RoleFeature('Tambah Berita','Publikasikan berita dari aplikasi','Tambah Berita',capability:'content:create'),
  'announce_add': RoleFeature('Tambah Pengumuman','Publikasikan pengumuman baru','Tambah Pengumuman',capability:'content:create'),
  'archive_add': RoleFeature('Tambah Arsip Ahli Waris','Catat nomor dan tahun surat lama','Tambah Arsip Ahli Waris',capability:'archive:create'),
  'archive_list': RoleFeature('Arsip Ahli Waris','Cari arsip tahun sebelumnya','Arsip Ahli Waris',capability:'archive:view'),
  'role_manage': RoleFeature('Hak Akses Role','Izinkan atau batasi akses petugas','Hak Akses Role',capability:'role:manage'),
  'monitor': RoleFeature('Monitoring Wilayah','Ringkasan seluruh laporan wilayah','Monitoring Wilayah',connected:false),
  'approval': RoleFeature('Persetujuan Lurah','Persetujuan dokumen resmi','Persetujuan Lurah',connected:false),
  'attendance': RoleFeature('Kehadiran','Absensi pegawai dan jadwal','Kehadiran',connected:false),
  'roster': RoleFeature('Jadwal Piket & Dinas','Jadwal tugas harian pegawai','Jadwal Piket',connected:false),
  'performance': RoleFeature('Kinerja Bulanan','Rekap kinerja PJLP / PPPK','Kinerja',connected:false),
  'leave': RoleFeature('Cuti Pegawai','Pengajuan dan rekap cuti','Cuti',connected:false),
  'protap': RoleFeature('PROTAP','Verifikasi pengaturan lampu piket','PROTAP',connected:false),
  'civil': RoleFeature('KTP & Kartu Keluarga','Layanan adminduk melalui petugas','Kependudukan',connected:false),
  'family': RoleFeature('Pendataan Keluarga','Pendataan Dasawisma wilayah','Pendataan Keluarga',connected:false),
  'profile': RoleFeature('Profil Akun','Identitas dan data akun','Profil'),
};
const roleMenus = <String,List<String>>{
 'admin':['wilayah_ketua','surat_wilayah','verify','chat_admin','news_add','announce_add','archive_add','archive_list','role_manage','news','announcements','gallery','services'],
 'admin_kelurahan':['surat_wilayah','verify','archive_add','archive_list','news_add','announce_add','chat_admin','news','announcements','services'],
 'lurah':['verify','archive_list','approval','monitor','protap','performance','news','announcements'],
 'asn':['verify','archive_list','monitor','kegiatan','news','announcements'],
 'pppk':['kegiatan','attendance','roster','performance','leave','history','news'],
 'pjlp':['kegiatan','attendance','roster','performance','protap','leave','history'],
 'ptsp':['verify','archive_list','civil','kegiatan','history','services'],
 'dukcapil':['civil','kegiatan','history','services','announcements'],
 'rt':['ttd_stempel','surat_wilayah','lpj_rt','bakti','jumantik','history','news','announcements'],
 'rw':['ttd_stempel','surat_wilayah','lpj_rw','bakti','monitor','history','news','announcements'],
 'fkdm':['fkdm','kegiatan','history','news','announcements'],
 'lmk':['ttd_stempel','lpj_lmk','history','news','announcements'],
 'jumantik_rt':['jumantik','history','news','announcements'],
 'jumantik_rw':['jumantik','monitor','history','news','announcements'],
 'dasawisma':['dasawisma','family','history','announcements'],
 'pkk':['dasawisma','history','announcements'],
 'posyandu':['posyandu','kegiatan','history','news','announcements'],
 'ppsu':['ppsu','bakti','kegiatan','history','news','announcements'],
 'warga':['surat_pengantar','services','waris','jumantik','history','news','announcements','gallery'],
};
List<RoleFeature> modulesForRole(String role, Map<String,bool> caps) {
 return (roleMenus[role]??roleMenus['warga']!).map((key)=>roleFeatures[key]!).where((feature)=>feature.capability==null || caps[feature.capability]==true).toList();
}
