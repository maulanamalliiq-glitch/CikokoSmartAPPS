import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/waris_requirements.dart';
import 'package:cikoko/role_catalog.dart';

void main() {
  test('Persyaratan menampilkan 9, 7, dan 9 dokumen sesuai layanan', () {
    expect(cikokoWarisRequirements.length,3);
    expect(cikokoWarisRequirements[0].requirements.length,9);
    expect(cikokoWarisRequirements[1].requirements.length,7);
    expect(cikokoWarisRequirements[2].requirements.length,9);
    expect(cikokoWarisRequirements[0].title,'Ahli Waris');
  });

  test('Tombol Ajukan Surat hanya untuk layanan Ahli Waris', () {
    expect(cikokoWarisRequirements.where((e)=>e.allowApply).length,1);
    expect(cikokoWarisRequirements.first.allowApply,isTrue);
    expect(cikokoWarisRequirements[1].allowApply,isFalse);
    expect(cikokoWarisRequirements[2].allowApply,isFalse);
  });

  test('Menu persyaratan tepat setelah surat ahli waris untuk warga', () {
    final warga=roleMenus['warga']!;
    final i=warga.indexOf('waris');
    expect(i,greaterThanOrEqualTo(0));
    expect(warga[i+1],'waris_requirements');
    expect(roleFeatures['waris_requirements']!.route,'Persyaratan Ahli Waris');
  });
}
