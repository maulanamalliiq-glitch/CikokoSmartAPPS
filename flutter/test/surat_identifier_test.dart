import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/surat_identifier.dart';

void main() {
  test('ID pengajuan harus berasal dari server dan positif', () {
    expect(cikokoPositiveId({'id': 10}), 10);
    expect(cikokoPositiveId({'id': '16'}), 16);
    expect(cikokoPositiveId({'id': null, 'application_id': '9'}), 9);
    expect(cikokoPositiveId({'id': 0}), isNull);
    expect(cikokoPositiveId({'id': ''}), isNull);
  });
  test('Hanya referensi Ahli Waris yang valid boleh menjadi cadangan', () {
    expect(cikokoWarisReference({'kind': 'waris', 'reference': 'AW-20261026-E4C39D56'}),
        'AW-20261026-E4C39D56');
    expect(cikokoWarisReference({'kind': 'report', 'reference': 'AW-20261026-E4C39D56'}), isNull);
    expect(cikokoWarisReference({'kind': 'waris', 'reference': 'not-valid'}), isNull);
  });
}
