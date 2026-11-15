import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import 'api.dart';
import 'cikoko_pjlp_location_picker.dart';

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
  String? selectedShift;
  List<Map<String, dynamic>> shiftReports = [];
  static const shiftNames = {'pagi': 'Pagi', 'siang': 'Siang', 'malam': 'Malam'};
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
        final settings = roster['config'];
        config = settings is Map ? Map<String, dynamic>.from(settings) : {};
      }
      if (!mounted) return;
      final target = employeeId;
      if (isPjlp || target != null) {
        record = await widget.api.callWithQuery(
          isPjlp ? 'pjlp_self_dashboard' : 'pjlp_monitor_dashboard',
          {'month': month, if (target != null) 'user_id': target},
        );
        final shift = record['active_shift'] as Map?;
        final activeDate = shift?['work_date'];
        if (isPjlp && activeDate is String && activeDate.length == 10) {
          final activeMonth = activeDate.substring(0, 7);
          final activeRecord = activeMonth == month ? record : await widget.api.callWithQuery(
            'pjlp_self_dashboard', {'month': activeMonth},
          );
          shiftReports = rows(activeRecord['daily'])
              .where((day) => day['date'] == activeDate)
              .expand((day) => rows(day['reports']))
              .toList();
        } else {
          shiftReports = [];
        }
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
    run(() => captureAndSend(action, fields, selfie: selfie));
  }

  Future<void> captureAndSend(String action, Map<String, String> fields,
      {required bool selfie}) async {
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
  }

  Future<Map<String, String>?> form(String title, Map<String, String> labels,
      {Map<String, dynamic> values = const {}, List<String> details = const [],
      bool readOnly = false, String submitLabel = 'Simpan', bool includeLocation = false}) async {
    final formKey = GlobalKey<FormState>();
    final result = <String, String>{};
    final latitude = double.tryParse('${values['latitude']}');
    final longitude = double.tryParse('${values['longitude']}');
    final savedLocation = latitude != null && longitude != null &&
        latitude.isFinite && longitude.isFinite &&
        latitude.abs() <= 90 && longitude.abs() <= 180
        ? LatLng(latitude, longitude) : null;
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
                for (final detail in details)
                  Align(alignment: Alignment.centerLeft, child: Text(detail)),
                if (includeLocation)
                  FormField<LatLng>(
                    initialValue: savedLocation,
                    validator: (value) => value == null ? 'Pilih lokasi pada peta.' : null,
                    onSaved: (value) {
                      final point = value!;
                      result['latitude'] = '${point.latitude}';
                      result['longitude'] = '${point.longitude}';
                    },
                    builder: (field) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.map_outlined),
                          label: Text(field.value == null ? 'Pilih di peta' : 'Ubah titik di peta'),
                          onPressed: () async {
                            final picked = await Navigator.of(dialogContext).push<LatLng>(
                              MaterialPageRoute<LatLng>(builder: (_) => CikokoPjlpLocationPicker(
                                savedLocation: field.value,
                                currentLocation: () async {
                                  final point = await position();
                                  return LatLng(point.latitude, point.longitude);
                                },
                              )),
                            );
                            if (picked != null && field.mounted) field.didChange(picked);
                          },
                        ),
                        if (field.value != null)
                          const Text('Titik lokasi sudah dipilih.'),
                        if (field.errorText != null)
                          Text(field.errorText!, style: TextStyle(
                            color: Theme.of(dialogContext).colorScheme.error,
                          )),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                if (!readOnly)
                  for (final field in labels.entries)
                    TextFormField(
                      initialValue: '${values[field.key] ?? ''}',
                      keyboardType: field.key == 'radius_m' ? TextInputType.number : null,
                      decoration: InputDecoration(
                        labelText: field.value,
                        helperText: field.key == 'radius_m' ? '30–2000 meter, misalnya 100' : null,
                        errorMaxLines: 2,
                      ),
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (field.key != 'radius_m') return text.isEmpty ? 'Wajib diisi' : null;
                        final radius = int.tryParse(text, radix: 10);
                        if (radius == null || radius < 30 || radius > 2000) {
                          return 'Masukkan angka 30–2000, tanpa satuan.';
                        }
                        return null;
                      },
                      onSaved: (value) => result[field.key] = value!.trim(),
                    ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          if (!readOnly) FilledButton(onPressed: () {
            if (!formKey.currentState!.validate()) return;
            formKey.currentState!.save();
            Navigator.pop(dialogContext, result);
          }, child: Text(submitLabel)),
        ],
      ),
    );
  }

  Future<void> configure(String action, String title, Map<String, String> fields,
      {Map<String, dynamic> values = const {}}) async {
    final data = await form(title, {
      ...fields,
      'radius_m': 'Radius dalam meter',
    }, values: values, includeLocation: true);
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

  String reportLabel(String mode) => mode == 'dinas_luar' ? 'Dinas Luar' : 'Laporan Rutin';

  Widget reportStages(String mode, String? blockedReason, {void Function(int)? onStage}) {
    final sent = {
      for (final report in shiftReports.where((row) => row['report_type'] == mode))
        int.parse('${report['stage']}'): report,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (blockedReason != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(blockedReason),
          ),
        for (final stage in [0, 50, 100]) ...[
          ListTile(
            leading: Icon(sent.containsKey(stage) ? Icons.check_circle_outline : Icons.add_a_photo_outlined),
            title: Text('Laporan $stage%'),
            subtitle: Text(sent.containsKey(stage)
                ? 'Terkirim ${sent[stage]!['submitted_at']} WIB'
                : stage == 0 || sent.containsKey(stage - 50)
                    ? 'Keterangan dan foto'
                    : 'Setelah laporan ${stage - 50}% dikirim'),
            enabled: sent.containsKey(stage) ||
                blockedReason == null && (stage == 0 || sent.containsKey(stage - 50)),
            onTap: sent.containsKey(stage)
                || blockedReason == null && (stage == 0 || sent.containsKey(stage - 50))
                ? () {
                    if (onStage != null) {
                      onStage(stage);
                    } else {
                      openStage(mode, stage, submitted: sent[stage]);
                    }
                  }
                : null,
          ),
        ],
      ],
    );
  }

  Future<void> openFieldReports(String? blockedReason) async {
    // Close the page before opening a form so the form can refresh dashboard state.
    final stage = await Navigator.of(context).push<int>(MaterialPageRoute<int>(
      builder: (pageContext) {
        return Scaffold(
          appBar: AppBar(title: const Text('Dinas Luar')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Nilai pekerjaan hari ini memakai laporan Dinas Luar setelah tahap pertama terkirim.'),
              reportStages('dinas_luar', blockedReason,
                onStage: (stage) => Navigator.pop(pageContext, stage)),
            ],
          ),
        );
      },
    ));
    if (stage == null || !mounted) return;
    final report = shiftReports.where((row) =>
        row['report_type'] == 'dinas_luar' && '${row['stage']}' == '$stage').firstOrNull;
    await openStage('dinas_luar', stage, submitted: report);
  }

  Future<void> openStage(String mode, int stage, {Map<String, dynamic>? submitted}) async {
    if (submitted != null) {
      await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
        title: Text('${reportLabel(mode)} $stage%'),
        content: SingleChildScrollView(child: Text(
          '${submitted['full_name']}\n'
          'Dibuka ${submitted['opened_at']} WIB\n'
          'Terkirim ${submitted['submitted_at']} WIB\n\n'
          '${submitted['description']}',
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Tutup')),
          TextButton(onPressed: () async {
            Navigator.pop(dialogContext);
            await showPhoto('pjlp_daily_report_photo', {
              'date': '${submitted['work_date']}', 'progress': '$stage', 'report_type': mode,
            });
          }, child: const Text('Lihat foto')),
        ],
      ));
      return;
    }
    await run(() async {
      final response = await widget.api.call('pjlp_daily_report_open', body: {
        'report_type': mode, 'progress': stage,
      });
      final draft = Map<String, dynamic>.from(response['report'] as Map);
      if (!mounted) return;
      final fields = await form('Formulir ${reportLabel(mode)} $stage%', {
        'description': 'Keterangan pekerjaan',
      }, details: [
        'Nama lengkap ${draft['full_name']}',
        'Dibuka ${draft['opened_at']} WIB',
        'Tanggal shift ${draft['work_date']}',
        if (draft['submitted_at'] != null) 'Terkirim ${draft['submitted_at']} WIB',
      ], readOnly: draft['submitted_at'] != null, submitLabel: 'Ambil foto dan kirim');
      if (fields == null || !mounted) return;
      await captureAndSend('pjlp_daily_report_submit', {
        ...fields,
        'date': '${draft['work_date']}',
        'report_type': mode,
        'progress': '$stage',
      }, selfie: false);
    });
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
    final daily = rows(record['daily']);
    final activeShift = record['active_shift'] as Map?;
    final supportsShifts = record.containsKey('active_shift');
    final current = serverDate.startsWith(month);
    final configured = record['configured'] == true;
    final attendanceBlock = !supportsShifts
        ? 'Server perlu diperbarui untuk absensi shift.'
        : !configured ? 'Admin Utama perlu menyimpan lokasi kantor dan bobot penilaian.' : null;
    final checkedInToday = record['checked_in_today'] == true;
    final reportBlock = attendanceBlock ??
        (activeShift?['shift_name'] == null ? 'Absen masuk dengan pilihan shift untuk mengisi laporan.' : null);
    final shift = selectedShift;
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
            ]),
            if (isPjlp) ...[
              Card(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Absensi shift', style: Theme.of(context).textTheme.titleMedium),
                    if (activeShift == null)
                      Wrap(spacing: 8, children: [
                        for (final option in shiftNames.entries)
                          ChoiceChip(
                            label: Text(option.value),
                            selected: shift == option.key,
                            onSelected: (_) => setState(() => selectedShift = option.key),
                          ),
                      ])
                    else
                      Text("Shift ${shiftNames[activeShift['shift_name']] ?? 'sebelumnya'}"
                        " · Masuk ${activeShift['checkin_at']} WIB"),
                    if (attendanceBlock != null)
                      Text(attendanceBlock)
                    else if (activeShift == null)
                      Text(checkedInToday ? 'Absensi hari ini sudah tercatat.'
                          : shift == null ? 'Pilih shift untuk absen masuk.'
                          : 'Ambil selfie untuk mencatat absensi masuk.'),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, children: [
                      FilledButton.icon(
                        onPressed: attendanceBlock == null && shift != null &&
                            activeShift == null && !checkedInToday
                          ? () => capture('pjlp_attendance_submit',
                              {'type': 'checkin', 'shift': shift}, selfie: true) : null,
                        icon: const Icon(Icons.login), label: const Text('Absen masuk')),
                      OutlinedButton.icon(
                        onPressed: attendanceBlock != null || activeShift == null
                          ? null : () => capture('pjlp_attendance_submit',
                              {'type': 'checkout', 'shift': '${activeShift['shift_name'] ?? ''}'}, selfie: true),
                        icon: const Icon(Icons.logout), label: const Text('Absen pulang')),
                    ]),
                  ],
                ),
              )),
              Card(child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ListTile(title: Text('Laporan Harian')),
                  reportStages('rutin', reportBlock),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: const Text('Dinas Luar'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => openFieldReports(reportBlock),
                  ),
                ],
              )),
            ],
            Text('Rekap bulanan', style: Theme.of(context).textTheme.titleMedium),
            Card(child: ListTile(
              title: Text('${record['employee']}'),
              subtitle: Text('Hadir ${summary['present_days']}/${summary['scheduled_days']} hari  •  '
                'Laporan selesai ${summary['completed_jobs']}/${summary['assigned_jobs']}\n'
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
            Text('Rekap harian', style: Theme.of(context).textTheme.titleMedium),
            if (daily.isEmpty) const ListTile(title: Text('Belum ada rekap shift pada periode ini')),
            for (final day in daily)
              ExpansionTile(
                title: Text("${day['date']} · Shift ${day['shift']}"),
                subtitle: Text(
                  "${day['valid'] == true ? 'Lengkap' : day['checkout_at'] == null ? 'Shift berjalan' : 'Kurang dari 8 jam'}"
                  " · ${day['minutes']} menit · ${reportLabel('${day['report_type']}')}"
                  "${day['score'] == null ? '' : ' · Nilai ${day['score']}'}",
                ),
                children: [
                  for (final report in rows(day['reports']))
                    ListTile(
                      title: Text("${reportLabel('${report['report_type']}')} ${report['stage']}%"),
                      subtitle: Text("${report['submitted_at']} WIB\n${report['description']}"),
                      onTap: () => showPhoto('pjlp_daily_report_photo', {
                        'date': '${day['date']}', 'progress': '${report['stage']}',
                        'report_type': '${report['report_type']}',
                      }),
                    ),
                ],
              ),
            if (jobs.isNotEmpty) Text('Pekerjaan terdahulu', style: Theme.of(context).textTheme.titleMedium),
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
