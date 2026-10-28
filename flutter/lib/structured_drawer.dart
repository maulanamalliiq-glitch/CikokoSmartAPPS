import 'package:flutter/material.dart';
import 'role_catalog.dart';

const _navy = Color(0xff10375f);
const _blue = Color(0xff226fda);
const _muted = Color(0xff647b91);
const _panel = Color(0xfff2f6fb);

/// Struktur navigasi saja. Setiap submenu berasal dari daftar RoleFeature
/// yang sudah disaring oleh hak akses akun pada role_catalog.dart.
class CikokoMenuGroup {
  final String id;
  final String title;
  final IconData icon;
  final List<RoleFeature> features;
  const CikokoMenuGroup(this.id, this.title, this.icon, this.features);
}

class _GroupDef {
  final String id;
  final String title;
  final IconData icon;
  const _GroupDef(this.id, this.title, this.icon);
}

const _menuOrder = <_GroupDef>[
  _GroupDef('petugas', 'Petugas & Wilayah', Icons.apartment_outlined),
  _GroupDef('laporan', 'Laporan Wilayah', Icons.fact_check_outlined),
  _GroupDef('surat', 'Surat & Ahli Waris', Icons.description_outlined),
  _GroupDef('informasi', 'Berita & Informasi', Icons.campaign_outlined),
  _GroupDef('komunikasi', 'Komunikasi', Icons.forum_outlined),
  _GroupDef('layanan', 'Layanan & Lainnya', Icons.widgets_outlined),
];

String cikokoGroupForFeature(RoleFeature feature) {
  final route = feature.route.toLowerCase();
  final name = feature.title.toLowerCase();

  // Kategori laporan: LPJ, kegiatan, monitoring dan verifikasi laporan.
  if (route.startsWith('laporan ') ||
      route.startsWith('lpj ') ||
      route == 'verifikasi kegiatan' ||
      route == 'monitoring wilayah' ||
      name.startsWith('laporan lpj')) {
    return 'laporan';
  }

  // Surat dan arsip, termasuk verifikasi yang khusus ahli waris.
  if (route.contains('ahli waris') ||
      route.startsWith('surat ') ||
      route == 'persetujuan lurah') {
    return 'surat';
  }

  // Pengelolaan petugas, hak akses dan wilayah kerja.
  if (route.contains('bendahara') ||
      route.contains('akun petugas') ||
      route.contains('ketua rt/rw') ||
      route.contains('hak akses') ||
      route.contains('pegawai') ||
      route.contains('piket') ||
      route.contains('kehadiran') ||
      route.contains('kinerja') ||
      route.contains('cuti') ||
      route == 'protap') {
    return 'petugas';
  }

  if (route == 'berita & kegiatan' ||
      route == 'pengumuman' ||
      route == 'galeri' ||
      route == 'tambah berita' ||
      route == 'tambah pengumuman') {
    return 'informasi';
  }

  if (route == 'pesan masuk' || route == 'hubungi kami') {
    return 'komunikasi';
  }

  return 'layanan';
}

List<CikokoMenuGroup> cikokoGroupedMenus(List<RoleFeature> allowedFeatures) {
  final groups = <String, List<RoleFeature>>{
    for (final definition in _menuOrder) definition.id: <RoleFeature>[],
  };
  for (final feature in allowedFeatures) {
    groups[cikokoGroupForFeature(feature)]!.add(feature);
  }
  return [
    for (final definition in _menuOrder)
      if (groups[definition.id]!.isNotEmpty)
        CikokoMenuGroup(
          definition.id, definition.title, definition.icon,
          List<RoleFeature>.unmodifiable(groups[definition.id]!),
        ),
  ];
}

/// Drawer accordion: hanya satu kelompok terbuka dalam satu waktu.
/// Tidak memanggil API, tidak menulis data, dan tidak menambah hak akses.
class CikokoStructuredDrawer extends StatefulWidget {
  final Widget avatar;
  final String accountName;
  final String roleLabel;
  final bool guest;
  final List<RoleFeature> allowedFeatures;
  final String currentRoute;
  final IconData Function(String route) iconFor;
  final ValueChanged<String> onNavigate;
  final VoidCallback onClose;
  final VoidCallback onLogin;
  final VoidCallback onLogout;

  const CikokoStructuredDrawer({
    super.key,
    required this.avatar,
    required this.accountName,
    required this.roleLabel,
    required this.guest,
    required this.allowedFeatures,
    required this.currentRoute,
    required this.iconFor,
    required this.onNavigate,
    required this.onClose,
    required this.onLogin,
    required this.onLogout,
  });

  @override
  State<CikokoStructuredDrawer> createState() => _CikokoStructuredDrawerState();
}

class _CikokoStructuredDrawerState extends State<CikokoStructuredDrawer> {
  String? _expanded;

  @override
  void initState() {
    super.initState();
    _expandCurrentRoute();
  }

  @override
  void didUpdateWidget(covariant CikokoStructuredDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentRoute != oldWidget.currentRoute ||
        widget.allowedFeatures != oldWidget.allowedFeatures) {
      _expandCurrentRoute();
    }
  }

  void _expandCurrentRoute() {
    final matches = cikokoGroupedMenus(widget.allowedFeatures)
        .where((g) => g.features.any((f) => f.route == widget.currentRoute));
    // Saat di Beranda: semua bagian tertutup agar navbar lebih ringkas.
    _expanded = matches.isEmpty ? null : matches.first.id;
  }

  Widget _homeTile() {
    final active = widget.currentRoute == 'Dashboard';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 7),
      child: Material(
        color: active ? const Color(0xffe4efff) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          key: const Key('nav_beranda'),
          dense: true,
          minLeadingWidth: 26,
          leading: Icon(active ? Icons.home_rounded : Icons.home_outlined,
              size: 21, color: active ? _blue : _muted),
          title: Text('Beranda', style: TextStyle(
              fontSize: 13.5, fontWeight: FontWeight.w700,
              color: active ? _blue : _navy)),
          trailing: active ? const Icon(Icons.circle, size: 8, color: _blue) : null,
          onTap: () => widget.onNavigate('Dashboard'),
        ),
      ),
    );
  }

  Widget _group(CikokoMenuGroup group) {
    final expanded = _expanded == group.id;
    final active = group.features.any((f) => f.route == widget.currentRoute);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 3, 12, 3),
      child: Column(children: [
        Material(
          color: expanded || active ? const Color(0xffeaf2fd) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            key: Key('nav_group_${group.id}'),
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() {
              _expanded = expanded ? null : group.id;
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(children: [
                Icon(group.icon, size: 21,
                    color: expanded || active ? _blue : _muted),
                const SizedBox(width: 13),
                Expanded(child: Text(group.title,
                  style: TextStyle(fontSize: 13.1, fontWeight: FontWeight.w700,
                    color: expanded || active ? _navy : const Color(0xff29445e)))),
                Container(
                  constraints: const BoxConstraints(minWidth: 21),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(7)),
                  child: Text('${group.features.length}', style: const TextStyle(
                      fontSize: 10, color: _muted, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 7),
                Icon(expanded ? Icons.keyboard_arrow_up_rounded :
                    Icons.keyboard_arrow_down_rounded, size: 20,
                    color: _muted),
              ]),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: expanded ? Padding(
            padding: const EdgeInsets.fromLTRB(19, 3, 0, 5),
            child: DecoratedBox(
              decoration: const BoxDecoration(border: Border(
                  left: BorderSide(color: Color(0xffd7e4f4), width: 2))),
              child: Column(children: [
                for (final feature in group.features)
                  _submenu(feature),
              ]),
            ),
          ) : const SizedBox.shrink(),
        ),
      ]),
    );
  }

  Widget _submenu(RoleFeature feature) {
    final active = feature.route == widget.currentRoute;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 0, 2),
      child: Material(
        color: active ? const Color(0xffe5efff) : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: ListTile(
          key: Key('nav_route_${feature.route}'),
          dense: true,
          visualDensity: const VisualDensity(vertical: -2),
          contentPadding: const EdgeInsets.symmetric(horizontal: 9),
          minLeadingWidth: 18,
          leading: Icon(widget.iconFor(feature.route), size: 18,
              color: active ? _blue : _muted),
          title: Text(feature.title, maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? _blue : _navy)),
          subtitle: feature.connected ? null : const Text(
              'Modul belum tersedia',
              style: TextStyle(fontSize: 9.5, color: _muted)),
          trailing: const Icon(Icons.chevron_right_rounded,
              size: 17, color: Color(0xff9aafc4)),
          onTap: () => widget.onNavigate(feature.route),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Append 'Hubungi Kami' hanya jika belum ada di modul pengguna.
    final features = [
      ...widget.allowedFeatures,
      if (!widget.allowedFeatures.any((f) => f.route == 'Hubungi Kami'))
        const RoleFeature('Hubungi Kami', 'Pesan ke petugas',
            'Hubungi Kami'),
    ];
    final groups = cikokoGroupedMenus(features);
    return SafeArea(child:Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        decoration: const BoxDecoration(color: _panel, border: Border(
            bottom: BorderSide(color: Color(0xffdfe8f3)))),
        child: Row(children: [
          widget.avatar,
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.accountName, maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15.5,
                      fontWeight: FontWeight.w800, color: _navy)),
              const SizedBox(height: 3),
              Text(widget.roleLabel, maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: _muted)),

            ])),
          IconButton(onPressed:widget.onClose,
            tooltip: 'Tutup menu', icon:const Icon(Icons.close_rounded, size:20)),
        ]),
      ),
      Expanded(child: ListView(
        padding: const EdgeInsets.only(bottom: 10),
        children: [
          _homeTile(),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 6, 12, 8),
            child: Text('KATEGORI MENU',
              style: TextStyle(color: _muted, letterSpacing: 1.05,
                  fontSize: 10, fontWeight: FontWeight.w800))),
          for (final group in groups) _group(group),
          if (groups.isEmpty) const Padding(
            padding: EdgeInsets.all(18),
            child: Text('Belum ada menu untuk hak akses akun ini.')),
        ],
      )),
      const Divider(height: 1),
      Padding(padding: const EdgeInsets.fromLTRB(11, 7, 11, 9),
        child: ListTile(
          key: Key(widget.guest ? 'nav_login' : 'nav_logout'),
          dense: true,
          leading: Icon(widget.guest ? Icons.login_rounded :
              Icons.logout_rounded, color: widget.guest ? _blue : _navy),
          title: Text(widget.guest ? 'Login / Daftar Warga' : 'Keluar',
              style: const TextStyle(fontSize: 13.5,
                  fontWeight: FontWeight.w700)),
          onTap: widget.guest ? widget.onLogin : widget.onLogout,
        )),
    ]));
  }
}
