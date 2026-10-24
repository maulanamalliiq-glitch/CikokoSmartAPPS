import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/main.dart';

void main() {
  testWidgets('Login page is native Flutter', (tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginPage(onLogin: () {})));
    expect(find.text('Login Cikoko'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
