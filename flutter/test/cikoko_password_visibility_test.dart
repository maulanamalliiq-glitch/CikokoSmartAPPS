import 'package:cikoko/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
 testWidgets('Login password eye switches masked and visible text',
   (tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginPage(onLogin: () {})));
    final key = find.byKey(const Key('login_password_field'));
    expect(tester.widget<TextField>(key).obscureText, true);
    await tester.tap(find.byKey(
      const Key('toggle_login_password_visibility')));
    await tester.pump();
    expect(tester.widget<TextField>(key).obscureText, false);
    await tester.tap(find.byKey(
      const Key('toggle_login_password_visibility')));
    await tester.pump();
    expect(tester.widget<TextField>(key).obscureText, true);
 });

 testWidgets('Registration and confirmation passwords have eye buttons',
   (tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginPage(onLogin: () {})));
    await tester.tap(find.text('Belum punya akun? Registrasi'));
    await tester.pump();
    expect(find.byKey(const Key('toggle_password_visibility')),
      findsOneWidget);
    expect(find.byKey(const Key('toggle_confirm_visibility')),
      findsOneWidget);
 });
}
