import 'package:cikoko/api.dart';
import 'package:cikoko/cikoko_admin_push_page.dart';
import 'package:cikoko/cikoko_admin_content_hub.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdminApi extends CikokoApi{
 Map<String,dynamic>? sent;
 @override Future<Map<String,dynamic>> call(String action,
  {Map<String,dynamic>? body,bool authorized=false}) async {
   switch(action){
    case 'admin_push_diagnostics':
     return {'ok':true,'devices':0,'pending_events':19,'last_fcm_accepted':0,
        'status':'fcm_key_missing','cron_active':true,
        'last_run_at':'2026-11-12 10:00:00','hint':'Firebase belum aktif'};
    case 'admin_push_accounts':
     return {'ok':true,'items':[
       {'id':'admin','name':'Admin Kelurahan','role':'admin'},
       {'id':'warga1','name':'Warga Uji','role':'warga'}]};
    case 'admin_push_send':
     sent=body;
     return {'ok':true,'recipient_count':2,'already_sent':false};
    default:return {'ok':true};
   }
  }
}
void main(){
 testWidgets('Admin has a direct in-app Push Notifikasi menu',(tester)async{
  String? route;
  await tester.pumpWidget(MaterialApp(home:Scaffold(body:
    CikokoAdminContentHub(role:'admin',openInApp:(v)=>route=v))));
  await tester.tap(find.byKey(const Key('admin_push_menu')));
  expect(route,'Push Notifikasi');
 });
 testWidgets('Warga cannot see admin push menu',(tester)async{
  await tester.pumpWidget(MaterialApp(home:Scaffold(body:
   CikokoAdminContentHub(role:'warga',openInApp:(_){ }))));
  expect(find.byKey(const Key('admin_push_menu')),findsNothing);
 });
 testWidgets('Push screen distinguishes stored inbox from delivered FCM',(tester)async{
  final api=_FakeAdminApi();
  await tester.pumpWidget(MaterialApp(home:Scaffold(body:CikokoAdminPushPage(api:api))));
  await tester.pumpAndSettle();
  expect(find.text('Push Notifikasi'),findsOneWidget);
  expect(find.text('fcm_key_missing',findRichText:true),findsWidgets);
  expect(find.text('Kirim Notifikasi'),findsOneWidget);
  expect(find.textContaining('Berhasil menyimpan bukan berarti push',findRichText:true),findsOneWidget);
 });
 testWidgets('Admin send requires confirmation and uses backend endpoint',(tester)async{
  final api=_FakeAdminApi();
  await tester.pumpWidget(MaterialApp(home:Scaffold(body:CikokoAdminPushPage(api:api))));
  await tester.pumpAndSettle();
  final fields=find.byType(TextFormField);
  await tester.enterText(fields.at(0),'Pengumuman Cikoko');
  await tester.enterText(fields.at(1),'Informasi layanan warga dari Kelurahan Cikoko.');
  final send=find.widgetWithText(FilledButton,'Kirim Notifikasi');
  await tester.ensureVisible(send);
  await tester.pumpAndSettle();
  await tester.tap(send);
  await tester.pumpAndSettle();
  expect(api.sent,isNull);
  final checkbox=find.byType(CheckboxListTile);
  await tester.ensureVisible(checkbox);
  await tester.pumpAndSettle();
  await tester.tap(checkbox);
  await tester.pumpAndSettle();
  await tester.ensureVisible(send);
  await tester.pumpAndSettle();
  await tester.tap(send);
  await tester.pumpAndSettle();
  expect(find.text('Konfirmasi Pengiriman'),findsOneWidget);
  await tester.tap(find.widgetWithText(FilledButton,'Kirim').last);
  await tester.pumpAndSettle();
  expect(api.sent?['scope'],'public');
  expect(api.sent?['category'],'info_aplikasi');
  expect(api.sent?['confirmed'],true);
  expect((api.sent?['request_id']??'').toString().length,32);
 });
}
