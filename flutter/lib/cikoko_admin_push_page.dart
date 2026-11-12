import 'dart:math';
import 'package:flutter/material.dart';
import 'api.dart';
import 'cikoko_v6_showcase.dart';

/// Native editor for admins. All requests are re-authorized on the backend.
class CikokoAdminPushPage extends StatefulWidget{
 final CikokoApi api;
 final Future<void> Function()? onSent;
 const CikokoAdminPushPage({super.key,required this.api,this.onSent});
 @override State<CikokoAdminPushPage> createState()=>_CikokoAdminPushPageState();
}
class _CikokoAdminPushPageState extends State<CikokoAdminPushPage>{
 final form=GlobalKey<FormState>();
 final title=TextEditingController(),message=TextEditingController();
 String category='info_aplikasi',scope='public',recipient='';
 bool loading=true,sending=false,confirmed=false;
 String? error,notice;
 Map<String,dynamic> stats={};
 List<Map<String,dynamic>> accounts=[];
 late String requestId;
 @override void initState(){super.initState();requestId=_id();load();}
 String _id(){final r=Random.secure();
  return List.generate(16,(_)=>r.nextInt(256).toRadixString(16).padLeft(2,'0')).join();}
 Future<void> load()async{
  if(mounted)setState(()=>loading=true);
  try{
   final results=await Future.wait([
     widget.api.call('admin_push_diagnostics'),widget.api.call('admin_push_accounts')]);
   if(!mounted)return;
   setState((){
    stats=Map<String,dynamic>.from(results[0]);
    accounts=List<dynamic>.from(results[1]['items']??[])
      .whereType<Map>().map((a)=>Map<String,dynamic>.from(a)).toList();
    error=null;loading=false;
   });
  }catch(e){if(mounted)setState((){
   error='Diagnostik belum tersedia. Pastikan patch Mobile API terbaru sudah dipasang. '
     +cikokoFormalMessage(e);
   loading=false;
  });}
 }
 Future<void> send()async{
  if(sending||!(form.currentState?.validate()??false))return;
  if(!confirmed){setState(()=>error='Konfirmasikan isi dan kelompok penerima.');return;}
  final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
   title:const Text('Konfirmasi Pengiriman'),
   content:Text('Kirim "'+title.text.trim()+'" ke '+
     ({'public':'semua akun aktif','warga':'warga','staff':'petugas dan admin',
       'personal':'akun pilihan'}[scope]??scope)+'?\n\n'
     'Pesan langsung tersedia di kotak masuk. Push HP bergantung pada Firebase dan Cron Jobs.'),
   actions:[
    TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Batal')),
    FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Kirim')),
   ]));
  if(ok!=true||!mounted)return;
  setState(()=>sending=true);
  try{
   final response=await widget.api.call('admin_push_send',body:{
    'title':title.text.trim(),'message':message.text.trim(),'category':category,
    'scope':scope,'recipient':scope=='personal'?recipient:'',
    'request_id':requestId,'confirmed':true,
   });
   if(!mounted)return;
   final count=(response['recipient_count']??0).toString();
   setState((){
    notice=(response['already_sent']==true
       ?'Permintaan ini sebelumnya sudah tersimpan untuk '
       :'Notifikasi tersimpan untuk ')+count+
       ' akun. Status push ke HP harus diperiksa pada diagnostik.';
    error=null;title.clear();message.clear();confirmed=false;requestId=_id();
   });
   if(widget.onSent!=null)await widget.onSent!();
   await load();
  }catch(e){
   if(mounted)setState(()=>error='Tidak berhasil: '+cikokoFormalMessage(e));
  }finally{if(mounted)setState(()=>sending=false);}
 }
 @override void dispose(){title.dispose();message.dispose();super.dispose();}
 @override Widget build(BuildContext context){
  final active=stats['cron_active']==true;
  final status=(stats['status']??'not_run').toString();
  return RefreshIndicator(onRefresh:load,child:ListView(
   key:const Key('cikoko_admin_push_page'),
   padding:const EdgeInsets.fromLTRB(14,12,14,30),children:[
    const V6PageHeader(title:'Push Notifikasi',
     description:'Kirim pemberitahuan dari aplikasi admin dan periksa status pengiriman ke HP.',
     icon:Icons.notifications_active_outlined),
    if(loading)const Center(child:Padding(padding:EdgeInsets.all(13),
      child:CircularProgressIndicator())),
    if(error!=null)Padding(padding:const EdgeInsets.only(bottom:10),
      child:V6Panel(child:Text(error!,
        style:const TextStyle(color:V6.red,fontSize:11.5)))),
    if(notice!=null)Padding(padding:const EdgeInsets.only(bottom:10),
      child:V6Panel(child:Text(notice!,
        style:const TextStyle(color:V6.green,fontSize:11.5)))),
    const V6Section(title:'Diagnostik Notifikasi'),
    V6Panel(child:Column(children:[
      Row(children:[
       Expanded(child:_metric((stats['devices']??0).toString(),'Token HP',Icons.smartphone,V6.blue)),
       Expanded(child:_metric((stats['pending_events']??0).toString(),
         'Antrean',Icons.schedule,V6.amber)),
       Expanded(child:_metric((stats['last_fcm_accepted']??0).toString(),
         'FCM diterima',Icons.check_circle_outline,V6.green)),
      ]),
      const Divider(height:18),
      Row(children:[
       Icon(active?Icons.check_circle:Icons.warning_amber,
         color:active?V6.green:V6.amber,size:20),
       const SizedBox(width:8),
       Expanded(child:Text(active?'Cron terdeteksi aktif':'Cron belum terdeteksi aktif',
        style:const TextStyle(color:V6.ink,fontSize:11.5,fontWeight:FontWeight.w800))),
       IconButton(onPressed:loading?null:load,
        icon:const Icon(Icons.refresh,color:V6.blue)),
      ]),
      Align(alignment:Alignment.centerLeft,child:Text(
       'Status: '+status+' · Terakhir: '+(stats['last_run_at']??'Belum ada').toString(),
       style:const TextStyle(color:V6.secondary,fontSize:10.5))),
      const SizedBox(height:5),
      Align(alignment:Alignment.centerLeft,child:Text(
       (stats['hint']??'Pastikan Cron Jobs dan kredensial Firebase aktif.').toString(),
       style:const TextStyle(fontSize:10.5,color:V6.secondary,height:1.4))),
    ])),
    const SizedBox(height:18),
    const V6Section(title:'Kirim Notifikasi dari Admin'),
    V6Panel(child:Form(key:form,child:Column(
     crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      DropdownButtonFormField<String>(
       value:category,
       decoration:const InputDecoration(labelText:'Jenis pemberitahuan'),
       items:const [
        DropdownMenuItem(value:'info_aplikasi',child:Text('Informasi Umum')),
        DropdownMenuItem(value:'berita',child:Text('Berita Terbaru')),
        DropdownMenuItem(value:'pengumuman',child:Text('Pengumuman')),
        DropdownMenuItem(value:'inovasi',child:Text('Inovasi Kelurahan')),
       ],onChanged:(v)=>setState(()=>category=v??category)),
      const SizedBox(height:12),
      DropdownButtonFormField<String>(
       value:scope,decoration:const InputDecoration(labelText:'Kelompok penerima'),
       items:const [
        DropdownMenuItem(value:'public',child:Text('Semua Akun Aktif')),
        DropdownMenuItem(value:'warga',child:Text('Warga')),
        DropdownMenuItem(value:'staff',child:Text('Petugas dan Admin')),
        DropdownMenuItem(value:'personal',child:Text('Satu Akun')),
       ],onChanged:(v)=>setState((){
        scope=v??scope;recipient='';confirmed=false;
       })),
      if(scope=='personal')...[
       const SizedBox(height:12),
       DropdownButtonFormField<String>(
        value:recipient.isEmpty?null:recipient,isExpanded:true,
        decoration:const InputDecoration(labelText:'Akun penerima'),
        items:[for(final a in accounts)DropdownMenuItem(
          value:(a['id']??'').toString(),
          child:Text((a['name']??'Akun').toString()+' · '+(a['role']??'').toString(),
            maxLines:1,overflow:TextOverflow.ellipsis))],
        validator:(v)=>v==null||v.isEmpty?'Pilih akun':null,
        onChanged:(v)=>setState(()=>recipient=v??'')),
      ],
      const SizedBox(height:13),
      TextFormField(controller:title,maxLength:180,
       decoration:const InputDecoration(labelText:'Judul notifikasi'),
       validator:(v)=>v==null||v.trim().length<5?'Minimal 5 karakter':null),
      const SizedBox(height:9),
      TextFormField(controller:message,maxLength:900,minLines:4,maxLines:7,
       decoration:const InputDecoration(labelText:'Isi notifikasi'),
       validator:(v)=>v==null||v.trim().length<10?'Minimal 10 karakter':null),
      CheckboxListTile(
       contentPadding:EdgeInsets.zero,
       controlAffinity:ListTileControlAffinity.leading,
       value:confirmed,onChanged:(v)=>setState(()=>confirmed=v??false),
       title:const Text('Saya sudah memeriksa isi dan penerima. Tidak ada data pribadi.',
         style:TextStyle(fontSize:11,color:V6.ink))),
      const SizedBox(height:7),
      FilledButton.icon(
       onPressed:loading||sending?null:send,
       icon:const Icon(Icons.send_outlined,size:18),
       label:Text(sending?'Menyimpan…':'Kirim Notifikasi')),
      const SizedBox(height:10),
      const Text('Berhasil menyimpan bukan berarti push telah diterima HP. '
       'Periksa token perangkat dan status Cron/FCM di atas.',
       style:TextStyle(color:V6.secondary,fontSize:10.5,height:1.4)),
     ],
    ))),
   ],
  ));
 }
 Widget _metric(String count,String label,IconData icon,Color color)=>Column(children:[
  Icon(icon,color:color,size:20),const SizedBox(height:5),
  Text(count,style:TextStyle(color:color,fontSize:21,fontWeight:FontWeight.w900)),
  Text(label,textAlign:TextAlign.center,
    style:const TextStyle(color:V6.secondary,fontSize:10.1)),
 ]);
}
