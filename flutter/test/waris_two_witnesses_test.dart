import 'package:cikoko/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Dua KTP saksi muncul setelah Surat Nikah tanpa bergantung pada scroll', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: WarisForm())));

    // The form uses ListView(children: [...]). Inspect its complete child
    // delegate directly: a lazy viewport does not build every offscreen widget.
    final listFinder = find.descendant(
      of: find.byType(WarisForm),
      matching: find.byType(ListView),
    );
    final list = tester.widget<ListView>(listFinder.first);
    final children = (list.childrenDelegate as SliverChildListDelegate).children;
    final labels = <String>[];
    for (final child in children) {
      if (child is PhotoInput) labels.add(child.label);
      if (child is Text && child.data != null) labels.add(child.data!);
    }

    final marriage = labels.indexOf('Surat nikah');
    final heading = labels.indexOf('Dua Orang Saksi');
    final firstWitness = labels.indexOf('KTP Saksi Pertama');
    final secondWitness = labels.indexOf('KTP Saksi Kedua');
    final optional = labels.indexOf('Dokumen Kondisional');

    expect(marriage, greaterThanOrEqualTo(0));
    expect(heading, marriage + 1);
    expect(firstWitness, heading + 1);
    expect(secondWitness, firstWitness + 1);
    expect(optional, secondWitness + 1);

    // Both witness rows are the existing PhotoInput component,
    // which already supports Camera and Gallery uploads.
    expect(children.whereType<PhotoInput>()
        .where((photo) => photo.label == 'KTP Saksi Pertama').length, 1);
    expect(children.whereType<PhotoInput>()
        .where((photo) => photo.label == 'KTP Saksi Kedua').length, 1);
  });
}
