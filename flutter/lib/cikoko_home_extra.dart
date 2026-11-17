import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';
import 'cikoko_v6_showcase.dart';

class V6AnnouncementTicker extends StatefulWidget {
  final List<dynamic> items;
  final VoidCallback onAll;
  const V6AnnouncementTicker({super.key, required this.items, required this.onAll});
  @override
  State<V6AnnouncementTicker> createState() => _V6AnnouncementTickerState();
}

class _V6AnnouncementTickerState extends State<V6AnnouncementTicker> {
  final controller = PageController();
  Timer? timer;
  int current = 0;

  List<Map<String, dynamic>> get rows => widget.items
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .where((e) => ['pengumuman', 'agenda', 'kegiatan']
          .contains((e['type'] ?? '').toString()))
      .take(8)
      .toList();

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant V6AnnouncementTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      current = 0;
      _start();
    }
  }

  void _start() {
    timer?.cancel();
    if (rows.length < 2) return;
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !controller.hasClients) return;
      current = (current + 1) % rows.length;
      controller.animateToPage(current,
          duration: const Duration(milliseconds: 420), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  String _date(Map<String, dynamic> row) {
    final value = (row['event_date'] ?? row['date'] ?? row['created_at'] ?? '').toString();
    final parsed = DateTime.tryParse(value);
    return parsed == null ? '—' : cikokoDateOnly(value).split(' ').take(3).join(' ');
  }

  String _time(Map<String, dynamic> row) {
    final value = (row['event_time'] ?? row['time'] ?? '').toString().trim();
    if (value.isNotEmpty) return value;
    final parsed = DateTime.tryParse((row['created_at'] ?? '').toString());
    if (parsed == null) return '—';
    return parsed.hour.toString().padLeft(2, '0') + ':' +
        parsed.minute.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    final visible = rows;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      V6Section(title: 'Pengumuman & Agenda',
          action: 'Lihat semua', onAction: widget.onAll),
      if (visible.isEmpty)
        const V6Panel(child: Text('Belum ada pengumuman kegiatan.',
            style: TextStyle(color: V6.secondary, fontSize: 11.5))),
      if (visible.isNotEmpty)
        V6Panel(
          padding: EdgeInsets.zero,
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                  color: V6.pale,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
              child: const Row(children: [
                Expanded(flex: 3, child: Text('TANGGAL',
                    style: TextStyle(fontSize: 9, color: V6.blue, fontWeight: FontWeight.w900))),
                Expanded(flex: 2, child: Text('WAKTU',
                    style: TextStyle(fontSize: 9, color: V6.blue, fontWeight: FontWeight.w900))),
                Expanded(flex: 6, child: Text('KEGIATAN',
                    style: TextStyle(fontSize: 9, color: V6.blue, fontWeight: FontWeight.w900))),
              ]),
            ),
            SizedBox(
              height: 48,
              child: PageView.builder(
                controller: controller,
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final row = visible[index];
                  return InkWell(
                    onTap: widget.onAll,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(children: [
                        Expanded(flex: 3, child: Text(_date(row), maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10.5, color: V6.ink,
                                fontWeight: FontWeight.w700))),
                        Expanded(flex: 2, child: Text(_time(row), maxLines: 1,
                            style: const TextStyle(fontSize: 10.5, color: V6.secondary))),
                        Expanded(flex: 6, child: Text(
                            (row['title'] ?? 'Kegiatan Kelurahan').toString(),
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10.5, color: V6.ink,
                                fontWeight: FontWeight.w700))),
                      ]),
                    ),
                  );
                },
              ),
            ),
            if (visible.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var i = 0; i < visible.length; i++)
                    Container(
                      width: i == current ? 14 : 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                          color: i == current ? V6.blue : V6.border,
                          borderRadius: V6.radius(5)),
                    ),
                ]),
              ),
          ]),
        ),
    ]);
  }
}

class V6NewsCarousel extends StatelessWidget {
  final List<dynamic> items;
  final CikokoApi api;
  final ValueChanged<Map<String, dynamic>> onOpen;
  final VoidCallback onAll;
  const V6NewsCarousel({
    super.key, required this.items, required this.api,
    required this.onOpen, required this.onAll,
  });

  @override
  Widget build(BuildContext context) {
    final rows = items.whereType<Map>()
        .where((e) => e['type'] == 'berita')
        .take(8).map((e) => Map<String, dynamic>.from(e)).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      V6Section(title: 'Berita Terbaru', action: 'Lihat semua', onAction: onAll),
      if (rows.isEmpty)
        const V6Panel(child: Text('Belum ada berita yang dipublikasikan.',
            style: TextStyle(color: V6.secondary, fontSize: 11.5))),
      if (rows.isNotEmpty)
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(width: 9),
            itemBuilder: (context, index) {
              final item = rows[index];
              final url = api.media((item['image'] ?? '').toString());
              return SizedBox(
                width: 218,
                child: Material(
                  color: Colors.white,
                  borderRadius: V6.radius(12),
                  child: InkWell(
                    onTap: () => onOpen(item),
                    borderRadius: V6.radius(12),
                    child: Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: V6.border),
                          borderRadius: V6.radius(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                            child: url.isEmpty
                                ? Container(height: 126, color: V6.pale,
                                    child: const Icon(Icons.newspaper_outlined,
                                        color: V6.blue, size: 32))
                                : Image.network(url, height: 126, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                        height: 126, color: V6.pale,
                                        child: const Icon(Icons.image_not_supported_outlined,
                                            color: V6.blue, size: 28))),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
                            child: Text((item['title'] ?? 'Berita Kelurahan').toString(),
                                maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11.5, color: V6.ink,
                                    fontWeight: FontWeight.w800, height: 1.25)),
                          ),
                          const Spacer(),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () => onOpen(item),
                              style: TextButton.styleFrom(
                                  padding: const EdgeInsets.fromLTRB(10, 0, 8, 7),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                              child: const Text('Lihat selengkapnya',
                                  style: TextStyle(fontSize: 10.5,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
    ]);
  }
}

String _waUrl(String phone) {
  var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('0')) digits = '62' + digits.substring(1);
  return digits.isEmpty ? '' : 'https://wa.me/' + digits;
}

Future<void> _openWhatsApp(BuildContext context, String phone) async {
  final uri = Uri.tryParse(_waUrl(phone));
  if (uri == null || !await canLaunchUrl(uri)) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp pengelola belum dapat dibuka.')));
    return;
  }
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class V6BoardingHouseDirectoryPage extends StatefulWidget {
  final CikokoApi api;
  const V6BoardingHouseDirectoryPage({super.key, required this.api});
  @override
  State<V6BoardingHouseDirectoryPage> createState() =>
      _V6BoardingHouseDirectoryPageState();
}

class _V6BoardingHouseDirectoryPageState extends State<V6BoardingHouseDirectoryPage> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> items = [];

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final value = await widget.api.call('boarding_public');
      if (mounted) {
        items = (value['items'] as List? ?? [])
            .whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        error = null;
      }
    } catch (e) {
      if (mounted) error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: load,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
      children: [
        const V6PageHeader(
          title: 'Direktori Rumah Kos Cikoko',
          description: 'Daftar kos aktif yang telah diverifikasi. Alamat dan kontak mengikuti izin publikasi.',
          icon: Icons.apartment_outlined,
        ),
        if (loading) const Center(
            child: Padding(padding: EdgeInsets.all(24),
                child: CircularProgressIndicator())),
        if (error != null) V6Panel(child: Text(error!,
            style: const TextStyle(color: V6.secondary))),
        if (!loading && error == null && items.isEmpty)
          const V6Panel(child: Text('Belum ada rumah kos yang dipublikasikan.')),
        for (final row in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: V6Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if ((row['photo_url'] ?? '').toString().isNotEmpty)
                ClipRRect(
                  borderRadius: V6.radius(10),
                  child: Image.network(row['photo_url'].toString(),
                      width: double.infinity, height: 190, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(height: 130,
                          color: V6.pale,
                          child: const Icon(Icons.apartment_outlined,
                              color: V6.blue, size: 35))),
                ),
              const SizedBox(height: 8),
              Text((row['name'] ?? 'Rumah kos').toString(),
                  style: const TextStyle(fontSize: 15, color: V6.ink,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              Text('RT ' + (row['rt'] ?? '—').toString() +
                  ' / RW ' + (row['rw'] ?? '—').toString(),
                  style: const TextStyle(fontSize: 11.5, color: V6.secondary)),
              Text((row['available_rooms'] ?? 0).toString() + ' kamar tersedia dari ' +
                  (row['total_rooms'] ?? 0).toString() + ' kamar',
                  style: const TextStyle(fontSize: 11.5, color: V6.secondary)),
              if ((row['address'] ?? '').toString().isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 6),
                    child: Text('Alamat: ' + row['address'].toString(),
                        style: const TextStyle(fontSize: 11.5, color: V6.ink))),
              if ((row['facilities'] as List? ?? []).isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 6),
                    child: Wrap(spacing: 5, runSpacing: 3,
                        children: (row['facilities'] as List).map((x) => Chip(
                            label: Text(x.toString(),
                                style: const TextStyle(fontSize: 10)),
                            visualDensity: VisualDensity.compact)).toList())),
              if (widget.api.token != null &&
                  (row['public_phone'] ?? '').toString().isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 5),
                    child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF168A52)),
                        onPressed: () => _openWhatsApp(
                            context, row['public_phone'].toString()),
                        icon: const Icon(Icons.chat),
                        label: const Text('Hubungi lewat WhatsApp'))),
              ]),
            ),
          ),
      ],
    ),
  );
}
