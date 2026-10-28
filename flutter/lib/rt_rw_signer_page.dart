import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api.dart';

/// Only the logged-in account may submit its own authorised signature/stamp.
class RtRwSignerPage extends StatefulWidget {
  final CikokoApi api;
  const RtRwSignerPage({super.key,required this.api});
  @override State<RtRwSignerPage> createState()=>_RtRwSignerPageState();
}
class _RtRwSignerPageState extends State<RtRwSignerPage> {
  final password=TextEditingController();
  XFile? signature,stamp;
  bool saving=false;
  late Future<Map<String,dynamic>> status;
  @override void initState(){super.initState();reload();}
  void reload(){status=widget.api.call('rt_rw_signer_status');}
  @override void dispose(){password.dispose();super.dispose();}
  Future<void> pick(bool isSignature)async{
    final file=await ImagePicker().pickImage(source:ImageSource.gallery,maxWidth:1800,imageQuality:90);
    if(file!=null&&mounted)setState((){
      if(isSignature){signature=file;}else{stamp=file;}
    });
  }
  Future<void> save()async{
    if(saving)return;
    if(signature==null||stamp==null||password.text.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:Text('Lengkapi kedua gambar dan password akun.')));
      return;
    }
    setState(()=>saving=true);
    try{
      await widget.api.upload('rt_rw_signer_upload',
        {'password':password.text},
        {'signature':[signature!.path],'stamp':[stamp!.path]});
      password.clear();
      if(mounted){setState(reload);ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text('TTD dan stempel tersimpan.')));}
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e')));
    }finally{if(mounted)setState(()=>saving=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('TTD & Stempel Petugas')),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      Text('Tanda Tangan & Stempel',
        style:Theme.of(context).textTheme.titleLarge),
      const SizedBox(height:8),
      const Text('Hanya unggah gambar tanda tangan dan cap yang secara resmi Anda berwenang gunakan. '
        'Gambar ini akan direkam saat Anda menyetujui surat, bukan digunakan otomatis tanpa persetujuan.'),
      const SizedBox(height:14),
      FutureBuilder<Map<String,dynamic>>(future:status,builder:(context,s){
        if(s.hasError)return Text('Status belum dapat dimuat: ${s.error}');
        if(!s.hasData)return const LinearProgressIndicator();
        return Text(s.data?['ready']==true?'TTD dan stempel sudah tersedia':'TTD/stempel belum didaftarkan',
          style:const TextStyle(fontWeight:FontWeight.bold));
      }),
      const SizedBox(height:12),
      OutlinedButton.icon(onPressed:saving?null:()=>pick(true),
        icon:const Icon(Icons.draw_outlined),
        label:Text(signature==null?'Pilih Gambar TTD':'TTD dipilih: ${signature!.name}')),
      const SizedBox(height:10),
      OutlinedButton.icon(onPressed:saving?null:()=>pick(false),
        icon:const Icon(Icons.verified_outlined),
        label:Text(stamp==null?'Pilih Gambar Stempel':'Stempel dipilih: ${stamp!.name}')),
      const SizedBox(height:12),
      TextField(controller:password,obscureText:true,
        decoration:const InputDecoration(labelText:'Konfirmasi Password Akun',border:OutlineInputBorder())),
      const SizedBox(height:14),
      FilledButton.icon(onPressed:saving?null:save,
        icon:const Icon(Icons.save_outlined),label:Text(saving?'Menyimpan...':'Simpan TTD & Stempel')),
      const SizedBox(height:12),
      const Text('Berkas privat dan diverifikasi saat persetujuan. '
        'TTD/cap gambar tidak sama dengan tanda tangan elektronik tersertifikasi.',
        style:TextStyle(fontSize:12,color:Colors.blueGrey)),
    ]),
  );
}
