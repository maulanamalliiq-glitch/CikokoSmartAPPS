import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';

class CikokoPpsuLeaveHub extends StatefulWidget {
 final CikokoApi api;
 final String role;
 const CikokoPpsuLeaveHub({super.key,required this.api,required this.role});
 @override State<CikokoPpsuLeaveHub> createState()=>_LeaveState();
}
class _LeaveState extends State<CikokoPpsuLeaveHub> {
 bool loading=true;
 String? error;
 Map<String,dynamic> profile={},adminData={};
 List<dynamic> requests=[],officials=[];
 bool get admin=>widget.role=='admin'||widget.role=='admin_kelurahan';
 bool get ppsu=>widget.role=='ppsu';
 String get userId=>(widget.api.profile?['id']??'').toString();
 @override void initState(){super.initState();reload();}
 Future<void> reload()async{
  if(!mounted)return;
  setState((){loading=true;error=null;});
  try{
   if(ppsu)profile=await widget.api.call('pjlp_me');
   if(admin){
    adminData=await widget.api.call('pjlp_admin_accounts');
    officials=(await widget.api.call('pjlp_officials'))['items'] as List<dynamic>? ?? [];
   }
   requests=(await widget.api.call('pjlp_list'))['items'] as List<dynamic>? ?? [];
  }catch(e){error=cikokoFormalMessage(e);}
  if(mounted)setState(()=>loading=false);
 }
 void toast(Object message){
  if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(cikokoFormalMessage(message))));
 }
 Future<void> post(BuildContext ctx,String action,Map<String,dynamic> values)async{
  try{
   await widget.api.call(action,body:values);
   if(ctx.mounted)Navigator.of(ctx).pop();
   toast('Data berhasil disimpan');await reload();
  }catch(e){toast(e);}
 }
 String date(DateTime x)=>x.year.toString().padLeft(4,'0')+'-'+x.month.toString().padLeft(2,'0')+'-'+x.day.toString().padLeft(2,'0');
 Future<void> apply()async{
  final reason=TextEditingController(),addr=TextEditingController(),phone=TextEditingController();
  DateTimeRange? picked;
  await showDialog<void>(context:context,builder:(dialog)=>StatefulBuilder(builder:(ctx,update)=>AlertDialog(
   title:const Text('Ajukan Cuti PPSU'),
   content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
    TextField(controller:reason,maxLength:145,maxLines:2,decoration:const InputDecoration(labelText:'II. Alasan cuti')),
    ListTile(leading:const Icon(Icons.date_range),
     title:Text(picked==null?'Pilih tanggal':'Dari '+date(picked!.start)+' sampai '+date(picked!.end)),
     onTap:()async{
      final year=DateTime.now().year;
      final r=await showDateRangePicker(context:ctx,firstDate:DateTime(year-1),lastDate:DateTime(year+3));
      if(r!=null)update(()=>picked=r);
     }),
    TextField(controller:addr,maxLength:155,maxLines:2,decoration:const InputDecoration(labelText:'V. Alamat selama cuti')),
    TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Nomor telepon')),
    const Text('Jumlah hari kerja dihitung server; hari libur diatur admin.',style:TextStyle(fontSize:11)),
   ])),
   actions:[
    TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Batal')),
    FilledButton(onPressed:(){
     if(picked==null||reason.text.trim().isEmpty||addr.text.trim().isEmpty||phone.text.trim().isEmpty){toast('Lengkapi semua kolom');return;}
     post(dialog,'pjlp_apply',{'reason':reason.text,'leave_address':addr.text,
      'phone':phone.text,'start_date':date(picked!.start),'end_date':date(picked!.end)});
    },child:const Text('Kirim Pengajuan'))
   ],
  )));
  reason.dispose();addr.dispose();phone.dispose();
 }
 Future<void> employeeEditor([Map<String,dynamic>? old])async{
  final people=(adminData['accounts'] as List<dynamic>? ?? []);
  final leaders=(adminData['supervisors'] as List<dynamic>? ?? []);
  String? selected=old?['user_id']?.toString(),supervisor=old?['supervisor_user_id']?.toString();
  final phl=TextEditingController(text:(old?['id_phl']??'').toString());
  final hired=TextEditingController(text:(old?['hired_on']??'').toString());
  final position=TextEditingController(text:(old?['position_name']??'PJLP PPSU').toString());
  final unit=TextEditingController(text:(old?['work_unit']??'Kantor Kelurahan Cikoko').toString());
  await showDialog<void>(context:context,builder:(dialog)=>StatefulBuilder(builder:(ctx,update)=>AlertDialog(
   title:const Text('Data Pegawai PPSU'),
   content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
    DropdownButtonFormField<String>(isExpanded:true,
     value:people.any((e)=>e['user_id'].toString()==selected)?selected:null,
     decoration:const InputDecoration(labelText:'Pilih akun PPSU'),
     items:people.map((e)=>DropdownMenuItem<String>(value:e['user_id'].toString(),child:Text(e['name'].toString()))).toList(),
     onChanged:old==null?(v)=>update(()=>selected=v):null),
    TextField(controller:phl,decoration:const InputDecoration(labelText:'ID PHL')),
    TextField(controller:hired,decoration:const InputDecoration(labelText:'Tanggal mulai kerja YYYY-MM-DD')),
    TextField(controller:position,decoration:const InputDecoration(labelText:'Jabatan')),
    TextField(controller:unit,decoration:const InputDecoration(labelText:'Unit kerja')),
    DropdownButtonFormField<String>(isExpanded:true,
     value:leaders.any((e)=>e['user_id'].toString()==supervisor)?supervisor:null,
     decoration:const InputDecoration(labelText:'Atasan langsung'),
     items:leaders.map((e)=>DropdownMenuItem<String>(value:e['user_id'].toString(),child:Text(e['name'].toString()))).toList(),
     onChanged:(v)=>update(()=>supervisor=v))
   ])),
   actions:[
    TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Batal')),
    FilledButton(onPressed:()=>post(dialog,'pjlp_employee_save',{
     'user_id':selected,'id_phl':phl.text,'hired_on':hired.text,
     'position_name':position.text,'work_unit':unit.text,'supervisor_user_id':supervisor
    }),child:const Text('Simpan'))
   ],
  )));
  phl.dispose();hired.dispose();position.dispose();unit.dispose();
 }
 Future<void> balanceEditor(Map<String,dynamic> e)async{
  final year=TextEditingController(text:DateTime.now().year.toString());
  final allowance=TextEditingController(text:(e['allowance_days']??0).toString());
  await showDialog<void>(context:context,builder:(ctx)=>AlertDialog(
   title:Text('Jatah Cuti '+e['full_name'].toString()),
   content:Column(mainAxisSize:MainAxisSize.min,children:[
    TextField(controller:year,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Tahun')),
    TextField(controller:allowance,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Jatah hari')),
   ]),
   actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Batal')),
    FilledButton(onPressed:()=>post(ctx,'pjlp_balance_set',{
     'employee_id':e['id'],'year':int.tryParse(year.text),'allowance_days':int.tryParse(allowance.text)
    }),child:const Text('Simpan'))],
  ));
  year.dispose();allowance.dispose();
 }
 Future<void> officialEditor()async{
  final people=[...(adminData['supervisors'] as List<dynamic>? ?? []),...(adminData['lurah'] as List<dynamic>? ?? [])];
  String? person;XFile? photo;
  final name=TextEditingController(),title=TextEditingController(),nip=TextEditingController(),unit=TextEditingController(text:'Kelurahan Cikoko');
  await showDialog<void>(context:context,builder:(dialog)=>StatefulBuilder(builder:(ctx,update)=>AlertDialog(
   title:const Text('Profil Pimpinan & QR Unik'),
   content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
    DropdownButtonFormField<String>(isExpanded:true,decoration:const InputDecoration(labelText:'Akun pejabat'),
     items:people.map((e)=>DropdownMenuItem<String>(value:e['user_id'].toString(),
      child:Text(e['name'].toString()+' ('+e['role'].toString()+')'))).toList(),
     onChanged:(v)=>update(()=>person=v)),
    TextField(controller:name,decoration:const InputDecoration(labelText:'Nama pejabat')),
    TextField(controller:title,decoration:const InputDecoration(labelText:'Jabatan pada surat')),
    TextField(controller:nip,decoration:const InputDecoration(labelText:'NIP')),
    TextField(controller:unit,decoration:const InputDecoration(labelText:'Unit kerja')),
    OutlinedButton.icon(icon:const Icon(Icons.photo_camera),
     label:Text(photo==null?'Pilih Foto Pimpinan':photo!.name),
     onPressed:()async{
      final f=await ImagePicker().pickImage(source:ImageSource.gallery,maxWidth:1500,maxHeight:1500);
      if(f!=null)update(()=>photo=f);
     }),
    const Text('QR unik dibuat otomatis oleh server saat profil disimpan.',style:TextStyle(fontSize:12)),

   ])),
   actions:[
    TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Batal')),
    FilledButton(onPressed:()async{
     if(person==null||name.text.isEmpty||title.text.isEmpty||nip.text.isEmpty){toast('Lengkapi data pejabat');return;}
     String encoded='';
     if(photo!=null){
      final bytes=await photo!.readAsBytes();
      if(bytes.length>2097152){toast('Foto maksimal 2 MB');return;}
      encoded=base64Encode(bytes);
     }
     await post(dialog,'pjlp_official_save',{
      'user_id':person,'full_name':name.text,'title':title.text,'nip':nip.text,'work_unit':unit.text,'photo_base64':encoded,'is_public':true
     });
    },child:const Text('Simpan'))],
  )));
  name.dispose();title.dispose();nip.dispose();unit.dispose();
 }
 Future<void> holidayEditor()async{
  final day=TextEditingController(),desc=TextEditingController();
  await showDialog<void>(context:context,builder:(ctx)=>AlertDialog(
   title:const Text('Hari Libur'),
   content:Column(mainAxisSize:MainAxisSize.min,children:[
    TextField(controller:day,decoration:const InputDecoration(labelText:'Tanggal YYYY-MM-DD')),
    TextField(controller:desc,decoration:const InputDecoration(labelText:'Keterangan')),
   ]),
   actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Batal')),
    FilledButton(onPressed:()=>post(ctx,'pjlp_holiday_set',{'date':day.text,'description':desc.text}),child:const Text('Simpan'))],
  ));
  day.dispose();desc.dispose();
 }
 Future<void> numberEditor(Map<String,dynamic> r)async{
  final field=TextEditingController(text:(r['official_number']??'').toString());
  await showDialog<void>(context:context,builder:(ctx)=>AlertDialog(
   title:const Text('Nomor Surat Resmi'),
   content:TextField(controller:field,decoration:const InputDecoration(labelText:'Nomor sesuai tata naskah dinas')),
   actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Batal')),
    FilledButton(onPressed:()=>post(ctx,'pjlp_number_set',{
     'request_id':r['id'],'official_number':field.text}),child:const Text('Simpan'))],
  ));
  field.dispose();
 }
 Future<void> decide(Map<String,dynamic> r)async{
  String decision='approve';
  final reason=TextEditingController();
  final number=TextEditingController(text:(r['official_number']??'').toString());
  await showDialog<void>(context:context,builder:(dialog)=>StatefulBuilder(builder:(ctx,update)=>AlertDialog(
   title:Text('Persetujuan Cuti #'+r['id'].toString()),
   content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
    DropdownButtonFormField<String>(value:decision,decoration:const InputDecoration(labelText:'Keputusan Admin'),
     items:const [
      DropdownMenuItem(value:'approve',child:Text('Disetujui')),
      DropdownMenuItem(value:'revision',child:Text('Perubahan')),
      DropdownMenuItem(value:'defer',child:Text('Ditangguhkan')),
      DropdownMenuItem(value:'reject',child:Text('Ditolak')),
     ],onChanged:(v)=>update(()=>decision=v??'approve')),
    if(decision=='approve')...[
     const SizedBox(height:12),
     TextField(controller:number,decoration:const InputDecoration(
      labelText:'Nomor Surat Cuti (opsional)',hintText:'Otomatis: 35/KG 11.01',
      helperText:'Kosongkan agar nomor dibuat berurutan saat disetujui; bisa diisi manual')),
    ],
    if(decision!='approve')TextField(controller:reason,maxLines:2,
     decoration:const InputDecoration(labelText:'Alasan keputusan')),
   ])),
   actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Batal')),
    FilledButton(onPressed:()async{
     if(decision=='approve'&&number.text.trim().isNotEmpty&&!RegExp(r'^[a-zA-Z0-9./ -]{4,100}
      toast('Isi nomor surat resmi, contoh: 12/KG 11.01');return;
     }
     await post(dialog,'pjlp_review',{
      'request_id':r['id'],'decision':decision,'reason':reason.text,
      'official_number':number.text.trim()
     });
    },child:Text(decision=='approve'?'Setujui & Terbitkan PDF':'Simpan Keputusan'))],
  )));
  reason.dispose();number.dispose();
 }
 Future<void> printLetter(Map<String,dynamic> r)async{
  try{
   final uri=Uri.parse(CikokoApi.root+'?action=pjlp_pdf&id='+r['id'].toString());
   final response=await http.get(uri,headers:{
    'Authorization':'Bearer '+(widget.api.token??''),'Accept':'application/pdf'
   }).timeout(const Duration(seconds:40));
   if(response.statusCode!=200||!response.headers['content-type'].toString().contains('application/pdf'))throw ApiError('Surat PDF belum tersedia.');
   await Printing.layoutPdf(name:'Cuti-PPSU-'+r['id'].toString()+'.pdf',onLayout:(_)=>response.bodyBytes);
  }catch(e){toast(e);}
 }
 Widget employeePanel(){
  final e=profile['employee'] as Map<String,dynamic>?;
  final b=profile['balance'] as Map<String,dynamic>?;
  if(e==null)return const Card(child:ListTile(
   title:Text('Akun PPSU belum didaftarkan admin'),subtitle:Text('Minta admin mengisi ID PHL, masa kerja dan atasan langsung.')));
  int num(dynamic v)=>int.tryParse(v?.toString()??'')??0;
  final remaining=num(b?['allowance_days'])+num(b?['adjustment_days'])-num(b?['used_days'])-num(b?['held_days']);
  return Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(
   crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(e['full_name'].toString(),style:const TextStyle(fontSize:17,fontWeight:FontWeight.bold)),
    Text('ID PHL: '+e['id_phl'].toString()),
    Text('Jatah: '+(b?['allowance_days']?.toString()??'Belum diatur')+' hari'),
    Text('Terpakai: '+num(b?['used_days']).toString()+' hari; proses: '+num(b?['held_days']).toString()+' hari'),
    Text('Sisa tersedia: '+(b==null?'-':remaining.toString())+' hari'),
    const SizedBox(height:10),
    FilledButton.icon(onPressed:b==null?null:apply,icon:const Icon(Icons.add),label:const Text('Ajukan Cuti')),
   ])));
 }
 Widget adminPanel(){
  final employees=adminData['employees'] as List<dynamic>? ?? [];
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Wrap(spacing:8,runSpacing:8,children:[
    FilledButton.icon(onPressed:()=>employeeEditor(),icon:const Icon(Icons.person_add),label:const Text('Daftar PPSU')),
    OutlinedButton.icon(onPressed:officialEditor,icon:const Icon(Icons.qr_code),label:const Text('QR Pejabat')),
    OutlinedButton.icon(onPressed:holidayEditor,icon:const Icon(Icons.event),label:const Text('Hari Libur')),
   ]),
   const SizedBox(height:8),
   Text('Pegawai terdaftar: '+employees.length.toString(),style:const TextStyle(fontWeight:FontWeight.bold)),
   for(final raw in employees)
    Card(child:ListTile(
     title:Text(raw['full_name'].toString()),
     subtitle:Text('ID PHL: '+raw['id_phl'].toString()+' · Jatah: '+(raw['allowance_days']??'-').toString()),
     trailing:PopupMenuButton<String>(
      itemBuilder:(_)=>const [
       PopupMenuItem(value:'edit',child:Text('Edit Pegawai')),
       PopupMenuItem(value:'balance',child:Text('Atur Jatah Cuti')),
      ],
      onSelected:(choice){
       final r=Map<String,dynamic>.from(raw as Map);
       if(choice=='edit')employeeEditor(r);
       if(choice=='balance')balanceEditor(r);
      },
     ),
    )),
   const SizedBox(height:12),
   const Text('Direktori Profil Pimpinan & QR Unik',style:TextStyle(fontWeight:FontWeight.bold)),
   for(final raw in officials)
    Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(
     crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(raw['full_name'].toString(),style:const TextStyle(fontWeight:FontWeight.bold)),
      Text(raw['title'].toString()+' · '+raw['nip'].toString()),
      if(raw['public_token']!=null&&raw['public_token'].toString().isNotEmpty)...[
       Center(child:QrImageView(
        data:'https://datawebs.my.id/mobile-api/pjlp_profile.php?id='+raw['public_token'].toString(),
        version:QrVersions.auto,size:148)),
       TextButton.icon(icon:const Icon(Icons.open_in_browser),label:const Text('Lihat Halaman Hasil Scan'),
        onPressed:()async{
         final url=Uri.parse('https://datawebs.my.id/mobile-api/pjlp_profile.php?id='+raw['public_token'].toString());
         if(!await launchUrl(url,mode:LaunchMode.externalApplication))toast('Tidak dapat membuka profil');
        }),
      ],
     ]))),

  ]);
 }
 String statusText(String s)=>switch(s){
  'pending_admin'=>'Menunggu Admin','pending_supervisor'=>'Menunggu Admin',
  'pending_lurah'=>'Menunggu Admin','approved'=>'Disetujui',
  'revision'=>'Perubahan','deferred'=>'Ditangguhkan','rejected'=>'Ditolak',_=>s
 };
 Widget requestItem(Map<String,dynamic> r){
  final status=r['status'].toString();
  final permitted=admin&&(status=='pending_admin'||status=='pending_supervisor'||status=='pending_lurah');
  return Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(
   crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text('#'+r['id'].toString()+' · '+(r['full_name']??profile['employee']?['full_name']??'PPSU').toString(),
     style:const TextStyle(fontWeight:FontWeight.bold)),
    Text(r['start_date'].toString()+' - '+r['end_date'].toString()+' · '+r['requested_days'].toString()+' hari'),
    Text(r['reason'].toString(),maxLines:2,overflow:TextOverflow.ellipsis),
    Text(statusText(status),style:const TextStyle(color:Colors.blue,fontWeight:FontWeight.bold)),
    Wrap(spacing:8,children:[
     if(permitted)TextButton.icon(onPressed:()=>decide(r),icon:const Icon(Icons.fact_check),label:const Text('Keputusan')),
     if(admin&&(status=='pending_admin'||status=='pending_supervisor'||status=='pending_lurah'))TextButton.icon(onPressed:()=>numberEditor(r),icon:const Icon(Icons.tag),label:const Text('Nomor Surat')),
     if(status=='approved')TextButton.icon(onPressed:()=>printLetter(r),icon:const Icon(Icons.print),label:const Text('Cetak PDF')),
    ])
   ])));
 }
 @override Widget build(BuildContext context)=>RefreshIndicator(onRefresh:reload,child:ListView(
  padding:const EdgeInsets.all(14),children:[
   const Text('CUTI PJLP / PPSU',style:TextStyle(fontWeight:FontWeight.bold,fontSize:21,color:Color(0xFF155997))),
   const Text('Kelurahan Cikoko · Kecamatan Pancoran'),
   const SizedBox(height:12),
   if(loading)const Center(child:CircularProgressIndicator()),
   if(error!=null)Card(child:ListTile(title:Text(error!),subtitle:const Text('Pastikan backend PHP dan database telah dipasang'),
    trailing:IconButton(onPressed:reload,icon:const Icon(Icons.refresh)))),
   if(!loading&&error==null)...[
    if(ppsu)employeePanel(),
    if(admin)adminPanel(),
    Text('Riwayat / Pengajuan ('+requests.length.toString()+')',
     style:const TextStyle(fontWeight:FontWeight.bold,fontSize:16)),
    if(requests.isEmpty)const Card(child:ListTile(title:Text('Belum ada pengajuan'))),
    for(final r in requests)requestItem(Map<String,dynamic>.from(r as Map)),
   ],
   const SizedBox(height:25),
   const Text('QR tetap dari admin bukan TTE tersertifikasi.',
    style:TextStyle(color:Colors.blueGrey,fontSize:11)),
  ],
 ));
}
).hasMatch(number.text.trim())){
      toast('Isi nomor surat resmi, contoh: 12/KG 11.01');return;
     }
     await post(dialog,'pjlp_review',{
      'request_id':r['id'],'decision':decision,'reason':reason.text,
      'official_number':number.text.trim()
     });
    },child:Text(decision=='approve'?'Setujui & Terbitkan PDF':'Simpan Keputusan'))],
  )));
  reason.dispose();number.dispose();
 }
 Future<void> printLetter(Map<String,dynamic> r)async{
  try{
   final uri=Uri.parse(CikokoApi.root+'?action=pjlp_pdf&id='+r['id'].toString());
   final response=await http.get(uri,headers:{
    'Authorization':'Bearer '+(widget.api.token??''),'Accept':'application/pdf'
   }).timeout(const Duration(seconds:40));
   if(response.statusCode!=200||!response.headers['content-type'].toString().contains('application/pdf'))throw ApiError('Surat PDF belum tersedia.');
   await Printing.layoutPdf(name:'Cuti-PPSU-'+r['id'].toString()+'.pdf',onLayout:(_)=>response.bodyBytes);
  }catch(e){toast(e);}
 }
 Widget employeePanel(){
  final e=profile['employee'] as Map<String,dynamic>?;
  final b=profile['balance'] as Map<String,dynamic>?;
  if(e==null)return const Card(child:ListTile(
   title:Text('Akun PPSU belum didaftarkan admin'),subtitle:Text('Minta admin mengisi ID PHL, masa kerja dan atasan langsung.')));
  int num(dynamic v)=>int.tryParse(v?.toString()??'')??0;
  final remaining=num(b?['allowance_days'])+num(b?['adjustment_days'])-num(b?['used_days'])-num(b?['held_days']);
  return Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(
   crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(e['full_name'].toString(),style:const TextStyle(fontSize:17,fontWeight:FontWeight.bold)),
    Text('ID PHL: '+e['id_phl'].toString()),
    Text('Jatah: '+(b?['allowance_days']?.toString()??'Belum diatur')+' hari'),
    Text('Terpakai: '+num(b?['used_days']).toString()+' hari; proses: '+num(b?['held_days']).toString()+' hari'),
    Text('Sisa tersedia: '+(b==null?'-':remaining.toString())+' hari'),
    const SizedBox(height:10),
    FilledButton.icon(onPressed:b==null?null:apply,icon:const Icon(Icons.add),label:const Text('Ajukan Cuti')),
   ])));
 }
 Widget adminPanel(){
  final employees=adminData['employees'] as List<dynamic>? ?? [];
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Wrap(spacing:8,runSpacing:8,children:[
    FilledButton.icon(onPressed:()=>employeeEditor(),icon:const Icon(Icons.person_add),label:const Text('Daftar PPSU')),
    OutlinedButton.icon(onPressed:officialEditor,icon:const Icon(Icons.qr_code),label:const Text('QR Pejabat')),
    OutlinedButton.icon(onPressed:holidayEditor,icon:const Icon(Icons.event),label:const Text('Hari Libur')),
   ]),
   const SizedBox(height:8),
   Text('Pegawai terdaftar: '+employees.length.toString(),style:const TextStyle(fontWeight:FontWeight.bold)),
   for(final raw in employees)
    Card(child:ListTile(
     title:Text(raw['full_name'].toString()),
     subtitle:Text('ID PHL: '+raw['id_phl'].toString()+' · Jatah: '+(raw['allowance_days']??'-').toString()),
     trailing:PopupMenuButton<String>(
      itemBuilder:(_)=>const [
       PopupMenuItem(value:'edit',child:Text('Edit Pegawai')),
       PopupMenuItem(value:'balance',child:Text('Atur Jatah Cuti')),
      ],
      onSelected:(choice){
       final r=Map<String,dynamic>.from(raw as Map);
       if(choice=='edit')employeeEditor(r);
       if(choice=='balance')balanceEditor(r);
      },
     ),
    )),
   const SizedBox(height:12),
   const Text('Direktori Profil Pimpinan & QR Unik',style:TextStyle(fontWeight:FontWeight.bold)),
   for(final raw in officials)
    Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(
     crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(raw['full_name'].toString(),style:const TextStyle(fontWeight:FontWeight.bold)),
      Text(raw['title'].toString()+' · '+raw['nip'].toString()),
      if(raw['public_token']!=null&&raw['public_token'].toString().isNotEmpty)...[
       Center(child:QrImageView(
        data:'https://datawebs.my.id/mobile-api/pjlp_profile.php?id='+raw['public_token'].toString(),
        version:QrVersions.auto,size:148)),
       TextButton.icon(icon:const Icon(Icons.open_in_browser),label:const Text('Lihat Halaman Hasil Scan'),
        onPressed:()async{
         final url=Uri.parse('https://datawebs.my.id/mobile-api/pjlp_profile.php?id='+raw['public_token'].toString());
         if(!await launchUrl(url,mode:LaunchMode.externalApplication))toast('Tidak dapat membuka profil');
        }),
      ],
     ]))),

  ]);
 }
 String statusText(String s)=>switch(s){
  'pending_admin'=>'Menunggu Admin','pending_supervisor'=>'Menunggu Admin',
  'pending_lurah'=>'Menunggu Admin','approved'=>'Disetujui',
  'revision'=>'Perubahan','deferred'=>'Ditangguhkan','rejected'=>'Ditolak',_=>s
 };
 Widget requestItem(Map<String,dynamic> r){
  final status=r['status'].toString();
  final permitted=admin&&(status=='pending_admin'||status=='pending_supervisor'||status=='pending_lurah');
  return Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(
   crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text('#'+r['id'].toString()+' · '+(r['full_name']??profile['employee']?['full_name']??'PPSU').toString(),
     style:const TextStyle(fontWeight:FontWeight.bold)),
    Text(r['start_date'].toString()+' - '+r['end_date'].toString()+' · '+r['requested_days'].toString()+' hari'),
    Text(r['reason'].toString(),maxLines:2,overflow:TextOverflow.ellipsis),
    Text(statusText(status),style:const TextStyle(color:Colors.blue,fontWeight:FontWeight.bold)),
    Wrap(spacing:8,children:[
     if(permitted)TextButton.icon(onPressed:()=>decide(r),icon:const Icon(Icons.fact_check),label:const Text('Keputusan')),
     if(admin&&(status=='pending_admin'||status=='pending_supervisor'||status=='pending_lurah'))TextButton.icon(onPressed:()=>numberEditor(r),icon:const Icon(Icons.tag),label:const Text('Nomor Surat')),
     if(status=='approved')TextButton.icon(onPressed:()=>printLetter(r),icon:const Icon(Icons.print),label:const Text('Cetak PDF')),
    ])
   ])));
 }
 @override Widget build(BuildContext context)=>RefreshIndicator(onRefresh:reload,child:ListView(
  padding:const EdgeInsets.all(14),children:[
   const Text('CUTI PJLP / PPSU',style:TextStyle(fontWeight:FontWeight.bold,fontSize:21,color:Color(0xFF155997))),
   const Text('Kelurahan Cikoko · Kecamatan Pancoran'),
   const SizedBox(height:12),
   if(loading)const Center(child:CircularProgressIndicator()),
   if(error!=null)Card(child:ListTile(title:Text(error!),subtitle:const Text('Pastikan backend PHP dan database telah dipasang'),
    trailing:IconButton(onPressed:reload,icon:const Icon(Icons.refresh)))),
   if(!loading&&error==null)...[
    if(ppsu)employeePanel(),
    if(admin)adminPanel(),
    Text('Riwayat / Pengajuan ('+requests.length.toString()+')',
     style:const TextStyle(fontWeight:FontWeight.bold,fontSize:16)),
    if(requests.isEmpty)const Card(child:ListTile(title:Text('Belum ada pengajuan'))),
    for(final r in requests)requestItem(Map<String,dynamic>.from(r as Map)),
   ],
   const SizedBox(height:25),
   const Text('QR tetap dari admin bukan TTE tersertifikasi.',
    style:TextStyle(color:Colors.blueGrey,fontSize:11)),
  ],
 ));
}
