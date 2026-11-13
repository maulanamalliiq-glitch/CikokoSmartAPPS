import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'api.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CikokoPppkPerformancePage extends StatefulWidget {
 final CikokoApi api;
 final String role;
 const CikokoPppkPerformancePage({super.key,required this.api,required this.role});
 @override State<CikokoPppkPerformancePage> createState()=>_PppkState();
}
class _PppkState extends State<CikokoPppkPerformancePage> {
 static const titles=<String>[
 'Laporan hasil peninjauan lapangan terkait laporan/pengaduan masyarakat dalam mendukung pekerjaan yang perlu segera ditindaklanjuti karena mengganggu kepentingan publik/masyarakat',
 'Dokumen administrasi aktivitas/pekerjaan PPSU di tingkat Kelurahan',
 'Dokumen basis data yang diperlukan dalam percepatan proses pengelolaan administrasi kelurahan yang berorientasi pada pelayanan masyarakat',
 'Laporan pelaksanaan tugas-tugas kedinasan lainnya yang diberikan oleh pimpinan',
 ];
 bool busy=false;List<dynamic> reports=[];
 bool get admin=>widget.role=='admin'||widget.role=='admin_kelurahan';
 String get currentMonth{final d=DateTime.now();return '${d.year}-${d.month.toString().padLeft(2,'0')}';}
 @override void initState(){super.initState();refresh();}
 void notify(Object e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(cikokoFormalMessage(e))));}
 Future<void> refresh()async{
  setState(()=>busy=true);
  try{final r=await widget.api.call('pppk_list');if(mounted)setState(()=>reports=r['items'] as List<dynamic>? ?? []);}
  catch(e){notify(e);}finally{if(mounted)setState(()=>busy=false);}
 }
 Future<void> review(Map<String,dynamic> report,bool approve)async{
  final note=TextEditingController();
  final yes=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
   title:Text(approve?'Setujui laporan?':'Tolak laporan?'),
   content:Column(mainAxisSize:MainAxisSize.min,children:[
    Text('Laporan ${report['employee_name']} — ${report['report_month']}'),
    TextField(controller:note,maxLines:2,decoration:InputDecoration(labelText:approve?'Catatan (opsional)':'Alasan penolakan')),
   ]),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Batal')),
    FilledButton(onPressed:()=>Navigator.pop(c,true),child:Text(approve?'Setujui':'Tolak'))],
  ));
  if(yes==true){
   try{await widget.api.call('pppk_review',body:{'id':report['id'],'decision':approve?'approved':'rejected','note':note.text});notify('Keputusan berhasil disimpan');await refresh();}
   catch(e){notify(e);}
  }
  note.dispose();
 }
 Future<void> openReport([Map<String,dynamic>? row])async{
  final month=row?['report_month']?.toString()??currentMonth;
  Map<String,dynamic>? detail;
  if(row!=null){
   try{detail=(await widget.api.callWithQuery('pppk_detail',{'id':'${row['id']}'}))['report'] as Map<String,dynamic>?;}
   catch(e){notify(e);return;}
  }
  if(!mounted)return;
  await Navigator.push(context,MaterialPageRoute(builder:(_)=>_PppkEditor(api:widget.api,month:month,report:detail,admin:admin)));
  await refresh();
 }
 static const navy=Color(0xff14345c);
 static const blue=Color(0xff1768cc);
 String statusLabel(String v)=>switch(v){
  'approved'=>'Disetujui','pending_admin'=>'Menunggu Persetujuan',
  'rejected'=>'Perlu Perbaikan',_=>'Draf',
 };
 Color statusColor(String v)=>switch(v){
  'approved'=>const Color(0xff18794e),'pending_admin'=>const Color(0xffa3680b),
  'rejected'=>const Color(0xffbd4040),_=>const Color(0xff63748a),
 };
 @override Widget build(BuildContext context){
  final pending=reports.where((e)=>e['status']=='pending_admin').length;
  final approved=reports.where((e)=>e['status']=='approved').length;
  return Scaffold(
   backgroundColor:const Color(0xfff3f6fb),
   appBar:AppBar(title:Text(admin?'Verifikasi Kinerja PPPK':'Kinerja Bulanan PPPK'),backgroundColor:Colors.white),
   floatingActionButton:admin?null:FloatingActionButton.extended(
    backgroundColor:blue,foregroundColor:Colors.white,onPressed:()=>openReport(),
    icon:const Icon(Icons.add_rounded),label:const Text('Buat Laporan')),
   body:RefreshIndicator(onRefresh:refresh,child:ListView(padding:const EdgeInsets.all(16),children:[
    Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(
     gradient:const LinearGradient(colors:[navy,Color(0xff246fc4)]),
     borderRadius:BorderRadius.circular(20)),
     child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Icon(Icons.assessment_outlined,color:Colors.white,size:32),
      const SizedBox(height:14),
      Text(admin?'Panel Persetujuan PPPK':'Laporan Kinerja Bulanan',
       style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold,fontSize:21)),
      const SizedBox(height:6),
      Text(admin?'Periksa dokumentasi dan setujui laporan pegawai.':
       'Dokumentasikan 4 kegiatan, 2 periode setiap bulan.',
       style:const TextStyle(color:Color(0xffdcecff))),
      const SizedBox(height:18),
      Row(children:[
       _summaryChip('Total',reports.length.toString()),
       const SizedBox(width:8),_summaryChip('Menunggu',pending.toString()),
       const SizedBox(width:8),_summaryChip('Disetujui',approved.toString()),
      ]),
     ])),
    const SizedBox(height:22),
    Row(children:[
     const Expanded(child:Text('Daftar Laporan',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800,color:navy))),
     IconButton(tooltip:'Muat ulang',onPressed:refresh,icon:const Icon(Icons.refresh)),
    ]),
    if(busy)const LinearProgressIndicator(),
    if(reports.isEmpty&&!busy)Container(
     padding:const EdgeInsets.symmetric(vertical:40,horizontal:24),
     decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16)),
     child:Column(children:[
      const Icon(Icons.description_outlined,size:54,color:Color(0xff8fa3bd)),
      const SizedBox(height:12),
      const Text('Belum ada laporan',style:TextStyle(fontSize:17,fontWeight:FontWeight.bold)),
      const SizedBox(height:6),
      Text(admin?'Belum ada laporan PPPK untuk ditinjau.':'Tekan Buat Laporan untuk mulai mengisi kegiatan bulan ini.',textAlign:TextAlign.center),
     ])),
    for(final item in reports)Container(
     margin:const EdgeInsets.only(bottom:12),decoration:BoxDecoration(
      color:Colors.white,borderRadius:BorderRadius.circular(16),
      border:Border.all(color:const Color(0xffe4ebf4))),
     child:Column(children:[
      ListTile(contentPadding:const EdgeInsets.fromLTRB(16,12,12,8),
       leading:Container(padding:const EdgeInsets.all(10),
        decoration:BoxDecoration(color:const Color(0xffe9f2ff),borderRadius:BorderRadius.circular(12)),
        child:const Icon(Icons.article_outlined,color:blue)),
       title:Text('${item['employee_name']}',style:const TextStyle(fontWeight:FontWeight.w700,color:navy)),
       subtitle:Padding(padding:const EdgeInsets.only(top:5),child:Text('Periode ${item['report_month']}')),
       trailing:const Icon(Icons.chevron_right_rounded),
       onTap:()=>openReport(Map<String,dynamic>.from(item))),
      Padding(padding:const EdgeInsets.fromLTRB(16,0,16,12),child:Align(
       alignment:Alignment.centerLeft,child:Container(
        padding:const EdgeInsets.symmetric(horizontal:12,vertical:6),
        decoration:BoxDecoration(color:statusColor('${item['status']}').withValues(alpha:.10),borderRadius:BorderRadius.circular(20)),
        child:Text(statusLabel('${item['status']}'),
         style:TextStyle(color:statusColor('${item['status']}'),fontWeight:FontWeight.w700,fontSize:12))))),
      if(admin&&item['status']=='pending_admin')
       Padding(padding:const EdgeInsets.fromLTRB(12,0,12,12),child:Row(children:[
        Expanded(child:OutlinedButton.icon(onPressed:()=>review(Map<String,dynamic>.from(item),false),
         icon:const Icon(Icons.close_rounded),label:const Text('Tolak'))),
        const SizedBox(width:8),
        Expanded(child:FilledButton.icon(onPressed:()=>review(Map<String,dynamic>.from(item),true),
         icon:const Icon(Icons.check_rounded),label:const Text('Setujui'))),
       ])),
     ])),
    const SizedBox(height:100),
   ])),
  );
 }
 Widget _summaryChip(String label,String value)=>Expanded(child:Container(
  padding:const EdgeInsets.symmetric(vertical:10,horizontal:8),
  decoration:BoxDecoration(color:Colors.white.withValues(alpha:.14),borderRadius:BorderRadius.circular(12)),
  child:Column(children:[Text(value,style:const TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.bold)),
   Text(label,style:const TextStyle(color:Colors.white,fontSize:11))]),
  ));

}
class _PppkEditor extends StatefulWidget {
 final CikokoApi api;final String month;final Map<String,dynamic>? report;final bool admin;
 const _PppkEditor({required this.api,required this.month,required this.report,required this.admin});
 @override State<_PppkEditor> createState()=>_PppkEditorState();
}
class _PppkEditorState extends State<_PppkEditor>{
 late final TextEditingController name,nip;
 late final List<List<TextEditingController>> descriptions;
 late String month;int? id;late String status;bool busy=false;
 final Map<String,Uint8List> photos={};
 final Set<String> stored={};
 bool get editable=>!widget.admin&&(status=='draft'||status=='rejected');
 @override void initState(){
  super.initState();final r=widget.report;id=r?['id'] as int?;month=widget.month;status='${r?['status']??'draft'}';
  name=TextEditingController(text:'${r?['employee_name']??widget.api.profile?['name']??widget.api.profile?['full_name']??''}');
  nip=TextEditingController(text:'${r?['employee_nip']??widget.api.profile?['nip']??''}');
  final data=r?['payload'] as List<dynamic>? ?? [];
  descriptions=List.generate(4,(i)=>List.generate(2,(j)=>TextEditingController(text:i<data.length?'${(data[i] as Map)['period${j+1}']??''}':'')));
  for(final p in r?['photos'] as List<dynamic>? ?? []){
   stored.add('${p['section_no']}-${p['period_no']}');
  }
 }
 @override void dispose(){name.dispose();nip.dispose();for(final a in descriptions){for(final c in a){c.dispose();}}super.dispose();}
 Future<void> save()async{
  if(!editable)return;
  setState(()=>busy=true);
  try{
   final r=await widget.api.call('pppk_save',body:{
    'month':month,'name':name.text,'nip':nip.text,
    'sections':[for(final row in descriptions){'period1':row[0].text,'period2':row[1].text}],
   });
   id=r['id'] as int;
   for(final entry in photos.entries){
    final bits=entry.key.split('-');
    await widget.api.call('pppk_upload',body:{
     'id':id,'section':int.parse(bits[0]),'period':int.parse(bits[1]),'image_base64':base64Encode(entry.value),
    });
    stored.add(entry.key);
   }
   photos.clear();notify('Draf berhasil disimpan');
  }catch(e){notify(e);}finally{if(mounted)setState(()=>busy=false);}
 }
 void notify(Object e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(cikokoFormalMessage(e))));}
 Future<void> pick(int i,int j)async{
  final x=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:75,maxWidth:1400);
  if(x==null)return;
  final bytes=await x.readAsBytes();
  if(bytes.length>3500000){notify('Foto maksimal 3,5 MB');return;}
  setState(()=>photos['${i+1}-${j+1}']=bytes);
 }
 Future<void> printReport()async{
  if(id==null)return;
  setState(()=>busy=true);
  try{
   final data=(await widget.api.callWithQuery('pppk_detail',{'id':'$id'}))['report'] as Map<String,dynamic>;
   final entries=data['payload'] as List<dynamic>? ?? [];
   final uploaded=data['photos'] as List<dynamic>? ?? [];
   final images=<String,pw.MemoryImage>{};
   for(final item in uploaded){
    final key='${item['section_no']}-${item['period_no']}';
    final url=Uri.parse('${CikokoApi.root}?action=pppk_photo&id=$id&section=${item['section_no']}&period=${item['period_no']}');
    final response=await http.get(url,headers:{'Authorization':'Bearer ${widget.api.token}'});
    if(response.statusCode==200)images[key]=pw.MemoryImage(response.bodyBytes);
   }
   final approved=data['status']=='approved';
   final token='${data['approved_token']??''}';
   final pdf=pw.Document();
   final regular=pw.Font.helvetica();
   final bold=pw.Font.helveticaBold();
   pw.Text tx(String text,{double size=8,bool strong=false})=>pw.Text(text,style:pw.TextStyle(font:strong?bold:regular,fontSize:size));
   pdf.addPage(pw.Page(pageFormat:PdfPageFormat.a4,margin:const pw.EdgeInsets.all(14),
    build:(ctx)=>pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[
     tx('KELURAHAN CIKOKO - JAYA RAYA',size:13,strong:true),
     tx('Laporan Kinerja PPPK ${data['month']} - ${data['employee_name']}',size:9),
     tx('Tanggal cetak: ${DateTime.now().toIso8601String().substring(0,10)} | NIP/No. pegawai: ${data['employee_nip']}',size:8),
     pw.Divider(color:PdfColors.teal700),
     for(var i=0;i<4;i++)pw.Container(
      decoration:pw.BoxDecoration(border:pw.Border.all(color:PdfColors.grey400)),
      padding:const pw.EdgeInsets.all(6),
      child:pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[
       tx(_PppkState.titles[i],size:8,strong:true),
       pw.SizedBox(height:4),
       pw.Row(children:[for(var j=0;j<2;j++)pw.Expanded(child:pw.Padding(
        padding:pw.EdgeInsets.only(right:j==0?6:0),
        child:pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[
         pw.Container(height:104,width:double.infinity,
          decoration:pw.BoxDecoration(border:pw.Border.all(color:PdfColors.grey400)),
          child:pw.Column(children:[
           pw.Align(alignment:pw.Alignment.centerLeft,child:tx('Periode ${j+1}',size:7,strong:true)),
           pw.Expanded(child:images.containsKey('${i+1}-${j+1}')
            ?pw.Image(images['${i+1}-${j+1}']!,fit:pw.BoxFit.contain)
            :pw.Center(child:tx('Belum ada foto',size:7))),
          ])),
         pw.SizedBox(height:4),
         tx(i<entries.length?'${(entries[i] as Map)['period${j+1}']??''}':'Keterangan belum diisi',size:7),
        ]),
       ))]),
      ]),
     ),
     pw.Spacer(),
     pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween,children:[
      tx('Sumber: Laporan kinerja website Cikoko (data tersimpan).',size:7),
      tx('A4 | Halaman 1/1',size:7),
     ]),
     pw.SizedBox(height:8),
     pw.Align(alignment:pw.Alignment.centerRight,child:pw.Column(children:[
      tx('Kasi Ekonomi dan Pembangunan',size:8),
      pw.SizedBox(height:3),
      if(approved&&token.length==48)
       pw.BarcodeWidget(barcode:pw.Barcode.qrCode(),data:'https://datawebs.my.id/mobile-api/pppk_verify.php?token=$token',width:60,height:60)
      else pw.SizedBox(height:60,child:pw.Center(child:tx('Menunggu persetujuan Admin',size:7))),
      tx('Desi Andriyani',size:8,strong:true),
      tx('NIP 198712292010012024',size:7),
     ])),
    ])));
   await Printing.layoutPdf(onLayout:(_)=>pdf.save(),name:'Kinerja-PPPK-${data['month']}.pdf');
  }catch(e){notify(e);}finally{if(mounted)setState(()=>busy=false);}
 }
 Future<void> submit()async{
  await save();if(id==null||photos.isNotEmpty)return;
  try{await widget.api.call('pppk_submit',body:{'id':id});notify('Laporan dikirim untuk persetujuan Admin');if(mounted)Navigator.pop(context);}
  catch(e){notify(e);}
 }
 static const navy=Color(0xff14345c);
 static const blue=Color(0xff1768cc);
 @override Widget build(BuildContext context){
  final completed=List.generate(4,(i)=>List.generate(2,(j){
   final key='${i+1}-${j+1}';
   return descriptions[i][j].text.trim().isNotEmpty&&(stored.contains(key)||photos.containsKey(key));
  }).where((v)=>v).length).fold<int>(0,(a,b)=>a+b);
  return Scaffold(
   backgroundColor:const Color(0xfff3f6fb),
   appBar:AppBar(title:Text('Laporan PPPK $month'),backgroundColor:Colors.white),
   body:ListView(padding:const EdgeInsets.all(16),children:[
    Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(
     gradient:const LinearGradient(colors:[navy,Color(0xff236dbd)]),borderRadius:BorderRadius.circular(18)),
     child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('LAPORAN KINERJA BULANAN',style:TextStyle(color:Color(0xffcfe2ff),fontSize:11,fontWeight:FontWeight.bold,letterSpacing:1.3)),
      const SizedBox(height:6),
      Text(month,style:const TextStyle(color:Colors.white,fontSize:25,fontWeight:FontWeight.w800)),
      const SizedBox(height:10),
      Text('Status: $status',style:const TextStyle(color:Colors.white)),
      const SizedBox(height:12),
      ClipRRect(borderRadius:BorderRadius.circular(6),child:LinearProgressIndicator(
       value:completed/8,minHeight:8,backgroundColor:Colors.white24,valueColor:const AlwaysStoppedAnimation<Color>(Color(0xff8ce0b5)))),
      const SizedBox(height:8),
      Text('$completed dari 8 dokumentasi lengkap',style:const TextStyle(color:Colors.white,fontSize:12)),
     ])),
    const SizedBox(height:16),
    if(status=='approved')const Card(child:Padding(padding:EdgeInsets.all(14),
     child:Row(children:[Icon(Icons.verified,color:Colors.green),SizedBox(width:10),
      Expanded(child:Text('Disetujui Admin. QR verifikasi tersedia pada PDF resmi.'))]))),
    if(status=='rejected')const Card(child:Padding(padding:EdgeInsets.all(14),
     child:Text('Laporan dikembalikan. Perbaiki dokumentasi, lalu kirim kembali.'))),
    Card(color:Colors.white,child:Padding(padding:const EdgeInsets.all(16),child:Column(
     crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Row(children:[Icon(Icons.badge_outlined,color:blue),SizedBox(width:8),
       Text('Identitas Pegawai',style:TextStyle(fontWeight:FontWeight.w800,color:navy,fontSize:16))]),
      const SizedBox(height:12),
      if(editable)ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.calendar_month,color:blue),
       title:Text('Bulan laporan: $month'),subtitle:const Text('Pilih bulan laporan'),
       onTap:()async{
        final initial=DateTime(int.parse(month.substring(0,4)),int.parse(month.substring(5,7)));
        final chosen=await showDatePicker(context:context,initialDate:initial,firstDate:DateTime(2025),
         lastDate:DateTime(DateTime.now().year+1,12),initialDatePickerMode:DatePickerMode.year);
        if(chosen!=null&&mounted)setState(()=>month='${chosen.year}-${chosen.month.toString().padLeft(2,'0')}');
       }),
      TextField(controller:name,readOnly:!editable,decoration:const InputDecoration(
       labelText:'Nama lengkap',prefixIcon:Icon(Icons.person_outline),border:OutlineInputBorder())),
      const SizedBox(height:12),
      TextField(controller:nip,readOnly:!editable,decoration:const InputDecoration(
       labelText:'NIP / No. Pegawai',prefixIcon:Icon(Icons.numbers),border:OutlineInputBorder())),
     ]))),
    const SizedBox(height:12),
    for(var i=0;i<4;i++)Container(
     margin:const EdgeInsets.only(bottom:14),
     decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16),
      border:Border.all(color:const Color(0xffdce6f3))),
     child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Container(width:double.infinity,padding:const EdgeInsets.all(14),
       decoration:const BoxDecoration(color:Color(0xffeaf2ff),borderRadius:BorderRadius.vertical(top:Radius.circular(16))),
       child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('KEGIATAN ${i+1} / 4',style:const TextStyle(color:blue,fontWeight:FontWeight.bold,fontSize:11,letterSpacing:1)),
        const SizedBox(height:6),
        Text(_PppkState.titles[i],style:const TextStyle(fontWeight:FontWeight.w700,color:navy)),
       ])),
      for(var j=0;j<2;j++)Padding(
       padding:const EdgeInsets.fromLTRB(14,12,14,10),
       child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[
         Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),
          decoration:BoxDecoration(color:const Color(0xffe8f6ef),borderRadius:BorderRadius.circular(8)),
          child:Text('Periode ${j+1}',style:const TextStyle(fontWeight:FontWeight.w700,color:Color(0xff17744b)))),
         const Spacer(),
         if(stored.contains('${i+1}-${j+1}'))const Icon(Icons.cloud_done,color:Color(0xff178154),size:20),
        ]),
        const SizedBox(height:10),
        Container(height:150,width:double.infinity,
         decoration:BoxDecoration(color:const Color(0xfff6f8fc),
          borderRadius:BorderRadius.circular(12),border:Border.all(color:const Color(0xffdce6f3))),
         child:photos.containsKey('${i+1}-${j+1}')
          ?ClipRRect(borderRadius:BorderRadius.circular(12),
            child:Image.memory(photos['${i+1}-${j+1}']!,fit:BoxFit.contain))
          :Column(mainAxisAlignment:MainAxisAlignment.center,children:[
           Icon(stored.contains('${i+1}-${j+1}')?Icons.check_circle_outline:Icons.add_photo_alternate_outlined,
            color:const Color(0xff7291b3),size:34),
           const SizedBox(height:6),
           Text(stored.contains('${i+1}-${j+1}')?'Foto sudah tersimpan':'Belum ada foto',
            style:const TextStyle(color:Color(0xff657c96))),
          ])),
        if(editable)Align(alignment:Alignment.centerRight,child:TextButton.icon(
         onPressed:()=>pick(i,j),icon:const Icon(Icons.photo_library_outlined),
         label:Text(stored.contains('${i+1}-${j+1}')?'Ganti Foto':'Unggah Foto'))),
        const SizedBox(height:8),
        TextField(controller:descriptions[i][j],readOnly:!editable,maxLines:2,
         onChanged:(_)=>setState((){}),
         decoration:const InputDecoration(labelText:'Keterangan / hasil kegiatan',
          hintText:'Tuliskan hasil pekerjaan pada periode ini',border:OutlineInputBorder())),
       ])),
     ])),
    const SizedBox(height:4),
    if(id!=null)OutlinedButton.icon(onPressed:busy?null:printReport,
     icon:const Icon(Icons.picture_as_pdf_outlined),label:const Text('Pratinjau & Cetak PDF A4')),
    if(editable)...[
     const SizedBox(height:8),
     FilledButton.icon(onPressed:busy?null:save,icon:const Icon(Icons.save_outlined),
      label:const Text('Simpan Draf')),
     const SizedBox(height:8),
     FilledButton.icon(onPressed:busy?null:submit,icon:const Icon(Icons.send_outlined),
      label:const Text('Kirim ke Admin')),
    ],
    if(busy)const Padding(padding:EdgeInsets.all(12),child:LinearProgressIndicator()),
    const SizedBox(height:60),
   ]),
  );
 }

}
