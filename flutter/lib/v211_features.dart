import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';
import 'cikoko_v4_public_pages.dart';
import 'cikoko_v6_showcase.dart';

const civicBlue=Color(0xff216bd7), civicNavy=Color(0xff12375d);
const String cikokoPlayStoreUrl=''; // TODO: isi URL Play Store aplikasi Cikoko

void civicMessage(BuildContext context,String message){
 if(!context.mounted)return;
 ScaffoldMessenger.of(context).hideCurrentSnackBar();
 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(message),behavior:SnackBarBehavior.floating));
}

class InnovationPage extends StatefulWidget{
 final CikokoApi api;
 const InnovationPage({super.key,required this.api});
 @override State<InnovationPage> createState()=>_InnovationPageState();
}
class _InnovationPageState extends State<InnovationPage>{
 late Future<Map<String,dynamic>> pending;
 @override void initState(){super.initState();reload();}
 static const defaults=[
 {'slug':'eco-edu-wisata-ciliwung','title':'ECO EDU WISATA CILIWUNG','summary':'Edukasi lingkungan dan wisata Sungai Ciliwung','body':'Rincian program akan tersinkronisasi dari website Kelurahan Cikoko.'},
 {'slug':'cikoko-bio-farm-education','title':'CIKOKO BIO FARM EDUCATION','summary':'Edukasi pertanian dan lingkungan perkotaan','body':'Rincian program akan tersinkronisasi dari website Kelurahan Cikoko.'},
 {'slug':'kampung-inggris','title':'KAMPUNG INGGRIS','summary':'Pengembangan bahasa Inggris untuk masyarakat','body':'Rincian program akan tersinkronisasi dari website Kelurahan Cikoko.'},
];
 Future<Map<String,dynamic>> fetchInnovations()async{
  try{return await widget.api.call('v211_innovations');}
  catch(_){return {'ok':true,'offline':true,'items':<dynamic>[]};}
 }
 void reload(){pending=fetchInnovations();}
 Future<void> edit(Map<String,dynamic> item)async{
  final ctrls={for(final k in ['title','summary','body'])k:TextEditingController(text:'${item[k]??''}')};
  final slug='${item['slug']??''}';
  var photos=List<String>.from((item['images'] is List)?item['images']:[]);
  if(photos.isEmpty&&'${item['image']??''}'.isNotEmpty)photos=['${item['image']}'];
  var saving=false;
  try{
   await showModalBottomSheet<void>(context:context,isScrollControlled:true,useSafeArea:true,showDragHandle:true,
    builder:(sheet)=>StatefulBuilder(builder:(sheet,refreshSheet)=>Padding(
     padding:EdgeInsets.fromLTRB(16,4,16,MediaQuery.viewInsetsOf(sheet).bottom+18),
     child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Kelola Informasi Inovasi',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800)),
      const SizedBox(height:12),
      for(final e in ctrls.entries)Padding(padding:const EdgeInsets.only(bottom:12),child:TextField(
       controller:e.value,maxLines:e.key=='body'?5:1,
       decoration:InputDecoration(labelText:const {'title':'Judul','summary':'Ringkasan','body':'Deskripsi'}[e.key]))),
      const Text('Foto inovasi (maksimal 5)',style:TextStyle(fontWeight:FontWeight.w700)),
      const SizedBox(height:8),
      Wrap(spacing:8,runSpacing:8,children:[
       for(final photo in photos)Chip(
        label:Text('Foto ${photos.indexOf(photo)+1}'),
        onDeleted:saving?null:()=>refreshSheet(()=>photos.remove(photo))),
      ]),
      OutlinedButton.icon(
       onPressed:saving||photos.length>=5?null:()async{
        final picked=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:78,maxWidth:1800);
        if(picked==null)return;
        refreshSheet(()=>saving=true);
        try{
         final result=await widget.api.upload('v211_innovations_upload',{'slug':slug},{'photo':[picked.path]});
         if(sheet.mounted)refreshSheet(()=>photos=List<String>.from(result['images']??[]));
        }catch(e){if(sheet.mounted)civicMessage(sheet,'Unggah foto gagal: ${e.toString()}');}
        finally{if(sheet.mounted)refreshSheet(()=>saving=false);}
       },
       icon:const Icon(Icons.photo_library_outlined),label:const Text('Pilih Foto dari Galeri')),
      const SizedBox(height:12),
      SizedBox(width:double.infinity,child:FilledButton(
       onPressed:saving?null:()async{
        refreshSheet(()=>saving=true);
        try{
         await widget.api.call('v211_innovations_update',body:{
          'slug':slug,
          for(final e in ctrls.entries)e.key:e.value.text.trim(),
          'images':photos,
         });
         if(sheet.mounted)Navigator.pop(sheet);
         if(mounted){setState(reload);civicMessage(context,'Inovasi berhasil diperbarui.');}
        }catch(e){if(sheet.mounted)civicMessage(sheet,'Gagal menyimpan: ${e.toString()}');}
        finally{if(sheet.mounted)refreshSheet(()=>saving=false);}
       },child:Text(saving?'Memproses...':'Simpan Perubahan'))),
     ])))));
  }finally{for(final c in ctrls.values){c.dispose();}}
 }
 @override Widget build(BuildContext context)=>FutureBuilder<Map<String,dynamic>>(
  future:pending,builder:(ctx,s){
   if(s.hasError)return Center(child:TextButton.icon(onPressed:()=>setState(reload),
    icon:const Icon(Icons.refresh),label:const Text('Muat Ulang Inovasi')));
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   final items=List<dynamic>.from(s.data?['items']??[]);
   return RefreshIndicator(onRefresh:()async{setState(reload);await pending;},
    child:ListView(padding:const EdgeInsets.all(14),children:[
     const V6PageHeader(title:'Inovasi Kelurahan',
       description:'Program inovasi dan kegiatan pengembangan Kelurahan Cikoko.',
       icon:Icons.auto_awesome_outlined),
     if(s.data?['offline']==true)Padding(padding:const EdgeInsets.only(bottom:12),
       child:V6Panel(child:Row(children:[
         const Expanded(child:Text('Informasi inovasi belum dapat dimuat dari server.',
           style:TextStyle(fontSize:11,color:V6.secondary))),
         IconButton(onPressed:()=>setState(reload),icon:const Icon(Icons.refresh,color:V6.blue)),
       ]))),
     if(items.isEmpty&&s.data?['offline']!=true)const V6Panel(
       child:Text('Belum ada inovasi yang diterbitkan.',
          style:TextStyle(fontSize:11.5,color:V6.secondary))),
     for(final raw in items)...[
       Builder(builder:(ctx){
         final item=Map<String,dynamic>.from(raw);
         final image=widget.api.media((item['image']??'').toString());
         final title=(item['title']??'Inovasi Kelurahan').toString();
         final summary=(item['summary']??'').toString();
         return V6Panel(padding:const EdgeInsets.all(9),child:InkWell(
          onTap:()=>showModalBottomSheet<void>(context:context,
            isScrollControlled:true,showDragHandle:true,
            builder:(sheet)=>SafeArea(child:Padding(
              padding:const EdgeInsets.all(18),
              child:SingleChildScrollView(child:Column(
               mainAxisSize:MainAxisSize.min,
               crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text(title,style:const TextStyle(
                 fontSize:19,color:V6.ink,fontWeight:FontWeight.w900)),
                const SizedBox(height:12),
                Text((item['body']??summary).toString(),
                  style:const TextStyle(fontSize:12.3,color:V6.secondary,height:1.5)),
               ]))))),
          child:Row(children:[
            ClipRRect(borderRadius:V6.radius(9),child:image.isEmpty
              ?Container(width:91,height:85,color:V6.pale,
                 child:const Icon(Icons.eco_outlined,color:V6.blue,size:31))
              :Image.network(image,width:91,height:85,fit:BoxFit.cover,
                  errorBuilder:(_,__,___)=>Container(width:91,height:85,
                   color:V6.pale,child:const Icon(Icons.image_not_supported_outlined,color:V6.blue)))),
            const SizedBox(width:10),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(title,maxLines:2,overflow:TextOverflow.ellipsis,
                style:const TextStyle(color:V6.ink,fontSize:12.3,fontWeight:FontWeight.w900)),
              const SizedBox(height:5),
              Text(summary,maxLines:3,overflow:TextOverflow.ellipsis,
                style:const TextStyle(color:V6.secondary,fontSize:10.6)),
              const SizedBox(height:7),
              const Text('Lihat Selengkapnya  →',
                style:TextStyle(color:V6.blue,fontSize:10,fontWeight:FontWeight.w800)),
            ])),
            if(widget.api.profile?['role']=='admin')IconButton(
              tooltip:'Edit dan unggah foto inovasi',
              onPressed:()=>edit(item),icon:const Icon(Icons.edit_outlined,color:V6.blue,size:21)),
          ]),
         ));
       }),
       const SizedBox(height:9),
     ],
    ]));
  });

}

class CivicProfilePage extends StatefulWidget{final CikokoApi api;final ValueChanged<String>? onNavigate;final Future<void> Function()? onLogout;const CivicProfilePage({super.key,required this.api,this.onNavigate,this.onLogout});@override State<CivicProfilePage> createState()=>_CivicProfileState();}
class _CivicProfileState extends State<CivicProfilePage>{
 late Future<Map<String,dynamic>> pending;final fields={for(final k in ['name','username','phone','email','address','nik','rt','rw'])k:TextEditingController()};
 final currentPassword=TextEditingController();bool editing=false,saving=false,avatarReady=false;int imageVersion=0;
 Future<Map<String,dynamic>> loadProfile()async{
  try{return await widget.api.call('v211_profile');}
  catch(_){return {'ok':true,'offline':true,'user':widget.api.profile??<String,dynamic>{}};}
 }
 @override void initState(){super.initState();pending=loadProfile();}
 @override void dispose(){for(final c in fields.values){c.dispose();}currentPassword.dispose();super.dispose();}
 void fill(Map<String,dynamic> row){for(final k in fields.keys){final raw='${row[k]??''}';if(k=='rt'||k=='rw'){final n=int.tryParse(raw);fields[k]!.text=n==null?'':n.toString().padLeft(2,'0');}else{fields[k]!.text=raw;}}}
 Future<void> save()async{if(saving)return;setState(()=>saving=true);try{
  await widget.api.call('v211_profile_update',body:{for(final k in ['name','phone','email','address','nik'])k:fields[k]!.text.trim(),if(widget.api.profile?['role']=='warga') ...{'rt':fields['rt']!.text.trim(),'rw':fields['rw']!.text.trim(),'current_password':currentPassword.text}});
  widget.api.profile?['name']=fields['name']!.text.trim();
  widget.api.profile?['rt']=fields['rt']!.text.trim().padLeft(2,'0');widget.api.profile?['rw']=fields['rw']!.text.trim().padLeft(2,'0');
  currentPassword.clear();if(mounted){civicMessage(context,'Perubahan profil berhasil disimpan.');setState((){editing=false;pending=loadProfile();});}
 }catch(_){if(mounted)civicMessage(context,'Perubahan profil belum berhasil disimpan. Silakan periksa kembali isian Anda.');}finally{if(mounted)setState(()=>saving=false);}}
 Future<void> uploadAvatar()async{final f=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:80,maxWidth:1400);if(f==null)return;
  try{await widget.api.upload('v211_profile_upload',{}, {'photo':[f.path]});if(mounted){setState((){imageVersion++;avatarReady=true;});civicMessage(context,'Foto profil berhasil diperbarui.');}}catch(_){if(mounted)civicMessage(context,'Foto profil belum berhasil diperbarui.');}}
 @override Widget build(BuildContext c)=>FutureBuilder<Map<String,dynamic>>(
 future:pending,builder:(ctx,s){
  if(s.hasError)return Center(child:TextButton.icon(
   onPressed:()=>setState(()=>pending=loadProfile()),icon:const Icon(Icons.refresh),
   label:const Text('Muat Ulang Profil')));
  if(!s.hasData)return const Center(child:CircularProgressIndicator());
  final row=Map<String,dynamic>.from(s.data?['user']??{});
  if(!editing&&fields['name']!.text.isEmpty)fill(row);
  final photoUrl=CikokoApi.root.replaceFirst('index.php','v211.php')+
    '?action=v211_profile_photo&v='+imageVersion.toString();
  final hasImage=row['has_photo']==true||avatarReady;
  final role=(widget.api.profile?['role']??'warga').toString();
  return ListView(padding:const EdgeInsets.all(14),children:[
   const V6PageHeader(title:'Profil Akun',
     description:'Identitas dan pengaturan akun Cikoko Smart.',icon:Icons.person_outline),
   V6Panel(child:Row(children:[
     Stack(children:[
      CircleAvatar(radius:30,backgroundColor:V6.pale,
        backgroundImage:hasImage?NetworkImage(photoUrl,
          headers:{'Authorization':'Bearer '+(widget.api.token??'')}):null,
        child:hasImage?null:const Icon(Icons.person_outline,color:V6.blue,size:35)),
      Positioned(right:0,bottom:0,child:InkWell(
        onTap:uploadAvatar,
        child:Container(width:23,height:23,decoration:BoxDecoration(
          color:V6.blue,borderRadius:V6.radius(12)),
          child:const Icon(Icons.camera_alt_outlined,size:14,color:Colors.white)))),
     ]),
     const SizedBox(width:11),
     Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
       Text(fields['name']!.text.isEmpty?'Pengguna Cikoko':fields['name']!.text,
          style:const TextStyle(color:V6.ink,fontSize:15,fontWeight:FontWeight.w900)),
       const SizedBox(height:4),
       Text('Akun '+role.toUpperCase(),style:const TextStyle(
        color:V6.secondary,fontSize:10.5,fontWeight:FontWeight.w700)),
     ])),
     IconButton(onPressed:()=>setState(()=>editing=!editing),
       icon:Icon(editing?Icons.close:Icons.edit_outlined,color:V6.blue,size:21)),
   ])),
   const SizedBox(height:18),
   if(!editing)...[
     const V6Section(title:'Pengaturan Akun'),
     for(final menu in const [
       ('Data Profil','Kelola data pribadi Anda',Icons.person_outline,'Profil'),
       ('Riwayat Pengajuan','Lihat semua pengajuan',Icons.fact_check_outlined,'Riwayat'),
       ('Notifikasi','Pemberitahuan aktivitas aplikasi',Icons.notifications_none,'Notifikasi'),
       ('Tentang Kami','Informasi Kelurahan Cikoko',Icons.info_outline,'Tentang Kami'),
       ('Bantuan & FAQ','Hubungi petugas kelurahan',Icons.help_outline,'Hubungi Kami'),
     ])Padding(padding:const EdgeInsets.only(bottom:8),
       child:V6Panel(padding:EdgeInsets.zero,child:ListTile(
         leading:Icon(menu.$3,color:V6.blue,size:22),
         title:Text(menu.$1,style:const TextStyle(color:V6.ink,
          fontSize:12.3,fontWeight:FontWeight.w800)),
         subtitle:Text(menu.$2,style:const TextStyle(
          color:V6.secondary,fontSize:10.5)),
         trailing:const Icon(Icons.chevron_right_rounded,color:V6.blue,size:19),
         onTap:menu.$4=='Profil'?()=>setState(()=>editing=true):
           ()=>widget.onNavigate?.call(menu.$4),
       ))),
     if(widget.onLogout!=null)Padding(padding:const EdgeInsets.only(top:7),
       child:OutlinedButton.icon(
         onPressed:()async{
          final yes=await showDialog<bool>(context:context,builder:(dialog)=>AlertDialog(
           title:const Text('Konfirmasi Keluar'),
           content:const Text('Keluar dari akun Cikoko Smart?'),
           actions:[
            TextButton(onPressed:()=>Navigator.pop(dialog,false),
              child:const Text('Batal')),
            FilledButton(onPressed:()=>Navigator.pop(dialog,true),
              child:const Text('Keluar')),
           ]));
          if(yes==true&&widget.onLogout!=null)await widget.onLogout!();
         },
         icon:const Icon(Icons.logout,size:18,color:V6.red),
         label:const Text('Keluar Akun',style:TextStyle(color:V6.red)))),
   ]else...[
     const V6Section(title:'Edit Data Pribadi'),
     V6Panel(child:Column(children:[
      for(final entry in <String,String>{
       'name':'Nama Lengkap','username':'Username','phone':'Nomor HP',
       'email':'Email','address':'Alamat Lengkap','nik':'NIK',
       'rt':'RT','rw':'RW'}.entries)
       if(!['rt','rw'].contains(entry.key)||role=='warga')
       Padding(padding:const EdgeInsets.only(bottom:11),child:TextField(
        controller:fields[entry.key],enabled:entry.key!='username',
        minLines:entry.key=='address'?2:1,
        maxLines:entry.key=='address'?3:1,
        keyboardType:entry.key=='email'?TextInputType.emailAddress:
           (entry.key=='rt'||entry.key=='rw'||entry.key=='nik'||entry.key=='phone')
            ?TextInputType.number:TextInputType.text,
        decoration:InputDecoration(labelText:entry.value))),
      if(role=='warga')Padding(padding:const EdgeInsets.only(bottom:12),
       child:TextField(controller:currentPassword,obscureText:true,
        decoration:const InputDecoration(
         labelText:'Konfirmasi Kata Sandi (perubahan RT/RW)',
         helperText:'Diperlukan untuk perubahan wilayah domisili.'))),
      SizedBox(width:double.infinity,child:FilledButton.icon(
       onPressed:saving?null:save,
       icon:const Icon(Icons.save_outlined,size:18),
       label:Text(saving?'Menyimpan…':'Simpan Perubahan'))),
      TextButton(onPressed:(){
        fill(row);setState(()=>editing=false);
       },child:const Text('Batal')),
     ])),
   ],
   const SizedBox(height:25),
  ]);
 });

}

class PpsuReportPage extends StatefulWidget{final CikokoApi api;const PpsuReportPage({super.key,required this.api});@override State<PpsuReportPage> createState()=>_PpsuReportState();}
class _PpsuReportState extends State<PpsuReportPage>{
 final name=TextEditingController(),activity=TextEditingController();DateTime date=DateTime.now();String team='Jalur';final photos=<String?>[null,null,null];bool sending=false;
 @override void initState(){super.initState();name.text='${widget.api.profile?['name']??''}';}
 @override void dispose(){name.dispose();activity.dispose();super.dispose();}
 Future<void> pick(int index,ImageSource source)async{final f=await ImagePicker().pickImage(source:source,imageQuality:86,maxWidth:2200);if(f!=null && mounted)setState(()=>photos[index]=f.path);}
 Future<void> send()async{if(sending)return;if(name.text.trim().isEmpty||activity.text.trim().length<5||photos.any((x)=>x==null)){civicMessage(context,'Mohon lengkapi nama, kegiatan, dan tiga foto dokumentasi.');return;}setState(()=>sending=true);
 try{await widget.api.upload('v211_ppsu_submit',{'name':name.text.trim(),'team':team,'work_date':date.toIso8601String().substring(0,10),'activity':activity.text.trim()}, {'photo1':[photos[0]!],'photo2':[photos[1]!],'photo3':[photos[2]!]});
  if(mounted){setState((){for(var i=0;i<3;i++){photos[i]=null;}activity.clear();});civicMessage(context,'Laporan PPSU telah diterima untuk ditindaklanjuti.');}
 }catch(_){if(mounted)civicMessage(context,'Laporan belum berhasil dikirim. Mohon coba kembali.');}finally{if(mounted)setState(()=>sending=false);}}
 @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(14),children:[const Text('Laporan Kegiatan PPSU',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold,color:civicNavy)),const SizedBox(height:7),
  Card(child:Padding(padding:const EdgeInsets.all(13),child:Column(children:[
   ListTile(dense:true,leading:const Icon(Icons.calendar_today,color:civicBlue),title:Text('Hari dan tanggal: ${date.day}/${date.month}/${date.year}'),trailing:const Icon(Icons.edit_calendar),onTap:()async{final d=await showDatePicker(context:context,initialDate:date,firstDate:DateTime(2020),lastDate:DateTime.now());if(d!=null && mounted)setState(()=>date=d);}),
   TextField(controller:name,decoration:const InputDecoration(labelText:'Nama Lengkap')),const SizedBox(height:12),
   DropdownButtonFormField<String>(initialValue:team,decoration:const InputDecoration(labelText:'Tim PPSU'),items:['Jalur','Hilux','Penataan','Taman'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>setState(()=>team=v??team)),const SizedBox(height:12),
   TextField(controller:activity,minLines:3,maxLines:5,decoration:const InputDecoration(labelText:'Uraian Kegiatan')),const SizedBox(height:10),
   for(var i=0;i<3;i++)Padding(padding:const EdgeInsets.only(bottom:9),child:Row(children:[
    if(photos[i]!=null)ClipRRect(borderRadius:BorderRadius.circular(8),child:Image.file(File(photos[i]!),width:55,height:55,fit:BoxFit.cover))else const SizedBox(width:55,height:55,child:Icon(Icons.add_a_photo_outlined,color:civicBlue)),
    const SizedBox(width:8),Expanded(child:Text('Foto kegiatan ${i+1}',style:const TextStyle(fontSize:12))),
    IconButton(tooltip:'Kamera',onPressed:()=>pick(i,ImageSource.camera),icon:const Icon(Icons.camera_alt_outlined)),
    IconButton(tooltip:'Galeri',onPressed:()=>pick(i,ImageSource.gallery),icon:const Icon(Icons.photo_library_outlined)),
   ])),
   SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:sending?null:send,icon:const Icon(Icons.send_outlined),label:Text(sending?'Mengirim laporan…':'Kirim Laporan PPSU'))),
  ]))),const SizedBox(height:12),
  OutlinedButton.icon(onPressed:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>Scaffold(appBar:AppBar(title:const Text('Riwayat Kegiatan PPSU')),body:PpsuHistoryPage(api:widget.api)))) ,icon:const Icon(Icons.history),label:const Text('Lihat Riwayat Kegiatan')),
 ]);
}
class PpsuHistoryPage extends StatelessWidget{final CikokoApi api;const PpsuHistoryPage({super.key,required this.api});@override Widget build(BuildContext context)=>FutureBuilder<Map<String,dynamic>>(future:api.call('v211_ppsu_list'),builder:(c,s){if(s.hasError)return const Center(child:Text('Laporan belum dapat dimuat.'));if(!s.hasData)return const Center(child:CircularProgressIndicator());final rows=List<dynamic>.from(s.data?['items']??[]);return ListView(children:[for(final raw in rows)Card(child:ListTile(title:Text('${raw['team']} · ${raw['work_date']}'),subtitle:Text('${raw['activity']}',maxLines:2,overflow:TextOverflow.ellipsis),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>PpsuDetailPage(api:api,id:int.parse('${raw['id']}')))))),if(rows.isEmpty)const ListTile(title:Text('Belum ada laporan kegiatan PPSU.'))]);});}
class PpsuDetailPage extends StatelessWidget{final CikokoApi api;final int id;const PpsuDetailPage({super.key,required this.api,required this.id});@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Detail Kegiatan PPSU')),body:FutureBuilder<Map<String,dynamic>>(future:api.callWithQuery('v211_ppsu_detail',{'id':'$id'}),builder:(ctx,s){if(s.hasError)return const Center(child:Text('Detail belum dapat ditampilkan.'));if(!s.hasData)return const Center(child:CircularProgressIndicator());final r=Map<String,dynamic>.from(s.data?['item']??{});return ListView(padding:const EdgeInsets.all(16),children:[Text('${r['team']} · ${r['work_date']}',style:const TextStyle(fontWeight:FontWeight.bold,fontSize:18)),Text('Petugas: ${r['name']??''}'),const SizedBox(height:8),Text('${r['activity']??''}'),const SizedBox(height:12),for(var i=0;i<3;i++)Padding(padding:const EdgeInsets.only(bottom:12),child:GestureDetector(onTap:()=>showDialog<void>(context:c,builder:(_)=>Dialog(child:InteractiveViewer(child:Image.network(api.photoUrl('v211_ppsu_photo',{'id':'$id','index':'$i'}),headers:api.authHeaders())))),child:ClipRRect(borderRadius:BorderRadius.circular(12),child:Image.network(api.photoUrl('v211_ppsu_photo',{'id':'$id','index':'$i'}),headers:api.authHeaders(),height:180,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Text('Foto tidak tersedia')))))]);}),);
}

class CivicNewsDetail extends StatefulWidget{final CikokoApi api;final Map<String,dynamic> preview;const CivicNewsDetail({super.key,required this.api,required this.preview});@override State<CivicNewsDetail> createState()=>_CivicNewsState();}
class _CivicNewsState extends State<CivicNewsDetail>{late Future<Map<String,dynamic>> article,comments;final comment=TextEditingController();int page=0;int? replyTo;
 String get id=>'${widget.preview['id']??''}';
 Future<Map<String,dynamic>> loadArticle()async{
  try{return await widget.api.callWithQuery('v211_news_detail',{'id':id});}
  catch(_){
    final cover='${widget.preview['image']??''}';
    return {'ok':true,'offline':true,'item':{
      'id':id,'title':widget.preview['title']??'Berita Kelurahan Cikoko',
      'body':widget.preview['body']??'',
      'images':widget.preview['images']??(cover.isEmpty?<String>[]:<String>[cover]),
    }};
  }
 }
 @override void initState(){super.initState();article=loadArticle();reload();}
 @override void dispose(){comment.dispose();super.dispose();}
 void reload(){comments=widget.api.callWithQuery('v211_comments',{'id':id});}
 Future<void> send()async{if(widget.api.token==null){civicMessage(context,'Silakan masuk ke akun Anda untuk memberikan komentar.');return;}if(comment.text.trim().isEmpty)return;try{await widget.api.call('v211_comment_add',body:{'news_id':id,'body':comment.text.trim(),'parent_id':replyTo??0});if(mounted){comment.clear();setState((){replyTo=null;reload();});civicMessage(context,'Komentar telah dikirim.');}}catch(e){if(mounted)civicMessage(context,'Komentar belum dapat diterima. Mohon gunakan bahasa yang santun.');}}
 Future<void> share(String service)async{
  final urlBerita='https://datawebs.my.id/berita-galeri.php?id=$id';
  Map<String,dynamic> item;
  try{
    final res=await article;
    item=Map<String,dynamic>.from(res['item']??widget.preview);
  }catch(_){
    item=Map<String,dynamic>.from(widget.preview);
  }
  final judul='${item['title']??widget.preview['title']??'Berita Kelurahan Cikoko'}'.trim();
  var ringkasan='${item['body']??widget.preview['body']??''}'.replaceAll(RegExp(r'<[^>]*>'),' ').replaceAll('&nbsp;',' ').replaceAll('&amp;','&').replaceAll('&quot;','"').replaceAll('&#039;',"'").replaceAll(RegExp(r'\s+'),' ').trim();
  if(ringkasan.length>200){ringkasan='${ringkasan.substring(0,200).trim()}…';}
  final buf=StringBuffer();
  buf.writeln('*$judul*');
  if(ringkasan.isNotEmpty){buf.writeln();buf.writeln(ringkasan);}
  buf.writeln();
  buf.writeln('Baca selengkapnya: $urlBerita');
  if(cikokoPlayStoreUrl.isNotEmpty){buf.writeln();buf.writeln('Unduh aplikasi Cikoko di Play Store: $cikokoPlayStoreUrl');}
  final teksKaya=buf.toString().trim();
  if(service=='copy'||service=='instagram'){
    await Clipboard.setData(ClipboardData(text:teksKaya));
    if(mounted)civicMessage(context,'Tautan dan cuplikan berita disalin.');
    return;
  }
  if(service=='wa'){
    await launchUrl(Uri.parse('https://wa.me/?text=${Uri.encodeComponent(teksKaya)}'),mode:LaunchMode.externalApplication);
  }else{
    final quote=Uri.encodeComponent(judul);
    await launchUrl(Uri.parse('https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(urlBerita)}&quote=$quote'),mode:LaunchMode.externalApplication);
  }
 }
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Berita Kelurahan Cikoko')),body:FutureBuilder<Map<String,dynamic>>(future:article,builder:(ctx,s){if(s.hasError)return Center(child:TextButton.icon(onPressed:()=>setState(()=>article=loadArticle()),icon:const Icon(Icons.refresh),label:const Text('Muat ulang berita')));if(!s.hasData)return const Center(child:CircularProgressIndicator());final x=Map<String,dynamic>.from(s.data?['item']??widget.preview);final photos=List<dynamic>.from(x['images']??[]).map((v)=>widget.api.media('$v')).where((v)=>v.isNotEmpty).take(5).toList();return ListView(padding:const EdgeInsets.all(14),children:[
  const CivicV4Header(title:'Detail Berita',subtitle:'Berita dan informasi Kelurahan Cikoko',icon:Icons.newspaper_outlined),
  const SizedBox(height:12),
  if(photos.isNotEmpty)...[
    SizedBox(
      height:215,
      child:PageView.builder(
        itemCount:photos.length,
        onPageChanged:(v)=>setState(()=>page=v),
        itemBuilder:(_,i)=>ClipRRect(
          borderRadius:BorderRadius.circular(12),
          child:Image.network(photos[i],fit:BoxFit.cover,
            errorBuilder:(_,__,___)=>const Icon(Icons.broken_image_outlined)),
        ),
      ),
    ),
    const SizedBox(height:6),
    Text('${page+1} / ${photos.length}',textAlign:TextAlign.center,style:const TextStyle(fontSize:11,color:Colors.blueGrey)),
  ],
  const SizedBox(height:14),Text('${x['title']??''}',style:const TextStyle(fontSize:19,fontWeight:FontWeight.w800,color:civicNavy)),const SizedBox(height:10),Text('${x['body']??''}'),const SizedBox(height:12),
  Row(mainAxisAlignment:MainAxisAlignment.spaceEvenly,children:[
   _shareIcon(Icons.chat_outlined,'WhatsApp',Colors.green,()=>share('wa')),
   _shareIcon(Icons.facebook,'Facebook',Colors.blue,()=>share('fb')),
   _shareIcon(Icons.camera_alt_outlined,'Instagram',Colors.deepPurple,()=>share('instagram')),
   _shareIcon(Icons.link,'Salin tautan',Colors.blueGrey,()=>share('copy')),
  ]),const Divider(height:26),const Text('Komentar dan Tanggapan',style:TextStyle(fontWeight:FontWeight.w800,fontSize:15,color:civicNavy)),const SizedBox(height:8),
  if(replyTo!=null)Row(children:[Expanded(child:Text('Membalas komentar #$replyTo',style:const TextStyle(fontSize:11))),TextButton(onPressed:()=>setState(()=>replyTo=null),child:const Text('Batal'))]),
  Row(children:[Expanded(child:TextField(controller:comment,maxLines:3,minLines:1,decoration:const InputDecoration(hintText:'Tulis komentar yang santun…'))),IconButton(onPressed:send,tooltip:'Kirim komentar',icon:const Icon(Icons.send_rounded,color:civicBlue))]),const SizedBox(height:8),
  FutureBuilder<Map<String,dynamic>>(future:comments,builder:(ctx,s){if(!s.hasData)return const Padding(padding:EdgeInsets.all(12),child:Text('Memuat komentar…'));final rows=List<dynamic>.from(s.data?['items']??[]);return Column(children:[for(final r in rows)Card(child:ListTile(dense:true,leading:const CircleAvatar(radius:17,child:Icon(Icons.person_outline,size:18)),title:Text('${r['display_name']??'Pengguna'}',style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700)),subtitle:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${r['body']??''}'),const SizedBox(height:5),TextButton(onPressed:()=>setState(()=>replyTo=int.tryParse('${r['id']}')),child:const Text('Balas',style:TextStyle(fontSize:11)))]),trailing:widget.api.profile?['role']=='admin'||widget.api.profile?['role']=='admin_kelurahan'?IconButton(tooltip:'Sembunyikan komentar',icon:const Icon(Icons.visibility_off_outlined,size:18),onPressed:()async{await widget.api.call('v211_comment_moderate',body:{'id':r['id']});if(mounted)setState(reload);}):null)),if(rows.isEmpty)const Text('Belum ada komentar.',style:TextStyle(color:Colors.blueGrey,fontSize:12))]);}),
 ]);}),);
 Widget _shareIcon(IconData icon,String tooltip,Color color,VoidCallback action)=>IconButton.filledTonal(tooltip:tooltip,onPressed:action,style:IconButton.styleFrom(foregroundColor:color),icon:Icon(icon));
}

class ArchiveEditorPage extends StatefulWidget{final CikokoApi api;final int? editId;const ArchiveEditorPage({super.key,required this.api,this.editId});@override State<ArchiveEditorPage> createState()=>_ArchiveEditorState();}
class _ArchiveEditorState extends State<ArchiveEditorPage>{
 final data={for(final key in ['archive_year','reference_no','name','nik','phone','address','relation','deceased_name','birthplace','birthdate','marriage_date','deathdate','marital_status','heirs','notes'])key:TextEditingController()};
 final children=<TextEditingController>[];final photos=<String,String>{};bool saving=false,loaded=false;
 @override void initState(){super.initState();data['archive_year']!.text='${DateTime.now().year}';if(widget.editId!=null)load();}
 @override void dispose(){for(final c in data.values){c.dispose();}for(final c in children){c.dispose();}super.dispose();}
 Future<void> load()async{try{final r=await widget.api.callWithQuery('v211_archive_detail',{'id':'${widget.editId}'});final row=Map<String,dynamic>.from(r['item'] as Map);final details=Map<String,dynamic>.from(row['details']??{});for(final e in data.entries){e.value.text='${row[e.key]??details[e.key]??''}';}data['name']!.text='${row['applicant_name']??''}';final raw=List<dynamic>.from(details['children']??[]);for(final item in raw){children.add(TextEditingController(text:'${item['name']??''}'));}if(mounted)setState(()=>loaded=true);}catch(_){if(mounted)civicMessage(context,'Arsip belum dapat dimuat untuk disunting.');}}
 Future<void> photoPick(String key,ImageSource source)async{final f=await ImagePicker().pickImage(source:source,maxWidth:2300,imageQuality:85);if(f!=null&&mounted)setState(()=>photos[key]=f.path);}
 Widget photoEntry(String key,String label)=>Card(child:Padding(padding:const EdgeInsets.all(9),child:Row(children:[if(photos.containsKey(key))Image.file(File(photos[key]!),height:48,width:48,fit:BoxFit.cover)else const Icon(Icons.image_outlined,color:civicBlue),const SizedBox(width:9),Expanded(child:Text(label,style:const TextStyle(fontSize:11.5))),IconButton(onPressed:()=>photoPick(key,ImageSource.camera),tooltip:'Kamera',icon:const Icon(Icons.camera_alt_outlined)),IconButton(onPressed:()=>photoPick(key,ImageSource.gallery),tooltip:'Galeri',icon:const Icon(Icons.photo_library_outlined))])));
 Future<void> save()async{if(saving)return;setState(()=>saving=true);try{final fields={for(final e in data.entries)e.key:e.value.text.trim(),'id':'${widget.editId??0}','children_json':'[${children.map((c)=>'{"name":${_quote(c.text.trim())}}').join(',')}]'};
 final files={for(final e in photos.entries)e.key:[e.value]};await widget.api.upload('v211_archive_save',fields,files);if(mounted){civicMessage(context,'Arsip Ahli Waris berhasil disimpan.');if(widget.editId!=null)Navigator.of(context).pop(true);else{for(final c in data.values){c.clear();}data['archive_year']!.text='${DateTime.now().year}';for(final c in children){c.dispose();}children.clear();setState(()=>photos.clear());}}}catch(_){if(mounted)civicMessage(context,'Arsip belum berhasil disimpan. Mohon periksa kembali data dan lampiran.');}finally{if(mounted)setState(()=>saving=false);}}
 String _quote(String v)=>'"${v.replaceAll('\\','\\\\').replaceAll('"','\\"').replaceAll('\n',' ')}"';
 Widget field(String key,String label,{int lines=1})=>Padding(padding:const EdgeInsets.only(bottom:10),child:TextField(controller:data[key],maxLines:lines,decoration:InputDecoration(labelText:label)));
 @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(14),children:[Text(widget.editId==null?'Tambah Arsip Ahli Waris':'Edit Arsip Ahli Waris',style:const TextStyle(color:civicNavy,fontSize:19,fontWeight:FontWeight.w800)),if(widget.editId!=null&&!loaded)const LinearProgressIndicator(),const SizedBox(height:10),
  const Text('Data Surat dan Pemohon',style:TextStyle(color:civicBlue,fontWeight:FontWeight.w800)),
  field('archive_year','Tahun Surat'),field('reference_no','Nomor Surat'),field('name','Nama Pemohon'),field('nik','NIK Pemohon'),field('phone','Nomor HP'),field('address','Alamat Pemohon',lines:2),field('relation','Hubungan dengan Pewaris'),
  const Text('Data Pewaris',style:TextStyle(color:civicBlue,fontWeight:FontWeight.w800)),field('deceased_name','Nama Almarhum/Almarhumah'),field('birthplace','Tempat Lahir'),field('birthdate','Tanggal Lahir (YYYY-MM-DD)'),field('marriage_date','Tanggal Menikah (YYYY-MM-DD)'),field('marital_status','Status Perkawinan'),field('deathdate','Tanggal Meninggal (YYYY-MM-DD)'),field('heirs','Daftar Ahli Waris',lines:3),field('notes','Catatan Arsip',lines:3),
  const SizedBox(height:8),const Text('Dokumen Persyaratan',style:TextStyle(color:civicBlue,fontWeight:FontWeight.w800)),
  for(final item in const <String,String>{'r1':'Surat Pengantar RT/RW','r2':'Surat Permohonan','r3':'Pernyataan Keabsahan','r4':'KTP/KK/Akta Lahir Ahli Waris','r5':'Surat Kematian','r6':'Surat Nikah','r7':'Akta Cerai (jika ada)','r8':'Surat Kematian Ahli Waris (jika ada)'}.entries)photoEntry(item.key,item.value),
  Row(children:[const Expanded(child:Text('Daftar Anak (maksimal 10)',style:TextStyle(color:civicBlue,fontWeight:FontWeight.w800))),TextButton(onPressed:children.length>=10?null:()=>setState(()=>children.add(TextEditingController())),child:const Text('+ Tambah Anak'))]),
  for(var i=0;i<children.length;i++)Card(child:Padding(padding:const EdgeInsets.all(10),child:Column(children:[TextField(controller:children[i],decoration:InputDecoration(labelText:'Nama anak ke-${i+1}')),photoEntry('child_${i+1}','KTP, KK dan Akta Lahir anak ke-${i+1}')]))),
  const SizedBox(height:15),FilledButton.icon(onPressed:saving?null:save,icon:const Icon(Icons.save_outlined),label:Text(saving?'Menyimpan…':'Simpan Data Arsip')),const SizedBox(height:25),
 ]);
}

class PpsuHighlights extends StatelessWidget {
 final CikokoApi api;
 const PpsuHighlights({super.key,required this.api});
 @override Widget build(BuildContext context)=>FutureBuilder<Map<String,dynamic>>(
  future:api.call('v211_ppsu_list'),builder:(ctx,s){
   if(!s.hasData)return const SizedBox.shrink();
   final rows=List<dynamic>.from(s.data?['items']??[]).take(3).toList();
   if(rows.isEmpty)return const SizedBox.shrink();
   return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Padding(padding:EdgeInsets.symmetric(vertical:10),child:Text('Kegiatan PPSU',style:TextStyle(fontSize:15,color:civicNavy,fontWeight:FontWeight.w800))),
    for(final r in rows)Card(child:ListTile(dense:true,leading:ClipRRect(borderRadius:BorderRadius.circular(7),child:Image.network(api.photoUrl('v211_ppsu_photo',{'id':'${r['id']}','index':'0'}),headers:api.authHeaders(),width:52,height:52,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Icon(Icons.cleaning_services_outlined,color:civicBlue))),title:Text('${r['team']} · ${r['work_date']}',style:const TextStyle(fontSize:12.5,fontWeight:FontWeight.w700)),subtitle:Text('${r['activity']}',maxLines:2,overflow:TextOverflow.ellipsis),trailing:const Icon(Icons.chevron_right,size:19),onTap:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>PpsuDetailPage(api:api,id:int.parse('${r['id']}')))))),
   ]);
  });
}
