import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api.dart';
import 'cikoko_v6_showcase.dart';

/// In-app editor for the website's appearance.json slots.
class CikokoAppearanceAdmin extends StatefulWidget {
  final CikokoApi api;
  final VoidCallback? onPublished;
  const CikokoAppearanceAdmin({
    super.key, required this.api, this.onPublished,
  });
  @override State<CikokoAppearanceAdmin> createState() =>
    _CikokoAppearanceAdminState();
}

class _CikokoAppearanceAdminState extends State<CikokoAppearanceAdmin> {
  static const labels = <String,String>{
    'brand_logo':'Logo Website',
    'hero':'Foto Header Cadangan',
    'news':'Foto Berita',
    'gallery':'Foto Galeri',
    'service':'Ikon Layanan',
    'service_1':'Layanan 1',
    'service_2':'Layanan 2',
    'service_3':'Layanan 3',
    'service_4':'Layanan 4',
    'service_5':'Layanan 5',
    'service_6':'Layanan 6',
  };
  bool loading = true;
  String? error;
  Map<String,Map<String,dynamic>> slots = {};
  @override void initState(){super.initState();load();}
  Future<void> load() async {
    if(mounted)setState((){loading=true;error=null;});
    try{
      final response=await widget.api.call('cms_appearance_list');
      final raw=Map<String,dynamic>.from(response['slots'] as Map);
      if(mounted)setState(()=>slots=raw.map(
        (key,value)=>MapEntry(key,Map<String,dynamic>.from(value as Map))));
    }catch(e){if(mounted)setState(()=>
      error='Tampilan website belum dapat dimuat: '+e.toString());}
    finally{if(mounted)setState(()=>loading=false);}
  }
  Future<void> edit(String slot)async{
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder:(_)=>Scaffold(
        appBar:AppBar(title:Text(labels[slot]??slot)),
        body:CikokoAppearanceSlotForm(
          api:widget.api,slot:slot,record:slots[slot]??{},
          onPublished:(){widget.onPublished?.call();load();},
        ),
      ),
    ));
    if(mounted)load();
  }
  @override Widget build(BuildContext context)=>ListView(
    key:const Key('native_cms_appearance_editor'),
    padding:const EdgeInsets.all(14),children:[
      const V6PageHeader(title:'Tampilan Website',
        description:'Ganti logo, foto, posisi dan tampilan langsung dari aplikasi.',
        icon:Icons.palette_outlined),
      const SizedBox(height:9),
      const V6Panel(child:Text(
        'Untuk mengganti foto header utama website dan Android secara bersamaan, '
        'gunakan menu Ganti Foto Header. Foto di bagian ini adalah '
        'pengaturan tampilan website lainnya dan gambar cadangan.',
        style:TextStyle(fontSize:12))),
      if(loading)const LinearProgressIndicator(),
      if(error!=null)Text(error!,style:const TextStyle(color:Colors.red)),
      for(final entry in labels.entries)
        Card(child:ListTile(
          key:Key('appearance_'+entry.key),
          leading:const Icon(Icons.photo_outlined,color:V6.blue),
          title:Text(entry.value),
          subtitle:Text((slots[entry.key]?['file']??'Belum diatur').toString(),
            maxLines:1,overflow:TextOverflow.ellipsis),
          onTap:loading||error!=null?null:()=>edit(entry.key),
          trailing:const Icon(Icons.chevron_right),
        )),
      TextButton.icon(onPressed:load,icon:const Icon(Icons.refresh),
        label:const Text('Muat Ulang')),
    ],
  );
}

class CikokoAppearanceSlotForm extends StatefulWidget {
 final CikokoApi api;
 final String slot;
 final Map<String,dynamic> record;
 final VoidCallback? onPublished;
 const CikokoAppearanceSlotForm({
  super.key,required this.api,required this.slot,
  required this.record,this.onPublished,
 });
 @override State<CikokoAppearanceSlotForm> createState()=>
   _CikokoAppearanceSlotFormState();
}
class _CikokoAppearanceSlotFormState extends State<CikokoAppearanceSlotForm>{
 late String fit;
 late double horizontal,vertical;
 String? pickedPath,error;
 bool saving=false;
 @override void initState(){
  super.initState();
  fit=widget.record['fit']=='contain'?'contain':'cover';
  horizontal=((widget.record['x'] as num?)?.toDouble()??50).clamp(0,100);
  vertical=((widget.record['y'] as num?)?.toDouble()??50).clamp(0,100);
 }
 Future<void> pick()async{
  final picked=await ImagePicker().pickImage(
    source:ImageSource.gallery,maxWidth:2048,imageQuality:80);
  if(picked!=null&&mounted)setState(()=>pickedPath=picked.path);
 }
 Future<void> save()async{
  if(saving)return;
  setState((){saving=true;error=null;});
  try{
    String path=(widget.record['file']??'').toString();
    if(pickedPath!=null){
      final uploaded=await widget.api.upload(
       'cms_media_upload',{}, {'photo':[pickedPath!]});
      path=(uploaded['path']??'').toString();
      if(!path.startsWith('assets/images/')){
        throw ApiError('Foto tidak berhasil diunggah.');
      }
    }
    await widget.api.call('cms_appearance_save',body:{
      'slot':widget.slot,'file':path,'fit':fit,
      'x':horizontal.round(),'y':vertical.round(),
    });
    widget.onPublished?.call();
    if(mounted)Navigator.pop(context);
  }catch(e){if(mounted)setState(()=>error='Gagal menyimpan: '+e.toString());}
  finally{if(mounted)setState(()=>saving=false);}
 }
 @override Widget build(BuildContext context)=>ListView(
  padding:const EdgeInsets.all(16),children:[
    const V6PageHeader(title:'Edit Tampilan',
      description:'Perubahan disimpan ke pengaturan website yang sama.',
      icon:Icons.tune_outlined),
    const SizedBox(height:10),
    Text('Slot: '+widget.slot,
      style:const TextStyle(fontWeight:FontWeight.w800)),
    const SizedBox(height:10),
    OutlinedButton.icon(
      key:const Key('cms_appearance_choose_photo'),
      onPressed:saving?null:pick,
      icon:const Icon(Icons.photo_library_outlined),
      label:const Text('Pilih Foto dari Galeri')),
    if(pickedPath!=null)
      const Text('Foto baru siap diunggah saat disimpan.'),
    const SizedBox(height:16),
    DropdownButtonFormField<String>(
      initialValue:fit,
      decoration:const InputDecoration(labelText:'Cara Memotong Foto'),
      items:const [
        DropdownMenuItem(value:'cover',child:Text('Penuh (Cover)')),
        DropdownMenuItem(value:'contain',child:Text('Seluruh Foto (Contain)')),
      ],
      onChanged:saving?null:(v){if(v!=null)setState(()=>fit=v);},
    ),
    const SizedBox(height:14),
    Text('Posisi Horizontal: '+horizontal.round().toString()+'%'),
    Slider(value:horizontal,min:0,max:100,divisions:20,
      onChanged:saving?null:(v)=>setState(()=>horizontal=v)),
    Text('Posisi Vertikal: '+vertical.round().toString()+'%'),
    Slider(value:vertical,min:0,max:100,divisions:20,
      onChanged:saving?null:(v)=>setState(()=>vertical=v)),
    if(error!=null)Text(error!,style:const TextStyle(color:Colors.red)),
    FilledButton.icon(
      key:const Key('cms_appearance_save'),
      onPressed:saving?null:save,
      icon:const Icon(Icons.save_outlined),
      label:Text(saving?'Menyimpan...':'Simpan Tampilan'),
    ),
  ],
 );
}
