import 'package:cikoko/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Form Ahli Waris mencakup dua KTP saksi setelah Surat Nikah', (tester) async {
    await tester.pumpWidget(const MaterialApp(home:Scaffold(body:WarisForm())));
    final scrollable=find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('Surat nikah'),350,scrollable:scrollable);
    expect(find.text('Surat nikah'),findsOneWidget);
    await tester.scrollUntilVisible(find.text('Dua Orang Saksi'),260,scrollable:scrollable);
    expect(find.text('Dua Orang Saksi'),findsOneWidget);
    await tester.scrollUntilVisible(find.text('KTP Saksi Kedua'),260,scrollable:scrollable);
    expect(find.text('KTP Saksi Kedua'),findsOneWidget);
  });
}
