import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';

const _ink = Color(0xff12375d);
const _accent = Color(0xff246ac5);

/// Available to signed-in residents. Entries are read from the server when
/// configured, otherwise this public, read-only starting catalog is shown.
/// Missing links are deliberately NOT fabricated.
List<Map<String,dynamic>> cikokoDefaultIntegratedServices() => [
  {'id':'ptsp','title':'PTSP','description':'Pelayanan perizinan dan nonperizinan DKI Jakarta.','url':'https://ptsp.jakarta.go.id/','logo_url':'','active':true},
  {'id':'dukcapil','title':'Dukcapil','description':'Informasi dan layanan administrasi kependudukan.','url':'https://kependudukancapil.jakarta.go.id/layanan-online/','logo_url':'','active':true},
  {'id':'alpukat','title':'Alpukat Betawi','description':'Pengajuan dokumen kependudukan secara daring.','url':'https://alpukat-dukcapil.jakarta.go.id/','logo_url':'','active':true},
  {'id':'jakevo','title':'Jak Evo','description':'Pengurusan perizinan melalui JAKEVO.','url':'https://jakevo.jakarta.go.id/','logo_url':'','active':true},
  {'id':'sosial','title':'Sosial','description':'Informasi layanan kesejahteraan sosial Jakarta.','url':'https://dinsos.jakarta.go.id/','logo_url':'','active':true},
  {'id':'puskesmas','title':'Puskesmas','description':'Layanan kesehatan dan pendaftaran Puskesmas.','url':'https://www.jakarta.go.id/index.php/aplikasi-jaksehat','logo_url':'','active':true},
  {'id':'kecamatan','title':'Kecamatan','description':'Informasi pelayanan Kecamatan Pancoran.','url':'','logo_url':'','active':true},
  {'id':'pajak','title':'Pajak Online','description':'Pelayanan pajak daerah dan informasi PBB.','url':'https://pajakonline.jakarta.go.id/','logo_url':'','active':true},
  {'id':'jawara','title':'Jawara','description':'Akses layanan Jawara sesuai pengaturan Admin Utama.','url':'','logo_url':'','active':true},
  {'id':'jaksehat','title':'Jak-Sehat','description':'Akses aplikasi dan layanan kesehatan Jakarta.','url':'https://www.jakarta.go.id/index.php/aplikasi-jaksehat','logo_url':'','active':true},
  {'id':'bpjstk','title':'BPJS Ketenagakerjaan','description':'Informasi kepesertaan dan pelayanan jaminan sosial ketenagakerjaan.','url':'https://www.bpjsketenagakerjaan.go.id/','logo_url':'','active':true},
];

class CikokoIntegratedServices extends StatefulWidget {
  final CikokoApi api;
  final bool admin;
  const CikokoIntegratedServices({super.key,required this.api,this.admin=false});
  @override State<CikokoIntegratedServices> createState()=>_CikokoIntegratedServicesState();
}
class _CikokoIntegratedServicesState extends State<CikokoIntegratedServices> {
  List<Map<String,dynamic>> entries=[];
  bool loading=true,saving=false;
  String? notice;
  @override void initState(){super.initState();load();}
  Future<void> load()async{
    if(mounted)setState(()=>loading=true);
    try{
      final result=await widget.api.call('integrated_services');
      final rows=List<dynamic>.from(result['items']??[]);
      if(mounted)setState((){entries=rows.map((e)=>Map<String,dynamic>.from(e as Map)).toList();notice=null;});
    }catch(_){
      if(mounted)setState((){
        entries=cikokoDefaultIntegratedServices();
        notice=widget.admin
          ?'Pengaturan layanan belum terhubung ke server. Perubahan belum dapat disimpan.'
          :'Daftar layanan dasar ditampilkan. Beberapa tautan dapat diperbarui oleh pengelola.';
      });
    }finally{if(mounted)setState(()=>loading=false);}
  }
  Future<void> openLink(String raw)async{
    final target=Uri.tryParse(raw.trim());
    if(target==null||target.scheme!='https'||target.host.isEmpty){
      _message('Tautan layanan ini belum tersedia. Silakan hubungi pengelola.');return;
    }
    try{
      final ok=await launchUrl(target,mode:LaunchMode.externalApplication);
      if(!ok)_message('Tautan belum dapat dibuka. Silakan coba kembali.');
    }catch(_){_message('Layanan tujuan belum dapat dibuka. Silakan coba kembali.');}
  }
  void _message(String text){if(!mounted)return;ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(text)));}
  Future<void> save(List<Map<String,dynamic>> next)async{
    setState(()=>saving=true);
    try{
      await widget.api.call('integrated_services_save',body:{'items':next});
      if(mounted){setState(()=>entries=next);_message('Perubahan layanan berhasil disimpan.');}
    }catch(_){_message('Perubahan belum dapat disimpan. Periksa koneksi atau pengaturan layanan.');}
    finally{if(mounted)setState(()=>saving=false);}
  }
  Future<void> edit([Map<String,dynamic>? old])async{
    final title=TextEditingController(text:'${old?['title']??''}');
    final desc=TextEditingController(text:'${old?['description']??''}');
    final logo=TextEditingController(text:'${old?['logo_url']??''}');
    final link=TextEditingController(text:'${old?['url']??''}');
    bool active=old?['active']!=false;
    final form=GlobalKey<FormState>();
    try{
      final updated=await showDialog<Map<String,dynamic>>(context:context,builder:(c)=>StatefulBuilder(builder:(ctx,change)=>AlertDialog(
        title:Text(old==null?'Tambah Layanan':'Edit Layanan'),
        content:SingleChildScrollView(child:Form(key:form,child:Column(mainAxisSize:MainAxisSize.min,children:[
          TextFormField(controller:title,decoration:const InputDecoration(labelText:'Judul layanan'),maxLength:80,
              validator:(v)=>(v??'').trim().isEmpty?'Judul wajib diisi':null),
          TextFormField(controller:desc,decoration:const InputDecoration(labelText:'Keterangan'),maxLines:3,maxLength:300),
          TextFormField(controller:logo,decoration:const InputDecoration(labelText:'URL logo HTTPS (opsional)'),keyboardType:TextInputType.url,
              validator:(v){final x=(v??'').trim();return x.isNotEmpty&&(Uri.tryParse(x)?.scheme!='https')?'Gunakan alamat HTTPS':null;}),
          TextFormField(controller:link,decoration:const InputDecoration(labelText:'Link Lihat Selengkapnya (HTTPS)'),keyboardType:TextInputType.url,
              validator:(v){final x=(v??'').trim();return x.isNotEmpty&&(Uri.tryParse(x)?.scheme!='https')?'Gunakan alamat HTTPS':null;}),
          SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Tampilkan kepada warga'),value:active,onChanged:(v)=>change(()=>active=v)),
        ]))),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Batal')),
          FilledButton(onPressed:(){if(form.currentState!.validate())Navigator.pop(ctx,{
            'id':'${old?['id']??DateTime.now().microsecondsSinceEpoch}',
            'title':title.text.trim(),'description':desc.text.trim(),
            'logo_url':logo.text.trim(),'url':link.text.trim(),'active':active,
          });},child:const Text('Simpan')),
        ],
      )));
      if(updated==null)return;
      final next=entries.map((e)=>Map<String,dynamic>.from(e)).toList();
      final index=next.indexWhere((e)=>e['id']==updated['id']);
      if(index<0){next.add(updated);}else{next[index]=updated;}
      await save(next);
    }finally{title.dispose();desc.dispose();logo.dispose();link.dispose();}
  }
  Future<void> remove(Map<String,dynamic> entry)async{
    final confirm=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
      title:const Text('Hapus layanan?'),content:Text('Layanan ${entry['title']} akan dihapus dari katalog, bukan dari situs tujuan.'),
      actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Batal')),
        FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Hapus'))]));
    if(confirm==true)await save(entries.where((e)=>e['id']!=entry['id']).toList());
  }
  Widget logoFor(Map<String,dynamic> entry){
    final url='${entry['logo_url']??''}';
    final uri=Uri.tryParse(url);
    if(uri?.scheme=='https'&&uri?.host.isNotEmpty==true){
      return Image.network(url,width:42,height:42,fit:BoxFit.contain,errorBuilder:(_,__,___)=>const Icon(Icons.account_balance_outlined,color:_accent));
    }
    return const Icon(Icons.account_balance_outlined,color:_accent,size:25);
  }
  @override Widget build(BuildContext context){
    final visible=widget.admin?entries:entries.where((e)=>e['active']!=false).toList();
    return RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(14),children:[
      Text(widget.admin?'Kelola Layanan Terpadu':'Layanan Masyarakat Terpadu',
          style:const TextStyle(fontSize:19,fontWeight:FontWeight.w800,color:_ink)),
      const SizedBox(height:6),
      Text(widget.admin?'Atur logo, judul, keterangan, tautan, dan layanan yang tampil bagi warga.':
        'Pilih layanan untuk membuka situs resmi penyedia layanan.',
        style:const TextStyle(fontSize:12,color:Colors.blueGrey)),
      if(notice!=null)Padding(padding:const EdgeInsets.only(top:12),child:Card(
        child:Padding(padding:const EdgeInsets.all(12),child:Text(notice!,style:const TextStyle(fontSize:12))))),
      if(widget.admin)Padding(padding:const EdgeInsets.symmetric(vertical:10),child:FilledButton.icon(
        onPressed:saving?null:()=>edit(),icon:const Icon(Icons.add),label:const Text('Tambah Layanan'))),
      if(loading)const LinearProgressIndicator(),
      for(final entry in visible)Card(child:Padding(padding:const EdgeInsets.all(8),child:Row(children:[
        SizedBox(width:56,height:56,child:Center(child:logoFor(entry))),
        const SizedBox(width:6),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('${entry['title']??''}',style:const TextStyle(fontSize:13.5,fontWeight:FontWeight.w700,color:_ink)),
          Text('${entry['description']??''}',style:const TextStyle(fontSize:11,color:Colors.blueGrey),maxLines:3),
          if(!widget.admin)TextButton.icon(
            onPressed:()=>openLink('${entry['url']??''}'),
            icon:const Icon(Icons.open_in_new,size:14),
            label:const Text('Lihat Selengkapnya')),
          if(widget.admin)Text(entry['active']==false?'Disembunyikan':'Aktif',
            style:const TextStyle(fontSize:10,color:Colors.blueGrey)),
        ])),
        if(widget.admin)PopupMenuButton<String>(enabled:!saving,onSelected:(v)=>v=='edit'?edit(entry):remove(entry),
          itemBuilder:(_)=>const [
            PopupMenuItem(value:'edit',child:Text('Edit')),
            PopupMenuItem(value:'remove',child:Text('Hapus')),
          ])
      ]))),
      if(visible.isEmpty&&!loading)const Center(child:Padding(padding:EdgeInsets.all(20),
        child:Text('Belum ada layanan yang tersedia.'))),
    ]));
  }
}
