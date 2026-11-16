import 'package:cikoko/cikoko_v6_showcase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Existing Cikoko homepage uses a website-managed hero photo',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: V6Hero(
          onServices: () {},
          onAbout: () {},
          photoUrl: 'https://datawebs.my.id/assets/images/visual-test.jpg',
          photoFit: BoxFit.contain,
          photoAlignment: Alignment.topRight,
        ),
      ),
    ));

    final image = tester.widget<Image>(
      find.byKey(const Key('cikoko_live_website_header')),
    );
    expect(image.image, isA<NetworkImage>());
    expect(image.fit, BoxFit.contain);
    expect(image.alignment, Alignment.topRight);
    expect(find.text('Cikoko Smart'), findsOneWidget);
    expect(find.text('Ajukan Layanan  →'), findsOneWidget);
  });

  testWidgets('Existing Cikoko homepage still displays its bundled fallback',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: V6Hero(onServices: () {}, onAbout: () {}),
      ),
    ));
    expect(find.byKey(const Key('cikoko_live_website_header')), findsNothing);
    expect(find.byType(Image), findsWidgets);
  });
}
