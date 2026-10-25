import 'package:flutter/material.dart';
import 'api.dart';
import 'home_customization.dart';

class HomeServicesAdminPage extends StatefulWidget {
 final CikokoApi api; final VoidCallback? onSaved;
 const HomeServicesAdminPage({super.key,required this.api,this.onSaved});
 @override State<HomeServicesAdminPage> createState()=>_HomeServicesAdminState();
}
class _HomeServicesAdminState extends State<HomeServicesAdminPage>{
 static const routes=['route:Layanan Online','route:Surat Ahli Waris','route:Hubungi Kami',
  'route:Pusat Informasi','route:Menu Cikoko','route:Berita & Kegiatan',
  'route:Pengumuman','route:Galeri','route:Inovasi','route:Riwayat','route:Laporan Jumantik'];
 static const palette=['#2868c9','#15966d','#e88a25','#6554cb','#d34450','#54738d'];
 late Future<Map<String,dynamic>> future; bool saving=false;
 @override void initState(){super.initState();reload();}
 void reload(){future=widget.api.call('v211_home_manage');}
 Future<void> refresh()async{setState(reload);try{await future;}catch(_){}}
 void message(String text){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(text)));}
 List<Map<String,dynamic>> list(Map<String,dynamic> d)=>List<dynamic>.from(d['items']??[])
   .map((e)=>Map<String,dynamic>.from(e as Map)).toList();
 Future<void> save(Map<String,dynamic> source,List<Map<String,dynamic>> rows)async{
  if(saving)return;setState(()=>saving=true);
  try{
   await widget.api.call('v211_home_save',body:{'revision':source['revision'],
    'items':rows,'labels':source['labels']});
   if(!mounted)return;
   message('Perubahan pelayanan sudah tersimpan untuk website dan aplikasi.');
   await refresh();widget.onSaved?.call();
  }catch(e){message('Gagal menyimpan: $e');}
  finally{if(mounted)setState(()=>saving=false);}
 }
 Future<Map<String,dynamic>?> form([Map<String,dynamic>? original])async{
  final name=TextEditingController(text:(original?['title']??'').toString());
  final desc=TextEditingController(text:(original?['subtitle']??'').toString());
  final link=TextEditingController(text:(original?['target']??'route:Layanan Online').toString());
  var icon=(original?['icon']??'apps').toString();
  if(!homeIcons.containsKey(icon))icon='apps';
  var color=(original?['color']??'#2868c9').toString();
  if(!palette.contains(color))color=palette.first;
  var visible=original?['visible']!=false;
  final result=await showModalBottomSheet<Map<String,dynamic>>(context:context,
    isScrollControlled:true,useSafeArea:true,showDragHandle:true,
    builder:(ctx)=>StatefulBuilder(builder:(sheet,change)=>Padding(
     padding:EdgeInsets.fromLTRB(15,3,15,MediaQuery.viewInsetsOf(sheet).bottom+16),
     child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:650),
      child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,
       crossAxisAlignment:CrossAxisAlignment.start,children:[
       Text(original==null?'Tambah Pelayanan':'Edit Pelayanan',
        style:const TextStyle(fontSize:19,fontWeight:FontWeight.w800)),
       const SizedBox(height:12),
       TextField(controller:name,maxLength:90,decoration:const InputDecoration(labelText:'Nama Pelayanan',border:OutlineInputBorder())),
       const SizedBox(height:7),
       TextField(controller:desc,maxLength:140,decoration:const InputDecoration(labelText:'Keterangan',border:OutlineInputBorder())),
       const SizedBox(height:7),
       DropdownButtonFormField<String>(initialValue:icon,isExpanded:true,
        decoration:const InputDecoration(labelText:'Ikon Pelayanan',border:OutlineInputBorder()),
        items:[for(final e in homeIcons.entries)DropdownMenuItem(value:e.key,
         child:Row(children:[Icon(e.value,size:19),const SizedBox(width:8),Text(e.key)]))],
        onChanged:(value){if(value!=null)change(()=>icon=value);}),
       const SizedBox(height:12),
       const Text('Warna Ikon',style:TextStyle(fontWeight:FontWeight.w700)),
       Wrap(spacing:7,children:[for(final swatch in palette)ChoiceChip(
        label:Icon(Icons.circle,size:18,color:homeColor(swatch)),
        selected:color==swatch,onSelected:(_)=>change(()=>color=swatch))]),
       const SizedBox(height:10),
       DropdownButtonFormField<String>(
        initialValue:routes.contains(link.text)?link.text:'https',
        isExpanded:true,decoration:const InputDecoration(labelText:'Tujuan',border:OutlineInputBorder()),
        items:[for(final r in routes)DropdownMenuItem(value:r,child:Text(r.substring(6))),
         const DropdownMenuItem(value:'https',child:Text('Tautan website HTTPS'))],
        onChanged:(v){if(v!=null)change(()=>link.text=v=='https'?'https://':v);}),
       const SizedBox(height:9),
       TextField(controller:link,maxLength:450,decoration:const InputDecoration(
        labelText:'Link atau halaman aplikasi',border:OutlineInputBorder(),
        helperText:'route:Nama Halaman atau https://alamat-website')),
       SwitchListTile(title:const Text('Tampilkan di Beranda'),value:visible,
        onChanged:(v)=>change(()=>visible=v)),
       SizedBox(width:double.infinity,child:FilledButton.icon(icon:const Icon(Icons.save_outlined),
        onPressed:(){
         final title=name.text.trim(),target=link.text.trim(),uri=Uri.tryParse(link.text.trim());
         if(title.isEmpty||title.length>90||!(routes.contains(target)||
            (uri?.scheme=='https'&&uri?.host.isNotEmpty==true))){
          ScaffoldMessenger.of(sheet).showSnackBar(const SnackBar(
           content:Text('Isi nama dan tujuan yang valid.')));return;
         }
         Navigator.pop(sheet,{
           if(original?['id']!=null)'id':original!['id'],
           'title':title,'subtitle':desc.text.trim(),'target':target,
           'icon':icon,'color':color,'visible':visible,
         });
        },label:const Text('Simpan Pelayanan'))),
      ]))),
    )));
  name.dispose();desc.dispose();link.dispose();return result;
 }
 Future<void> add(Map<String,dynamic> original)async{
  final rows=list(original);if(rows.length>=24){message('Maksimal 24 layanan.');return;}
  final value=await form();if(value==null||!mounted)return;
  await save(original,[...rows,value]);
 }
 Future<void> edit(Map<String,dynamic> original,int i)async{
  final rows=list(original);final value=await form(rows[i]);if(value==null||!mounted)return;
  rows[i]=value;await save(original,rows);
 }
 Future<void> move(Map<String,dynamic> original,int i,int delta)async{
  final rows=list(original);final other=i+delta;if(other<0||other>=rows.length)return;
  final value=rows.removeAt(i);rows.insert(other,value);await save(original,rows);
 }
 Future<void> delete(Map<String,dynamic> original,int i)async{
  final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
   title:const Text('Hapus tombol pelayanan?'),
   content:const Text('Hanya tombol Beranda dihapus. Data pelayanan, surat, dan berita tetap tersimpan.'),
   actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Batal')),
    FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Hapus Tombol'))]));
  if(ok!=true||!mounted)return;final rows=list(original);
  if(rows.length<=1){message('Setidaknya satu tombol diperlukan.');return;}
  rows.removeAt(i);await save(original,rows);
 }
 @override Widget build(BuildContext context){
  if(widget.api.profile?['role']!='admin')return const Center(child:Text('Hanya Admin Utama.'));
  return FutureBuilder<Map<String,dynamic>>(future:future,builder:(ctx,result){
   if(result.hasError)return Center(child:TextButton.icon(onPressed:refresh,
    icon:const Icon(Icons.refresh),label:const Text('Coba Muat Ulang')));
   if(!result.hasData)return const Center(child:CircularProgressIndicator());
   final data=result.data!,rows=list(data);
   return RefreshIndicator(onRefresh:refresh,child:ListView(padding:const EdgeInsets.all(14),children:[
    const Text('Kelola Pelayanan Beranda',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800)),
    const SizedBox(height:6),
    const Text('Tambahkan pelayanan dari HP Admin. Perubahan tersimpan di website dan ditampilkan di akun warga.',
     style:TextStyle(fontSize:12,color:Colors.blueGrey)),
    const SizedBox(height:12),
    FilledButton.icon(onPressed:saving?null:()=>add(data),icon:const Icon(Icons.add),label:const Text('Tambah Pelayanan')),
    const SizedBox(height:12),
    for(var i=0;i<rows.length;i++)Card(child:Padding(padding:const EdgeInsets.fromLTRB(9,6,9,8),
     child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      ListTile(contentPadding:EdgeInsets.zero,
       leading:CircleAvatar(backgroundColor:homeColor(rows[i]['color']).withValues(alpha:.12),
        child:Icon(homeIcons[(rows[i]['icon']??'').toString()]??Icons.apps_outlined,color:homeColor(rows[i]['color']))),
       title:Text((rows[i]['title']??'').toString(),style:const TextStyle(fontWeight:FontWeight.w700)),
       subtitle:Text((rows[i]['subtitle']??'').toString(),style:const TextStyle(fontSize:11)),
       trailing:Icon(rows[i]['visible']==false?Icons.visibility_off_outlined:Icons.visibility_outlined)),
      Text((rows[i]['target']??'').toString(),maxLines:1,overflow:TextOverflow.ellipsis,
       style:const TextStyle(fontSize:11,color:Colors.blueGrey)),
      Wrap(alignment:WrapAlignment.end,children:[
       IconButton(tooltip:'Naikkan',onPressed:saving||i==0?null:()=>move(data,i,-1),icon:const Icon(Icons.arrow_upward)),
       IconButton(tooltip:'Turunkan',onPressed:saving||i==rows.length-1?null:()=>move(data,i,1),icon:const Icon(Icons.arrow_downward)),
       TextButton.icon(onPressed:saving?null:()=>edit(data,i),
        icon:const Icon(Icons.edit_outlined,size:18),label:const Text('Edit')),
       IconButton(tooltip:'Hapus tombol',onPressed:saving?null:()=>delete(data,i),
        icon:const Icon(Icons.delete_outline,color:Colors.red)),
      ]),
     ]))),
    const SizedBox(height:74),
   ]));
  });
 }
}
