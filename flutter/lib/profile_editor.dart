import 'package:flutter/material.dart';
import 'api.dart';
class CikokoProfileEditor extends StatefulWidget {
 final CikokoApi api;
 const CikokoProfileEditor({super.key,required this.api});
 @override State<CikokoProfileEditor> createState()=>_State();
}
class _State extends State<CikokoProfileEditor> {
 final name=TextEditingController(),phone=TextEditingController(),email=TextEditingController(),address=TextEditingController();
 bool busy=false;String feedback='';
 @override void initState(){super.initState();final p=widget.api.profile??{};name.text='${p['name']??''}';phone.text='${p['phone']??''}';email.text='${p['email']??''}';address.text='${p['address']??''}';}
 @override void dispose(){name.dispose();phone.dispose();email.dispose();address.dispose();super.dispose();}
 Future<void> save()async{
  setState((){busy=true;feedback='';});
  try{final v=await widget.api.call('profile_update',body:{'name':name.text.trim(),'phone':phone.text.trim(),'email':email.text.trim(),'address':address.text.trim()});widget.api.profile=Map<String,dynamic>.from(v['user'] as Map);if(mounted)setState(()=>feedback='Profil berhasil diperbarui.');}
  catch(_){if(mounted)setState(()=>feedback='Perubahan belum dapat disimpan. Periksa kembali data Anda.');}
  finally{if(mounted)setState(()=>busy=false);}
 }
 Widget field(String title,TextEditingController ctl,{int lines=1,TextInputType? keyboard})=>Padding(padding:const EdgeInsets.only(bottom:12),child:TextField(controller:ctl,maxLines:lines,keyboardType:keyboard,decoration:InputDecoration(labelText:title,border:const OutlineInputBorder())));
 @override Widget build(BuildContext context){
 final p=widget.api.profile??{};
 final initial=(name.text.trim().isEmpty?'C':name.text.trim().substring(0,1)).toUpperCase();
 return ListView(padding:const EdgeInsets.all(14),children:[
  Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(children:[CircleAvatar(radius:35,backgroundColor:const Color(0xffe9f2fc),child:Text(initial,style:const TextStyle(fontSize:25,fontWeight:FontWeight.bold,color:Color(0xff12375d)))),const SizedBox(height:8),Text('${p['name']??''}',style:Theme.of(context).textTheme.titleMedium),Text('@${p['username']??''}',style:Theme.of(context).textTheme.bodySmall)]))),
  const SizedBox(height:10),
  Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
   Text('Informasi Profil',style:Theme.of(context).textTheme.titleMedium),const SizedBox(height:14),
   field('Nama Lengkap',name),field('Nomor HP',phone,keyboard:TextInputType.phone),field('Email',email,keyboard:TextInputType.emailAddress),field('Alamat Lengkap',address,lines:3),
   if((p['nik']??'').toString().isNotEmpty)Padding(padding:const EdgeInsets.only(bottom:12),child:Text('NIK: ${p['nik']}')),
   if(feedback.isNotEmpty)Padding(padding:const EdgeInsets.only(bottom:10),child:Text(feedback)),
   FilledButton.icon(onPressed:busy?null:save,icon:const Icon(Icons.save_outlined),label:Text(busy?'Menyimpan...':'Simpan Perubahan')),
  ]))),
 ]);
 }
}
