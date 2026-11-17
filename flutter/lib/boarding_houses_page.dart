import 'package:flutter/material.dart';
import 'api.dart';
import 'cikoko_v6_showcase.dart';

class BoardingHousesPage extends StatefulWidget {
  final CikokoApi api;
  final String role;
  const BoardingHousesPage({super.key, required this.api, required this.role});
  @override
  State<BoardingHousesPage> createState() => _BoardingHousesPageState();
}

class _BoardingHousesPageState extends State<BoardingHousesPage> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> items = [];
  String rt = '', rw = '';
  bool get canEnter => widget.role == 'rt' || widget.role == 'admin' || widget.role == 'admin_kelurahan';
  bool get canVerify => widget.role == 'rw' || widget.role == 'admin' || widget.role == 'admin_kelurahan';

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      final result = await widget.api.call('boarding_list');
      if (!mounted) return;
      setState(() {
        items = (result['items'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        rt = (result['rt'] ?? '').toString();
        rw = (result['rw'] ?? '').toString();
      });
    } catch (e) { if (mounted) setState(() => error = e.toString()); }
    finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> edit([Map<String, dynamic>? existing]) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context, isScrollControlled: true, useSafeArea: true,
      showDragHandle: true, builder: (_) => _BoardingHouseForm(existing: existing, rt: rt, rw: rw, canChooseArea: widget.role == 'admin' || widget.role == 'admin_kelurahan'));
    if (result == null) return;
    try {
      await widget.api.call('boarding_save', body: result);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data tersimpan dan menunggu verifikasi Ketua RW.')));
      await load();
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
  }

  Future<void> decide(Map<String, dynamic> item, bool approve) async {
    final note = TextEditingController();
    final decision = approve ? 'verified' : 'rejected';
    if (!approve) {
      final value = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Kembalikan untuk diperbaiki'),
        content: TextField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'Catatan untuk RT', border: OutlineInputBorder())),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(ctx, note.text.trim()), child: const Text('Kirim'))],
      ));
      if (value == null || value.isEmpty) return;
    }
    try {
      await widget.api.call('boarding_verify', body: {'id': item['id'], 'decision': decision, 'note': note.text.trim()});
      await load();
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: load,
    child: ListView(padding: const EdgeInsets.fromLTRB(14, 10, 14, 24), children: [
      const V6PageHeader(title: 'Pendataan Rumah Kos', description: 'RT mendata rumah kos di wilayahnya. Ketua RW memeriksa sebelum data dipublikasikan.', icon: Icons.apartment_outlined),
      if (rt.isNotEmpty || rw.isNotEmpty) V6Panel(child: Row(children: [const Icon(Icons.location_on_outlined, color: V6.blue), const SizedBox(width: 8), Text('Wilayah tugas  RT ${rt.isEmpty ? '—' : rt}  ·  RW ${rw.isEmpty ? '—' : rw}', style: const TextStyle(color: V6.ink, fontWeight: FontWeight.w700, fontSize: 12))])),
      const SizedBox(height: 12),
      if (canEnter) Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: () => edit(), icon: const Icon(Icons.add), label: const Text('Tambah data kos')),
      if (loading) const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())),
      if (!loading && error != null) V6Panel(child: Column(children: [Text(error!, textAlign: TextAlign.center), TextButton(onPressed: load, child: const Text('Coba lagi'))])),
      if (!loading && error == null && items.isEmpty) const V6Panel(child: Text('Belum ada data rumah kos pada wilayah ini.', style: TextStyle(color: V6.secondary))),
      for (final item in items) _BoardingHouseCard(item: item, canEnter: canEnter, canVerify: canVerify, onEdit: () => edit(item), onApprove: () => decide(item, true), onReject: () => decide(item, false)),
    ]),
  );
}

class _BoardingHouseCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool canEnter, canVerify;
  final VoidCallback onEdit, onApprove, onReject;
  const _BoardingHouseCard({required this.item, required this.canEnter, required this.canVerify, required this.onEdit, required this.onApprove, required this.onReject});
  @override
  Widget build(BuildContext context) {
    final status = (item['review_status'] ?? 'pending').toString();
    final verified = status == 'verified';
    final rejected = status == 'rejected';
    final label = verified ? 'Terverifikasi' : rejected ? 'Perlu diperbaiki' : 'Menunggu verifikasi';
    final color = verified ? V6.green : rejected ? V6.red : V6.amber;
    return Padding(padding: const EdgeInsets.only(top: 10), child: V6Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text((item['name'] ?? 'Rumah kos').toString(), style: const TextStyle(fontWeight: FontWeight.w800, color: V6.ink, fontSize: 14))), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: V6.radius(20)), child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)))]),
      const SizedBox(height: 8),
      Text('${item['address']}\nRT ${item['rt']} / RW ${item['rw']}  ·  Kamar ${item['occupied_rooms']}/${item['total_rooms']} terisi', style: const TextStyle(color: V6.secondary, height: 1.45, fontSize: 11.5)),
      if ((item['review_note'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 7), child: Text('Catatan: ${item['review_note']}', style: const TextStyle(color: V6.red, fontSize: 11))),
      if ((item['facilities'] as List? ?? []).isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Wrap(spacing: 5, runSpacing: 5, children: (item['facilities'] as List).map<Widget>((e) => Chip(label: Text(e.toString()), visualDensity: VisualDensity.compact, labelStyle: const TextStyle(fontSize: 10))).toList())),
      const Divider(height: 20),
      Wrap(spacing: 8, runSpacing: 8, children: [
        if (canEnter) OutlinedButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 16), label: const Text('Ubah')),
        if (canVerify && status == 'pending') ...[
          FilledButton.icon(onPressed: onApprove, icon: const Icon(Icons.check, size: 16), label: const Text('Setujui')),
          OutlinedButton.icon(onPressed: onReject, icon: const Icon(Icons.undo, size: 16), label: const Text('Kembalikan')),
        ],
      ]),
    ])));
  }
}

class _BoardingHouseForm extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final String rt, rw;
  final bool canChooseArea;
  const _BoardingHouseForm({this.existing, required this.rt, required this.rw, required this.canChooseArea});
  @override State<_BoardingHouseForm> createState() => _BoardingHouseFormState();
}
class _BoardingHouseFormState extends State<_BoardingHouseForm> {
  final formKey = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.existing?['name']?.toString() ?? '');
  late final address = TextEditingController(text: widget.existing?['address']?.toString() ?? '');
  late final manager = TextEditingController(text: widget.existing?['manager_name']?.toString() ?? '');
  late final phone = TextEditingController(text: widget.existing?['manager_phone']?.toString() ?? '');
  late final rooms = TextEditingController(text: widget.existing?['total_rooms']?.toString() ?? '');
  late final occupied = TextEditingController(text: widget.existing?['occupied_rooms']?.toString() ?? '0');
  late final rt = TextEditingController(text: widget.existing?['rt']?.toString() ?? widget.rt);
  final facilities = <String>{};
  bool listing = true, publicAddress = false, publicContact = false, active = true;
  static const options = ['Wi-Fi','AC','Kamar mandi dalam','Parkir','Furnitur','Dapur','Keamanan'];
  @override void initState() { super.initState(); final e = widget.existing; if (e != null) { facilities.addAll((e['facilities'] as List? ?? []).map((v) => v.toString())); listing = e['public_listing'] == true; publicAddress = e['public_address'] == true; publicContact = e['public_contact'] == true; active = e['record_status'] != 'closed'; } }
  @override void dispose() { name.dispose(); address.dispose(); manager.dispose(); phone.dispose(); rooms.dispose(); occupied.dispose(); rt.dispose(); super.dispose(); }
  String? requiredValue(String? value, String label) => (value == null || value.trim().isEmpty) ? 'Isi $label.' : null;
  @override Widget build(BuildContext context) => Padding(padding: EdgeInsets.fromLTRB(18, 4, 18, MediaQuery.viewInsetsOf(context).bottom + 18), child: Form(key: formKey, child: ListView(shrinkWrap: true, children: [
    Text(widget.existing == null ? 'Tambah rumah kos' : 'Ubah data rumah kos', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: V6.ink)),
    const SizedBox(height: 6), const Text('Jangan masukkan nama penghuni, NIK, atau nomor KK.', style: TextStyle(fontSize: 11, color: V6.secondary)), const SizedBox(height: 14),
    TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Nama rumah kos', border: OutlineInputBorder()), validator: (v) => requiredValue(v, 'nama kos')),
    const SizedBox(height: 10), TextFormField(controller: address, maxLines: 2, decoration: const InputDecoration(labelText: 'Alamat lengkap untuk petugas', border: OutlineInputBorder()), validator: (v) => requiredValue(v, 'alamat')),
    const SizedBox(height: 10), if (widget.canChooseArea) TextFormField(controller: rt, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'RT', border: OutlineInputBorder())),
    if (!widget.canChooseArea) Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text('Wilayah: RT ${widget.rt} / RW ${widget.rw}', style: const TextStyle(color: V6.secondary))),
    const SizedBox(height: 4), TextFormField(controller: manager, decoration: const InputDecoration(labelText: 'Nama pengelola', border: OutlineInputBorder()), validator: (v) => requiredValue(v, 'nama pengelola')),
    const SizedBox(height: 10), TextFormField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Nomor telepon pengelola (opsional)', border: OutlineInputBorder())),
    const SizedBox(height: 10), Row(children: [Expanded(child: TextFormField(controller: rooms, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Jumlah kamar', border: OutlineInputBorder()), validator: (v) => requiredValue(v, 'jumlah kamar'))), const SizedBox(width: 8), Expanded(child: TextFormField(controller: occupied, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Kamar terisi', border: OutlineInputBorder()), validator: (v) => requiredValue(v, 'kamar terisi')))]),
    const SizedBox(height: 12), const Text('Fasilitas', style: TextStyle(fontWeight: FontWeight.w700, color: V6.ink)), Wrap(spacing: 4, children: options.map((v) => FilterChip(label: Text(v), selected: facilities.contains(v), onSelected: (on) => setState(() => on ? facilities.add(v) : facilities.remove(v)))).toList()),
    SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Kos masih aktif'), value: active, onChanged: (v) => setState(() => active = v)),
    const Divider(), const Text('Tampilan di beranda aplikasi', style: TextStyle(fontWeight: FontWeight.w800, color: V6.ink)),
    SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Tampilkan nama kos dan jumlah kamar'), value: listing, onChanged: (v) => setState(() { listing = v; if (!v) { publicAddress = false; publicContact = false; } })),
    SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Tampilkan alamat lengkap'), subtitle: const Text('RT/RW tetap terlihat jika alamat lengkap disembunyikan.'), value: publicAddress && listing, onChanged: listing ? (v) => setState(() => publicAddress = v) : null),
    SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Tampilkan nomor pengelola'), value: publicContact && listing, onChanged: listing && phone.text.isNotEmpty ? (v) => setState(() => publicContact = v) : null),
    const SizedBox(height: 12), FilledButton(onPressed: () { if (formKey.currentState?.validate() != true) return; final total = int.tryParse(rooms.text) ?? 0, used = int.tryParse(occupied.text) ?? -1; if (total < 1 || used < 0 || used > total) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pastikan jumlah kamar benar dan kamar terisi tidak melebihi jumlah kamar.'))); return; } Navigator.pop(context, <String, dynamic>{'id': widget.existing?['id'], 'name': name.text.trim(), 'address': address.text.trim(), 'manager_name': manager.text.trim(), 'manager_phone': phone.text.trim(), 'total_rooms': total, 'occupied_rooms': used, 'facilities': facilities.toList(), 'public_listing': listing, 'public_address': publicAddress, 'public_contact': publicContact, 'record_status': active ? 'active' : 'closed', 'rt': rt.text.trim(), 'rw': widget.rw}); }, child: const Text('Simpan data')),
  ])));
}
