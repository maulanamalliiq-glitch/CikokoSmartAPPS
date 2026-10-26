import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/main.dart';

void main() {
  testWidgets('Tanggal Ahli Waris memakai date picker, bukan keyboard bebas',
      (tester) async {
    final ctrl=TextEditingController();
    addTearDown(ctrl.dispose);
    await tester.pumpWidget(MaterialApp(home:Scaffold(
      body:Field('Tanggal lahir',ctrl,date:true))));
    final field=tester.widget<TextField>(find.byType(TextField));
    expect(field.readOnly,isTrue);
    expect(find.byIcon(Icons.calendar_month_outlined),findsOneWidget);
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog),findsOneWidget);
  });
  testWidgets('Nomor telepon menggunakan papan ketik khusus telepon',
      (tester) async {
    final ctrl=TextEditingController();
    addTearDown(ctrl.dispose);
    await tester.pumpWidget(MaterialApp(home:Scaffold(
      body:Field('Nomor HP',ctrl,keyboard:TextInputType.phone))));
    final field=tester.widget<TextField>(find.byType(TextField));
    expect(field.keyboardType,TextInputType.phone);
  });
  testWidgets('NIK memakai angka dan input filter angka',
      (tester) async {
    final ctrl=TextEditingController();
    addTearDown(ctrl.dispose);
    await tester.pumpWidget(MaterialApp(home:Scaffold(
      body:Field('NIK',ctrl,keyboard:TextInputType.number))));
    final field=tester.widget<TextField>(find.byType(TextField));
    expect(field.keyboardType,TextInputType.number);
    expect(field.inputFormatters,isNotEmpty);
  });
}
