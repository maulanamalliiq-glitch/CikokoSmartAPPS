import 'package:flutter/material.dart';

/// Tahap 1: kerangka laporan kinerja PPPK sesuai empat kelompok dalam PDF contoh.
/// Penyimpanan, unggah foto, persetujuan Admin dan PDF baru diaktifkan
/// setelah endpoint aman dan pengujian integrasi selesai.
class CikokoPppkPerformancePage extends StatelessWidget {
  const CikokoPppkPerformancePage({super.key});

  static const sections = <String>[
    'Laporan hasil peninjauan lapangan terkait laporan/pengaduan masyarakat dalam mendukung pekerjaan yang perlu segera ditindaklanjuti karena mengganggu kepentingan publik/masyarakat',
    'Dokumen administrasi aktivitas/pekerjaan PPSU di tingkat Kelurahan',
    'Dokumen basis data yang diperlukan dalam percepatan proses pengelolaan administrasi kelurahan yang berorientasi pada pelayanan masyarakat',
    'Laporan pelaksanaan tugas-tugas kedinasan lainnya yang diberikan oleh pimpinan',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final period = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return Scaffold(
      backgroundColor: const Color(0xfff5f8fc),
      appBar: AppBar(title: const Text('Kinerja Bulanan PPPK')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Laporan Kinerja PPPK $period',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text('Format laporan: 4 kegiatan, masing-masing Periode 1 dan Periode 2.'),
                  const SizedBox(height: 8),
                  const Text(
                    'Tahap pengembangan: formulir, unggah foto, penyimpanan dan persetujuan Admin belum diaktifkan. Belum ada data yang dikirim.',
                    style: TextStyle(color: Color(0xff9b5600)),
                  ),
                ],
              ),
            ),
          ),
          for (var i = 0; i < sections.length; i++)
            Card(
              margin: const EdgeInsets.only(top: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${i + 1}. ${sections[i]}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    for (final period in [1, 2])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xffdce5f0)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Periode $period',
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              const Text('Foto kegiatan dan keterangan akan diisi di sini.'),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          const Text(
            'Alur yang akan diaktifkan: PPPK mengirim laporan → Admin menyetujui → QR Kasi Ekonomi dan Pembangunan muncul pada PDF A4.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
