import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/api.dart';
import 'package:cikoko/public_letters.dart';
import 'package:cikoko/role_catalog.dart';

class FakeStatusApi extends CikokoApi {
 @override
 Future<Map<String,dynamic>> call(String action,{Map<String,dynamic>? body,bool authorized=false})async {
  if(action!='public_letter_status')throw StateError('Read-only test.');
  return {'ok':true,'counts':{'masuk':2,'proses':3,'selesai':4},'items':[]};
 }
}

void main(){
 test('Menu Admin Utama memisahkan Ahli Waris dan Laporan Kegiatan',(){
  final menu=roleMenus['admin']!;
  final waris=menu.indexOf('verify_waris');
  expect(waris,greaterThanOrEqualTo(0));
  expect(menu[waris+1],'verify_kegiatan');
  expect(menu.contains('verify'),isFalse);
  expect(roleFeatures['verify_waris']!.route,'Verifikasi Ahli Waris');
  expect(roleFeatures['verify_kegiatan']!.title,'Laporan Kegiatan');
  expect(roleMenus['asn'],contains('verify'));
  expect(roleMenus['warga'],contains('waris'));
 });
 testWidgets('Pie lightbox memuat 3 warna dan jumlah dari API publik',(tester)async{
  final api=FakeStatusApi();
  await tester.pumpWidget(MaterialApp(home:Scaffold(body:Builder(builder:(context)=>
    TextButton(onPressed:()=>showPublicLetterPie(context,api),child:const Text('Buka Status'))))));
  await tester.tap(find.text('Buka Status'));
  await tester.pumpAndSettle();
  expect(find.text('Status Pelayanan Surat'),findsOneWidget);
  expect(find.text('Total Surat'),findsOneWidget);
  expect(find.text('9'),findsOneWidget);
  expect(find.text('Surat Masuk'),findsOneWidget);
  expect(find.text('Diproses'),findsOneWidget);
  expect(find.text('Selesai'),findsOneWidget);
  expect(find.text('2'),findsOneWidget);
  expect(find.text('3'),findsOneWidget);
  expect(find.text('4'),findsOneWidget);
 });
}
