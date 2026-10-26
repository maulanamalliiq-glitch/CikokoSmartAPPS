import 'package:flutter/material.dart';
import 'api.dart';

/// V2513 — alur verifikasi wilayah. Tidak menerbitkan TTE, stempel, atau PDF.
class RtRwLettersPage extends StatefulWidget {
  final CikokoApi api;
  const RtRwLettersPage({super.key, required this.api});
  @override
  State<RtRwLettersPage> createState() => _RtRwLettersState();
}

class _RtRwLettersState extends State<RtRwLettersPage> {
  final subject = TextEditingController();
  final notes = TextEditingController();
  late Future<Map<String, dynamic>> requests;
  bool saving = false;

  String get role => '${widget.api.profile?['role'] ?? ''}';
  @override
  void initState() { super.initState(); refresh(); }
  @override
  void dispose() { subject.dispose(); notes.dispose(); super.dispose(); }
  void refresh() { requests = widget.api.call('rt_rw_list'); }
  void flash(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
  String statusLabel(String status) {
    const labels = {
      'menunggu_rt': 'Menunggu Ketua RT',
      'menunggu_rw': 'Menunggu Ketua RW',
      'terverifikasi': 'Verifikasi RT dan RW selesai',
      'ditolak': 'Ditolak',
    };
    return labels[status] ?? status;
  }
  Future<void> submit() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await widget.api.call('rt_rw_submit', body: {
        'subject': subject.text.trim(), 'notes': notes.text.trim(),
      });
      subject.clear(); notes.clear();
      if (mounted) setState(refresh);
      flash('Permohonan berhasil dikirim ke Ketua RT sesuai data profil.');
    } catch (e) { flash('$e'); }
    finally { if (mounted) setState(() => saving = false); }
  }

  Future<void> decide(Map<String, dynamic> letter) async {
    final reason = TextEditingController(), password = TextEditingController();
    String decision = 'approve';
    try {
      final approved = await showDialog<bool>(
        context: context,
        builder: (dialog) => StatefulBuilder(builder: (context, rebuild) => AlertDialog(
          title: const Text('Verifikasi Surat Pengantar'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${letter['subject'] ?? ''}'),
            const SizedBox(height: 8),
            Text('RT ${letter['rt'] ?? ''} / RW ${letter['rw'] ?? ''}'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: decision,
              decoration: const InputDecoration(labelText: 'Keputusan'),
              items: const [
                DropdownMenuItem(value: 'approve', child: Text('Setujui tahap ini')),
                DropdownMenuItem(value: 'reject', child: Text('Tolak permohonan')),
              ],
              onChanged: (v) => rebuild(() => decision = v ?? 'approve'),
            ),
            const SizedBox(height: 10),
            TextField(controller: reason, maxLines: 2,
              decoration: InputDecoration(labelText: decision == 'reject' ? 'Alasan penolakan (wajib)' : 'Catatan (opsional)')),
            const SizedBox(height: 10),
            TextField(controller: password, obscureText: true,
              decoration: const InputDecoration(labelText: 'Konfirmasi password petugas')),
            const SizedBox(height: 8),
            const Text('Verifikasi ini bukan tanda tangan atau stempel elektronik.',
              style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Simpan Keputusan')),
          ],
        )),
      );
      if (approved != true) return;
      await widget.api.call('rt_rw_decide', body: {
        'id': letter['id'], 'decision': decision,
        'note': reason.text.trim(), 'current_password': password.text,
      });
      if (mounted) setState(refresh);
      flash('Verifikasi tersimpan.');
    } catch (e) { flash('$e'); }
    finally { reason.dispose(); password.dispose(); }
  }

  @override
  Widget build(BuildContext context) {
    final isWarga = role == 'warga';
    final canVerify = role == 'rt' || role == 'rw';
    return ListView(padding: const EdgeInsets.all(14), children: [
      Text(isWarga ? 'Surat Pengantar RT/RW' : 'Permohonan Surat Wilayah',
        style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      const Text('Wilayah penerima mengikuti RT/RW yang tersimpan pada profil warga.'),
      const SizedBox(height: 12),
      if (isWarga) Card(child: Padding(padding: const EdgeInsets.all(14), child:
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('RT ${widget.api.profile?['rt'] ?? '-'} / RW ${widget.api.profile?['rw'] ?? '-'}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(controller: subject, decoration: const InputDecoration(labelText: 'Keperluan surat')),
          const SizedBox(height: 10),
          TextField(controller: notes, minLines: 3, maxLines: 5,
            decoration: const InputDecoration(labelText: 'Keterangan permohonan')),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: saving ? null : submit, icon: const Icon(Icons.send_outlined),
            label: Text(saving ? 'Mengirim...' : 'Kirim ke Ketua RT Otomatis')),
          const SizedBox(height: 6),
          const Text('Jika RT/RW belum terisi, lengkapi Profil dengan konfirmasi password terlebih dahulu.',
            style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
        ]))),
      const SizedBox(height: 14),
      Text(isWarga ? 'Riwayat Surat Pengantar' : 'Daftar Surat yang Ditangani',
        style: Theme.of(context).textTheme.titleMedium),
      FutureBuilder<Map<String, dynamic>>(
        future: requests,
        builder: (context, result) {
          if (result.connectionState != ConnectionState.done) {
            return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
          }
          if (result.hasError) {
            return TextButton.icon(onPressed: () => setState(refresh),
              icon: const Icon(Icons.refresh), label: Text('Gagal memuat: ${result.error}. Coba lagi'));
          }
          final rows = List<Map<String, dynamic>>.from(
            (result.data?['items'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e as Map)));
          if (rows.isEmpty) return const ListTile(title: Text('Belum ada permohonan surat.'));
          return Column(children: [
            for (final letter in rows) Card(child: Padding(padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${letter['subject'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${letter['applicant_name'] ?? ''} • RT ${letter['rt'] ?? ''} / RW ${letter['rw'] ?? ''}',
                  style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 5),
                Text('${letter['notes'] ?? ''}', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                Text(statusLabel('${letter['status'] ?? ''}'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
                if (canVerify && ((role == 'rt' && letter['status'] == 'menunggu_rt') ||
                    (role == 'rw' && letter['status'] == 'menunggu_rw')))
                  Align(alignment: Alignment.centerRight, child: TextButton.icon(
                    onPressed: () => decide(letter),
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('Verifikasi'))),
              ]))),
          ]);
        },
      ),
      const SizedBox(height: 12),
      const Text('Persetujuan RT/RW belum menghasilkan surat PDF resmi atau tanda tangan/stempel digital. '
        'Surat resmi hanya boleh diterbitkan setelah modul penerbitan dan otorisasi siap.',
        style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
    ]);
  }
}

/// Hak Admin Utama hanya menugaskan wilayah akun petugas, bukan memetakan warga.
class RtRwOfficerManager extends StatefulWidget {
  final CikokoApi api;
  const RtRwOfficerManager({super.key, required this.api});
  @override
  State<RtRwOfficerManager> createState() => _RtRwOfficerManagerState();
}
class _RtRwOfficerManagerState extends State<RtRwOfficerManager> {
  late Future<Map<String, dynamic>> officers;
  @override
  void initState() { super.initState(); reload(); }
  void reload() { officers = widget.api.call('rt_rw_officers'); }
  Future<void> edit(Map<String, dynamic> officer) async {
    final rt = TextEditingController(text: '${officer['rt'] ?? ''}');
    final rw = TextEditingController(text: '${officer['rw'] ?? ''}');
    try {
      final yes = await showDialog<bool>(context: context, builder: (d) => AlertDialog(
        title: Text('Wilayah ${officer['name'] ?? ''}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (officer['role'] == 'rt') TextField(controller: rt, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Nomor RT')),
          const SizedBox(height: 10),
          TextField(controller: rw, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Nomor RW')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Simpan')),
        ],
      ));
      if (yes != true) return;
      await widget.api.call('rt_rw_officer_assign', body: {
        'officer_id': officer['id'], 'rt': rt.text.trim(), 'rw': rw.text.trim(),
      });
      if (mounted) setState(reload);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wilayah Ketua RT/RW tersimpan.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally { rt.dispose(); rw.dispose(); }
  }
  @override Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: officers,
    builder: (context, response) {
      if (response.connectionState != ConnectionState.done)
        return const Center(child: CircularProgressIndicator());
      if (response.hasError)
        return Center(child: TextButton(onPressed: () => setState(reload),
          child: const Text('Muat ulang daftar Ketua RT/RW')));
      final rows = (response.data?['items'] as List<dynamic>? ?? [])
          .map((v) => Map<String, dynamic>.from(v as Map)).toList();
      return ListView(padding: const EdgeInsets.all(14), children: [
        Text('Wilayah Petugas RT/RW', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        const Text('Penugasan akun Ketua RT/RW resmi. Wilayah warga tetap dipilih saat mendaftar.'),
        const SizedBox(height: 12),
        if (rows.isEmpty) const ListTile(title: Text('Buat akun petugas berperan RT/RW terlebih dahulu.')),
        for (final officer in rows) Card(child: ListTile(
          title: Text('${officer['name'] ?? ''} (${(officer['role'] ?? '').toString().toUpperCase()})'),
          subtitle: Text('RT ${officer['rt'] ?? '-'} / RW ${officer['rw'] ?? '-'}'
            '${officer['active'] == true ? '' : ' • Tidak aktif'}'),
          trailing: const Icon(Icons.edit_location_alt_outlined),
          onTap: () => edit(officer),
        )),
      ]);
    },
  );
}
