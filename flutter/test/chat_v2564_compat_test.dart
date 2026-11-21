import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/api.dart';
import 'package:cikoko/cikoko_chat_v2548.dart';

void main(){
 test('v2564: missing standalone thread may use the authenticated legacy API',(){
  expect(cikokoLegacyChatFallbackAllowed(ApiError('Percakapan belum tersedia.')),isTrue);
  expect(cikokoLegacyChatFallbackAllowed(ApiError('Percakapan warga tidak ditemukan. Perbarui inbox.')),isTrue);
  expect(cikokoLegacyChatFallbackAllowed(ApiError('Aksi chat tidak tersedia.')),isTrue);
 });
 test('v2564: auth and network errors must never trigger message retries',(){
  expect(cikokoLegacyChatFallbackAllowed(ApiError('Hak akses ditolak untuk fitur ini')),isFalse);
  expect(cikokoLegacyChatFallbackAllowed(ApiError('Sesi tidak valid. Silakan login ulang.')),isFalse);
  expect(cikokoLegacyChatFallbackAllowed(ApiError('Waktu koneksi habis')),isFalse);
  expect(cikokoLegacyChatFallbackAllowed(ApiError('Layanan belum tersedia.')),isFalse);
 });
}
