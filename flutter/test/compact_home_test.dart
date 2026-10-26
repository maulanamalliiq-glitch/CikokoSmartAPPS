import 'package:cikoko/home_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Banner kantor menampilkan identitas kelurahan tanpa kartu sambutan', (tester) async {
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:CikokoOfficeHero(
      onService: () {}, onProfile: () {}))));
    expect(find.text('Kelurahan Cikoko'),findsOneWidget);
    expect(find.textContaining('Selamat datang'),findsNothing);
    expect(find.text('Layanan Online'),findsOneWidget);
    expect(find.text('Profil Kelurahan'),findsOneWidget);
  });
  testWidgets('Kategori pelayanan native bisa diketuk', (tester) async {
    var touched=false;
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:Center(child:SizedBox(
      width:240,height:90,child:CikokoServiceTile(
        title:'Administrasi Kependudukan',description:'Informasi KTP dan KK',
        icon:Icons.badge_outlined,accent:const Color(0xff2868c9),onTap:()=>touched=true))))));
    await tester.tap(find.text('Administrasi Kependudukan'));
    expect(touched,isTrue);
  });
  testWidgets('Ringkasan surat publik tidak menampilkan data pemohon', (tester) async {
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:CikokoLetterCounters(
      counts:null,onStatusTap:(_){}))));
    expect(find.text('—'),findsNWidgets(3));
    expect(find.text('Status Pelayanan Surat'),findsOneWidget);
  });
  testWidgets('Status warga berasal dari data yang disuplai API', (tester) async {
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:CikokoLetterCounters(
      counts:const {'masuk':2,'proses':1,'selesai':3},onStatusTap:(_){}))));
    expect(find.text('2'),findsOneWidget);
    expect(find.text('1'),findsOneWidget);
    expect(find.text('3'),findsOneWidget);
  });
}
