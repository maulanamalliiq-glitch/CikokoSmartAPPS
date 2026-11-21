import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Read-only annual aggregate, not an account balance. Published/closed data only.
class BankSampahAnnualHome2618 extends StatefulWidget {
  const BankSampahAnnualHome2618({super.key});

  @override
  State<BankSampahAnnualHome2618> createState() =>
      _BankSampahAnnualHome2618State();
}

class _BankSampahAnnualHome2618State extends State<BankSampahAnnualHome2618> {
  late Future<Map<String, dynamic>> pending;
  int get year => DateTime.now().year;

  @override
  void initState() {
    super.initState();
    pending = fetchTotals();
  }

  Future<Map<String, dynamic>> fetchTotals() async {
    final endpoint = Uri.parse(
      'https://datawebs.my.id/mobile-api/bank_sampah_public_2618.php',
    ).replace(queryParameters: {'year': '$year'});
    final response = await http.get(endpoint, headers: {
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw StateError('Rekap tahunan belum tersedia.');
    }
    final parsed = jsonDecode(utf8.decode(response.bodyBytes));
    if (parsed is! Map || parsed['ok'] != true || parsed['totals'] is! Map) {
      throw const FormatException('Format rekap tahunan tidak valid.');
    }
    return Map<String, dynamic>.from(parsed);
  }

  void refresh() => setState(() => pending = fetchTotals());

  String group(int n) {
    final s = n.abs().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return n < 0 ? '-$b' : b.toString();
  }

  String weight(num amount) {
    final parts = amount.toDouble().toStringAsFixed(3).split('.');
    final fraction = parts.last.replaceFirst(RegExp(r'0+$'), '');
    final base = group(int.parse(parts.first));
    return fraction.isEmpty ? '$base Kg' : '$base,$fraction Kg';
  }

  Widget cell(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xffedf9f3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(
          color: Color(0xff61748c), fontSize: 10.2)),
        const SizedBox(height: 6),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
          child: Text(value, style: const TextStyle(
            color: Color(0xff128252), fontSize: 18,
            fontWeight: FontWeight.w900))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('bank_2618_annual_home'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffe0eaf5)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.recycling_rounded,
            color: Color(0xff128252), size: 22),
          const SizedBox(width: 8),
          const Expanded(child: Text('Total Tahunan Bank Sampah Cikoko',
            style: TextStyle(fontWeight: FontWeight.w800,
              fontSize: 14, color: Color(0xff0c1a48)))),
          Text('$year', style: const TextStyle(
            color: Color(0xff128252), fontWeight: FontWeight.w800)),
          IconButton(
            key: const Key('bank_2618_reload'),
            tooltip: 'Perbarui rekap Bank Sampah',
            icon: const Icon(Icons.refresh_rounded,
              color: Color(0xff128252)),
            onPressed: refresh,
          ),
        ]),
        const SizedBox(height: 10),
        FutureBuilder<Map<String, dynamic>>(
          future: pending,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Memuat rekap Bank Sampah…'),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Text(
                'Rekap tahunan belum dapat ditampilkan. Tekan ikon perbarui.',
                style: TextStyle(fontSize: 11.2),
              );
            }
            final data = snapshot.data!;
            final totals = Map<String, dynamic>.from(data['totals'] as Map);
            final kg = num.tryParse((totals['weight_kg'] ?? '').toString());
            final rp = int.tryParse((totals['amount_rp'] ?? '').toString());
            final count = int.tryParse((totals['entries'] ?? '').toString());
            if (kg == null || rp == null || count == null) {
              return const Text('Format rekap tahunan belum valid.');
            }
            final a = cell('Total Penimbangan', weight(kg));
            final b = cell('Total Nilai Sampah', 'Rp ' + group(rp));
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              LayoutBuilder(builder: (context, constraints) {
                if (constraints.maxWidth < 320) {
                  return Column(children: [
                    a, const SizedBox(height: 8), b,
                  ]);
                }
                return Row(children: [
                  Expanded(child: a), const SizedBox(width: 8),
                  Expanded(child: b),
                ]);
              }),
              const SizedBox(height: 10),
              Text(group(count) + ' catatan penimbangan terkonfirmasi',
                style: const TextStyle(
                  fontSize: 10.6, color: Color(0xff61748c))),
            ]);
          },
        ),
      ]),
    );
  }
}
