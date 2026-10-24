import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/main.dart';
void main(){
  testWidgets('native photo UI shows both camera and gallery actions', (tester) async {
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:PhotoInput(label:'Surat Kematian',onChanged:(_){ }))));
    expect(find.text('Kamera'),findsOneWidget);
    expect(find.text('Galeri'),findsOneWidget);
    expect(find.text('Belum ada foto'),findsOneWidget);
  });
}
