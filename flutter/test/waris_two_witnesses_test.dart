import 'package:cikoko/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Form Ahli Waris memiliki dua KTP saksi sesudah surat nikah', (tester) async {
    await tester.pumpWidget(const MaterialApp(home:Scaffold(body:WarisForm())));
    expect(find.text('Dua Orang Saksi'), findsOneWidget);
    expect(find.text('KTP Saksi Pertama'), findsOneWidget);
    expect(find.text('KTP Saksi Kedua'), findsOneWidget);
    final form=find.byType(WarisForm);
    expect(form,findsOneWidget);
    // The two uploads use the same PhotoInput camera and gallery UI as before.
    expect(find.text('Surat nikah'), findsOneWidget);
  });
}
