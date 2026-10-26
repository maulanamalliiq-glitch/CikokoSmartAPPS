import 'package:flutter/material.dart';
import 'api.dart';

/// All accounts can edit their ordinary contact profile.
/// Residents can propose RT/RW, but only Admin verification makes it authoritative.
class CikokoProfileEditor extends StatefulWidget {
 final CikokoApi api;
 const CikokoProfileEditor({super.key,required this.api});
 @override State<CikokoProfileEditor> createState()=>_State();
}
class _State extends State<CikokoProfileEditor> {
 final name=TextEditingController(),phone=TextEditingController(),email=TextEditingController(),
  address=TextEditingController(),rt=TextEditingController(),rw=TextEditingController(),areaAddress=TextEditingController(),areaPassword=TextEditingController();
 bool busy=false,areaBusy=false;
 String feedback='',areaFeedback='';
 Map<String,dynamic>? areaProfile;
 bool loadingArea=true;
 String? areaError;
 String get role=>(widget.api.profile?['role']??'warga').toString();
 @override void initState(){
  super.initState();
  final p=widget.api.profile??{};
  name.text=(p['name']??'').toString();phone.text=(p['phone']??'').toString();
  email.text=(p['email']??'').toString();address.text=(p['address']??'').toString();
  loadArea();
 }
 @override void dispose(){
  name.dispose();phone.dispose();email.dispose();address.dispose();
  rt.dispose();rw.dispose();areaAddress.dispose();areaPassword.dispose();super.dispose();
 }
 Future<void> loadArea()async{
  if(mounted)setState((){loadingArea=true;areaError=null;});
  try{
   final x=await widget.api.call('civic_profile_get');
   if(!mounted)return;
   final req=x['area_request'] is Map?Map<String,dynamic>.from(x['area_request'] as Map):null;
   final verified=x['verified_area'] is Map?Map<String,dynamic>.from(x['verified_area'] as Map):null;
   final p=req??verified;
   rt.text=(p?['rt']??'').toString();rw.text=(p?['rw']??'').toString();
   areaAddress.text=(x['registered_address']??address.text).toString();
   setState((){areaProfile=Map<String,dynamic>.from(x);loadingArea=false;});
  }catch(e){if(mounted)setState((){loadingArea=false;areaError=e.toString();});}
 }
 Future<void> save()async{
  if(busy)return;
  setState((){busy=true;feedback='';});
  try{
   final v=await widget.api.call('profile_update',body:{
    'name':name.text.trim(),'phone':phone.text.trim(),'email':email.text.trim(),'address':address.text.trim()});
   widget.api.profile=Map<String,dynamic>.from(v['user'] as Map);
   if(mounted)setState(()=>feedback='Data diri berhasil disimpan.');
  }catch(e){if(mounted)setState(()=>feedback='Perubahan tidak berhasil: '+e.toString());}
  finally{if(mounted)setState(()=>busy=false);}
 }
 Future<void> requestArea()async{
  if(areaBusy)return;
  final r=rt.text.trim(),w=rw.text.trim(),a=areaAddress.text.trim();
  if(!RegExp(r'^\d{1,3}$').hasMatch(r)||!RegExp(r'^\d{1,3}$').hasMatch(w)||a.length<10){
   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Isi RT dan RW 1–3 angka serta alamat lengkap.')));
   return;
  }
  final confirmed=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
   title:const Text('Simpan RT/RW Domisili?'),
   content:Text('RT '+r+' / RW '+w+' akan dipakai otomatis untuk semua surat baru. Dokumen lama tetap di wilayah sebelumnya.'),
   actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Batal')),
    FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Simpan Wilayah'))]));
  if(confirmed!=true||!mounted)return;
  setState((){areaBusy=true;areaFeedback='';});
  try{
   await widget.api.call('civic_profile_request',body:{'rt':r,'rw':w,'address':a,'password':areaPassword.text});
   if(mounted){setState(()=>areaFeedback='RT/RW berhasil disimpan dan langsung aktif.');areaPassword.clear();await loadArea();}
  }catch(e){if(mounted)setState(()=>areaFeedback='Gagal mengirim: '+e.toString());}
  finally{if(mounted)setState(()=>areaBusy=false);}
 }
 Widget field(String title,TextEditingController ctl,{int lines=1,TextInputType? keyboard})=>
  Padding(padding:const EdgeInsets.only(bottom:12),child:TextField(controller:ctl,maxLines:lines,keyboardType:keyboard,
   decoration:InputDecoration(labelText:title,border:const OutlineInputBorder())));
 Widget areaSection(){
  if(loadingArea)return const Card(child:Padding(padding:EdgeInsets.all(22),child:Center(child:CircularProgressIndicator())));
  if(areaError!=null)return Card(child:ListTile(title:const Text('Wilayah belum dapat dimuat'),subtitle:Text(areaError!),
   trailing:IconButton(icon:const Icon(Icons.refresh),onPressed:loadArea)));
  final p=areaProfile??{},verified=p['verified_area'] is Map?Map<String,dynamic>.from(p['verified_area'] as Map):null;
  final request=p['area_request'] is Map?Map<String,dynamic>.from(p['area_request'] as Map):null;
  final duty=p['duty'] is Map?Map<String,dynamic>.from(p['duty'] as Map):null;
  final pending=false,rejected=false;
  return Card(child:Padding(padding:const EdgeInsets.all(16),
   child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    const Text('Detail Wilayah RT/RW',style:TextStyle(fontSize:17,fontWeight:FontWeight.w800)),
    const SizedBox(height:8),
    if(role=='warga')...[
     Text(pending?'Status: TERDAFTAR':verified!=null?'Status: TERDAFTAR':'Status: BELUM DIISI',
      style:TextStyle(fontWeight:FontWeight.w700,color:pending?Colors.deepOrange:verified!=null?Colors.green:Colors.red)),
     if(verified!=null)Padding(padding:const EdgeInsets.only(top:6,bottom:9),
      child:Text('RT '+(verified['rt']??'').toString()+' / RW '+(verified['rw']??'').toString()+' • diisi saat pendaftaran',
       style:const TextStyle(fontWeight:FontWeight.w700))),
     if(rejected)Text('Alasan revisi: '+(request?['reason']??'Periksa data wilayah').toString(),
       style:const TextStyle(color:Colors.red)),
     const SizedBox(height:10),
     field('Nomor RT',rt,keyboard:TextInputType.number),
     field('Nomor RW',rw,keyboard:TextInputType.number),
     field('Alamat Domisili Lengkap',areaAddress,lines:3),
     const Text('RT/RW langsung digunakan untuk mengirim surat ke akun Ketua RT yang sesuai, kemudian diteruskan ke RW. Nomor RT/RW tidak membuat akun petugas.',
      style:TextStyle(color:Colors.blueGrey,fontSize:12)),
     const SizedBox(height:12),
     if(verified!=null)...[
      TextField(controller:areaPassword,obscureText:true,decoration:const InputDecoration(labelText:'Password akun jika mengubah RT/RW',border:OutlineInputBorder())),
      const SizedBox(height:12),
     ],
     FilledButton.icon(onPressed:areaBusy?null:requestArea,icon:const Icon(Icons.save_outlined),
      label:Text(areaBusy?'Mengirim...':'Simpan RT/RW')),
    ]else if(duty!=null)...[
     const Text('Wilayah penugasan resmi (hanya dapat diubah Admin):',style:TextStyle(color:Colors.blueGrey,fontSize:12)),
     Text('Jabatan: '+(duty['duty']??'').toString().toUpperCase(),style:const TextStyle(fontWeight:FontWeight.w700)),
     Text('RT '+(duty['rt']??'-').toString()+' / RW '+(duty['rw']??'-').toString(),
       style:const TextStyle(fontWeight:FontWeight.w700)),
     const SizedBox(height:10),
     const Text('Tanda tangan dan stempel dapat dikelola di menu Administrasi RT/RW & LMK. Hubungi admin jika wilayah tugas salah.',
      style:TextStyle(color:Colors.blueGrey,fontSize:12)),
    ]else...[
     const Text('Wilayah/jabatan petugas belum ditetapkan Admin Kelurahan. Data pribadi tetap bisa diperbarui di atas.',
       style:TextStyle(color:Colors.blueGrey,fontSize:12)),
    ],
    if(areaFeedback.isNotEmpty)Padding(padding:const EdgeInsets.only(top:10),child:Text(areaFeedback)),
   ])));
 }
 @override Widget build(BuildContext context){
  final p=widget.api.profile??{};
  final initial=(name.text.trim().isEmpty?'C':name.text.trim().substring(0,1)).toUpperCase();
  return RefreshIndicator(onRefresh:loadArea,child:ListView(padding:const EdgeInsets.all(14),children:[
   Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(children:[
    CircleAvatar(radius:35,backgroundColor:const Color(0xffe9f2fc),
     child:Text(initial,style:const TextStyle(fontSize:25,fontWeight:FontWeight.bold,color:Color(0xff12375d)))),
    const SizedBox(height:8),Text((p['name']??'').toString(),style:Theme.of(context).textTheme.titleMedium),
    Text('@'+(p['username']??'').toString(),style:Theme.of(context).textTheme.bodySmall),
   ]))),
   const SizedBox(height:10),
   Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Text('Informasi Profil',style:Theme.of(context).textTheme.titleMedium),const SizedBox(height:14),
    field('Nama Lengkap',name),field('Nomor HP',phone,keyboard:TextInputType.phone),
    field('Email',email,keyboard:TextInputType.emailAddress),field('Alamat Lengkap',address,lines:3),
    if(feedback.isNotEmpty)Padding(padding:const EdgeInsets.only(bottom:10),child:Text(feedback)),
    FilledButton.icon(onPressed:busy?null:save,icon:const Icon(Icons.save_outlined),
     label:Text(busy?'Menyimpan...':'Simpan Data Diri')),
   ]))),
   const SizedBox(height:10),
   areaSection(),
   const SizedBox(height:24),
  ]));
 }
}
