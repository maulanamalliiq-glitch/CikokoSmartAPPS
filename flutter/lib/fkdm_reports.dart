import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api.dart';

class FkdmReportPage extends StatefulWidget {
 final CikokoApi api;
 const FkdmReportPage({super.key, required this.api});
 @override State<FkdmReportPage> createState()=>_FkdmReportState();
}
class _FkdmReportState extends State<FkdmReportPage>{
 final name=TextEditingController(),number=TextEditingController(),location=TextEditingController(),activity=TextEditingController();
 final photos=<String?>[null,null,null];bool sending=false;
 late Future<Map<String,dynamic>> history;
 @override void initState(){super.initState();name.text=(widget.api.profile?['name']??'').toString();load();}
 @override void dispose(){name.dispose();number.dispose();location.dispose();activity.dispose();super.dispose();}
 void load(){history=widget.api.call('v211_fkdm_list');}
 Future<void> choose(int i,ImageSource source)async{
  try{final x=await ImagePicker().pickImage(source:source,maxWidth:1900,imageQuality:78);
    if(x!=null&&mounted)setState(()=>photos[i]=x.path);
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
 }
 Future<void> send()async{
  if(sending)return;
  if(name.text.trim().length<3||number.text.trim().length<2||location.text.trim().length<3||activity.text.trim().length<5||photos.any((p)=>p==null)){
   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Lengkapi nama, nomor anggota, lokasi, kegiatan dan tiga foto.')));return;
  }
  setState(()=>sending=true);
  try{
   await widget.api.upload('v211_fkdm_submit',{'full_name':name.text.trim(),'member_number':number.text.trim(),
    'location':location.text.trim(),'activity':activity.text.trim()},
    {'photo1':[photos[0]!],'photo2':[photos[1]!],'photo3':[photos[2]!]});
   if(mounted){setState((){activity.clear();for(var i=0;i<3;i++)photos[i]=null;load();});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Laporan FKDM sudah tampil di publik.')));}
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Gagal mengirim: '+e.toString())));}
  finally{if(mounted)setState(()=>sending=false);}
 }
 Widget field(String text,TextEditingController c,{int lines=1})=>Padding(padding:const EdgeInsets.only(bottom:10),
  child:TextField(controller:c,minLines:lines,maxLines:lines==1?1:5,decoration:InputDecoration(labelText:text,border:const OutlineInputBorder())));
 @override Widget build(BuildContext context)=>RefreshIndicator(onRefresh:()async{setState(load);await history;},
  child:ListView(padding:const EdgeInsets.all(14),children:[
   const Text('Laporan FKDM',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800)),
   const Text('Hasil langsung tampil di website dan aplikasi. Nomor anggota tetap hanya untuk petugas dan admin.',style:TextStyle(color:Colors.blueGrey,fontSize:12)),
   const SizedBox(height:12),
   Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(children:[
    field('Nama Lengkap',name),field('Nomor Anggota',number),field('Lokasi',location),
    field('Keterangan Kegiatan',activity,lines:4),
    const Text('Foto / Galeri (3 Foto)',style:TextStyle(fontWeight:FontWeight.w700)),
    for(var i=0;i<3;i++)Row(children:[
     if(photos[i]!=null)Image.file(File(photos[i]!),width:55,height:55,fit:BoxFit.cover)
     else const SizedBox(width:55,height:55,child:Icon(Icons.add_a_photo_outlined)),
     const SizedBox(width:8),Expanded(child:Text('Foto '+(i+1).toString())),
     IconButton(tooltip:'Kamera',onPressed:()=>choose(i,ImageSource.camera),icon:const Icon(Icons.camera_alt_outlined)),
     IconButton(tooltip:'Galeri',onPressed:()=>choose(i,ImageSource.gallery),icon:const Icon(Icons.photo_library_outlined)),
    ]),
    const SizedBox(height:12),
    SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:sending?null:send,
      icon:const Icon(Icons.send_outlined),label:Text(sending?'Mengirim...':'Kirim & Publikasikan'))),
   ]))),
   const SizedBox(height:13),
   const Text('Riwayat Laporan Saya',style:TextStyle(fontSize:16,fontWeight:FontWeight.w800)),
   FutureBuilder<Map<String,dynamic>>(future:history,builder:(ctx,s){
    if(s.hasError)return TextButton.icon(onPressed:()=>setState(load),icon:const Icon(Icons.refresh),label:const Text('Muat ulang'));
    if(!s.hasData)return const Center(child:CircularProgressIndicator());
    final rows=List<dynamic>.from(s.data?['items']??[]);
    return Column(children:[
     for(final r in rows)Card(child:ListTile(
      title:Text((r['location']??'').toString(),style:const TextStyle(fontWeight:FontWeight.w700)),
      subtitle:Text((r['created_at']??'').toString()+' · '+(r['activity']??'').toString(),maxLines:2,overflow:TextOverflow.ellipsis),
      trailing:const Icon(Icons.chevron_right),
      onTap:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>FkdmDetail(api:widget.api,id:int.parse(r['id'].toString())))),
     )),
     if(rows.isEmpty)const ListTile(title:Text('Belum ada laporan FKDM.')),
    ]);
   }),
  ]));
}
class FkdmDetail extends StatelessWidget{
 final CikokoApi api;final int id;
 const FkdmDetail({super.key,required this.api,required this.id});
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Detail FKDM')),
  body:FutureBuilder<Map<String,dynamic>>(future:api.callWithQuery('v211_fkdm_detail',{'id':id.toString()}),builder:(ctx,s){
   if(s.hasError)return Center(child:Text(s.error.toString()));
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   final r=Map<String,dynamic>.from(s.data?['item']??{});
   final imgs=List<dynamic>.from(r['images']??[]);
   return ListView(padding:const EdgeInsets.all(16),children:[
    Text((r['full_name']??'').toString(),style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800)),
    Text('No Anggota: '+(r['member_number']??'').toString()),
    Text('Lokasi: '+(r['location']??'').toString()),const SizedBox(height:9),
    Text((r['activity']??'').toString()),const SizedBox(height:12),
    for(final path in imgs)Padding(padding:const EdgeInsets.only(bottom:10),
     child:Image.network(api.media(path.toString()),height:195,fit:BoxFit.cover,
       errorBuilder:(_,__,___)=>const Icon(Icons.broken_image_outlined))),
   ]);
  }));
}
class FieldReportsAdminPage extends StatefulWidget{
 final CikokoApi api;const FieldReportsAdminPage({super.key,required this.api});
 @override State<FieldReportsAdminPage> createState()=>_FieldAdminState();
}
class _FieldAdminState extends State<FieldReportsAdminPage>{
 late Future<Map<String,dynamic>> future;
 @override void initState(){super.initState();reload();}
 void reload(){future=widget.api.call('v211_public_field_reports');}
 Future<void> remove(String kind,int id)async{
  final yes=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Hapus kegiatan?'),
   content:const Text('Laporan akan hilang dari daftar admin, akun petugas, dan halaman publik.'),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Batal')),
     FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Hapus'))]));
  if(yes!=true)return;
  try{await widget.api.call('v211_field_delete',body:{'kind':kind,'id':id});
   if(mounted)setState(reload);
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
 }
 @override Widget build(BuildContext context)=>FutureBuilder<Map<String,dynamic>>(future:future,builder:(c,s){
  if(s.hasError)return Center(child:TextButton.icon(onPressed:()=>setState(reload),icon:const Icon(Icons.refresh),label:const Text('Muat ulang')));
  if(!s.hasData)return const Center(child:CircularProgressIndicator());
  final rows=List<dynamic>.from(s.data?['items']??[]);
  return RefreshIndicator(onRefresh:()async{setState(reload);await future;},
   child:ListView(padding:const EdgeInsets.all(14),children:[
    const Text('Kelola Laporan PPSU & FKDM',style:TextStyle(fontWeight:FontWeight.w800,fontSize:18)),
    const Text('Otomatis publik. Admin dapat menghapus kegiatan yang tidak diperlukan.',style:TextStyle(color:Colors.blueGrey,fontSize:12)),
    for(final r in rows)Card(child:ListTile(
     title:Text((r['title']??'').toString()),
     subtitle:Text((r['name']??'').toString()+' · '+(r['body']??'').toString(),maxLines:3,overflow:TextOverflow.ellipsis),
     trailing:IconButton(tooltip:'Hapus kegiatan',icon:const Icon(Icons.delete_outline,color:Colors.red),
      onPressed:()=>remove((r['role']??'').toString().toLowerCase(),int.tryParse((r['source_id']??'').toString())??0)),
    )),
    if(rows.isEmpty)const ListTile(title:Text('Belum ada laporan PPSU atau FKDM.')),
   ]));
 });
}
