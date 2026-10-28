import 'package:cikoko/integrated_services.dart';
import 'package:cikoko/role_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Layanan terpadu menyediakan seluruh 11 pilihan awal warga', () {
    final data=cikokoDefaultIntegratedServices();
    final titles=data.map((e)=>e['title']).toSet();
    expect(data.length,11);
    for(final title in [
      'PTSP','Dukcapil','Alpukat Betawi','Jak Evo','Sosial',
      'Puskesmas','Kecamatan','Pajak Online','Jawara','Jak-Sehat',
      'BPJS Ketenagakerjaan'
    ]){expect(titles.contains(title),isTrue,reason:title);}
    for(final item in data){
      final url='${item['url']??''}';
      expect(url.isEmpty||url.startsWith('https://'),isTrue,
        reason:'Tidak boleh membuat tautan palsu atau tidak aman.');
    }
  });
  test('Hanya Admin Utama yang memiliki editor layanan', () {
    final admin=modulesForRole('admin',{'role:manage':true});
    final resident=modulesForRole('warga',{'role:manage':true});
    expect(admin.any((f)=>f.route=='Kelola Layanan Terpadu'),isTrue);
    expect(resident.any((f)=>f.route=='Kelola Layanan Terpadu'),isFalse);
  });
}