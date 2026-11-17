import 'package:cikoko/api.dart';
import 'package:cikoko/cikoko_pjlp_2557_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class PjlpFixtureApi extends CikokoApi {
  PjlpFixtureApi({required this.configured, this.active = false});

  final bool configured;
  final bool active;

  @override
  Future<Map<String, dynamic>> callWithQuery(
      String action, Map<String, String> query) async {
    final date = "${query['month']}-15";
    return {
      'employee': 'Pegawai Uji',
      'server_date': date,
      'configured': configured,
      'active_shift': active
          ? {'work_date': date, 'shift_name': 'malam', 'checkin_at': '$date 22:00:00'}
          : null,
      'checked_in_today': active,
      'daily': <Map<String, dynamic>>[],
    };
  }
}

void main() {
  testWidgets('PJLP still sees shifts, reports and field duty during initial setup',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: CikokoPjlp2557Page(api: PjlpFixtureApi(configured: false), role: 'pjlp'),
    )));
    await tester.pumpAndSettle();

    for (final title in ['Pagi', 'Siang', 'Malam', 'Absen masuk', 'Absen pulang']) {
      expect(find.text(title), findsOneWidget);
    }
    final checkin = find.ancestor(of: find.text('Absen masuk'),
        matching: find.byWidgetPredicate((widget) => widget is FilledButton));
    expect(tester.widget<FilledButton>(checkin).onPressed, isNull);
    expect(find.text('Admin Utama perlu menyimpan lokasi kantor dan bobot penilaian.'),
        findsWidgets);
    await tester.scrollUntilVisible(find.text('Dinas Luar'), 280);
    await tester.tap(find.text('Dinas Luar'));
    await tester.pumpAndSettle();
    for (final stage in [0, 50, 100]) {
      final tile = find.widgetWithText(ListTile, 'Laporan $stage%');
      expect(tester.widget<ListTile>(tile).onTap, isNull);
    }
  });

  testWidgets('active shift can start the 0% report before later stages',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: CikokoPjlp2557Page(
        api: PjlpFixtureApi(configured: true, active: true), role: 'pjlp',
      ),
    )));
    await tester.pumpAndSettle();

    ListTile stage(int progress) =>
        tester.widget<ListTile>(find.widgetWithText(ListTile, 'Laporan $progress%'));
    expect(stage(0).onTap, isNotNull);
    expect(stage(50).onTap, isNull);
    expect(stage(100).onTap, isNull);
  });
}
