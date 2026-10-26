import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/rt_rw_letters.dart';

void main() {
  test('accepts the server numeric application ID', () {
    expect(cikokoLetterId({'id': 55, 'reference': 'AW-TEST'}), 55);
    expect(cikokoLetterId({'id': '17'}), 17);
    expect(cikokoLetterId({'id': null, 'application_id': 19}), 19);
  });
  test('never creates an ID from a public reference or a list index', () {
    expect(cikokoLetterId({'reference': 'AW-20261026-E4C39D56'}), isNull);
    expect(cikokoLetterId({'id': 0, 'reference': 'AW-20261026-E4C39D56'}), isNull);
    expect(cikokoLetterId({'id': 'not-a-number'}), isNull);
  });
  test('maps review stages to Indonesian labels', () {
    expect(cikokoLetterStatus('menunggu_rt'), 'Menunggu Verifikasi RT');
    expect(cikokoLetterStatus('menunggu_rw'), 'Menunggu Verifikasi RW');
  });
}
