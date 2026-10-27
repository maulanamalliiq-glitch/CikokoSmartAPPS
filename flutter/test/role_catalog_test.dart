import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/role_catalog.dart';

void main() {
 test('Seluruh role memiliki menu utama', () {
   for (final role in roleNames.keys) {
     expect(roleMenus.containsKey(role),isTrue,reason:role);
     expect(roleMenus[role],isNotEmpty);
   }
 });
 test('Warga tidak melihat menu verifikasi dan administrasi', () {
   final caps={'waris:create':true,'report:jumantik':true};
   final modules=modulesForRole('warga',caps);
   expect(modules.any((f)=>f.route=='Surat Ahli Waris'),isTrue);
   expect(modules.any((f)=>f.route=='Verifikasi Laporan'),isFalse);
   expect(modules.any((f)=>f.route=='Tambah Berita'),isFalse);
 });
 test('Izin kosong menyembunyikan menu sensitif', () {
   final modules=modulesForRole('admin_kelurahan',{});
   expect(modules.any((f)=>f.route=='Tambah Arsip Ahli Waris'),isFalse);
   expect(modules.any((f)=>f.route=='Pesan Masuk'),isFalse);
 });
 test('Warga hanya melihat pengajuan, bukan inbox atau kelola wilayah petugas', () {
   final modules=modulesForRole('warga',{'waris:create':true});
   expect(modules.any((f)=>f.route=='Surat Pengantar RT/RW'),isTrue);
   expect(modules.any((f)=>f.route=='Surat Wilayah'),isFalse);
   expect(modules.any((f)=>f.route=='Wilayah Ketua RT/RW'),isFalse);
 });
 test('Hanya Admin Utama dengan izin dapat mengakses penugasan petugas', () {
   expect(modulesForRole('admin',{'role:manage':true}).any((f)=>f.route=='Wilayah Ketua RT/RW'),isTrue);
   expect(modulesForRole('admin_kelurahan',{}).any((f)=>f.route=='Wilayah Ketua RT/RW'),isFalse);
 });
 test('Admin Utama mendapat pengelolaan hak akses', () {
   final modules=modulesForRole('admin',{'role:manage':true});
   expect(modules.any((f)=>f.route=='Hak Akses Role'),isTrue);
 });
 test('RT RW dan LMK mendapat LPJ sesuai role tanpa menu kegiatan lama', () {
   final rt=modulesForRole('rt',{});
   final rw=modulesForRole('rw',{});
   final lmk=modulesForRole('lmk',{});
   expect(rt.any((f)=>f.route=='Laporan LPJ RT'),isTrue);
   expect(rt.any((f)=>f.route=='Laporan LPJ RW'),isFalse);
   expect(rw.any((f)=>f.route=='Laporan LPJ RW'),isTrue);
   expect(rw.any((f)=>f.route=='Laporan LPJ RT'),isFalse);
   expect(lmk.where((f)=>f.route=='Laporan LPJ LMK').length,1);
   for (final menus in [rt,rw,lmk]) {
     expect(menus.any((f)=>f.route=='Laporan Kegiatan'),isFalse);
   }
   expect(modulesForRole('pppk',{'report:kegiatan':true}).any((f)=>f.route=='Laporan Kegiatan'),isTrue);
 });

}
