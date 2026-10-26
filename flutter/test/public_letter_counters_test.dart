import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/home_widgets.dart';

void main(){
  testWidgets('Public guest sees numeric counts and readonly status buttons',(tester) async {
    String? tapped;
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:Center(
      child:CikokoLetterCounters(
        counts:const {'masuk':4,'proses':3,'selesai':2},
        onStatusTap:(value)=>tapped=value,
      )))));
    expect(find.text('4'),findsOneWidget);
    expect(find.text('3'),findsOneWidget);
    expect(find.text('2'),findsOneWidget);
    expect(find.text('Login →'),findsNothing);
    await tester.tap(find.text('Surat Masuk'));
    expect(tapped,'masuk');
    await tester.tap(find.text('Lihat Status →'));
    expect(tapped,'all');
  });
}
