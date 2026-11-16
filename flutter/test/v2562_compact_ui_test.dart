import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/cikoko_v6_showcase.dart';
import 'package:cikoko/cikoko_v6_content.dart';
import 'package:cikoko/cikoko_home_sections.dart';

void main() {
 testWidgets('v2562 hero opens the existing public service route', (tester) async {
  String? destination;
  await tester.pumpWidget(MaterialApp(home:Scaffold(body:V6Hero(
    onServices:()=>destination='Layanan Online',
    onAbout:()=>destination='Tentang Kami',
  ))));
  expect(find.byKey(const Key('v2562_compact_hero')),findsOneWidget);
  expect(find.text('Cikoko Smart'),findsOneWidget);
  await tester.tap(find.text('Ajukan Layanan  →'));
  expect(destination,'Layanan Online');
 });

 testWidgets('v2562 compact quick actions open real routes', (tester) async {
  String? destination;
  await tester.pumpWidget(MaterialApp(home:Scaffold(body:Center(
   child:V6QuickActions(navigate:(route)=>destination=route)
  ))));
  expect(find.byKey(const Key('v2562_quick_actions')),findsOneWidget);
  for(var i=0;i<4;i++){
   expect(find.byKey(Key('v2562_quick_$i')),findsOneWidget);
  }
  await tester.tap(find.byKey(const Key('v2562_quick_1')));
  expect(destination,'Riwayat');
  await tester.tap(find.byKey(const Key('v2562_quick_2')));
  expect(destination,'Notifikasi');
 });

 testWidgets('v2562 service search filters existing enabled routes', (tester) async {
  String? destination;
  await tester.pumpWidget(MaterialApp(home:Scaffold(body:
   V6ServicesPage(guest:false,onOpen:(route)=>destination=route)
  )));
  expect(find.byKey(const Key('v2562_services_header')),findsOneWidget);
  await tester.enterText(find.byKey(const Key('v2562_service_search')),'Jumantik');
  await tester.pump();
  expect(find.text('Laporan Jumantik'),findsOneWidget);
  expect(find.text('Pengantar RT/RW'),findsNothing);
  await tester.tap(find.text('Laporan Jumantik'));
  expect(destination,'Laporan Jumantik');
 });

 testWidgets('v2562 letter status cards show API counts and keep callbacks', (tester) async {
  String? status;
  await tester.pumpWidget(MaterialApp(home:Scaffold(body:
   V6LetterStatusStrip(counts:const {'masuk':1,'proses':2,'selesai':29},
    onStatus:(value)=>status=value)
  )));
  expect(find.text('29'),findsOneWidget);
  await tester.tap(find.byKey(const Key('v6_status_selesai')));
  expect(status,'selesai');
 });
}
