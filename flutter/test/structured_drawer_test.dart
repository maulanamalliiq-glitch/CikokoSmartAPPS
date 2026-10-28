import 'package:cikoko/role_catalog.dart';
import 'package:cikoko/structured_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Laporan wilayah hanya memuat laporan yang diizinkan akun', () {
    final allowed = modulesForRole('admin', {
      'reports:view': true,
      'chat:reply': true,
      'content:create': true,
      'archive:create': true,
      'role:manage': true,
    });
    final groups = cikokoGroupedMenus(allowed);
    final report = groups.singleWhere((g) => g.id == 'laporan');
    final letters = groups.singleWhere((g) => g.id == 'surat');
    final staff = groups.singleWhere((g) => g.id == 'petugas');

    expect(report.features.any((f) => f.route == 'Laporan Kegiatan Admin'), isTrue);
    expect(report.features.any((f) => f.route == 'Laporan LPJ RT'), isTrue);
    expect(letters.features.any((f) => f.route == 'Verifikasi Ahli Waris'), isTrue);
    expect(staff.features.any((f) => f.route == 'Hak Akses Role'), isTrue);
    expect(report.features.any((f) => f.route == 'Verifikasi Ahli Waris'), isFalse);

    final flat = groups.expand((g) => g.features).toList();
    expect(flat.length, allowed.length);
    expect(flat.toSet().length, allowed.length);
  });

  test('LPJ RT dan RW termasuk Laporan Wilayah tanpa menambah route baru', () {
    const lpjRt = RoleFeature('Laporan LPJ RT', 'Rekap LPJ RT', 'Laporan LPJ RT');
    const lpjRw = RoleFeature('Laporan LPJ RW', 'Rekap LPJ RW', 'Laporan LPJ RW');
    expect(cikokoGroupForFeature(lpjRt), 'laporan');
    expect(cikokoGroupForFeature(lpjRw), 'laporan');
  });

  test('Menu sensitif yang tidak diizinkan tidak muncul di grup mana pun', () {
    final modules = modulesForRole('warga', {'waris:create': true});
    final all = cikokoGroupedMenus(modules).expand((g) => g.features);
    expect(all.any((f) => f.route == 'Verifikasi Ahli Waris'), isFalse);
    expect(all.any((f) => f.route == 'Hak Akses Role'), isFalse);
  });

  testWidgets('Laporan Wilayah bisa dibuka dan ditutup', (tester) async {
    final modules = [
      const RoleFeature('Laporan Kegiatan','Periksa kegiatan','Laporan Kegiatan Admin'),
      const RoleFeature('Verifikasi Ahli Waris','Periksa surat','Verifikasi Ahli Waris'),
    ];
    String? opened;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: SizedBox(width: 340, child: CikokoStructuredDrawer(
        avatar: const Icon(Icons.account_circle, size: 45),
        accountName: 'Administrator',
        roleLabel: 'Admin Utama',
        guest: false,
        allowedFeatures: modules,
        currentRoute: 'Dashboard',
        iconFor: (_) => Icons.article_outlined,
        onNavigate: (route) => opened = route,
        onClose: () {},
        onLogin: () {},
        onLogout: () {},
      )),
    )));

    expect(find.text('Laporan Wilayah'), findsOneWidget);
    expect(find.text('Laporan Kegiatan'), findsNothing);
    await tester.tap(find.text('Laporan Wilayah'));
    await tester.pumpAndSettle();
    expect(find.text('Laporan Kegiatan'), findsOneWidget);
    await tester.tap(find.text('Laporan Kegiatan'));
    expect(opened, 'Laporan Kegiatan Admin');
    await tester.tap(find.text('Laporan Wilayah'));
    await tester.pumpAndSettle();
    expect(find.text('Laporan Kegiatan'), findsNothing);
  });
}
