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
 @override Widget build(BuildContext context)=>Scaffold(
  appBar:AppBar(title:Text(admin?'Persetujuan Kinerja PPPK':'Kinerja Bulanan PPPK')),
  floatingActionButton:admin?null:FloatingActionButton.extended(onPressed:()=>openReport(),icon:const Icon(Icons.add),label:const Text('Isi Bulan Ini')),
  body:RefreshIndicator(onRefresh:refresh,child:ListView(padding:const EdgeInsets.all(14),children:[
   const Card(child:Padding(padding:EdgeInsets.all(14),child:Text('Laporan kinerja bulanan: empat kegiatan, masing-masing Periode 1 dan Periode 2. QR Kasi Ekonomi dan Pembangunan hanya muncul setelah persetujuan Admin.'))),
   if(busy)const LinearProgressIndicator(),
   if(reports.isEmpty&&!busy)const Padding(padding:EdgeInsets.all(20),child:Text('Belum ada laporan kinerja.')),
   for(final item in reports)
    Card(child:ListTile(
     title:Text('${item['employee_name']} — ${item['report_month']}'),
     subtitle:Text('Status: ${item['status']}${item['review_note']!=null&&'${item['review_note']}'.isNotEmpty?' • ${item['review_note']}':''}'),
     trailing:const Icon(Icons.chevron_right),onTap:()=>openReport(Map<String,dynamic>.from(item)),
    )),
   if(admin)for(final item in reports)
    if(item['status']=='pending_admin')
     Padding(padding:const EdgeInsets.only(bottom:10),child:Row(children:[
      Expanded(child:OutlinedButton(onPressed:()=>review(Map<String,dynamic>.from(item),false),child:const Text('Tolak'))),
      const SizedBox(width:8),
      Expanded(child:FilledButton(onPressed:()=>review(Map<String,dynamic>.from(item),true),child:const Text('Setujui'))),
     ])),
   const SizedBox(height:80),
  ])),
 );
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
    ]),
   ])));
   await Printing.layoutPdf(onLayout:(_)=>pdf.save(),name:'Kinerja-PPPK-${data['month']}.pdf');
  }catch(e){notify(e);}finally{if(mounted)setState(()=>busy=false);}
 }
 Future<void> submit()async{
  await save();if(id==null||photos.isNotEmpty)return;
  try{await widget.api.call('pppk_submit',body:{'id':id});notify('Laporan dikirim untuk persetujuan Admin');if(mounted)Navigator.pop(context);}
  catch(e){notify(e);}
 }
 @override Widget build(BuildContext context)=>Scaffold(
  appBar:AppBar(title:Text('Laporan PPPK $month')),
  body:ListView(padding:const EdgeInsets.all(12),children:[
   Text('Status: $status',style:Theme.of(context).textTheme.titleMedium),
   if(editable)ListTile(leading:const Icon(Icons.calendar_month),title:Text('Bulan laporan: $month'),subtitle:const Text('Ketuk untuk memilih bulan'),onTap:()async{
    final initial=DateTime(int.parse(month.substring(0,4)),int.parse(month.substring(5,7)));
    final chosen=await showDatePicker(context:context,initialDate:initial,firstDate:DateTime(2025),lastDate:DateTime(DateTime.now().year+1,12),initialDatePickerMode:DatePickerMode.year);
    if(chosen!=null&&mounted)setState(()=>month='${chosen.year}-${chosen.month.toString().padLeft(2,'0')}');
   }),
   if(status=='approved')const Text('Disetujui Admin. QR Kasi akan ditampilkan pada PDF resmi.'),
   TextField(controller:name,readOnly:!editable,decoration:const InputDecoration(labelText:'Nama pegawai')),
   TextField(controller:nip,readOnly:!editable,decoration:const InputDecoration(labelText:'NIP / No. Pegawai')),
   for(var i=0;i<4;i++)Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text('${i+1}. ${_PppkState.titles[i]}',style:const TextStyle(fontWeight:FontWeight.bold)),
    for(var j=0;j<2;j++)Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     const SizedBox(height:12),
     Text('Periode ${j+1}',style:const TextStyle(fontWeight:FontWeight.w600)),
     if(photos.containsKey('${i+1}-${j+1}'))
      Image.memory(photos['${i+1}-${j+1}']!,height:130),
     if(stored.contains('${i+1}-${j+1}'))const Text('Foto tersimpan di server'),
     if(editable)TextButton.icon(onPressed:()=>pick(i,j),icon:const Icon(Icons.add_photo_alternate),label:const Text('Pilih Foto')),
     TextField(controller:descriptions[i][j],readOnly:!editable,maxLines:2,decoration:const InputDecoration(labelText:'Keterangan kegiatan')),
    ]),
   ]))),
   if(id!=null)OutlinedButton.icon(onPressed:busy?null:printReport,icon:const Icon(Icons.picture_as_pdf),label:const Text('Cetak PDF A4')),
   if(editable)...[
    FilledButton(onPressed:busy?null:save,child:const Text('Simpan Draf')),
    const SizedBox(height:8),
    OutlinedButton(onPressed:busy?null:submit,child:const Text('Kirim untuk Persetujuan Admin')),
   ],
   const SizedBox(height:60),
  ]),
 );
}
