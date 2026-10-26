import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import 'api.dart';

class CivicAdministrationPage extends StatefulWidget {
 final CikokoApi api;
 const CivicAdministrationPage({super.key,required this.api});
 @override State<CivicAdministrationPage> createState()=>_CivicAdministrationState();
}
class _CivicAdministrationState extends State<CivicAdministrationPage> {
 late Future<Map<String,dynamic>> data;
 late Future<Map<String,dynamic>> catalog;
 late Future<Map<String,dynamic>> region;
 Map<String,dynamic>? scope;
 @override void initState(){super.initState();reload();}
 void reload(){
  data=widget.api.call('civic_list');catalog=widget.api.call('civic_catalog');
  region=widget.api.call('civic_profile_get');
  catalog.then((v){if(mounted)setState(()=>scope=v['scope'] is Map?Map<String,dynamic>.from(v['scope']):null);}).catchError((_){});
 }
 Future<void> refresh()async{setState(reload);try{await Future.wait([data,catalog,region]);}catch(_){}}
 String get role=>(widget.api.profile?['role']??'warga').toString();
 Future<void> create(String kind)async{
  final changed=await Navigator.of(context).push<bool>(MaterialPageRoute(builder:(_)=>CivicNewDocument(api:widget.api,kind:kind)));
  if(changed==true)await refresh();
 }
 Future<void> enroll()async{
  final changed=await Navigator.of(context).push<bool>(MaterialPageRoute(builder:(_)=>CivicSealPage(api:widget.api,stampRequired:scope?['duty']=='rt'||scope?['duty']=='rw')));
  if(changed==true)await refresh();
 }
 @override Widget build(BuildContext context)=>RefreshIndicator(onRefresh:refresh,
 child:ListView(padding:const EdgeInsets.all(14),children:[
  const Text('Administrasi RT/RW & LMK',style:TextStyle(fontSize:21,fontWeight:FontWeight.w800)),
  const SizedBox(height:6),const Text('Surat pengantar digital dan laporan pertanggungjawaban bulanan Kelurahan Cikoko.',style:TextStyle(color:Colors.blueGrey,fontSize:12)),
  const SizedBox(height:14),
  FutureBuilder<Map<String,dynamic>>(future:catalog,builder:(ctx,s){
   if(s.hasError)return ListTile(title:const Text('Pengaturan belum tersedia'),subtitle:Text(s.error.toString()));
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   return Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    if(role=='warga')FutureBuilder<Map<String,dynamic>>(future:region,builder:(ctx,area){
     if(area.hasError)return const Text('Wilayah tidak dapat diperiksa. Coba muat ulang.',style:TextStyle(color:Colors.red));
     if(!area.hasData)return const LinearProgressIndicator();
     final authorized=area.data?['can_apply']==true;
     final verified=area.data?['verified_area'] is Map
      ?Map<String,dynamic>.from(area.data!['verified_area'] as Map):null;
     return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
       Text(authorized?'Wilayah terverifikasi: RT '+(verified?['rt']??'').toString()+
         ' / RW '+(verified?['rw']??'').toString():'Lengkapi Profil → Detail Wilayah RT/RW terlebih dahulu',
         style:TextStyle(fontWeight:FontWeight.w700,color:authorized?Colors.green:Colors.deepOrange)),
       const SizedBox(height:9),
       if(!authorized)const Text('Surat baru dapat diajukan setelah Admin Kelurahan memverifikasi RT/RW Anda.',
        style:TextStyle(color:Colors.blueGrey,fontSize:12)),
       for(final item in const [
        ['pengantar','Surat Pengantar RT/RW'],['domisili','Surat Domisili (template sementara)'],
        ['keterangan','Surat Keterangan (template sementara)'],['permohonan','Surat Permohonan (template sementara)'],
       ])ListTile(leading:const Icon(Icons.description_outlined),title:Text(item[1]),
         trailing:Icon(authorized?Icons.chevron_right:Icons.lock_outline),
         onTap:authorized?()=>create(item[0]):null),
     ]);
    }),
    if(scope!=null)...[
     Text('Jabatan: '+(scope?['duty']??'').toString()+' • RT '+(scope?['rt']??'-').toString()+' / RW '+(scope?['rw']??'-').toString(),
       style:const TextStyle(fontWeight:FontWeight.bold)),
     OutlinedButton.icon(onPressed:enroll,icon:const Icon(Icons.draw_outlined),label:const Text('Tanda tangan / Stempel / PIN')),
     if(scope?['duty']=='bendahara_rt')FilledButton(onPressed:()=>create('lpj_rt'),child:const Text('Buat LPJ RT')),
     if(scope?['duty']=='bendahara_rw')FilledButton(onPressed:()=>create('lpj_rw'),child:const Text('Buat LPJ RW')),
     if(scope?['duty']=='lmk')...[
      FilledButton(onPressed:()=>create('lpj_lmk_a'),child:const Text('Buat LPJ LMK A')),
      FilledButton(onPressed:()=>create('lpj_lmk_b'),child:const Text('Buat LPJ LMK B')),
     ],
    ],
    if(role=='admin'||role=='admin_kelurahan')const ListTile(
     title:Text('Pengelolaan wilayah dan petugas'),
     subtitle:Text('Penugasan akun RT/RW/Bendahara/LMK dan verifikasi wilayah warga dilakukan dari admin-civic.php di dashboard website.')),
   ])));
  }),
  const SizedBox(height:15),
  const Text('Riwayat dan Dokumen Masuk',style:TextStyle(fontSize:17,fontWeight:FontWeight.w800)),
  FutureBuilder<Map<String,dynamic>>(future:data,builder:(ctx,s){
   if(s.hasError)return TextButton.icon(onPressed:refresh,icon:const Icon(Icons.refresh),label:Text('Muat Ulang: '+s.error.toString()));
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   final items=List<dynamic>.from(s.data?['items']??[]);
   if(items.isEmpty)return const ListTile(title:Text('Belum ada dokumen.'));
   return Column(children:[for(final row in items)Card(child:ListTile(
    title:Text((row['kind']??'').toString().replaceAll('_',' ').toUpperCase()+' #'+(row['id']??'').toString()),
    subtitle:Text((row['owner_name']??'').toString()+' • '+(row['status']??'').toString()),
    trailing:const Icon(Icons.chevron_right),
    onTap:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>CivicDetailPage(api:widget.api,id:int.parse(row['id'].toString()),scope:scope))).then((_)=>refresh()),
   ))]);
  })
 ]));
}

class CivicNewDocument extends StatefulWidget {
 final CikokoApi api;final String kind;final int? revisionOf;final Map<String,dynamic>? original;
 const CivicNewDocument({super.key,required this.api,required this.kind,this.revisionOf,this.original});
 @override State<CivicNewDocument> createState()=>_CivicNewState();
}
class _CivicNewState extends State<CivicNewDocument>{
 final inputs=<String,TextEditingController>{};final expenses=<Map<String,TextEditingController>>[];
 bool busy=false;
 bool get isLetter=>!widget.kind.startsWith('lpj_');
 static const labels=<String,String>{
  'name':'Nama Lengkap','nik':'NIK (16 angka)','birthplace':'Tempat Lahir','birthdate':'Tanggal Lahir (YYYY-MM-DD)',
  'occupation':'Pekerjaan','religion':'Agama','marital_status':'Status Pernikahan','citizenship':'Warga Negara',
  'education':'Pendidikan','gender':'Jenis Kelamin',
  'address':'Alamat','purpose':'Maksud dan Keperluan'};
 @override void initState(){super.initState();
  for(final k in (isLetter?labels.keys:['period','opening','income']))inputs[k]=TextEditingController();
  if(isLetter){
   inputs['name']!.text=(widget.api.profile?['name']??'').toString();
   inputs['address']!.text=(widget.api.profile?['address']??'').toString();
  }
  if(!isLetter){final now=DateTime.now();inputs['period']!.text=now.year.toString()+'-'+now.month.toString().padLeft(2,'0');inputs['opening']!.text='0';}
  if(widget.original!=null){
    for(final e in widget.original!.entries){
      if(inputs.containsKey(e.key))inputs[e.key]!.text=e.value.toString();
    }
    if(!isLetter){
      for(final raw in List<dynamic>.from(widget.original!['entries']??[])){
        if(raw is Map)expenses.add({
          'activity':TextEditingController(text:(raw['activity']??'').toString()),
          'amount':TextEditingController(text:(raw['amount']??0).toString()),
          'notes':TextEditingController(text:(raw['notes']??'').toString())
        });
      }
    }
  }
 }
 @override void dispose(){for(final x in inputs.values)x.dispose();for(final r in expenses)for(final x in r.values)x.dispose();super.dispose();}
 int amount(String? v)=>int.tryParse((v??'').replaceAll(RegExp(r'[^0-9]'),''))??0;
 void addExpense()=>setState(()=>expenses.add({'activity':TextEditingController(),'amount':TextEditingController(),'notes':TextEditingController()}));
 Future<void> send()async{
  if(busy)return;setState(()=>busy=true);
  try{
   final Map<String,dynamic> p=isLetter?{for(final e in inputs.entries)e.key:e.value.text.trim()}:
    {'opening':amount(inputs['opening']?.text),'income':amount(inputs['income']?.text),
     'entries':[for(final r in expenses){'activity':r['activity']!.text.trim(),'amount':amount(r['amount']!.text),'notes':r['notes']!.text.trim()}]};
   await widget.api.call(widget.revisionOf==null?'civic_submit':'civic_resubmit',body:{'kind':widget.kind,'fields':p,if(!isLetter)'period':inputs['period']!.text.trim(),if(widget.revisionOf!=null)'id':widget.revisionOf});
   if(mounted)Navigator.of(context).pop(true);
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  finally{if(mounted)setState(()=>busy=false);}
 }
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.kind.toUpperCase().replaceAll('_',' '))),
 body:ListView(padding:const EdgeInsets.all(15),children:[
  if(isLetter)...[
   if(widget.kind!='pengantar')const ListTile(leading:Icon(Icons.info_outline),title:Text('Template sementara, menunggu format resmi')),
   for(final e in labels.entries)if(e.key=='gender')Padding(padding:const EdgeInsets.only(bottom:11),child:DropdownButtonFormField<String>(
     initialValue:inputs['gender']!.text.isEmpty?null:inputs['gender']!.text,
     decoration:const InputDecoration(labelText:'Jenis Kelamin',border:OutlineInputBorder()),
     items:const [DropdownMenuItem(value:'Laki-laki',child:Text('Laki-laki')),DropdownMenuItem(value:'Perempuan',child:Text('Perempuan'))],
     onChanged:(value){inputs['gender']!.text=value??'';}))
   else Padding(padding:const EdgeInsets.only(bottom:11),child:TextField(
     controller:inputs[e.key],maxLines:e.key=='purpose'?3:1,
     keyboardType:e.key=='nik'?TextInputType.number:null,
     decoration:InputDecoration(labelText:e.value,border:const OutlineInputBorder()))),
  ]else...[
   const Text('Isi penerimaan bulan ini berdasarkan nilai yang benar. Angka dalam PDF Januari 2026 hanya contoh.',
      style:TextStyle(color:Colors.blueGrey,fontSize:12)),
   for(final row in const [['period','Bulan/Tahun (YYYY-MM)'],['opening','Saldo Bulan Lalu (Rp)'],['income','Penerimaan Bulan Ini (Rp)']])
    Padding(padding:const EdgeInsets.only(bottom:10),child:TextField(
      controller:inputs[row[0]],decoration:InputDecoration(labelText:row[1],border:const OutlineInputBorder()))),
   const Text('Daftar Pengeluaran',style:TextStyle(fontWeight:FontWeight.bold)),
   for(var i=0;i<expenses.length;i++)Card(child:Padding(padding:const EdgeInsets.all(10),child:Column(children:[
    TextField(controller:expenses[i]['activity'],decoration:const InputDecoration(labelText:'Kegiatan')),
    TextField(controller:expenses[i]['amount'],keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Jumlah Rp')),
    TextField(controller:expenses[i]['notes'],decoration:const InputDecoration(labelText:'Keterangan')),
    Align(alignment:Alignment.centerRight,child:IconButton(onPressed:()=>setState(()=>expenses.removeAt(i)),icon:const Icon(Icons.delete_outline))),
   ]))),
   OutlinedButton.icon(onPressed:addExpense,icon:const Icon(Icons.add),label:const Text('Tambah Baris Pengeluaran')),
  ],
  const SizedBox(height:15),
  FilledButton.icon(onPressed:busy?null:send,icon:const Icon(Icons.send_outlined),label:Text(busy?'Mengirim...':'Kirim Pengajuan')),
  const SizedBox(height:32),
 ]));
}

class CivicSealPage extends StatefulWidget {
 final CikokoApi api;final bool stampRequired;
 const CivicSealPage({super.key,required this.api,required this.stampRequired});
 @override State<CivicSealPage> createState()=>_CivicSealState();
}
class _CivicSealState extends State<CivicSealPage>{
 final pin=TextEditingController(),password=TextEditingController();String? sig,stamp;bool busy=false;
 @override void dispose(){pin.dispose();password.dispose();super.dispose();}
 Future<void> choose(bool seal)async{
  final f=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:90,maxWidth:1800);
  if(f!=null&&mounted)setState((){if(seal){stamp=f.path;}else{sig=f.path;}});
 }
 Future<void> submit()async{
  if(sig==null||(widget.stampRequired&&stamp==null))return;
  setState(()=>busy=true);
  try{
   await widget.api.upload('civic_enroll',{'pin':pin.text,'password':password.text},
    {'signature':[sig!],if(widget.stampRequired)'stamp':[stamp!]});
   if(mounted)Navigator.pop(context,true);
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  finally{if(mounted)setState(()=>busy=false);}
 }
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Tanda Tangan & Stempel')),
 body:ListView(padding:const EdgeInsets.all(15),children:[
  const Text('Berkas disimpan privat. Konfirmasi PIN diperlukan setiap persetujuan. Gambar TTD bukan tanda tangan elektronik tersertifikasi.',
   style:TextStyle(color:Colors.blueGrey,fontSize:12)),
  OutlinedButton.icon(onPressed:()=>choose(false),icon:const Icon(Icons.draw_outlined),label:Text(sig==null?'Unggah Tanda Tangan':'Tanda Tangan Dipilih')),
  if(widget.stampRequired)OutlinedButton.icon(onPressed:()=>choose(true),icon:const Icon(Icons.approval_outlined),label:Text(stamp==null?'Unggah Stempel':'Stempel Dipilih')),
  TextField(controller:pin,keyboardType:TextInputType.number,obscureText:true,maxLength:6,
   decoration:const InputDecoration(labelText:'PIN 6 angka',border:OutlineInputBorder())),
  TextField(controller:password,obscureText:true,decoration:const InputDecoration(labelText:'Password Akun',border:OutlineInputBorder())),
  const SizedBox(height:12),
  FilledButton(onPressed:busy?null:submit,child:const Text('Simpan dan Verifikasi')),
 ]));
}
class CivicDetailPage extends StatefulWidget {
 final CikokoApi api;final int id;final Map<String,dynamic>? scope;
 const CivicDetailPage({super.key,required this.api,required this.id,required this.scope});
 @override State<CivicDetailPage> createState()=>_CivicDetailState();
}
class _CivicDetailState extends State<CivicDetailPage>{
 late Future<Map<String,dynamic>> future;
 @override void initState(){super.initState();reload();}
 void reload(){future=widget.api.callWithQuery('civic_detail',{'id':widget.id.toString()});}
 bool canSign(Map d){
  final role=(widget.scope?['duty']??'').toString(),status=d['status'];
  return (status=='menunggu_rt'&&role=='rt')||(status=='menunggu_rw'&&role=='rw')||
   (status=='menunggu_ketua'&&role==(d['kind']=='lpj_rt'?'rt':'rw'))||
   (status=='menunggu_bendahara'&&role==(d['kind']=='lpj_rt'?'bendahara_rt':'bendahara_rw'))||
   (status=='menunggu_lmk'&&role=='lmk');
 }
 Future<void> act(String decision)async{
  final pin=TextEditingController(),reason=TextEditingController();
  final confirmed=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
   title:Text(decision=='approve'?'Setujui dengan TTD / Stempel':'Kembalikan untuk Perbaikan'),
   content:Column(mainAxisSize:MainAxisSize.min,children:[
    if(decision=='approve')TextField(controller:pin,obscureText:true,keyboardType:TextInputType.number,
      decoration:const InputDecoration(labelText:'PIN Persetujuan')),
    TextField(controller:reason,maxLines:2,decoration:const InputDecoration(labelText:'Catatan / Alasan')),
   ]),
   actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Batal')),
    FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Konfirmasi'))]));
  if(confirmed==true&&mounted){try{
   await widget.api.call('civic_review',body:{'id':widget.id,'decision':decision,'pin':pin.text,'notes':reason.text.trim()});
   if(mounted)setState(reload);
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}}
  pin.dispose();reason.dispose();
 }
 Future<void> pdf()async{
  try{await Printing.layoutPdf(onLayout:(_)=>widget.api.downloadPdf('civic_pdf',widget.id),name:'Cikoko-'+widget.id.toString()+'.pdf');}
  catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('PDF gagal: '+e.toString())));}
 }
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text('Dokumen #'+widget.id.toString())),
 body:FutureBuilder<Map<String,dynamic>>(future:future,builder:(ctx,s){
  if(s.hasError)return Center(child:TextButton.icon(onPressed:()=>setState(reload),icon:const Icon(Icons.refresh),label:Text(s.error.toString())));
  if(!s.hasData)return const Center(child:CircularProgressIndicator());
  final d=Map<String,dynamic>.from(s.data?['item']??{}),p=Map<String,dynamic>.from(d['payload']??{});
  final approvals=List<dynamic>.from(d['approvals']??[]);
  return ListView(padding:const EdgeInsets.all(16),children:[
   Text((d['kind']??'').toString().replaceAll('_',' ').toUpperCase(),style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800)),
   Text('Status: '+(d['status']??'').toString()+' • Revisi '+(d['revision']??'').toString()),
   Text('Pemohon: '+(d['owner_name']??'').toString()),
   Text('RT '+(d['rt']??'-').toString()+' / RW '+(d['rw']??'-').toString()),
   const Divider(),
   for(final e in p.entries)Padding(padding:const EdgeInsets.only(bottom:7),child:Text(e.key+': '+e.value.toString())),
   const Divider(),
   const Text('Persetujuan & Riwayat',style:TextStyle(fontWeight:FontWeight.w700)),
   for(final a in approvals)ListTile(leading:const Icon(Icons.fact_check_outlined),
    title:Text((a['duty']??'').toString()+' • '+(a['action']??'').toString()),
    subtitle:Text((a['created_at']??'').toString()+' '+(a['notes']??'').toString())),
   if(d['status']=='dikembalikan' &&
       (d['owner_id']??'').toString()==(widget.api.profile?['id']??'').toString())...[
      FilledButton.icon(onPressed:()async{
        final changed=await Navigator.of(context).push<bool>(MaterialPageRoute(builder:(_)=>
          CivicNewDocument(api:widget.api,kind:(d['kind']??'').toString(),
             revisionOf:widget.id,original:p)));
        if(changed==true&&mounted)setState(reload);
      },icon:const Icon(Icons.edit_note_outlined),label:const Text('Perbaiki & Kirim Ulang')),
   ],
   FilledButton.icon(onPressed:pdf,icon:const Icon(Icons.picture_as_pdf_outlined),
    label:Text(d['status']=='selesai'?'PDF Final':'Pratinjau PDF Draft')),
   if(canSign(d))...[
    FilledButton.icon(onPressed:()=>act('approve'),icon:const Icon(Icons.draw_outlined),label:const Text('Setujui & Tanda Tangan')),
    OutlinedButton.icon(onPressed:()=>act('return'),icon:const Icon(Icons.undo),label:const Text('Kembalikan untuk Revisi')),
   ],
   const SizedBox(height:50),
  ]);
 }));
}
