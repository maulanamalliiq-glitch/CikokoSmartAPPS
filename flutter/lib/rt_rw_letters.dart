import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api.dart';

/// The primary key belongs to the server; never infer it from list position.
int? cikokoLetterId(Map<String, dynamic> row) {
  for (final key in const ['id', 'application_id', 'request_id']) {
    final v = row[key];
    final id = v is int ? v : int.tryParse((v ?? '').toString().trim());
    if (id != null && id > 0) return id;
  }
  return null;
}

const rtRwFormFields = <String, String>{
  'nama': 'Nama Lengkap',
  'tempat_lahir': 'Tempat Lahir',
  'tanggal_lahir': 'Tanggal Lahir (YYYY-MM-DD)',
  'no_ktp_kk': 'Nomor KTP / KK',
  'agama': 'Agama',
  'kewarganegaraan': 'Kewarganegaraan',
  'pendidikan': 'Pendidikan',
  'jenis_kelamin': 'Jenis Kelamin (Laki-laki / Perempuan)',
  'status': 'Status Perkawinan',
  'pekerjaan': 'Pekerjaan',
  'alamat': 'Alamat Lengkap',
  'maksud_keperluan': 'Maksud / Keperluan',
};

String cikokoLetterStatus(String s) => switch (s) {
  'menunggu_rt' => 'Menunggu Verifikasi RT',
  'menunggu_rw' => 'Menunggu Verifikasi RW',
  'terverifikasi' => 'Sudah Terverifikasi RT/RW',
  'ditolak' => 'Ditolak',
  'masuk' => 'Surat Masuk',
  'proses' => 'Sedang Diproses',
  'selesai' => 'Selesai',
  _ => s.isEmpty ? 'Belum diketahui' : s,
};

class CikokoPublicLetterPage extends StatefulWidget {
  final CikokoApi api;
  const CikokoPublicLetterPage({super.key, required this.api});
  @override
  State<CikokoPublicLetterPage> createState() => _CikokoPublicLetterState();
}
class _CikokoPublicLetterState extends State<CikokoPublicLetterPage> {
  late Future<Map<String, dynamic>> future;
  @override
  void initState() { super.initState(); reload(); }
  void reload() { future = widget.api.call('public_letter_status'); if (mounted) setState(() {}); }
  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () async { reload(); await future; },
    child: FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) return ListView(children: [
          ListTile(title: const Text('Status surat belum tersedia'), subtitle: Text(snapshot.error.toString())),
          TextButton(onPressed: reload, child: const Text('Coba Lagi')),
        ]);
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!;
        final rows = List<dynamic>.from(data['items'] ?? []);
        final counts = Map<String, dynamic>.from(data['counts'] ?? {});
        return ListView(padding: const EdgeInsets.all(12), children: [
          const ListTile(title: Text('Status Pelayanan Surat'), subtitle: Text(
            'Informasi publik hanya memuat nomor dan progres surat. Identitas warga dan lampiran tidak ditampilkan.')),
          Card(child: Padding(padding: const EdgeInsets.all(14), child: Wrap(spacing: 16, runSpacing: 8, children: [
            for (final key in ['masuk', 'proses', 'selesai'])
              Chip(label: Text((key == 'masuk' ? 'Masuk' : key == 'proses' ? 'Proses' : 'Selesai') +
                ': ' + (counts[key] ?? 0).toString())),
          ]))),
          for (final raw in rows)
            Builder(builder: (context) {
              final item = Map<String, dynamic>.from(raw as Map);
              return Card(child: ListTile(
                title: Text((item['reference_no'] ?? 'Surat').toString()),
                subtitle: Text(cikokoLetterStatus((item['status'] ?? '').toString())),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showDialog<void>(context: context, builder: (ctx) => AlertDialog(
                  title: Text((item['reference_no'] ?? 'Surat').toString()),
                  content: Text('Status: ' + cikokoLetterStatus((item['status'] ?? '').toString()) +
                      '\nDiterima: ' + (item['created_at'] ?? '-').toString()),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))],
                )),
              ));
            }),
          if (rows.isEmpty) const ListTile(title: Text('Belum ada nomor surat publik.')),
        ]);
      },
    ),
  );
}

class CikokoRtRwPage extends StatefulWidget {
  final CikokoApi api;
  final String role;
  const CikokoRtRwPage({super.key, required this.api, required this.role});
  @override
  State<CikokoRtRwPage> createState() => _CikokoRtRwPageState();
}
class _CikokoRtRwPageState extends State<CikokoRtRwPage> {
  List<Map<String, dynamic>> letters = [];
  bool loading = true;
  String error = '';
  @override
  void initState() { super.initState(); reload(); }
  Future<void> reload() async {
    if (mounted) setState(() { loading = true; error = ''; });
    try {
      final result = await widget.api.call('rt_rw_list');
      if (mounted) setState(() => letters = List<dynamic>.from(result['items'] ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map)).toList());
    } catch (e) { if (mounted) setState(() => error = e.toString()); }
    finally { if (mounted) setState(() => loading = false); }
  }
  void detail(Map<String, dynamic> item) => showModalBottomSheet<void>(
    context: context, isScrollControlled: true, useSafeArea: true,
    builder: (sheet) {
      final form = item['form'] is Map ? Map<String, dynamic>.from(item['form'] as Map) : <String, dynamic>{};
      return SizedBox(height: MediaQuery.sizeOf(sheet).height * .82,
        child: ListView(padding: const EdgeInsets.all(18), children: [
          Text('Surat Pengantar RT/RW', style: Theme.of(sheet).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('No. CK-RT-' + (cikokoLetterId(item) ?? 0).toString().padLeft(6, '0')),
          Text('Status: ' + cikokoLetterStatus((item['status'] ?? '').toString())),
          Text('RT ' + (item['rt'] ?? '-').toString() + ' / RW ' + (item['rw'] ?? '-').toString()),
          const Divider(),
          for (final field in rtRwFormFields.entries)
            if (form[field.key] != null)
              ListTile(dense: true, title: Text(field.value), subtitle: Text(form[field.key].toString())),
          if (form.isEmpty) const ListTile(title: Text('Data formulir lama belum tersedia.')),
          const Divider(),
          const Text('Alur: Masuk → Verifikasi RT → Verifikasi RW → Terverifikasi',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 18),
          OutlinedButton(onPressed: () => Navigator.pop(sheet), child: const Text('Tutup')),
        ]),
      );
    },
  );
  bool canDecide(Map<String, dynamic> item) {
    final status = (item['status'] ?? '').toString();
    return (widget.role == 'rt' && status == 'menunggu_rt') ||
      (widget.role == 'rw' && status == 'menunggu_rw');
  }
  Future<void> decide(Map<String, dynamic> item) async {
    final id = cikokoLetterId(item);
    if (id == null) { showError('ID pengajuan tidak tersedia dari server. Muat ulang daftar.'); await reload(); return; }
    final password = TextEditingController();
    final note = TextEditingController();
    var reject = false;
    try {
      await showDialog<void>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) => AlertDialog(
        title: const Text('Verifikasi Surat RT/RW'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Nomor CK-RT-' + id.toString().padLeft(6, '0')),
          const SizedBox(height: 8),
          SwitchListTile(title: Text(reject ? 'Tolak pengajuan' : 'Setujui pengajuan'),
            value: reject, onChanged: (v) => setDialog(() => reject = v)),
          TextField(controller: note, maxLines: 2,
            decoration: InputDecoration(labelText: reject ? 'Alasan penolakan (wajib)' : 'Catatan (opsional)')),
          TextField(controller: password, obscureText: true,
            decoration: const InputDecoration(labelText: 'Password akun RT/RW')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(onPressed: () async {
            if (password.text.isEmpty || (reject && note.text.trim().length < 5)) {
              showError('Isi password dan alasan penolakan minimal 5 karakter bila menolak.'); return;
            }
            try {
              await widget.api.call('rt_rw_decide', body: {
                'id': id, 'decision': reject ? 'reject' : 'approve',
                'current_password': password.text, 'note': note.text.trim(),
              });
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (mounted) { ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Keputusan berhasil disimpan.'))); await reload(); }
            } catch (e) { showError(e.toString()); }
          }, child: const Text('Konfirmasi')),
        ],
      )));
    } finally { password.dispose(); note.dispose(); }
  }
  void showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700));
  }
  Future<void> setupSignature() async {
    final password = TextEditingController();
    XFile? signature, stamp;
    try {
      await showDialog<void>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) =>
        AlertDialog(title: const Text('Daftarkan TTD dan Stempel'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Gunakan gambar JPG/PNG/WebP maksimal 2 MB per berkas.'),
            TextButton(onPressed: () async {
              final file = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (file != null) setDialog(() => signature = file);
            }, child: Text(signature == null ? 'Pilih Gambar TTD' : 'TTD dipilih')),
            TextButton(onPressed: () async {
              final file = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (file != null) setDialog(() => stamp = file);
            }, child: Text(stamp == null ? 'Pilih Gambar Stempel' : 'Stempel dipilih')),
            TextField(controller: password, obscureText: true,
              decoration: const InputDecoration(labelText: 'Konfirmasi password akun')),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(onPressed: () async {
              if (signature == null || stamp == null || password.text.isEmpty) {
                showError('Pilih TTD, stempel dan isi password.'); return;
              }
              try {
                await widget.api.upload('rt_rw_signer_upload', {'password': password.text},
                  {'signature': [signature!.path], 'stamp': [stamp!.path]});
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('TTD dan stempel disimpan.')));
              } catch (e) { showError(e.toString()); }
            }, child: const Text('Simpan')),
          ],
        )));
    } finally { password.dispose(); }
  }
  Future<void> submit() async {
    final values = <String, TextEditingController>{for (final k in rtRwFormFields.keys) k: TextEditingController()};
    try {
      final profile = widget.api.profile ?? {};
      values['nama']!.text = (profile['name'] ?? '').toString();
      values['alamat']!.text = (profile['address'] ?? '').toString();
      await showDialog<void>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Ajukan Surat Pengantar RT/RW'),
        content: SizedBox(width: 500, child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min, children: [
            const Text('Wilayah RT/RW diambil otomatis dari profil akun Anda.'),
            for (final entry in rtRwFormFields.entries)
              Padding(padding: const EdgeInsets.only(top: 9), child: TextField(
                controller: values[entry.key],
                decoration: InputDecoration(labelText: entry.value),
                keyboardType: entry.key == 'tanggal_lahir' ? TextInputType.datetime : TextInputType.text,
              )),
          ],
        ))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(onPressed: () async {
            final form = <String, String>{for (final k in rtRwFormFields.keys) k: values[k]!.text.trim()};
            if (form.values.any((value) => value.isEmpty)) { showError('Lengkapi semua kolom formulir.'); return; }
            try {
              final result = await widget.api.call('rt_rw_submit', body: {'form': form});
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:
                  Text('Surat dikirim. ID: ' + (result['id'] ?? '').toString())));
                await reload();
              }
            } catch (e) { showError(e.toString()); }
          }, child: const Text('Kirim Surat')),
        ],
      ));
    } finally { for (final v in values.values) { v.dispose(); } }
  }
  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(padding: const EdgeInsets.all(10), child: Row(children: [
      const Expanded(child: Text('Surat Digital RT/RW',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
      if (widget.role == 'warga') FilledButton.icon(
        onPressed: submit, icon: const Icon(Icons.add), label: const Text('Ajukan')),
      if (widget.role == 'rt' || widget.role == 'rw')
        IconButton(tooltip: 'Daftarkan TTD/Stempel', onPressed: setupSignature,
          icon: const Icon(Icons.draw_outlined)),
      IconButton(onPressed: reload, icon: const Icon(Icons.refresh)),
    ])),
    Expanded(child: loading ? const Center(child: CircularProgressIndicator()) :
      error.isNotEmpty ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(error, textAlign: TextAlign.center),
        TextButton(onPressed: reload, child: const Text('Coba Lagi')),
      ])) : RefreshIndicator(onRefresh: reload, child: ListView(children: [
        for (final letter in letters) Card(child: ListTile(
          title: Text('Surat ' + (letter['subject'] ?? 'Pengantar').toString(),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('CK-RT-' + (cikokoLetterId(letter) ?? 0).toString().padLeft(6, '0') +
            '\n' + cikokoLetterStatus((letter['status'] ?? '').toString())),
          isThreeLine: true,
          onTap: () => detail(letter),
          trailing: canDecide(letter)
              ? TextButton(onPressed: () => decide(letter), child: const Text('Verifikasi'))
              : const Icon(Icons.chevron_right),
        )),
        if (letters.isEmpty) const ListTile(title: Text('Belum ada pengajuan di wilayah atau akun ini.')),
      ]))),
  ]);
}
