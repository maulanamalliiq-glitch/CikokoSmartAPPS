import 'package:flutter/material.dart';
import 'api.dart';

class MobileEditor extends StatefulWidget {
  final String mode;
  final CikokoApi api;
  const MobileEditor({super.key,required this.mode,required this.api});
  @override State<MobileEditor> createState()=>_MobileEditorState();
}
class _MobileEditorState extends State<MobileEditor> {
 final title=TextEditingController(),body=TextEditingController(),reference=TextEditingController(),deceased=TextEditingController(),year=TextEditingController();
 bool sending=false;
 bool get archive=>widget.mode=='archive';
 @override void dispose(){title.dispose();body.dispose();reference.dispose();deceased.dispose();year.dispose();super.dispose();}
 Future<void> submit() async {
  setState(()=>sending=true);
  try {
   final isNews=widget.mode=='berita';
   if(archive){await widget.api.call('archive_create',body:{'archive_year':int.tryParse(year.text)??0,'reference_no':reference.text.trim(),'applicant_name':title.text.trim(),'deceased_name':deceased.text.trim(),'notes':body.text.trim()});}
   else {await widget.api.call('content_create',body:{'type':isNews?'berita':'pengumuman','title':title.text.trim(),'body':body.text.trim()});}
   if(mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Data berhasil disimpan di server')));title.clear();body.clear();reference.clear();deceased.clear();year.clear();}
  } catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Gagal: $e')));}
  finally {if(mounted)setState(()=>sending=false);}
 }
 Widget entry(String label,TextEditingController controller,{int lines=1,TextInputType? keyboard}) => Padding(padding:const EdgeInsets.only(bottom:12),child:TextField(controller:controller,maxLines:lines,keyboardType:keyboard,decoration:InputDecoration(labelText:label)));
 @override Widget build(BuildContext context) => ListView(padding:const EdgeInsets.all(14),children:[
  Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(archive?'Tambah Arsip Ahli Waris':widget.mode=='berita'?'Publikasi Berita':'Tambah Pengumuman',style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:6),Text(archive?'Surat lama disimpan terpisah dari pengajuan online baru.':'Konten diterbitkan di website dan aplikasi setelah tersimpan.',style:Theme.of(context).textTheme.bodySmall)]))),
  const SizedBox(height:12),
  if(archive)...[entry('Tahun surat',year,keyboard:TextInputType.number),entry('Nomor surat',reference),entry('Nama pemohon',title),entry('Nama pewaris',deceased),entry('Catatan arsip',body,lines:4)]
  else ...[entry('Judul',title),entry('Isi ${widget.mode}',body,lines:9)],
  SizedBox(height:48,child:FilledButton.icon(onPressed:sending?null:submit,icon:const Icon(Icons.save_outlined),label:Text(sending?'Menyimpan...':'Simpan'))),
  const SizedBox(height:10),if(archive)const Text('Lampiran foto arsip lama tetap dikelola melalui panel cPanel. Fitur ini khusus pencatatan metadata.',style:TextStyle(fontSize:12,color:Colors.blueGrey)),
 ]);
}
class ArchiveList extends StatefulWidget {final CikokoApi api;const ArchiveList({super.key,required this.api});@override State<ArchiveList> createState()=>_ArchiveListState();}
class _ArchiveListState extends State<ArchiveList> {late Future<Map<String,dynamic>> result;@override void initState(){super.initState();result=widget.api.call('archives');}
 @override Widget build(BuildContext c)=>FutureBuilder<Map<String,dynamic>>(future:result,builder:(ctx,s){if(s.hasError)return Center(child:Text('Gagal memuat arsip: ${s.error}'));if(!s.hasData)return const Center(child:CircularProgressIndicator());final rows=(s.data!['items'] as List<dynamic>? ??[]);return ListView.builder(padding:const EdgeInsets.all(12),itemCount:rows.length,itemBuilder:(ctx,i){final row=rows[i] as Map<String,dynamic>;return Card(child:ListTile(leading:const Icon(Icons.folder_copy_outlined),title:Text('${row['reference_no']??''} • ${row['archive_year']??''}'),subtitle:Text('Pemohon: ${row['applicant_name']??''}\nPewaris: ${row['deceased_name']??''}')));});});}
}
