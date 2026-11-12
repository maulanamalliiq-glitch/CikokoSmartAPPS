import 'package:flutter/material.dart';
import 'api.dart';
import 'cikoko_v6_showcase.dart';

/// Native CMS forms for official page text and innovation records.
/// No external website login or WebView is involved.
class CikokoPagesAdmin extends StatefulWidget {
  final CikokoApi api;
  final String? initialSlug;
  final VoidCallback? onPublished;
  const CikokoPagesAdmin({
    super.key, required this.api, this.initialSlug, this.onPublished,
  });
  @override State<CikokoPagesAdmin> createState()=>_CikokoPagesAdminState();
}
class _CikokoPagesAdminState extends State<CikokoPagesAdmin>{
 static const pages=<String,String>{
  'cms-halaman':'CMS Halaman Website',
  'profil':'Profil Kelurahan',
  'ppid':'PPID',
  'kontak':'Kontak',
  'agenda':'Agenda Kegiatan',
  'pimpinan':'Profil Pimpinan',
  'wilayah':'Peta dan Profil Wilayah',
  'laporan-publik':'Laporan Publik',
 };
 bool loading=true;
 String? error;
 Map<String,Map<String,dynamic>> records={};
 @override void initState(){super.initState();load();}
 Future<void> load()async{
  if(mounted)setState((){loading=true;error=null;});
  try{
    final r=await widget.api.call('cms_page_list');
    final raw=Map<String,dynamic>.from(r['pages'] as Map);
    if(mounted)setState(()=>records=raw.map((k,v)=>
     MapEntry(k,Map<String,dynamic>.from(v as Map))));
  }catch(e){if(mounted)setState(()=>
    error='Halaman CMS belum dapat dimuat: '+e.toString());}
  finally{if(mounted)setState(()=>loading=false);}
 }
 Future<void> edit(String code)async{
  await Navigator.of(context).push(MaterialPageRoute<void>(
    builder:(_)=>Scaffold(
      appBar:AppBar(title:Text(pages[code]??code)),
      body:CikokoTextPageForm(api:widget.api,slug:code,
        saved:records[code]??{},
        onPublished:(){widget.onPublished?.call();load();}),
    ),
  ));
  if(mounted)load();
 }
 @override Widget build(BuildContext context){
  final visible=widget.initialSlug==null
    ?pages.entries.toList()
    :pages.entries.where((e)=>e.key==widget.initialSlug).toList();
  return ListView(
   key:const Key('native_cms_pages_editor'),
   padding:const EdgeInsets.all(14),children:[
    const V6PageHeader(title:'Kelola Halaman',
      description:'Edit judul dan isi halaman langsung di aplikasi.',
      icon:Icons.description_outlined),
    const SizedBox(height:12),
    if(loading)const LinearProgressIndicator(),
    if(error!=null)Text(error!,style:const TextStyle(color:Colors.red)),
    for(final entry in visible)Card(child:ListTile(
      key:Key('cms_page_'+entry.key),
      leading:const Icon(Icons.edit_note,color:V6.blue),
      title:Text(entry.value),
      subtitle:Text((records[entry.key]?['title']??'Belum diisi').toString(),
        maxLines:1,overflow:TextOverflow.ellipsis),
      trailing:const Icon(Icons.chevron_right),
      onTap:loading||error!=null?null:()=>edit(entry.key),
    )),
    TextButton.icon(onPressed:load,icon:const Icon(Icons.refresh),
     label:const Text('Muat Ulang')),
   ],
  );
 }
}

class CikokoTextPageForm extends StatefulWidget{
 final CikokoApi api;
 final String slug;
 final Map<String,dynamic> saved;
 final VoidCallback? onPublished;
 const CikokoTextPageForm({
  super.key,required this.api,required this.slug,
  required this.saved,this.onPublished,
 });
 @override State<CikokoTextPageForm> createState()=>_CikokoTextPageFormState();
}
class _CikokoTextPageFormState extends State<CikokoTextPageForm>{
 late final TextEditingController title,body;
 String? error;
 bool saving=false;
 @override void initState(){
  super.initState();
  title=TextEditingController(text:(widget.saved['title']??'').toString());
  body=TextEditingController(text:(widget.saved['body']??'').toString());
 }
 @override void dispose(){title.dispose();body.dispose();super.dispose();}
 Future<void> save()async{
  if(saving)return;
  if(title.text.trim().length<3||body.text.trim().length<3){
   setState(()=>error='Judul dan isi minimal 3 karakter.');return;
  }
  setState((){saving=true;error=null;});
  try{
   await widget.api.call('cms_page_save',body:{
    'slug':widget.slug,'title':title.text.trim(),'body':body.text.trim(),
   });
   widget.onPublished?.call();
   if(mounted)Navigator.pop(context);
  }catch(e){if(mounted)setState(()=>error='Belum berhasil disimpan: '+e.toString());}
  finally{if(mounted)setState(()=>saving=false);}
 }
 @override Widget build(BuildContext context)=>ListView(
  padding:const EdgeInsets.all(16),children:[
   TextField(controller:title,maxLength:160,
    decoration:const InputDecoration(labelText:'Judul Halaman')),
   const SizedBox(height:12),
   TextField(controller:body,minLines:8,maxLines:15,maxLength:12000,
    decoration:const InputDecoration(labelText:'Isi Halaman')),
   if(error!=null)Text(error!,style:const TextStyle(color:Colors.red)),
   const SizedBox(height:12),
   FilledButton.icon(
    key:const Key('cms_text_page_save'),
    onPressed:saving?null:save,
    icon:const Icon(Icons.save_outlined),
    label:Text(saving?'Menyimpan...':'Simpan Halaman'),
   ),
  ],
 );
}

/// Edit v211_innovations records through the existing admin-authenticated API.
class CikokoInnovationsAdmin extends StatefulWidget{
 final CikokoApi api;
 final VoidCallback? onPublished;
 const CikokoInnovationsAdmin({
  super.key,required this.api,this.onPublished,
 });
 @override State<CikokoInnovationsAdmin> createState()=>
  _CikokoInnovationsAdminState();
}
class _CikokoInnovationsAdminState extends State<CikokoInnovationsAdmin>{
 bool loading=true;
 String? error;
 List<Map<String,dynamic>> items=[];
 @override void initState(){super.initState();refresh();}
 Future<void> refresh()async{
  if(mounted)setState((){loading=true;error=null;});
  try{
   final r=await widget.api.call('v211_innovations');
   if(mounted)setState(()=>items=(r['items'] as List<dynamic>???[])
     .whereType<Map>().map((v)=>Map<String,dynamic>.from(v)).toList());
  }catch(e){if(mounted)setState(()=>
   error='Inovasi tidak dapat dimuat: '+e.toString());}
  finally{if(mounted)setState(()=>loading=false);}
 }
 Future<void> edit(Map<String,dynamic> item)async{
  await Navigator.of(context).push(MaterialPageRoute<void>(
   builder:(_)=>Scaffold(
    appBar:AppBar(title:const Text('Edit Inovasi')),
    body:CikokoInnovationForm(api:widget.api,item:item,
      onPublished:widget.onPublished),
   ),
  ));
  if(mounted)refresh();
 }
 @override Widget build(BuildContext context)=>ListView(
  key:const Key('native_innovations_editor'),
  padding:const EdgeInsets.all(14),children:[
   const V6PageHeader(title:'Inovasi Kelurahan',
    description:'Ubah detail inovasi langsung dari aplikasi.',
    icon:Icons.auto_awesome_outlined),
   if(loading)const LinearProgressIndicator(),
   if(error!=null)Text(error!,style:const TextStyle(color:Colors.red)),
   for(final item in items)
    Card(child:ListTile(
     key:Key('innovation_'+(item['slug']??'').toString()),
     title:Text((item['title']??'').toString()),
     subtitle:Text((item['summary']??'').toString(),maxLines:2),
     trailing:const Icon(Icons.edit_outlined),
     onTap:()=>edit(item),
    )),
   TextButton.icon(onPressed:refresh,icon:const Icon(Icons.refresh),
    label:const Text('Muat Ulang')),
  ],
 );
}
class CikokoInnovationForm extends StatefulWidget{
 final CikokoApi api;
 final Map<String,dynamic> item;
 final VoidCallback? onPublished;
 const CikokoInnovationForm({
  super.key,required this.api,required this.item,this.onPublished,
 });
 @override State<CikokoInnovationForm> createState()=>_CikokoInnovationFormState();
}
class _CikokoInnovationFormState extends State<CikokoInnovationForm>{
 late final TextEditingController title,summary,body;
 bool saving=false;
 String? error;
 @override void initState(){
  super.initState();
  title=TextEditingController(text:(widget.item['title']??'').toString());
  summary=TextEditingController(text:(widget.item['summary']??'').toString());
  body=TextEditingController(text:(widget.item['body']??'').toString());
 }
 @override void dispose(){title.dispose();summary.dispose();body.dispose();super.dispose();}
 Future<void> save()async{
  if(saving)return;
  if(title.text.trim().isEmpty){setState(()=>error='Judul wajib diisi.');return;}
  setState((){saving=true;error=null;});
  try{
   await widget.api.call('v211_innovations_update',body:{
    'slug':(widget.item['slug']??'').toString(),
    'title':title.text.trim(),'summary':summary.text.trim(),
    'body':body.text.trim(),
   });
   widget.onPublished?.call();
   if(mounted)Navigator.pop(context);
  }catch(e){if(mounted)setState(()=>error='Gagal: '+e.toString());}
  finally{if(mounted)setState(()=>saving=false);}
 }
 @override Widget build(BuildContext context)=>ListView(
  padding:const EdgeInsets.all(16),children:[
   TextField(controller:title,maxLength:160,
    decoration:const InputDecoration(labelText:'Judul')),
   TextField(controller:summary,maxLines:3,maxLength:500,
    decoration:const InputDecoration(labelText:'Ringkasan')),
   TextField(controller:body,minLines:6,maxLines:12,maxLength:16000,
    decoration:const InputDecoration(labelText:'Isi Inovasi')),
   if(error!=null)Text(error!,style:const TextStyle(color:Colors.red)),
   FilledButton.icon(onPressed:saving?null:save,
    icon:const Icon(Icons.save_outlined),
    label:Text(saving?'Menyimpan...':'Simpan Inovasi')),
  ],
 );
}
