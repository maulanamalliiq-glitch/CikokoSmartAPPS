import 'package:cikoko/home_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Header kantor Cikoko menggantikan salam panjang', (tester) async {
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:CikokoOfficeHero(
      onService: () {},onProfile: () {}))));
    expect(find.text('KELURAHAN CIKOKO'),findsOneWidget);
    expect(find.textContaining('Selamat datang'),findsNothing);
    expect(find.text('Layanan Online'),findsOneWidget);
  });
  testWidgets('Menu compact dapat diketuk', (tester) async {
    var touched=false;
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:CikokoQuickMenu(
      title:'Surat Ahli Waris',icon:Icons.description,onTap:()=>touched=true))));
    await tester.tap(find.text('Surat Ahli Waris'));
    expect(touched,isTrue);
  });
  testWidgets('Angka publik tidak dibuat-buat', (tester) async {
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:CikokoLetterCounters(
      guest:true,counts:null,onTap:(){}))));
    expect(find.text('—'),findsNWidgets(3));
    expect(find.text('Status Surat Saya'),findsOneWidget);
  });
}
