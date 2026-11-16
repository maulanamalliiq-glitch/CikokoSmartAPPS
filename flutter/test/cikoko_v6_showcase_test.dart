import 'package:cikoko/api.dart';
import 'package:cikoko/cikoko_v6_showcase.dart';
import 'package:cikoko/cikoko_v6_content.dart';
import 'package:cikoko/role_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main(){
 testWidgets('v2562: 5-tab nav Layanan Inovasi Beranda Chat Akun, Beranda centered',
  (tester)async{
  int? chosen;
  await tester.pumpWidget(MaterialApp(home:Scaffold(
    bottomNavigationBar:V6BottomNavigation(selected:2,onSelected:(n)=>chosen=n))));
  // These labels are the actual v2562 navigation contract, not legacy V4 labels.
  for(final label in const ['Layanan','Inovasi','Beranda','Chat','Akun']){
    expect(find.text(label),findsOneWidget);
  }
  expect(find.byKey(const Key('v6_nav_0')),findsOneWidget);
  expect(find.byKey(const Key('v6_nav_4')),findsOneWidget);
  final l=tester.getCenter(find.byKey(const Key('v6_nav_1')));
  final h=tester.getCenter(find.byKey(const Key('v6_nav_2')));
  final r=tester.getCenter(find.byKey(const Key('v6_nav_3')));
  expect((h.dx-l.dx).abs(),closeTo((r.dx-h.dx).abs(),1));
  await tester.tap(find.byKey(const Key('v6_nav_4')));
  expect(chosen,4);
 });
 testWidgets('V4 showcase hero uses office image and compact services CTA',
  (tester)async{
  await tester.pumpWidget(MaterialApp(home:Scaffold(body:
    V6Hero(onServices:(){},onAbout:(){}))));
  expect(find.text('Cikoko Smart'),findsOneWidget);
  expect(find.text('Ajukan Layanan  →'),findsOneWidget);
  expect(find.text('Lihat Profil Kelurahan  →'),findsOneWidget);
  expect(find.byType(Image),findsWidgets);
 });
 testWidgets('Reports appear before citizen services and contain live status',
  (tester)async{
  await tester.pumpWidget(MaterialApp(home:Scaffold(body:
    SingleChildScrollView(child:Column(children:[
      V6ReportPanel(role:'warga',guest:false,
       modules:const <RoleFeature>[],letterCounts:const {
        'masuk':1,'proses':0,'selesai':29},
       navigate:(_){},letterStatus:(_){ }),
      V6CitizenServices(navigate:(_){ }),
    ])))));
  expect(tester.getTopLeft(find.text('Laporan Terpadu')).dy,
   lessThan(tester.getTopLeft(find.text('Layanan Masyarakat')).dy));
  expect(find.text('Status Pelayanan Surat'),findsOneWidget);
  expect(find.text('29'),findsOneWidget);
 });
 testWidgets('Services screen opens existing RT/RW route',
  (tester)async{
   String? path;
   await tester.pumpWidget(MaterialApp(home:Scaffold(body:
     V6ServicesPage(guest:false,onOpen:(p)=>path=p))));
   await tester.tap(find.text('Pengantar RT/RW'));
   expect(path,'Surat Pengantar RT/RW');
 });
 testWidgets('News shows empty state without fake articles',
  (tester)async{
   await tester.pumpWidget(MaterialApp(home:Scaffold(body:
     V6NewsPage(api:CikokoApi(),content:const [],onOpen:(_){ }))));
   expect(find.text('Belum ada publikasi yang sesuai.'),findsOneWidget);
 });
}
