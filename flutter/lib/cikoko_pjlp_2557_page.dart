import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'api.dart';

class CikokoPjlp2557Page extends StatefulWidget {
  final CikokoApi api;
  final String role;
  const CikokoPjlp2557Page({super.key, required this.api, required this.role});

  @override
  State<CikokoPjlp2557Page> createState() => _CikokoPjlp2557PageState();
}

class _CikokoPjlp2557PageState extends State<CikokoPjlp2557Page> {
  bool busy = true;
  String? error;
  String? employeeId;
  Map<String, dynamic> record = {};
  Map<String, dynamic> config = {};
  List<Map<String, dynamic>> staff = [];
  String month = DateTime.now().toUtc().add(const Duration(hours: 7))
      .toIso8601String().substring(0, 7);

  bool get isPjlp => widget.role == 'pjlp';
  bool get isAdmin => widget.role == 'admin';
  bool get approved => record['approved'] == true;
  String get serverDate => '${record['server_date'] ?? ''}';
  bool get monthClosed => serverDate.length >= 7 &&
      month.compareTo(serverDate.substring(0, 7)) < 0;

  static List<Map<String, dynamic>> rows(Object? value) =>
      (value as List? ?? const []).cast<Map<String, dynamic>>();

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (!mounted) return;
    setState(() { busy = true; error = null; });
    try {
      if (!isPjlp) {
        final roster = await widget.api.call('pjlp_monitor_dashboard');
        staff = rows(roster['staff']);
        if (!staff.any((person) => '${person['user_id']}' == employeeId)) employeeId = null;
        config = Map<String, dynamic>.from(roster['config'] as Map? ?? {});
      }
      if (!mounted) return;
      final target = employeeId;
      if (isPjlp || target != null) {
        record = await widget.api.callWithQuery(
          isPjlp ? 'pjlp_self_dashboard' : 'pjlp_monitor_dashboard',
          {'month': month, if (target != null) 'user_id': target},
        );
      } else {
        record = {};
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void notify(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> run(Future<void> Function() action, {bool reload = true}) async {
    if (!mounted || busy) return;
    setState(() => busy = true);
    try {
      await action();
      if (reload) await load();
    } catch (e) {
      notify('$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<Position> position() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw ApiError('Aktifkan layanan lokasi untuk mencatat GPS.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
      throw ApiError('Izinkan lokasi presisi saat aplikasi digunakan melalui pengaturan Android.');
    }
    final result = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20),
      ),
    );
    if (result.isMocked || result.accuracy <= 0 || result.accuracy > 100) {
      throw ApiError('GPS belum cukup akurat. Coba lagi di lokasi terbuka.');
    }
    return result;
  }

  void capture(String action, Map<String, String> fields, {required bool selfie}) {
    run(() async {
      final point = await position();
      if (!mounted) return;
      final photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: selfie ? CameraDevice.front : CameraDevice.rear,
        maxWidth: 1600, maxHeight: 1600, imageQuality: 75,
      );
      if (photo == null) return;
      try {
        if (!mounted) return;
        final freshPoint = DateTime.now().difference(point.timestamp).inSeconds > 30
            ? await position() : point;
        await widget.api.upload(action, {
          ...fields,
          'latitude': '${freshPoint.latitude}',
          'longitude': '${freshPoint.longitude}',
          'accuracy_m': '${freshPoint.accuracy}',
        }, {'photo': [photo.path]});
        notify('Catatan tersimpan.');
      } finally {
        try { await File(photo.path).delete(); } on FileSystemException {
          // The system may already have cleared its temporary camera file.
        }
      }
    });
  }

  Future<Map<String, String>?> form(String title, Map<String, String> labels,
      {Map<String, dynamic> values = const {}}) async {
    final formKey = GlobalKey<FormState>();
    final result = <String, String>{};
    return showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final field in labels.entries)
                  TextFormField(
                    initialValue: '${values[field.key] ?? ''}',
                    decoration: InputDecoration(labelText: field.value),
                    validator: (value) => (value ?? '').trim().isEmpty ? 'Wajib diisi' : null,
                    onSaved: (value) => result[field.key] = value!.trim(),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          FilledButton(onPressed: () {
            if (!formKey.currentState!.validate()) return;
            formKey.currentState!.save();
            Navigator.pop(dialogContext, result);
          }, child: const Text('Simpan')),
        ],
      ),
    );
  }

  Future<void> configure(String action, String title, Map<String, String> fields,
      {Map<String, dynamic> values = const {}}) async {
    final data = await form(title, {
      ...fields,
      'latitude': 'Lintang',
      'longitude': 'Bujur',
      'radius_m': 'Radius dalam meter',
    }, values: values);
    if (data == null) return;
    await run(() async {
      await widget.api.call(action, body: {
        ...data,
        if (employeeId != null) 'user_id': employeeId,
        'month': month,
      });
      notify('Pengaturan disimpan.');
    });
  }

  Future<void> approve() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sahkan rekap bulanan?'),
        content: Text('Rekap ${record['employee']} untuk $month akan dikunci dan tersedia sebagai PDF.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sahkan')),
        ],
      ),
    );
    if (confirmed != true) return;
    await run(() async {
      await widget.api.call('pjlp_month_approve', body: {'month': month, 'user_id': employeeId});
      notify('Rekap disahkan.');
    });
  }

  Future<void> download({String? unit}) async {
    await run(() async {
      final uri = Uri.parse(CikokoApi.root).replace(queryParameters: {
        'action': unit == null ? 'pjlp_month_pdf' : 'pjlp_team_pdf',
        'month': month,
        if (employeeId != null) 'user_id': employeeId,
        if (unit != null) 'unit': unit,
      });
      final response = await http.get(uri, headers: widget.api.authHeaders())
          .timeout(const Duration(seconds: 40));
      if (response.statusCode != 200 ||
          !(response.headers['content-type'] ?? '').startsWith('application/pdf')) {
        throw ApiError('PDF belum tersedia untuk periode yang dipilih.');
      }
      final suffix = unit ?? '${record['employee'] ?? 'pegawai'}';
      final name = 'Rekap-PJLP-$month-${suffix.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}.pdf';
      final path = await const MethodChannel('cikoko/pdf_downloads').invokeMethod<String>(
        'savePdfToDownloads', {'name': name, 'bytes': response.bodyBytes},
      );
      if (path == null) throw ApiError('Android belum mengonfirmasi penyimpanan PDF.');
      notify('PDF tersimpan di folder Download.');
    }, reload: false);
  }

  Future<void> showPhoto(String action, Map<String, String> query) async {
    await run(() async {
      final uri = Uri.parse(CikokoApi.root).replace(queryParameters: {
        'action': action,
        ...query,
        if (employeeId != null) 'user_id': employeeId!,
      });
      final response = await http.get(uri, headers: widget.api.authHeaders())
          .timeout(const Duration(seconds: 25));
      if (response.statusCode != 200 ||
          !(response.headers['content-type'] ?? '').startsWith('image/jpeg')) {
        throw ApiError('Foto tidak tersedia.');
      }
      if (!mounted) return;
      await showDialog<void>(context: context, builder: (context) => Dialog(
        child: InteractiveViewer(child: Image.memory(response.bodyBytes)),
      ));
    }, reload: false);
  }

  Future<void> selectMonth() async {
    final parts = month.split('-').map(int.parse).toList();
    final chosen = await showDatePicker(
      context: context,
      initialDate: DateTime(parts[0], parts[1]),
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      helpText: 'Pilih tanggal dalam bulan rekap',
    );
    if (chosen == null || !mounted) return;
    setState(() => month = chosen.toIso8601String().substring(0, 7));
    await load();
  }

  @override
  Widget build(BuildContext context) {
    if (busy) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(error!, textAlign: TextAlign.center),
          TextButton(onPressed: load, child: const Text('Coba lagi')),
        ]),
      ));
    }
    final attendance = rows(record['attendance']);
    final jobs = rows(record['jobs']);
    final summary = record['summary'] as Map? ?? {};
    final todayEvents = attendance.where((event) => event['date'] == serverDate)
        .map((event) => event['status']).toSet();
    final current = serverDate.startsWith(month);
    final configured = record['configured'] == true;
    final unit = '${record['unit'] ?? ''}';
    const weights = {
      'attendance_weight': 'Bobot kehadiran (%)',
      'work_weight': 'Bobot tugas (%)',
      'evidence_weight': 'Bobot kelengkapan bukti (%)',
    };
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(isPjlp ? 'Absensi dan Kinerja Saya' : 'Monitoring PJLP',
            style: Theme.of(context).textTheme.headlineSmall),
          OutlinedButton.icon(onPressed: selectMonth, icon: const Icon(Icons.calendar_month),
            label: Text('Periode $month')),
          if (isAdmin)
            OutlinedButton(onPressed: () => configure('pjlp_location_save',
              'Lokasi kantor dan bobot', weights,
              values: {'attendance_weight': 30, 'work_weight': 50, 'evidence_weight': 20, ...config}),
              child: const Text('Lokasi kantor dan bobot')),
          if (!isPjlp)
            DropdownButtonFormField<String>(
              key: ValueKey(employeeId),
              initialValue: employeeId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Pegawai PJLP'),
              items: [for (final person in staff)
                DropdownMenuItem(value: '${person['user_id']}', child: Text('${person['full_name']}')),
              ],
              onChanged: (value) {
                employeeId = value;
                load();
              },
            ),
          if (!isPjlp && employeeId == null)
            ListTile(title: Text(staff.isEmpty ? 'Belum ada pegawai dalam cakupan akun ini.'
              : 'Pilih pegawai untuk melihat rekap.')),
          if (record.isNotEmpty) ...[
            if (isAdmin) Wrap(spacing: 8, children: [
              OutlinedButton(onPressed: () => configure('pjlp_schedule_save', 'Jadwal akhir pekan',
                {'date': 'Tanggal (YYYY-MM-DD)'}), child: const Text('Jadwal akhir pekan')),
              if (!monthClosed)
                OutlinedButton(onPressed: () => configure('pjlp_job_assign', 'Tugaskan pekerjaan',
                  {'title': 'Judul pekerjaan'}), child: const Text('Tugaskan pekerjaan')),
            ]),
            if (isPjlp && !configured)
              const ListTile(title: Text('Admin Utama perlu menyiapkan lokasi dan bobot penilaian.')),
            if (isPjlp && current && configured)
              Wrap(spacing: 8, children: [
                FilledButton.icon(
                  onPressed: todayEvents.contains('checkin') ? null :
                    () => capture('pjlp_attendance_submit', {'type': 'checkin'}, selfie: true),
                  icon: const Icon(Icons.login), label: const Text('Absen masuk')),
                FilledButton.icon(
                  onPressed: todayEvents.contains('checkin') && !todayEvents.contains('checkout') ?
                    () => capture('pjlp_attendance_submit', {'type': 'checkout'}, selfie: true) : null,
                  icon: const Icon(Icons.logout), label: const Text('Absen pulang')),
              ]),
            Card(child: ListTile(
              title: Text('${record['employee']}'),
              subtitle: Text('Hadir ${summary['present_days']}/${summary['scheduled_days']} hari  •  '
                'Tugas ${summary['completed_jobs']}/${summary['assigned_jobs']}\n'
                'Bukti lengkap ${summary['documented_jobs']}  •  '
                '${approved ? 'Nilai disahkan' : 'Nilai sementara'} ${summary['monthly_score'] ?? '–'}'),
            )),
            Wrap(spacing: 8, children: [
              if (isAdmin && monthClosed && !approved && summary['monthly_score'] != null)
                FilledButton(onPressed: approve, child: const Text('Sahkan rekap')),
              if (approved)
                FilledButton.icon(onPressed: download, icon: const Icon(Icons.download),
                  label: const Text('Unduh PDF pegawai')),
              if (!isPjlp && monthClosed && unit.isNotEmpty)
                OutlinedButton(onPressed: () => download(unit: unit), child: const Text('Unduh PDF unit')),
            ]),
            Text('Pekerjaan', style: Theme.of(context).textTheme.titleMedium),
            if (jobs.isEmpty) const ListTile(title: Text('Belum ada penugasan')),
            for (final job in jobs)
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text('${job['title']}'),
                      subtitle: Text('${job['stages']} dari 3 tahap terdokumentasi'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Wrap(spacing: 8, children: [
                        for (var stage = 0; stage < int.parse('${job['stages']}'); stage++)
                          TextButton(onPressed: () => showPhoto('pjlp_evidence_photo', {
                            'job_id': '${job['id']}', 'progress': '${stage * 50}',
                          }), child: Text('Lihat ${stage * 50}%')),
                        if (isPjlp && current && configured && int.parse('${job['stages']}') < 3)
                          FilledButton.tonal(
                            onPressed: () => capture('pjlp_job_progress',
                              {'job_id': '${job['id']}', 'progress': '${int.parse('${job['stages']}') * 50}'},
                              selfie: false),
                            child: Text('Ambil foto ${int.parse('${job['stages']}') * 50}%'),
                          ),
                      ]),
                    ),
                  ],
                ),
              ),
            Text('Riwayat absensi', style: Theme.of(context).textTheme.titleMedium),
            if (attendance.isEmpty) const ListTile(title: Text('Belum ada catatan absensi')),
            for (final event in attendance)
              ListTile(
                leading: Icon(event['status'] == 'checkin' ? Icons.login : Icons.logout),
                title: Text(event['status'] == 'checkin' ? 'Masuk' : 'Pulang'),
                subtitle: Text('${event['created_at']} WIB'),
                trailing: IconButton(
                  tooltip: 'Lihat selfie',
                  icon: const Icon(Icons.photo_outlined),
                  onPressed: () => showPhoto('pjlp_attendance_photo',
                    {'date': '${event['date']}', 'type': '${event['status']}'}),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
