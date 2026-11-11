import 'package:cikoko/cikoko_v5_shell.dart';
import 'package:cikoko/role_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main(){
  testWidgets('V5 navigation keeps Beranda in exact center and Tentang Kami at end',
    (tester)async{
    int? chosen;
    await tester.pumpWidget(MaterialApp(home:Scaffold(
      bottomNavigationBar:CikokoV5BottomNav(
        selected:2,onSelected:(index)=>chosen=index))));
    final first=tester.getCenter(find.byKey(const Key('v5_nav_0')));
    final third=tester.getCenter(find.byKey(const Key('v5_nav_2')));
    final fifth=tester.getCenter(find.byKey(const Key('v5_nav_4')));
    expect((third.dx-first.dx).abs(),closeTo((fifth.dx-third.dx).abs(),1.0));
    expect(find.text('Beranda'),findsOneWidget);
    expect(find.text('Tentang Kami'),findsOneWidget);
    await tester.tap(find.byKey(const Key('v5_nav_4')));
    expect(chosen,4);
  });

  testWidgets('V5 laporan terpadu is above layanan masyarakat',
    (tester)async{
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:
      SingleChildScrollView(child:Column(children:[
        CikokoV5ReportPanel(role:'warga',guest:false,
          modules:const <RoleFeature>[],
          letterCounts:const {'masuk':1,'proses':0,'selesai':29},
          navigate:(_){},onLetterStatus:(_){},expanded:true),
        CikokoV5ServicePanel(navigate:(_){}),
      ])))));
    final laporan=tester.getTopLeft(find.text('Laporan Terpadu'));
    final layanan=tester.getTopLeft(find.text('Layanan Masyarakat'));
    expect(laporan.dy,lessThan(layanan.dy));
    expect(find.text('Status Pelayanan Surat'),findsOneWidget);
    expect(find.text('Laporan Jumantik'),findsOneWidget);
  });

  testWidgets('V5 laporan allows guest to open actual route',
    (tester)async{
    String? route;
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:
      SingleChildScrollView(child:CikokoV5ReportPanel(
        role:'guest',guest:true,modules:const <RoleFeature>[],
        letterCounts:null,navigate:(x)=>route=x,onLetterStatus:(_){},
      )))));
    await tester.tap(find.text('Laporan Jumantik'));
    expect(route,'Laporan Jumantik');
  });
}
