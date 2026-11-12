import 'package:cikoko/api.dart';
import 'package:cikoko/cikoko_home_sections.dart';
import 'package:cikoko/cikoko_v6_showcase.dart';
import 'package:cikoko/role_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class HomeApiStub extends CikokoApi {
 @override Future<Map<String,dynamic>> call(String action,
    {Map<String,dynamic>? body,bool authorized=false}) async {
  if(action=='v211_innovations')return {
    'ok':true,'items':[
      {'title':'Bank Sampah Cikoko','summary':'Informasi inovasi uji.'}
    ]
  };
  return {'ok':true,'items':[]};
 }
}

void main(){
 testWidgets('Status Pelayanan Surat receives real counts and handles taps',(tester)async{
  String? chosen;
  await tester.pumpWidget(MaterialApp(home:Scaffold(
   body:V6LetterStatusStrip(counts:const {
    'masuk':1,'proses':0,'selesai':29
   },onStatus:(value)=>chosen=value),
  )));
  expect(find.text('Status Pelayanan Surat'),findsOneWidget);
  expect(find.text('29'),findsOneWidget);
  await tester.tap(find.byKey(const Key('v6_status_selesai')));
  expect(chosen,'selesai');
 });

 testWidgets('Integrated DKI services are three cards per row, logo and title only',(tester)async{
  Map<String,dynamic>? tapped;
  final data=<Map<String,dynamic>>[
   {'title':'PTSP','url':'https://ptsp.jakarta.go.id/','logo_url':'','active':true},
   {'title':'Dukcapil','url':'https://kependudukancapil.jakarta.go.id/','logo_url':'','active':true},
   {'title':'Alpukat Betawi','url':'https://alpukat-dukcapil.jakarta.go.id/','logo_url':'','active':true},
   {'title':'Jak Evo','url':'https://jakevo.jakarta.go.id/','logo_url':'','active':true},
  ];
  await tester.pumpWidget(MaterialApp(home:Scaffold(body:
    SingleChildScrollView(child:V6IntegratedServiceGrid(
      entries:data,onOpen:(row)=>tapped=row)))));
  final first=tester.getTopLeft(find.byKey(const Key('v6_integrated_0')));
  final second=tester.getTopLeft(find.byKey(const Key('v6_integrated_1')));
  final third=tester.getTopLeft(find.byKey(const Key('v6_integrated_2')));
  final fourth=tester.getTopLeft(find.byKey(const Key('v6_integrated_3')));
  expect(first.dy,second.dy);
  expect(first.dy,third.dy);
  expect(first.dx,lessThan(second.dx));
  expect(second.dx,lessThan(third.dx));
  expect(fourth.dy,greaterThan(first.dy));
  await tester.tap(find.byKey(const Key('v6_integrated_1')));
  expect(tapped?['title'],'Dukcapil');
  expect(tapped?['url'],'https://kependudukancapil.jakarta.go.id/');
  expect(find.text('Lihat Selengkapnya'),findsNothing);
  expect(find.text('Pelayanan perizinan'),findsNothing);
 });

 testWidgets('Home removes the duplicate reports table and places status after hero',(tester)async{
  await tester.pumpWidget(MaterialApp(home:Scaffold(body:V6Home(
   role:'warga',guest:false,modules:const <RoleFeature>[],api:HomeApiStub(),
   items:const [],letterCounts:const {'masuk':1,'proses':0,'selesai':29},
   integratedServices:const [
    {'title':'PTSP','url':'https://ptsp.jakarta.go.id/','active':true,'logo_url':''},
   ],
   navigate:(_){},letterStatus:(_){},integratedTap:(_){},
   articleTap:(_){},reload:()async{},
  ))));
  await tester.pump();
  expect(find.byKey(const Key('v6_home_letter_status')),findsOneWidget);
  expect(find.text('Laporan Terpadu'),findsNothing);
  expect(find.text('Status Pelayanan Surat'),findsOneWidget);
 });

 testWidgets('Innovation preview is linked to its full innovations page',(tester)async{
  var activated=false;
  await tester.pumpWidget(MaterialApp(home:Scaffold(body:
    V6InnovationPreview(api:HomeApiStub(),onAll:()=>activated=true))));
  await tester.pumpAndSettle();
  expect(find.text('Inovasi Kelurahan'),findsOneWidget);
  expect(find.text('Bank Sampah Cikoko'),findsOneWidget);
  await tester.tap(find.text('Bank Sampah Cikoko'));
  expect(activated,isTrue);
 });
}
