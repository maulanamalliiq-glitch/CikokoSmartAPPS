import 'package:cikoko/cikoko_v4_public_pages.dart';
import 'package:cikoko/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main(){
 testWidgets('V4 services expose actual route names', (tester)async{
  String? opened;
  await tester.pumpWidget(MaterialApp(home:Scaffold(body:
    CikokoV4Services(guest:true,navigate:(route)=>opened=route))));
  expect(find.text('Layanan Online'),findsWidgets);
  await tester.tap(find.text('Pengantar RT/RW'));
  expect(opened,'Surat Pengantar RT/RW');
 });
 testWidgets('V4 agenda never invents calendar events', (tester)async{
  await tester.pumpWidget(const MaterialApp(home:Scaffold(body:
    CikokoV4Agenda(content:[]))));
  expect(find.text('Belum ada agenda yang dipublikasikan.'),findsOneWidget);
 });
 testWidgets('V4 gallery renders empty state without photos', (tester)async{
  await tester.pumpWidget(MaterialApp(home:Scaffold(body:
    CikokoV4Gallery(content:const [],api:CikokoApi()))));
  expect(find.text('Belum ada dokumentasi kegiatan.'),findsOneWidget);
 });
 testWidgets('V4 onboarding has real navigation', (tester)async{
  await tester.pumpWidget(const MaterialApp(home:CikokoV4Onboarding()));
  expect(find.text('Layanan Kelurahan Lebih Dekat'),findsOneWidget);
  expect(find.text('Lanjutkan →'),findsOneWidget);
 });
}
