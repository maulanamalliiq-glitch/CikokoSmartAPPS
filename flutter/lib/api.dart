import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'photo_upload.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;


String cikokoFormalMessage(Object? error){
  final msg='${error??''}'.trim();
  if(msg.isEmpty||msg.length>240||RegExp(r'(SQLSTATE|PDO|database|fatal error|exception|stacktrace|unknown column|localhost|/var/|/home/|\\.php|config|server API|backend)',caseSensitive:false).hasMatch(msg)){
    return 'Layanan sedang mengalami kendala. Silakan mencoba kembali atau hubungi petugas.';
  }
  return msg;
}
class CikokoRequestProgress {
  static final ValueNotifier<double?> value=ValueNotifier<double?>(null);
  static int _current=0;
  static int begin(){final id=++_current;value.value=0;return id;}
  static void update(int id,double progress){if(id==_current)value.value=progress.clamp(0.0,0.95).toDouble();}
  static void finish(int id,{required bool success}){
    if(id!=_current)return;
    value.value=success?1:null;
    if(success)Future<void>.delayed(const Duration(milliseconds:900),(){
      if(id==_current)value.value=null;
    });
  }
}
class ApiError implements Exception {
  final String message;
  ApiError(this.message);
  @override String toString() => cikokoFormalMessage(message);
}
class CikokoApi {
  static const root = 'https://datawebs.my.id/mobile-api/index.php';
  final _storage = const FlutterSecureStorage();
  String? token;
  Map<String,dynamic>? profile;
  Future<void> restore() async { token = await _storage.read(key:'cikoko_token'); if(token!=null) {try {profile = (await call('me'))['user'] as Map<String,dynamic>?;}catch(_) {/* Saat server sementara tidak tersedia, jangan hapus sesi tersimpan. */}} }
  Future<Map<String,dynamic>> call(String action, {Map<String,dynamic>? body, bool authorized = false}) async {
    final u=Uri.parse('${action.startsWith('v211_') ? root.replaceFirst('index.php','v211.php') : root}?action=$action');
    final progressId=body!=null?CikokoRequestProgress.begin():null;
    var successful=false;
    try {
      final headers={'Accept':'application/json','Content-Type':'application/json'};
      if(token!=null)headers['Authorization']='Bearer $token';
      final http.Response r= body==null ? await http.get(u,headers:headers).timeout(const Duration(seconds:25)) : await http.post(u, headers:headers,body:jsonEncode(body)).timeout(const Duration(seconds:40));
      final d=jsonDecode(utf8.decode(r.bodyBytes));
      if(d is! Map<String,dynamic>)throw ApiError('Balasan server tidak valid');
      if(r.statusCode>=400 || d['ok']==false){final msg='${d['error']??'Layanan belum tersedia.'}';throw ApiError(RegExp(r'SQLSTATE|database|INSERT INTO|PDO|Fatal error',caseSensitive:false).hasMatch(msg)?'Layanan Cikoko sedang mengalami kendala. Silakan mencoba kembali.':msg);}
      successful=true;
      return d;
    } on SocketException {throw ApiError('Tidak ada koneksi internet');}
    on TimeoutException {throw ApiError('Waktu koneksi habis');}
    on FormatException {throw ApiError('Layanan Cikoko sedang mengalami kendala. Silakan mencoba kembali.');}
    finally {if(progressId!=null)CikokoRequestProgress.finish(progressId,success:successful);}
  }
  Future<Map<String,dynamic>> callWithQuery(String action,Map<String,String> query) async => call('$action&${Uri(queryParameters:query).query}');
  String photoUrl(String action,Map<String,String> params) => '${root.replaceFirst('index.php','v211.php')}?action=$action&${Uri(queryParameters:params).query}';
  Map<String,String> authHeaders() => token==null ? {} : {'Authorization':'Bearer $token'};
  Future<Map<String,dynamic>> callWithParams(String action,Map<String,String> params)=>callWithQuery(action,params);
  Future<void> login(String username,String password) async {
    final v=await call('login',body:{'username':username,'password':password});
    token = v['token'] as String;
    profile=Map<String,dynamic>.from(v['user'] as Map);
    await _storage.write(key:'cikoko_token',value:token);
  }
  Future<void> register(Map<String,dynamic> fields) async { await call('register',body:fields); }
  Future<void> logout() async {if(token!=null){try{await call('logout',body:{});}catch(_){}}token=null;profile=null;await _storage.delete(key:'cikoko_token');}
  String media(String? path) {
    final p=path??'';
    if(p.isEmpty)return '';
    final u=Uri.tryParse(p);
    if(u!=null&&u.scheme=='https'&&u.host=='datawebs.my.id')return p;
    if(p.startsWith('assets/') && !p.contains('..'))return 'https://datawebs.my.id/$p';
    return '';
  }
  Future<Map<String,dynamic>> upload(String action,Map<String,String> fields,
      Map<String,List<String>> files,{void Function(double)? progress}) async {
    final req=http.MultipartRequest('POST',Uri.parse(
      "${action.startsWith('v211_') ? root.replaceFirst('index.php','v211.php') : root}?action=$action"));
    req.headers['Accept']='application/json';
    if(token!=null)req.headers['Authorization']='Bearer $token';
    req.fields.addAll(fields);

    final progressId=CikokoRequestProgress.begin();
    var uploadSuccess=false;
    final temp=<File>[];
    final count=files.values.fold<int>(0,(sum,paths)=>sum+paths.length);
    var prepared=0;
    try {
      for(final entry in files.entries){
        for(final path in entry.value){
          String ready;
          try {
            ready=await CikokoPhotoUpload.prepare(entry.key,path);
          } on FileSystemException catch(e){
            throw ApiError(e.message);
          }
          if(ready!=path)temp.add(File(ready));
          req.files.add(await http.MultipartFile.fromPath(entry.key,ready));
          prepared++;
          final fraction=count==0?0.0:0.12*prepared/count;
          progress?.call(fraction);
          CikokoRequestProgress.update(progressId,fraction);
        }
      }
      final total=req.contentLength;
      final original=req.finalize();
      final streamed=http.StreamedRequest('POST',req.url);
      streamed.headers.addAll(req.headers);
      streamed.contentLength=total;
      final client=http.Client();
      try {
        final pending=client.send(streamed).timeout(const Duration(seconds:180));
        var sent=0;
        await streamed.sink.addStream(original.map((chunk){
          sent+=chunk.length;
          final fraction=total==0?0.12:0.12+0.82*sent/total;
          progress?.call(fraction);
          CikokoRequestProgress.update(progressId,fraction);
          return chunk;
        }));
        await streamed.sink.close();
        final response=await pending;
        final str=await response.stream.bytesToString();
        final data=jsonDecode(str);
        if(data is! Map<String,dynamic> || response.statusCode>=400 || data['ok']!=true){
          throw ApiError(data is Map? "${data['error']??'Upload gagal'}":'Upload gagal');
        }
        uploadSuccess=true;
        progress?.call(1);
        return data;
      }finally{
        client.close();
      }
    }finally{
      CikokoRequestProgress.finish(progressId,success:uploadSuccess);
      for(final file in temp){
        try{if(await file.exists())await file.delete();}catch(_){}
      }
    }
  }
}
