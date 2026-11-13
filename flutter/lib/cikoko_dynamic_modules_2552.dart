import 'package:flutter/material.dart';
import 'api.dart';

// Flutter-native server-driven module catalog; never executes server-supplied code.
class CikokoDynamicModulesPage extends StatefulWidget {
 const CikokoDynamicModulesPage({super.key,required this.api,required this.role});
 final CikokoApi api;final String role;
 @override State<CikokoDynamicModulesPage> createState()=>_DynamicState();
}
class _DynamicState extends State<CikokoDynamicModulesPage> {
 List<Map<String,dynamic>> items=[];bool busy=true;String? error;
 bool get admin=>widget.role=='admin'||widget.role=='admin_kelurahan';
 @override void initState(){super.initState();load();}
 Future<void> load()async{
  setState((){busy=true;error=null;});
  try{
   final result=await widget.api.call('dynamic_modules');
   if(mounted)setState(()=>items=(result['items'] as List? ??[]).map((e)=>Map<String,dynamic>.from(e as Map)).toList());
  }catch(e){if(mounted)setState(()=>error='$e');}
  finally{if(mounted)setState(()=>busy=false);}
 }
 Future<void> save()async{
  try{await widget.api.call('dynamic_modules_save',body:{'items':items});await load();}
  catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e')));}
 }
 Future<void> create()async{
  final title=TextEditingController(),id=TextEditingController();
  final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
   title:const Text('Tambah modul native'),
   content:Column(mainAxisSize:MainAxisSize.min,children:[
    TextField(controller:title,decoration:const InputDecoration(labelText:'Nama modul')),
    TextField(controller:id,decoration:const InputDecoration(labelText:'ID unik (huruf kecil)',hintText:'laporan_ppsu')),
   ]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Batal')),
    FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Tambahkan'))]));
  if(ok==true){
   final key=id.text.trim();
   if(!RegExp(r'^[a-z][a-z0-9_]{2,39}$').hasMatch(key)||title.text.trim().isEmpty){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('ID atau judul tidak valid')));return;}
   setState(()=>items.add({'id':key,'title':title.text.trim(),'description':'','active':false,'roles':['admin','admin_kelurahan','ppsu','pjlp'],'fields':<dynamic>[]}));
   await save();
  }
  title.dispose();id.dispose();
 }
 Future<void> edit(Map<String,dynamic> module)async{
  final title=TextEditingController(text:'${module['title']}');
  final description=TextEditingController(text:'${module['description']??''}');
  final fields=List<Map<String,dynamic>>.from((module['fields'] as List? ??[]).map((e)=>Map<String,dynamic>.from(e as Map)));
  bool active=module['active']==true;
  final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh)=>AlertDialog(
   title:const Text('Pengaturan modul'),
   content:SizedBox(width:420,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
    TextField(controller:title,decoration:const InputDecoration(labelText:'Nama modul')),
    TextField(controller:description,decoration:const InputDecoration(labelText:'Deskripsi')),
    SwitchListTile(title:const Text('Publikasikan modul'),value:active,onChanged:(v)=>refresh(()=>active=v)),
    const Divider(),
    for(final f in fields)ListTile(title:Text('${f['label']}'),subtitle:Text('${f['type']} · ${f['key']}'),
     trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()=>refresh(()=>fields.remove(f)))),
    OutlinedButton.icon(icon:const Icon(Icons.add),label:const Text('Tambah kolom formulir'),onPressed:()async{
     final label=TextEditingController(),key=TextEditingController();
     String type='text';
     final added=await showDialog<bool>(context:ctx,builder:(sub)=>StatefulBuilder(builder:(sub,change)=>AlertDialog(
      title:const Text('Kolom baru'),content:Column(mainAxisSize:MainAxisSize.min,children:[
       TextField(controller:label,decoration:const InputDecoration(labelText:'Label')),
       TextField(controller:key,decoration:const InputDecoration(labelText:'ID kolom')),
       DropdownButton<String>(value:type,isExpanded:true,items:const ['text','number','date','multiline'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>change(()=>type=v??'text'))
      ]),actions:[TextButton(onPressed:()=>Navigator.pop(sub,false),child:const Text('Batal')),FilledButton(onPressed:()=>Navigator.pop(sub,true),child:const Text('Tambah'))])));
     if(added==true&&RegExp(r'^[a-z][a-z0-9_]{1,39}$').hasMatch(key.text.trim())&&label.text.trim().isNotEmpty){
      refresh(()=>fields.add({'key':key.text.trim(),'label':label.text.trim(),'type':type,'required':false,'options':<String>[]}));
     }
     label.dispose();key.dispose();
    }),
   ]))),
   actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Batal')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Simpan'))]
  )));
  if(ok==true){setState((){module['title']=title.text.trim();module['description']=description.text.trim();module['active']=active;module['fields']=fields;});await save();}
  title.dispose();description.dispose();
 }
 void open(Map<String,dynamic> module){
  Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>Scaffold(
   appBar:AppBar(title:Text('${module['title']}')),
   body:ListView(padding:const EdgeInsets.all(16),children:[
    Text('${module['description']??''}',style:Theme.of(context).textTheme.bodyMedium),
    const SizedBox(height:12),
    for(final field in (module['fields'] as List? ??[]))
     Padding(padding:const EdgeInsets.only(bottom:12),child:TextFormField(
      readOnly:true,decoration:InputDecoration(border:const OutlineInputBorder(),labelText:'${field['label']}',helperText:'Formulir dinamis — pengiriman belum diaktifkan'))),
    const Card(child:Padding(padding:EdgeInsets.all(16),child:Text('Modul ini telah tersinkronisasi dari cPanel. Penyimpanan pengajuan membutuhkan endpoint layanan khusus.'))),
   ]),
  )));
 }
 @override Widget build(BuildContext context)=>RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(16),children:[
  Text('Modul Dinamis',style:Theme.of(context).textTheme.headlineSmall),
  const Text('Menu Flutter native yang tersinkronisasi dari server.'),
  if(admin)Padding(padding:const EdgeInsets.symmetric(vertical:12),child:FilledButton.icon(onPressed:create,icon:const Icon(Icons.add),label:const Text('Tambah modul'))),
  if(busy)const LinearProgressIndicator(),
  if(error!=null)Card(child:ListTile(title:const Text('Sinkronisasi belum tersedia'),subtitle:Text(error!))),
  for(final module in items)Card(child:ListTile(
   leading:const Icon(Icons.widgets_outlined),title:Text('${module['title']}'),
   subtitle:Text('${module['active']==true?'Aktif':'Draft'} · ${module['description']??''}'),
   onTap:()=>open(module),
   trailing:admin?IconButton(icon:const Icon(Icons.edit_outlined),onPressed:()=>edit(module)):const Icon(Icons.chevron_right))),
  if(!busy&&items.isEmpty)const Card(child:ListTile(title:Text('Belum ada modul'),subtitle:Text('Admin dapat menambahkan modul dari aplikasi setelah backend 2552 dipasang.'))),
 ]));
}
