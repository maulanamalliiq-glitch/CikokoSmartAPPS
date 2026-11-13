import 'package:cikoko/cikoko_admin_content_hub.dart';
import 'package:cikoko/cikoko_header_editor.dart';
import 'package:cikoko/api.dart';
import 'package:cikoko/role_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main(){
 testWidgets('Admin bottom navigation exposes central edit controls and Beranda centered',
   (tester)async{
    int? selected;
    await tester.pumpWidget(MaterialApp(home:Scaffold(
     bottomNavigationBar:CikokoAdminBottomNav(
       selected:2,onSelected:(v)=>selected=v))));
    expect(find.text('Kelola'),findsOneWidget);
    expect(find.text('Layanan'),findsOneWidget);
    expect(find.text('Beranda'),findsOneWidget);
    expect(find.text('Laporan'),findsOneWidget);
    expect(find.text('Akun'),findsOneWidget);
    final second=tester.getCenter(find.byKey(const Key('admin_nav_1')));
    final middle=tester.getCenter(find.byKey(const Key('admin_nav_2')));
    final fourth=tester.getCenter(find.byKey(const Key('admin_nav_3')));
    expect((middle.dx-second.dx).abs(),closeTo((fourth.dx-middle.dx).abs(),1));
    await tester.tap(find.byKey(const Key('admin_nav_0')));
    expect(selected,0);
 });
 testWidgets('Admin page hub provides actual CMS editor destinations',(tester)async{
   await tester.pumpWidget(MaterialApp(home:Scaffold(
    body:CikokoAdminContentHub(api:CikokoApi(),role:'admin',openInApp:(_){ }))));
   expect(find.text('Kelola Semua Halaman'),findsOneWidget);
   expect(find.text('Ganti Foto Header'),findsOneWidget);
   expect(find.byKey(const Key('cms_beranda-aplikasi')),findsOneWidget);
   expect(find.text('Tampilan Website'),findsOneWidget);
 });
 testWidgets('Header editor opens natively without browser',(tester)async{
   await tester.pumpWidget(MaterialApp(home:Scaffold(
     body:CikokoAdminContentHub(api:_FakeCmsApi(),
       role:'admin',openInApp:(_){ }))));
   await tester.ensureVisible(find.byKey(const Key('cms_beranda-aplikasi')));
   await tester.pumpAndSettle();
   await tester.tap(find.byKey(const Key('cms_beranda-aplikasi')));
   await tester.pumpAndSettle();
   expect(find.byType(CikokoHomeSlidesEditor),findsOneWidget);
   expect(find.text('Ganti Foto Header'),findsWidgets);
 });
 testWidgets('Non-administrator does not receive editor controls',(tester)async{
   await tester.pumpWidget(MaterialApp(home:Scaffold(
    body:CikokoAdminContentHub(api:CikokoApi(),role:'warga',openInApp:(_){ }))));
   expect(find.text('Pengaturan halaman hanya tersedia untuk administrator.'),findsOneWidget);
   expect(find.byKey(const Key('cms_beranda-aplikasi')),findsNothing);
 });
 test('Both administrator roles expose page management module when permitted',(){
  for(final role in ['admin','admin_kelurahan']){
   final modules=modulesForRole(role,{
    'content:create':true,
   });
   expect(modules.any((m)=>m.route=='Kelola Semua Halaman'),isTrue);
  }
 });
}

class _FakeCmsApi extends CikokoApi {
  @override
  Future<Map<String,dynamic>> call(String action,
      {Map<String,dynamic>? body,bool authorized=false}) async {
    if(action=='home_slides')return {'ok':true,'slides':[]};
    return {'ok':true};
  }
}
