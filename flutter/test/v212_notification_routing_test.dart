import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/push.dart';
void main(){
 test('chat notification opens a conversation directly',(){
  expect(destinationForPushCategory('chat',isStaff:false),'Hubungi Kami');
  expect(destinationForPushCategory('chat',isStaff:true),'Pesan Masuk');
 });
 test('letter update navigates to user tracking',(){
  expect(destinationForPushCategory('surat',isStaff:false),'Riwayat');
  expect(destinationForPushCategory('progres_surat',isStaff:true),'Verifikasi Laporan');
  expect(destinationForPushCategory('pengumuman',isStaff:false),'Pengumuman');
  expect(destinationForPushCategory('berita',isStaff:false),'Berita & Kegiatan');
  expect(destinationForPushCategory('inovasi',isStaff:true),'Inovasi');
 });
}
