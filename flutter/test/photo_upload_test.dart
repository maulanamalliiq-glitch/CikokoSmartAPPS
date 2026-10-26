import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/photo_upload.dart';

void main() {
  test('All account photo uploads target <= 1 MiB', () {
    expect(CikokoPhotoUpload.maxBytes, 1024*1024);
  });

  test('Keep PNG transparency for TTD and stamps', () {
    for(final code in ['signature','stamp','ttd','stempel']){
      expect(CikokoPhotoUpload.preserveTransparency(code), isTrue);
    }
    for(final code in ['photo','r4_ktp','child_10_akta','avatar']){
      expect(CikokoPhotoUpload.preserveTransparency(code), isFalse);
    }
  });

  test('Already small photos retain their original file path', () async {
    final temp=await Directory.systemTemp.createTemp('cikoko_upload_test_');
    try{
      final f=File('${temp.path}/sample.jpg');
      await f.writeAsBytes(List<int>.filled(900*1024, 37));
      final result=await CikokoPhotoUpload.prepare('photo',f.path);
      expect(result,f.path);
      expect(await f.length(),900*1024);
    }finally{
      await temp.delete(recursive:true);
    }
  });
}
