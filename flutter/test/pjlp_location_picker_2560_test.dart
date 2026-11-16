import 'package:cikoko/api.dart';
import 'package:cikoko/cikoko_pjlp_2557_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class LocationConfigApi extends CikokoApi {
  LocationConfigApi(this.settings);

  final Map<String, dynamic> settings;
  Map<String, dynamic>? saved;

  @override
  Future<Map<String, dynamic>> call(String action, {
    Map<String, dynamic>? body,
    bool authorized = false,
  }) async {
    if (action == 'pjlp_location_save') {
      saved = body;
      return {'ok': true};
    }
    return {'staff': [], 'config': settings};
  }
}

Future<void> openSettings(WidgetTester tester, LocationConfigApi api) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(
    body: CikokoPjlp2557Page(api: api, role: 'admin'),
  )));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Lokasi kantor dan bobot'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('first setup requires a map location without coordinate fields', (tester) async {
    final api = LocationConfigApi({});
    await openSettings(tester, api);

    expect(find.text('Pilih di peta'), findsOneWidget);
    expect(find.text('Lintang'), findsNothing);
    expect(find.text('Bujur'), findsNothing);
    expect(find.text('Radius dalam meter'), findsOneWidget);
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih lokasi pada peta.'), findsOneWidget);
    expect(api.saved, isNull);
  });

  testWidgets('editing weights keeps the existing map location in the API payload',
      (tester) async {
    final api = LocationConfigApi({
      'latitude': '-6.24', 'longitude': '106.84', 'radius_m': '75',
    });
    await openSettings(tester, api);

    expect(find.text('Ubah titik di peta'), findsOneWidget);
    expect(find.text('Titik lokasi sudah dipilih.'), findsOneWidget);
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(api.saved, containsPair('latitude', '-6.24'));
    expect(api.saved, containsPair('longitude', '106.84'));
    expect(api.saved, containsPair('radius_m', '75'));
  });

  testWidgets('an invalid radius keeps the dialog open so it can be corrected',
      (tester) async {
    final api = LocationConfigApi({
      'latitude': '-6.24', 'longitude': '106.84', 'radius_m': '75',
    });
    await openSettings(tester, api);

    final radius = find.widgetWithText(TextFormField, 'Radius dalam meter');
    for (final value in ['29', '2001', '100 meter']) {
      await tester.enterText(radius, value);
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(find.text('Masukkan angka 30–2000, tanpa satuan.'), findsOneWidget);
      expect(api.saved, isNull);
    }

    await tester.enterText(radius, '100');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(api.saved, containsPair('radius_m', '100'));
    expect(api.saved, containsPair('latitude', '-6.24'));
  });
}
