import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/admin_accounts.dart';
import 'package:cikoko/api.dart';

class FakeAdminAccountsApi extends CikokoApi {
  @override
  Future<Map<String, dynamic>> call(
    String action, {
    Map<String, dynamic>? body,
    bool authorized = false,
  }) async {
    if (action != 'accounts_list') {
      throw StateError('Tes UI ini tidak boleh menulis data.');
    }
    return {
      'ok': true,
      'roles': {
        'admin': 'Admin Utama',
        'rt': 'Ketua RT',
        'rw': 'Ketua RW',
        'bendahara_rt': 'Bendahara RT',
        'bendahara_rw': 'Bendahara RW',
        'warga': 'Warga',
      },
      'items': [
        {
          'name': 'Ketua Percobaan',
          'username': 'ketua_tes',
          'role': 'rt',
          'rt': '001',
          'rw': '001',
          'active': true,
        },
        {
          'name': 'Bendahara Percobaan',
          'username': 'bendahara_tes',
          'role': 'bendahara_rt',
          'rt': '001',
          'rw': '001',
          'active': true,
        },
      ],
    };
  }
}

void main() {
  testWidgets('Manajemen Bendahara menyembunyikan akun Ketua lain',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AdminAccountsPage(
          api: FakeAdminAccountsApi(),
          bendaharaOnly: true,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Manajemen Bendahara RT/RW'), findsOneWidget);
    expect(find.text('Bendahara Percobaan'), findsOneWidget);
    expect(find.text('Ketua Percobaan'), findsNothing);
    expect(find.text('Buat Akun Bendahara'), findsOneWidget);

    // Hanya dua role Bendahara yang dapat dipilih.
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('Bendahara RW'), findsWidgets);
    expect(find.text('Ketua RT'), findsNothing);
    expect(find.text('Ketua RW'), findsNothing);
    expect(find.text('Admin Utama'), findsNothing);
  });

  testWidgets('Mode umum Kelola Akun tetap tersedia', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AdminAccountsPage(api: FakeAdminAccountsApi()),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Kelola Akun Petugas'), findsOneWidget);
    expect(find.text('Ketua Percobaan'), findsOneWidget);
    expect(find.text('Bendahara Percobaan'), findsOneWidget);
  });
}
