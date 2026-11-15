import 'package:flutter/material.dart';
import 'api.dart';

/// Release 2557 PJLP / ASN module. Never treats a local form as a verified record.
/// The PHP backend must enforce role authorization, GPS, selfie and approval.
class CikokoPjlp2557Page extends StatefulWidget {
  final CikokoApi api;
  final String role;
  const CikokoPjlp2557Page({super.key, required this.api, required this.role});
  @override
  State<CikokoPjlp2557Page> createState() => _CikokoPjlp2557PageState();
}

class _CikokoPjlp2557PageState extends State<CikokoPjlp2557Page> {
  bool loading = true;
  String? error;
  Map<String, dynamic> summary = {};
  List<dynamic> jobs = [];
  List<dynamic> attendance = [];
  bool get isPjlp => widget.role == 'pjlp';
  bool get isAdmin => widget.role == 'admin';
  bool get canMonitor => isAdmin || widget.role == 'asn' || widget.role == 'lurah';

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() { loading = true; error = null; });
    try {
      // Read-only request. No optimistic writes or fake local records.
      final response = await widget.api.call(
        isPjlp ? 'pjlp_self_dashboard' : 'pjlp_monitor_dashboard');
      if (!mounted) return;
      setState(() {
        summary = Map<String, dynamic>.from(response['summary'] as Map? ?? {});
        jobs = List<dynamic>.from(response['jobs'] as List? ?? []);
        attendance = List<dynamic>.from(response['attendance'] as List? ?? []);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { error = 'Data PJLP belum dapat dimuat dari server: $e'; });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget info(String title, Object? value) => Card(
    child: ListTile(title: Text(title), trailing: Text('${value ?? '-'}',
      style: const TextStyle(fontWeight: FontWeight.bold))));

  @override
  Widget build(BuildContext context) {
    if (!isPjlp && !canMonitor) {
      return const Center(child: Text('Akun tidak memiliki akses modul PJLP.'));
    }
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          Text(error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: refresh, child: const Text('Coba lagi')),
        ])));
    }
    return RefreshIndicator(onRefresh: refresh, child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(isPjlp ? 'Aktivitas Saya · PJLP' : 'Monitoring PJLP',
          style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(isPjlp
          ? 'Absensi dan progres yang sudah diverifikasi oleh server.'
          : 'Monitoring hanya baca. Nilai final disahkan Admin Utama.'),
        const SizedBox(height: 12),
        info('Hari hadir terverifikasi', summary['present_days']),
        info('Tugas selesai', summary['completed_jobs']),
        info('Nilai bulanan sementara', summary['monthly_score']),
        const SizedBox(height: 12),
        Text('Riwayat absensi', style: Theme.of(context).textTheme.titleMedium),
        if (attendance.isEmpty) const ListTile(title: Text('Belum ada catatan absensi')),
        for (final entry in attendance)
          ListTile(leading: const Icon(Icons.fact_check_outlined),
            title: Text('${(entry as Map)['date'] ?? 'Tanggal belum tersedia'}'),
            subtitle: Text('${entry['status'] ?? 'Menunggu verifikasi'}')),
        const SizedBox(height: 12),
        Text('Pekerjaan', style: Theme.of(context).textTheme.titleMedium),
        if (jobs.isEmpty) const ListTile(title: Text('Belum ada penugasan')),
        for (final entry in jobs)
          ListTile(leading: const Icon(Icons.work_outline),
            title: Text('${(entry as Map)['title'] ?? 'Pekerjaan'}'),
            subtitle: Text('Progres terverifikasi: ${entry['progress'] ?? 0}%')),
        if (isPjlp) const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text('Pengiriman absensi GPS/selfie dan bukti foto akan aktif '
            'setelah endpoint aman dan validasi server terpasang.')),
        if (isAdmin) const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text('Pengesahan laporan belum diaktifkan sampai audit log '
            'dan penguncian nilai tersedia di server.')),
      ]));
  }
}
