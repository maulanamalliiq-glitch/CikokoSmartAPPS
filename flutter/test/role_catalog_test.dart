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
 test('Admin Utama mendapat pengelolaan hak akses', () {
   final modules=modulesForRole('admin',{'role:manage':true});
   expect(modules.any((f)=>f.route=='Hak Akses Role'),isTrue);
 });
}
