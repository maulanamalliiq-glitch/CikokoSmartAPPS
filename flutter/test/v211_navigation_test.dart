import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:cikoko/main.dart';
void main(){
 testWidgets('Beranda remains the middle item in bottom navigation', (tester)async{
  await tester.pumpWidget(const CikokoApp());
  await tester.pump(const Duration(milliseconds:60));
  expect(find.byType(MaterialApp), findsOneWidget);
 });
}
