import 'dart:io';
import 'dart:math';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Semua foto yang dikirim melalui CikokoApi.upload() diproses di sini.
/// Batas 1 MiB per berkas, format PNG untuk TTD/stempel agar transparansi aman.
/// Berkas yang belum perlu kompresi tidak dimodifikasi.
class CikokoPhotoUpload {
  static const int maxBytes=1024*1024;

  static bool preserveTransparency(String field) {
    final name=field.toLowerCase();
    return name=='signature'||name=='stamp'||name=='ttd'||name=='stempel';
  }

  static Future<String> prepare(String field,String path) async {
    final original=File(path);
    final length=await original.length();
    if(length<=maxBytes)return path;

    final png=preserveTransparency(field);
    final format=png?CompressFormat.png:CompressFormat.jpeg;
    final folder=Directory((await getTemporaryDirectory()).path+'/cikoko_upload_tmp');
    if(!await folder.exists())await folder.create(recursive:true);

    // Native compression avoids loading multi-megabyte input images into Dart.
    // Steps reduce pixels progressively when the image is especially detailed.
    const targets=<int>[1920,1600,1400,1200,1024,880,740,600,480,350,260];
    for(final edge in targets){
      try{
        final bytes=await FlutterImageCompress.compressWithFile(
          path,minWidth:edge,minHeight:edge,
          quality:png?95:(edge>=1200?72:64),
          format:format,keepExif:false,
        );
        if(bytes==null||bytes.isEmpty||bytes.length>maxBytes)continue;
        final unique=DateTime.now().microsecondsSinceEpoch.toString()+'_'
          +Random.secure().nextInt(0x7fffffff).toRadixString(16);
        final target=File(folder.path+'/'+unique+(png?'.png':'.jpg'));
        await target.writeAsBytes(bytes,flush:true);
        if(await target.length()<=maxBytes)return target.path;
        await target.delete();
      }catch(_){
        // Device codecs vary. Try smaller dimensions; never send huge originals.
      }
    }
    throw FileSystemException(
      'Foto '+field+' belum dapat dikompresi ke maksimal 1 MB. '
      'Pilih foto JPG/PNG lain atau ambil gambar ulang.');
  }
}
