import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/main.dart';

void main() {
  testWidgets('Registration requires an RT and RW field', (tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginPage(onLogin: () {})));
    await tester.tap(find.text('Daftar Akun Warga →'));
    await tester.pump();
    expect(find.text('Nomor RT (contoh: 003)'), findsOneWidget);
    expect(find.text('Nomor RW (contoh: 010)'), findsOneWidget);
  });
  testWidgets('Login page is native Flutter', (tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginPage(onLogin: () {})));
    expect(find.text('Login Cikoko'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
