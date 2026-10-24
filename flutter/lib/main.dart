import 'dart:async';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';
import 'push.dart';

const navy=Color(0xff10375f), blue=Color(0xff226fda), pale=Color(0xfff3f7fc);
final api=CikokoApi();
void main(){WidgetsFlutterBinding.ensureInitialized();runApp(const CikokoApp());}
class CikokoApp extends StatelessWidget {
 const CikokoApp({super.key});
 @override Widget build(BuildContext c)=>MaterialApp(title:'Cikoko',debugShowCheckedModeBanner:false,theme:ThemeData(useMaterial3:true,scaffoldBackgroundColor:pale,colorScheme:ColorScheme.fromSeed(seedColor:blue),appBarTheme:const AppBarTheme(backgroundColor:Colors.white,foregroundColor:navy),inputDecorationTheme:InputDecorationTheme(isDense:true,filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(12))),cardTheme:CardThemeData(color:Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))),textTheme:const TextTheme(titleLarge:TextStyle(fontSize:20,fontWeight:FontWeight.w700,color:navy),titleMedium:TextStyle(fontSize:15,fontWeight:FontWeight.w700,color:navy),bodyMedium:TextStyle(fontSize:13.5)) ),home:const Entry());
}
class Entry extends StatefulWidget{const Entry({super.key});@override State<Entry> createState()=>_EntryState();}
class _EntryState extends State<Entry>{bool loading=true;@override void initState(){super.initState();api.restore().whenComplete((){if(mounted)setState(()=>loading=false);});}
 @override Widget build(BuildContext c)=>loading?const Scaffold(body:Center(child:CircularProgressIndicator())):api.token==null?LoginPage(onLogin:()=>setState((){})):HomePage(onLogout:()=>setState((){}));}
class Logo extends StatelessWidget{final double size;const Logo({super.key,this.size=58});@override Widget build(BuildContext c)=>ClipOval(child:Image.asset('assets/logo.png',width:size,height:size,fit:BoxFit.cover));}
class LoginPage extends StatefulWidget{final VoidCallback onLogin;const LoginPage({super.key,required this.onLogin});@override State<LoginPage> createState()=>_LoginState();}
class _LoginState extends State<LoginPage>{final user=TextEditingController(),pass=TextEditingController();bool busy=false,signup=false;final fields=<String,TextEditingController>{};
 @override void dispose(){user.dispose();pass.dispose();for(final c in fields.values){c.dispose();}super.dispose();}
 TextEditingController ctrl(String key)=>fields.putIfAbsent(key,()=>TextEditingController());
 Future<void> submit() async{setState(()=>busy=true);try{if(signup){if(ctrl('password').text!=ctrl('confirm').text)throw ApiError('Konfirmasi password tidak sama');await api.register({for(final k in ['name','username','password','confirm','address','phone','email']) k:ctrl(k).text.trim()});if(mounted){setState(()=>signup=false);notify(context,'Akun warga aktif. Silakan login.');}}else{await api.login(user.text.trim(),pass.text);widget.onLogin();}}catch(e){if(mounted)notify(context,'$e',error:true);}finally{if(mounted)setState(()=>busy=false);}}
 @override
 Widget build(BuildContext context) {
   final title = signup ? 'Daftar Akun Warga' : 'Login Cikoko';
   return Scaffold(
     body: Center(
       child: SingleChildScrollView(
         padding: const EdgeInsets.all(18),
         child: ConstrainedBox(
           constraints: const BoxConstraints(maxWidth: 430),
           child: Card(
             elevation: 1,
             child: Padding(
               padding: const EdgeInsets.all(24),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   const Logo(),
                   const SizedBox(height: 16),
                   Text(title, style: Theme.of(context).textTheme.titleLarge),
                   const SizedBox(height: 6),
                   const Text('Layanan Digital Kelurahan Cikoko • Pancoran', style: TextStyle(color: Colors.blueGrey)),
                   const SizedBox(height: 22),
                   if (signup)
                     for (final entry in <String, String>{
                       'name': 'Nama lengkap',
                       'username': 'Username',
                       'password': 'Password',
                       'confirm': 'Ulangi password',
                       'address': 'Alamat lengkap',
                       'phone': 'Nomor telepon',
                       'email': 'Email',
                     }.entries)
                       Padding(
                         padding: const EdgeInsets.only(bottom: 12),
                         child: TextField(
                           controller: ctrl(entry.key),
                           obscureText: entry.key == 'password' || entry.key == 'confirm',
                           keyboardType: entry.key == 'email' ? TextInputType.emailAddress : entry.key == 'phone' ? TextInputType.phone : TextInputType.text,
                           decoration: InputDecoration(labelText: entry.value),
                         ),
                       )
                   else ...[
                     TextField(controller: user, decoration: const InputDecoration(labelText: 'Username'), textInputAction: TextInputAction.next),
                     const SizedBox(height: 12),
                     TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                   ],
                   const SizedBox(height: 22),
                   SizedBox(
                     width: double.infinity,
                     child: FilledButton(
                       onPressed: busy ? null : submit,
                       child: Padding(
                         padding: const EdgeInsets.all(12),
                         child: busy ? const SizedBox(height: 17, width: 17, child: CircularProgressIndicator(strokeWidth: 2)) : Text(signup ? 'Daftar Sekarang' : 'Masuk ke Akun'),
                       ),
                     ),
                   ),
                   const SizedBox(height: 14),
                   TextButton(onPressed: busy ? null : () => setState(() => signup = !signup), child: Text(signup ? 'Sudah punya akun? Login' : 'Daftar Akun Warga →')),
                   const Divider(),
                   const Text('Data pribadi diproses untuk pelayanan Kelurahan Cikoko.', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                 ],
               ),
             ),
           ),
         ),
       ),
     ),
   );
 }

}
void notify(BuildContext c,String text,{bool error=false}){ScaffoldMessenger.of(c).hideCurrentSnackBar();ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(text),backgroundColor:error?Colors.red.shade700:navy));}
class HomePage extends StatefulWidget{final VoidCallback onLogout;const HomePage({super.key,required this.onLogout});@override State<HomePage> createState()=>_HomeState();}
class _HomeState extends State<HomePage>{String section='Dashboard';List<dynamic> items=[],events=[];bool loading=false;Timer? timer;PushService? push;
 String get role => '${api.profile?['role']??'warga'}';bool get isStaff=>role!='warga';bool get isAdmin=>role=='admin'||role=='admin_kelurahan';
 @override void initState(){super.initState();load();push=PushService(api);push!.start(refresh);timer=Timer.periodic(const Duration(seconds:15),(_)=>refresh());}
 @override void dispose(){timer?.cancel();push?.dispose();super.dispose();}
 Future<void> refresh() async{try{final v=await api.call('events');if(mounted)setState(()=>events=List<dynamic>.from(v['events']??[]));}catch(_){}}
 Future<void> load() async{setState(()=>loading=true);try{await refresh();final result=await api.call('content',body:null);if(mounted)setState(()=>items=List<dynamic>.from(result['items']??[]));}catch(e){if(mounted)notify(context,'$e',error:true);}finally{if(mounted)setState(()=>loading=false);}}
 void switchTo(String s){setState(()=>section=s);Navigator.maybePop(context);}
 List<String> get menus=>['Dashboard','Berita & Kegiatan','Pengumuman','Layanan Online','Galeri','Surat Ahli Waris',if(role=='warga')'Jumantik Warga',if(isStaff)'Laporan Kegiatan','Riwayat',if(isAdmin)'Verifikasi Laporan',if(isAdmin)'Pesan Masuk','Hubungi Kami','Notifikasi','Profil'];
 IconData iconFor(String s)=>switch(s){'Dashboard'=>Icons.dashboard_outlined,'Berita & Kegiatan'=>Icons.newspaper_outlined,'Pengumuman'=>Icons.campaign_outlined,'Layanan Online'=>Icons.grid_view_outlined,'Galeri'=>Icons.photo_library_outlined,'Surat Ahli Waris'=>Icons.description_outlined,'Jumantik Warga'=>Icons.bug_report_outlined,'Laporan Kegiatan'=>Icons.assignment_outlined,'Riwayat'=>Icons.history,'Pesan Masuk'=>Icons.forum_outlined,'Hubungi Kami'=>Icons.chat_outlined,'Notifikasi'=>Icons.notifications_outlined,'Profil'=>Icons.person_outline,_=>Icons.assignment_turned_in_outlined};
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text(section,style:Theme.of(c).textTheme.titleMedium),actions:[IconButton(tooltip:'Notifikasi',onPressed:()=>switchTo('Notifikasi'),icon:Badge(isLabelVisible:events.isNotEmpty,label:Text('${events.length}'),child:const Icon(Icons.notifications_none))),IconButton(tooltip:'Muat ulang',onPressed:load,icon:const Icon(Icons.refresh))]),drawer:Drawer(child:SafeArea(child:Column(children:[const SizedBox(height:14),const Logo(size:70),const SizedBox(height:8),const Text('Kelurahan Cikoko',style:TextStyle(fontWeight:FontWeight.w800,fontSize:18)),Text('${api.profile?['name']??''} • $role',style:const TextStyle(color:Colors.blueGrey,fontSize:12)),const SizedBox(height:12),const Divider(),Expanded(child:ListView(children:menus.map((m)=>ListTile(dense:true,selected:section==m,selectedTileColor:const Color(0xffe4f0ff),leading:Icon(iconFor(m),size:21),title:Text(m,style:const TextStyle(fontSize:13.5,fontWeight:FontWeight.w600)),onTap:()=>switchTo(m))).toList())),const Divider(),ListTile(leading:const Icon(Icons.logout),title:const Text('Keluar'),onTap:() async {await api.logout();widget.onLogout();})]))),body:loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:load,child:_page()),floatingActionButton:section=='Hubungi Kami'?null:FloatingActionButton.small(tooltip:'Hubungi Admin',onPressed:()=>switchTo('Hubungi Kami'),child:const Icon(Icons.chat_bubble_outline)));
 Widget _page(){switch(section){case 'Dashboard':return home();case 'Berita & Kegiatan':return feed('berita');case 'Pengumuman':return feed('pengumuman');case 'Layanan Online':return feed('layanan');case 'Galeri':return feed('galeri');case 'Surat Ahli Waris':return const WarisForm();case 'Jumantik Warga':return const ReportForm(kind:'jumantik');case 'Laporan Kegiatan':return const ReportForm(kind:'kegiatan');case 'Riwayat':return const HistoryPage();case 'Hubungi Kami':return const ChatPage();case 'Pesan Masuk':return const AdminChatPage();case 'Notifikasi':return eventList();case 'Profil':return profilePage();case 'Verifikasi Laporan':return const AdminReports();default:return home();}}
 Widget home() => ListView(
   padding: const EdgeInsets.all(14),
   children: [
     Container(
       padding: const EdgeInsets.all(18),
       decoration: BoxDecoration(
         borderRadius: BorderRadius.circular(18),
         gradient: const LinearGradient(colors: [navy, Color(0xff156d81)]),
       ),
       child: Row(children: [
         const Logo(size: 60),
         const SizedBox(width: 16),
         Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
           Text('Halo, ${api.profile?['name']??'Warga'}', style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
           const SizedBox(height: 6),
           const Text('Pelayanan publik dan informasi Kelurahan Cikoko', style: TextStyle(color: Colors.white70)),
         ])),
       ]),
     ),
     const SizedBox(height: 20),
     Text('Menu Layanan', style: Theme.of(context).textTheme.titleMedium),
     const SizedBox(height: 12),
     LayoutBuilder(builder: (ctx, constraints) => GridView.count(
       shrinkWrap: true,
       physics: const NeverScrollableScrollPhysics(),
       crossAxisCount: constraints.maxWidth > 700 ? 4 : 2,
       childAspectRatio: 1.4,
       crossAxisSpacing: 10,
       mainAxisSpacing: 10,
       children: menus.where((x) => !['Dashboard','Profil','Notifikasi','Riwayat'].contains(x)).take(10).map((item) =>
         InkWell(
           onTap: () => switchTo(item),
           child: Card(child: Padding(
             padding: const EdgeInsets.all(10),
             child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
               Icon(iconFor(item), size: 27, color: blue),
               const SizedBox(height: 8),
               Text(item, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
             ]),
           )),
         )).toList(),
     )),
     const SizedBox(height: 14),
     Text('Informasi Terbaru', style: Theme.of(context).textTheme.titleMedium),
     ...items.where((x) => x['type'] == 'berita' || x['type'] == 'pengumuman').take(4).map((x) => contentCard(Map<String, dynamic>.from(x))),
   ],
 );

 Widget feed(String type)=>ListView(padding:const EdgeInsets.all(14),children:[for(final v in items.where((e)=>e['type']==type))contentCard(Map<String,dynamic>.from(v)),if(!items.any((e)=>e['type']==type))const Padding(padding:EdgeInsets.all(18),child:Text('Belum ada konten pada kategori ini.'))]);
 Widget contentCard(Map<String, dynamic> item) {
   final image = api.media('${item['image']??''}');
   final title = '${item['title']??''}';
   final description = '${item['body']??''}';
   final link = 'https://datawebs.my.id/article.php?id=${item['id']??''}';
   Widget photo() => image.isEmpty ? const SizedBox.shrink() : Image.network(
     image, height: 150, width: double.infinity, fit: BoxFit.cover,
     errorBuilder: (c, e, stack) => const SizedBox.shrink(),
   );
   Future<void> detail() async {
     await showDialog<void>(
       context: context,
       builder: (dialogContext) => AlertDialog(
         title: Text(title),
         content: SingleChildScrollView(child: Column(
           mainAxisSize: MainAxisSize.min,
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             if (image.isNotEmpty) photo(),
             const SizedBox(height: 12),
             Text(description),
             if (item['type'] == 'berita') ...[
               const SizedBox(height: 16),
               Wrap(spacing: 8, runSpacing: 6, children: [
                 TextButton.icon(onPressed: () => share('https://wa.me/?text=${Uri.encodeComponent('$title $link')}'), icon: const Icon(Icons.share), label: const Text('WhatsApp')),
                 TextButton(onPressed: () => share('https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(link)}'), child: const Text('Facebook')),
                 TextButton(onPressed: () async {
                   await Clipboard.setData(ClipboardData(text: link));
                   if (dialogContext.mounted) notify(dialogContext, 'Tautan disalin untuk Instagram');
                 }, child: const Text('Salin Tautan')),
               ]),
             ],
           ],
         )),
         actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Tutup'))],
       ),
     );
   }
   return Card(child: InkWell(
     onTap: detail,
     child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
       if (image.isNotEmpty) ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: photo()),
       Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
         Text(title, style: Theme.of(context).textTheme.titleMedium),
         const SizedBox(height: 6),
         Text(description, maxLines: 3, overflow: TextOverflow.ellipsis),
         const SizedBox(height: 10),
         const Row(mainAxisAlignment: MainAxisAlignment.end, children: [Text('Lihat Detail →', style: TextStyle(color: blue, fontWeight: FontWeight.w600, fontSize: 12))]),
       ])),
     ]),
   ));
 }

 Future<void> share(String link) async {final u=Uri.parse(link);await launchUrl(u,mode:LaunchMode.externalApplication);}
 Widget eventList()=>ListView(children:[for(final e in events)ListTile(leading:const Icon(Icons.notifications_active_outlined,color:blue),title:Text('${e['title']??''}'),subtitle:Text('${e['created_at']??''}')),if(events.isEmpty)const ListTile(title:Text('Belum ada notifikasi.'))]);
 Widget profilePage()=>ListView(padding:const EdgeInsets.all(16),children:[for(final e in (api.profile??{}).entries)if(!['id','password_hash','token'].contains(e.key))Card(child:ListTile(title:Text(e.key),subtitle:Text('${e.value}')))]);
}
class Field extends StatelessWidget{final String label;final TextEditingController ctrl;final int lines;final TextInputType keyboard;const Field(this.label,this.ctrl,{super.key,this.lines=1,this.keyboard=TextInputType.text});@override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.only(bottom:12),child:TextField(controller:ctrl,maxLines:lines,keyboardType:keyboard,decoration:InputDecoration(labelText:label,alignLabelWithHint:lines>1)));}
class PhotoInput extends StatefulWidget{final String label;final void Function(String path) onChanged;const PhotoInput({super.key,required this.label,required this.onChanged});@override State<PhotoInput> createState()=>_PhotoState();}
class _PhotoState extends State<PhotoInput>{String? selected;Future<void> pick(ImageSource source) async{try{final file=await ImagePicker().pickImage(source:source,maxWidth:1900,maxHeight:2400,imageQuality:78,requestFullMetadata:false);if(file!=null){var newPath=file.path;
        try{
          final original=File(file.path);
          if(await original.length()>1550000){
            for(final quality in [85,75,65,55]){
              final compressed=await FlutterImageCompress.compressWithFile(file.path,quality:quality,format:CompressFormat.jpeg,keepExif:false);
              if(compressed==null)break;
              final output=File('${Directory.systemTemp.path}/cikoko_${DateTime.now().microsecondsSinceEpoch}.jpg');
              await output.writeAsBytes(compressed,flush:true);newPath=output.path;
              if(compressed.length<=1550000)break;
            }
          }
        }catch(_){ /* Gunakan berkas foto dari picker bila kompresi gagal */ }
        setState(()=>selected=file.name);widget.onChanged(newPath);}}catch(e){if(mounted)notify(context,'Gagal mengambil foto: $e',error:true);}}
 @override Widget build(BuildContext c)=>Card(child:Padding(padding:const EdgeInsets.all(10),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(widget.label,style:const TextStyle(fontWeight:FontWeight.w600,fontSize:12)),const SizedBox(height:5),Wrap(spacing:6,children:[OutlinedButton.icon(onPressed:()=>pick(ImageSource.camera),icon:const Icon(Icons.camera_alt_outlined,size:18),label:const Text('Kamera')),OutlinedButton.icon(onPressed:()=>pick(ImageSource.gallery),icon:const Icon(Icons.photo_library_outlined,size:18),label:const Text('Galeri'))]),Text(selected??'Belum ada foto',style:const TextStyle(fontSize:11,color:Colors.blueGrey),overflow:TextOverflow.ellipsis)])));
}
class WarisForm extends StatefulWidget{const WarisForm({super.key});@override State<WarisForm> createState()=>_WarisState();}
class _WarisState extends State<WarisForm>{final inputs=<String,TextEditingController>{};final files=<String,List<String>>{};int children=0;bool sending=false;double progress=0;bool agree=false;
 TextEditingController v(String id)=>inputs.putIfAbsent(id,()=>TextEditingController());
 @override void dispose(){for(final x in inputs.values){x.dispose();}super.dispose();}
 static const names=<String,String>{'name':'Nama pemohon','nik':'NIK pemohon (16 digit)','phone':'Nomor HP','address':'Alamat lengkap','relation':'Hubungan dengan pewaris','deceased_name':'Nama almarhum / almarhumah','birthplace':'Tempat lahir pewaris','birthdate':'Tanggal lahir (YYYY-MM-DD)','marriage_date':'Tanggal menikah (YYYY-MM-DD)','deathdate':'Tanggal meninggal (YYYY-MM-DD)','marital_status':'Status perkawinan','heirs':'Daftar ahli waris'};
 static const requiredPhotos=<String,String>{'r1':'Surat pengantar RT/RW','r2':'Surat permohonan','r3':'Surat pernyataan keabsahan','r4':'KTP, KK, akta lahir ahli waris','r5':'Surat kematian','r6':'Surat nikah'};
 static const optionalPhotos=<String,String>{'r7':'Akta cerai (jika bercerai)','r8':'Surat kematian ahli waris (jika ada)'};
 Future<void> send()async{if(sending)return;for(final k in ['name','nik','phone','address','relation','deceased_name','heirs']){if(v(k).text.trim().isEmpty){notify(context,'Lengkapi ${names[k]}',error:true);return;}}if(!RegExp(r'^\d{16}$').hasMatch(v('nik').text)){notify(context,'NIK harus 16 digit',error:true);return;}for(final k in requiredPhotos.keys){if((files[k]??[]).isEmpty){notify(context,'Upload ${requiredPhotos[k]}',error:true);return;}}for(var i=1;i<=children;i++){if((files['child_$i']??[]).isEmpty){notify(context,'Upload dokumen anak ke-$i',error:true);return;}}if(!agree){notify(context,'Setujui pernyataan data',error:true);return;}
 setState((){sending=true;progress=0;});try{final data=<String,String>{for(final e in inputs.entries)e.key:e.value.text.trim(),'declaration':'1','child_count':'$children'};final response=await api.upload('waris',data,files,progress:(v){if(mounted)setState(()=>progress=v);});if(mounted){notify(context,'Terkirim. Nomor: ${response['reference']}');setState(()=>sending=false);}}catch(e){if(mounted)notify(context,'$e',error:true);}finally{if(mounted)setState(()=>sending=false);}}
 @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(12),children:[const Card(child:Padding(padding:EdgeInsets.all(16),child:Text('Permohonan Pencatatan Ahli Waris\nSemua data dan foto dokumen akan diperiksa petugas. Pastikan foto terbaca.',style:TextStyle(color:navy,fontWeight:FontWeight.w600)))),Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Identitas Pemohon dan Pewaris',style:Theme.of(c).textTheme.titleMedium),const SizedBox(height:14),for(final e in names.entries)Field(e.value,v(e.key),lines:e.key=='heirs'||e.key=='address'?3:1,keyboard:e.key=='nik'?TextInputType.number:TextInputType.text)]))),const SizedBox(height:12),Text('Foto Persyaratan Wajib',style:Theme.of(c).textTheme.titleMedium),for(final e in requiredPhotos.entries)PhotoInput(key:ValueKey(e.key),label:e.value,onChanged:(f)=>files[e.key]=[f]),const SizedBox(height:12),Text('Dokumen Kondisional',style:Theme.of(c).textTheme.titleMedium),for(final e in optionalPhotos.entries)PhotoInput(key:ValueKey(e.key),label:e.value,onChanged:(f)=>files[e.key]=[f]),const SizedBox(height:14),Row(children:[Expanded(child:Text('Data Anak (maksimal 10)',style:Theme.of(c).textTheme.titleMedium)),OutlinedButton(onPressed:children>=10?null:()=>setState(()=>children++),child:const Text('+ Tambah Anak'))]),for(var i=1;i<=children;i++)Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[Field('Nama anak ke-$i',v('child_name_$i')),PhotoInput(key:ValueKey('child_$i'),label:'Foto KTP, KK dan akta lahir anak ke-$i',onChanged:(f)=>files['child_$i']=[f])]))),CheckboxListTile(value:agree,onChanged:(v)=>setState(()=>agree=v??false),title:const Text('Saya menyatakan seluruh data dan foto dokumen sesuai keadaan sebenarnya.',style:TextStyle(fontSize:12))),if(sending)...[LinearProgressIndicator(value:progress),Padding(padding:const EdgeInsets.all(8),child:Text('Mengirim ${(progress*100).toStringAsFixed(0)}%'))],FilledButton.icon(onPressed:sending?null:send,icon:const Icon(Icons.send),label:const Padding(padding:EdgeInsets.all(12),child:Text('Kirim Permohonan Ahli Waris'))),const SizedBox(height:24)]);
}
class ReportForm extends StatefulWidget{final String kind;const ReportForm({super.key,required this.kind});@override State<ReportForm> createState()=>_ReportState();}
class _ReportState extends State<ReportForm>{final address=TextEditingController(),phone=TextEditingController(),notes=TextEditingController();String? photo;bool sending=false;double progress=0;
 @override void dispose(){address.dispose();phone.dispose();notes.dispose();super.dispose();}
 Future<void> send()async{if(address.text.trim().isEmpty||notes.text.trim().isEmpty||photo==null){notify(context,'Lengkapi alamat, keterangan dan foto',error:true);return;}setState(()=>sending=true);try{await api.upload('report',{'kind':widget.kind,'address':address.text,'phone':phone.text,'notes':notes.text},{'photo':[photo!]},progress:(p){if(mounted)setState(()=>progress=p);});if(mounted)notify(context,'Laporan berhasil dikirim');}catch(e){if(mounted)notify(context,'$e',error:true);}finally{if(mounted)setState(()=>sending=false);}}
 @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(14),children:[Field('Alamat / Lokasi',address),Field('Nomor telepon',phone),Field('Keterangan kegiatan / hasil pemantauan',notes,lines:5),PhotoInput(label:'Foto bukti kegiatan',onChanged:(f)=>photo=f),if(sending)...[LinearProgressIndicator(value:progress),Text('${(progress*100).round()}%')],FilledButton(onPressed:sending?null:send,child:const Text('Kirim Laporan'))]);
}
class HistoryPage extends StatefulWidget{const HistoryPage({super.key});@override State<HistoryPage> createState()=>_HistoryState();}
class _HistoryState extends State<HistoryPage>{Future<Map<String,dynamic>>? future;@override void initState(){super.initState();future=api.call('history');}
 @override Widget build(BuildContext c)=>FutureBuilder<Map<String,dynamic>>(future:future,builder:(c,s){if(s.hasError)return Center(child:Text('${s.error}'));if(!s.hasData)return const Center(child:CircularProgressIndicator());final rows=List<dynamic>.from(s.data!['items']??[]);return ListView(children:[for(final r in rows)ListTile(title:Text('${r['title']??r['reference']??'Pengajuan'}'),subtitle:Text('${r['status']??''} · ${r['created_at']??''}')),if(rows.isEmpty)const ListTile(title:Text('Belum ada riwayat pengajuan.'))]);});
}
class ChatPage extends StatefulWidget{const ChatPage({super.key});@override State<ChatPage> createState()=>_ChatState();}
class _ChatState extends State<ChatPage>{final ctrl=TextEditingController();List<dynamic> messages=[];bool busy=false;Timer?timer;@override void initState(){super.initState();refresh();timer=Timer.periodic(const Duration(seconds:15),(_)=>refresh());} @override void dispose(){timer?.cancel();ctrl.dispose();super.dispose();}
 Future<void> refresh()async{try{final d=await api.call('chat');if(mounted)setState(()=>messages=List<dynamic>.from(d['messages']??[]));}catch(_){}}
 Future<void> send()async{if(ctrl.text.trim().isEmpty)return;setState(()=>busy=true);try{await api.call('chat_send',body:{'message':ctrl.text.trim()});ctrl.clear();await refresh();}catch(e){if(mounted)notify(context,'$e',error:true);}finally{if(mounted)setState(()=>busy=false);}}
 @override Widget build(BuildContext c)=>Column(children:[Container(width:double.infinity,padding:const EdgeInsets.all(12),color:Colors.white,child:const Text('Hubungi Admin • Pesan dijawab pada jam kerja Sen–Kam 07.30–16.00, Jum 07.30–16.30 WIB.',style:TextStyle(fontSize:12))),Expanded(child:ListView(padding:const EdgeInsets.all(12),children:[for(final m in messages)Align(alignment:m['sender']=='admin'?Alignment.centerLeft:Alignment.centerRight,child:Card(color:m['sender']=='admin'?Colors.white:const Color(0xffdef0ff),child:Padding(padding:const EdgeInsets.all(12),child:Text('${m['message']}'))))])),SafeArea(child:Padding(padding:const EdgeInsets.all(10),child:Row(children:[Expanded(child:TextField(controller:ctrl,maxLines:3,minLines:1,decoration:const InputDecoration(hintText:'Tulis pesan ke admin...'))),IconButton(onPressed:busy?null:send,icon:const Icon(Icons.send,color:blue))])))]);
}
class AdminChatPage extends StatefulWidget{const AdminChatPage({super.key});@override State<AdminChatPage> createState()=>_AdminChatState();}
class _AdminChatState extends State<AdminChatPage>{List<dynamic> threads=[];@override void initState(){super.initState();load();}
 Future<void> load()async{try{final d=await api.call('chat_threads');if(mounted)setState(()=>threads=List<dynamic>.from(d['threads']??[]));}catch(e){if(mounted)notify(context,'$e',error:true);}}
 Future<void> reply(Map<String,dynamic> t) async {final ctrl=TextEditingController();await showDialog(context:context,builder:(c)=>AlertDialog(title:Text('Balas ${t['name']}'),content:TextField(controller:ctrl,decoration:const InputDecoration(hintText:'Balasan admin')),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Batal')),FilledButton(onPressed:()async{try{await api.call('chat_reply',body:{'user_id':t['user_id'],'message':ctrl.text});if(c.mounted)Navigator.pop(c);load();}catch(e){if(c.mounted)notify(c,'$e',error:true);}},child:const Text('Kirim'))]));ctrl.dispose();}
 @override Widget build(BuildContext c)=>ListView(children:[for(final t in threads)ListTile(leading:const Icon(Icons.person),title:Text('${t['name']}'),subtitle:Text('${t['message']}'),trailing:const Icon(Icons.reply),onTap:()=>reply(Map<String,dynamic>.from(t))),if(threads.isEmpty)const ListTile(title:Text('Belum ada pesan masuk.'))]);
}
class AdminReports extends StatefulWidget{const AdminReports({super.key});@override State<AdminReports> createState()=>_AdminReportsState();}
class _AdminReportsState extends State<AdminReports>{List<dynamic> rows=[];@override void initState(){super.initState();load();}
 Future<void> load()async{try{final d=await api.call('admin_reports');if(mounted)setState(()=>rows=List<dynamic>.from(d['items']??[]));}catch(e){if(mounted)notify(context,'$e',error:true);}}
 Future<void> update(Map<String,dynamic> r,String status)async{try{await api.call('status',body:{'kind':r['kind'],'id':r['id'],'status':status});load();}catch(e){if(mounted)notify(context,'$e',error:true);}}
 @override Widget build(BuildContext c)=>ListView(children:[for(final r in rows)Card(child:ListTile(title:Text('${r['title']??r['reference']}'),subtitle:Text('${r['status']} · ${r['name']??''}'),trailing:PopupMenuButton<String>(onSelected:(s)=>update(Map<String,dynamic>.from(r),s),itemBuilder:(c)=>['masuk','proses','revisi','selesai','ditolak'].map((s)=>PopupMenuItem(value:s,child:Text(s))).toList()))),if(rows.isEmpty)const ListTile(title:Text('Belum ada permohonan.'))]);
}
