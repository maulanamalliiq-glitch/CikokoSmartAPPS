import 'package:flutter/material.dart';
import 'api.dart';

/// Hanya Admin Utama yang mendapat menu ini. Server tetap melakukan
/// verifikasi role=admin sebelum membaca atau membuat akun.
class AdminAccountsPage extends StatefulWidget {
  final CikokoApi api;
  /// Tampilan khusus Bendahara memakai API dan autentikasi Admin Utama
  /// yang sudah ada. Tidak mengubah login atau aturan server.
  final bool bendaharaOnly;
  const AdminAccountsPage({
    super.key,
    required this.api,
    this.bendaharaOnly = false,
  });

  @override
  State<AdminAccountsPage> createState() => _AdminAccountsPageState();
}

class _AdminAccountsPageState extends State<AdminAccountsPage> {
  final name = TextEditingController();
  final username = TextEditingController();
  final password = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final rt = TextEditingController();
  final rw = TextEditingController();
  final formKey = GlobalKey<FormState>();

  Map<String, String> roles = {};
  List<Map<String, dynamic>> accounts = [];
  String? selectedRole;
  String? error;
  bool busy = false;
  bool loading = true;
  bool showForm = true;

  bool get needsRt => selectedRole == 'rt' || selectedRole == 'bendahara_rt';
  bool get needsRw => needsRt ||
      selectedRole == 'rw' ||
      selectedRole == 'bendahara_rw' ||
      selectedRole == 'lmk';

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    for (final controller in [name, username, password, phone, email, rt, rw]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> load() async {
    try {
      final res = await widget.api.call('accounts_list');
      if (!mounted) return;
      final roleMap = Map<String, dynamic>.from(res['roles'] as Map? ?? {});
      setState(() {
        roles = roleMap.map((k, v) => MapEntry(k, v.toString()))
          ..remove('admin')
          ..remove('warga');
        if (widget.bendaharaOnly) {
          // Pilihan dibatasi untuk dua peran resmi yang benar-benar
          // dikembalikan server; jangan pernah membuat role lokal palsu.
          roles.removeWhere((key, _) =>
              key != 'bendahara_rt' && key != 'bendahara_rw');
        }
        accounts = (res['items'] as List? ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where((account) =>
                !widget.bendaharaOnly ||
                account['role'] == 'bendahara_rt' ||
                account['role'] == 'bendahara_rw')
            .toList();
        if (!roles.containsKey(selectedRole)) {
          selectedRole = roles.containsKey('bendahara_rt')
              ? 'bendahara_rt'
              : (roles.isEmpty ? null : roles.keys.first);
        }
        loading = false;
        error = null;
      });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = '$e'; });
    }
  }

  String? nonEmpty(String? value) =>
      (value ?? '').trim().isEmpty ? 'Wajib diisi' : null;

  Future<void> create() async {
    if (busy || selectedRole == null || !roles.containsKey(selectedRole)) return;
    if (widget.bendaharaOnly &&
        selectedRole != 'bendahara_rt' &&
        selectedRole != 'bendahara_rw') return;
    if (!formKey.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await widget.api.call('accounts_create', body: {
        'name': name.text.trim(),
        'username': username.text.trim(),
        'password': password.text,
        'role': selectedRole,
        'phone': phone.text.trim(),
        'email': email.text.trim(),
        'rt': needsRt ? rt.text.trim() : '',
        'rw': needsRw ? rw.text.trim() : '',
      });
      if (!mounted) return;
      name.clear();
      username.clear();
      password.clear();
      phone.clear();
      email.clear();
      rt.clear();
      rw.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun petugas berhasil dibuat.')));
      await load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat akun: $e')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  InputDecoration decoration(String label, {String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
      );

  Widget field(TextEditingController controller, String label,
      {String? hint, bool required = true, bool secret = false,
      TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: secret,
        keyboardType: keyboard,
        decoration: decoration(label, hint: hint),
        validator: required ? nonEmpty : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Gagal membuka Kelola Akun: $error', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: load, child: const Text('Coba Lagi')),
        ]),
      ));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          widget.bendaharaOnly ? 'Manajemen Bendahara RT/RW' : 'Kelola Akun Petugas',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          widget.bendaharaOnly
              ? 'Khusus Admin Utama. Buat akun Bendahara RT/RW sesuai wilayah '
                'dan lihat status aktifnya. Login, akun lain, serta data LPJ '
                'tidak berubah.'
              : 'Hanya Admin Utama dapat membuat akun dan menetapkan '
                'jabatan resmi Ketua/Bendahara RT/RW. '
                'Username dan password disampaikan secara pribadi.',
          style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
        ),
        if (widget.bendaharaOnly && roles.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Peran Bendahara belum tersedia dari API cPanel. '
              'Pembuatan akun dinonaktifkan hingga server mengirimkan '
              'bendahara_rt atau bendahara_rw.',
              style: TextStyle(color: Colors.deepOrange),
            ),
          ),
        const SizedBox(height: 12),
        Card(child: Column(children: [
          ListTile(
            title: const Text('Tambah Akun'),
            subtitle: Text(widget.bendaharaOnly
                ? 'Buat akun Bendahara RT atau Bendahara RW'
                : 'Petugas baru, termasuk Bendahara RT dan RW'),
            trailing: Icon(showForm ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => showForm = !showForm),
          ),
          if (showForm && roles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
              child: Form(key: formKey, child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  field(name, 'Nama lengkap'),
                  field(username, 'Username', hint: 'Minimal 4 karakter'),
                  field(password, 'Password awal',
                      secret: true, hint: 'Minimal 8 karakter'),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    isExpanded: true,
                    decoration: decoration('Peran akun'),
                    items: roles.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: busy ? null : (v) => setState(() => selectedRole = v),
                  ),
                  const SizedBox(height: 12),
                  if (needsRt) field(rt, 'RT', hint: 'Contoh: 001',
                      keyboard: TextInputType.number),
                  if (needsRw) field(rw, 'RW', hint: 'Contoh: 001',
                      keyboard: TextInputType.number),
                  field(phone, 'Nomor telepon (opsional)', required: false,
                      keyboard: TextInputType.phone),
                  field(email, 'Email (opsional)', required: false,
                      keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 4),
                  FilledButton.icon(
                    onPressed: busy ? null : create,
                    icon: busy
                        ? const SizedBox(height: 16, width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.person_add_alt_1),
                    label: Text(busy
                        ? 'Menyimpan...'
                        : (widget.bendaharaOnly
                            ? 'Buat Akun Bendahara'
                            : 'Buat Akun Petugas')),
                  ),
                ],
              )),
            ),
        ])),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: Text(
              widget.bendaharaOnly
                  ? 'Daftar Bendahara RT/RW'
                  : 'Daftar Akun Terdaftar',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold))),
          IconButton(tooltip: 'Muat ulang', onPressed: load,
              icon: const Icon(Icons.refresh)),
        ]),
        if (accounts.isEmpty)
          Text(widget.bendaharaOnly
              ? 'Belum ada akun Bendahara RT/RW yang terdaftar.'
              : 'Belum ada akun petugas.'),
        for (final account in accounts)
          Card(child: ListTile(
            dense: true,
            leading: Icon(account['active'] == true
                ? Icons.verified_user_outlined
                : Icons.person_off_outlined),
            title: Text(account['name']?.toString() ?? ''),
            subtitle: Text(
              '${account['username'] ?? ''} • '
              '${roles[account['role']] ?? account['role']}'
              '${(account['rt'] ?? '').toString().isNotEmpty ? ' • RT ${account['rt']}' : ''}'
              '${(account['rw'] ?? '').toString().isNotEmpty ? ' / RW ${account['rw']}' : ''}',
            ),
            trailing: Text(account['active'] == true ? 'Aktif' : 'Nonaktif',
                style: const TextStyle(fontSize: 11)),
          )),
      ],
    );
  }
}
