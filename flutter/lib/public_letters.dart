import 'dart:math' as math;
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'api.dart';

/// Public read-only view: deliberately consumes only reference, kind and
/// status. It never requests authenticated detail or document attachments.
Future<void> showPublicLetterStatus(BuildContext context,CikokoApi api,
    {String category='all'}) {
  return showModalBottomSheet<void>(
    context:context,isScrollControlled:true,useSafeArea:true,
    backgroundColor:Colors.white,
    shape:const RoundedRectangleBorder(
      borderRadius:BorderRadius.vertical(top:Radius.circular(22))),
    builder:(_)=>FractionallySizedBox(
      heightFactor:.85,
      child:PublicLetterStatusSheet(api:api,initialCategory:category)),
  );
}
class PublicLetterStatusSheet extends StatefulWidget {
  final CikokoApi api;
  final String initialCategory;
  const PublicLetterStatusSheet({super.key,required this.api,required this.initialCategory});
  @override State<PublicLetterStatusSheet> createState()=>_PublicLetterStatusState();
}
class _PublicLetterStatusState extends State<PublicLetterStatusSheet>{
  late String category;
  late Future<Map<String,dynamic>> request;
  @override void initState(){super.initState();category=widget.initialCategory;reload();}
  void reload(){request=widget.api.call('public_letter_status');if(mounted)setState((){});}
  static const tabs={
    'all':'Semua',
    'masuk':'Surat Masuk',
    'proses':'Diproses',
    'selesai':'Selesai',
  };
  static const brand=Color(0xff10375f);
  void showNumber(Map<String,dynamic> item){
    final bucket='${item['bucket']??'proses'}';
    final stage=bucket=='masuk'?1:bucket=='selesai'?3:2;
    final state='${item['status']??'Dalam proses'}';
    showDialog<void>(context:context,builder:(dialog)=>AlertDialog(
      title:const Text('Progres Pengajuan',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800)),
      content:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Nomor pengajuan',style:TextStyle(fontSize:11,color:Colors.blueGrey)),
        SelectableText('${item['reference']??'-'}',style:const TextStyle(fontSize:16,fontWeight:FontWeight.w800,color:brand)),
        const SizedBox(height:8),
        Text('${item['title']??'Pelayanan Surat'}',style:const TextStyle(fontSize:12)),
        const SizedBox(height:12),
        Text('Status: $state',style:const TextStyle(fontWeight:FontWeight.bold)),
        const SizedBox(height:16),
        Row(children:[
          for(var i=1;i<=3;i++)Expanded(child:Column(children:[
            Icon(i<=stage?Icons.check_circle:Icons.radio_button_unchecked,
              size:23,color:i<=stage?const Color(0xff226fda):Colors.blueGrey.shade200),
            const SizedBox(height:5),
            Text(['Masuk','Diproses','Selesai'][i-1],
              textAlign:TextAlign.center,style:const TextStyle(fontSize:10)),
          ])),
        ]),
        const SizedBox(height:16),
        const Text('Informasi identitas, isi surat, dan lampiran hanya bisa dibuka oleh akun yang berwenang.',
          style:TextStyle(color:Colors.blueGrey,fontSize:11)),
      ]),
      actions:[FilledButton(onPressed:()=>Navigator.pop(dialog),child:const Text('Tutup'))],
    ));
  }
  @override Widget build(BuildContext context)=>Column(children:[
    Padding(padding:const EdgeInsets.fromLTRB(18,12,10,2),child:Row(children:[
      const Icon(Icons.fact_check_outlined,color:Color(0xff226fda)),
      const SizedBox(width:8),
      const Expanded(child:Text('Status Pelayanan Surat',
        style:TextStyle(fontWeight:FontWeight.w800,fontSize:17,color:brand))),
      IconButton(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.close)),
    ])),
    const Divider(height:3),
    SizedBox(height:48,child:ListView(scrollDirection:Axis.horizontal,
      padding:const EdgeInsets.symmetric(horizontal:12),
      children:[for(final t in tabs.entries)Padding(
        padding:const EdgeInsets.only(right:5),
        child:ChoiceChip(label:Text(t.value,style:const TextStyle(fontSize:12)),
          selected:category==t.key,onSelected:(_)=>setState(()=>category=t.key)),
      )])),
    Expanded(child:FutureBuilder<Map<String,dynamic>>(future:request,builder:(ctx,s){
      if(s.hasError)return Center(child:Padding(padding:const EdgeInsets.all(16),
        child:Column(mainAxisSize:MainAxisSize.min,children:[
          Text('Status surat belum tersedia. ${s.error}',textAlign:TextAlign.center),
          const SizedBox(height:12),
          OutlinedButton.icon(onPressed:reload,icon:const Icon(Icons.refresh),
            label:const Text('Coba lagi')),
        ])));
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      final rows=List<dynamic>.from(s.data!['items']??[]).map((raw){
        final data=Map<String,dynamic>.from(raw as Map);
        return <String,dynamic>{
          'reference':data['reference_no']??data['reference']??'-',
          'bucket':data['category']??data['bucket']??'proses',
          'status':data['status']??'Belum diketahui',
          'title':'Surat Pengantar RT/RW',
        };
      }).toList();
      final filtered=rows.where((e)=>category=='all'||e['bucket']==category).toList();
      if(filtered.isEmpty)return const Center(child:Text('Belum ada pengajuan dalam kategori ini.'));
      return RefreshIndicator(onRefresh:()async{reload();await request;},
        child:ListView.builder(
          padding:const EdgeInsets.all(12),itemCount:filtered.length+1,
          itemBuilder:(ctx,i){
            if(i==filtered.length)return const Padding(
              padding:EdgeInsets.all(14),
              child:Text('Menampilkan hingga 200 nomor pengajuan terbaru. Identitas dan dokumen tidak ditampilkan.',
                style:TextStyle(color:Colors.blueGrey,fontSize:11)));
            final data=Map<String,dynamic>.from(filtered[i] as Map);
            return Card(child:ListTile(
              leading:const Icon(Icons.description_outlined,color:Color(0xff226fda)),
              title:Text('${data['reference']??'-'}',
                style:const TextStyle(fontSize:13,fontWeight:FontWeight.bold)),
              subtitle:Text('${data['title']??'Surat'} • ${data['status']??''}',
                style:const TextStyle(fontSize:11)),
              trailing:const Icon(Icons.chevron_right),
              onTap:()=>showNumber(data),
            ));
          }));
    })),
  ]);
}

Future<void> showPublicLetterPie(BuildContext context,CikokoApi api){
 final request=api.call('public_letter_status');
 const blue=Color(0xff2467ba),orange=Color(0xffd58823),green=Color(0xff17875a);
 return showDialog<void>(context:context,builder:(dialog)=>Dialog(
  insetPadding:const EdgeInsets.symmetric(horizontal:20,vertical:24),
  shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20)),
  child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:420),child:
   Padding(padding:const EdgeInsets.all(19),
    child:FutureBuilder<Map<String,dynamic>>(future:request,builder:(ctx,s){
     if(s.hasError)return Column(mainAxisSize:MainAxisSize.min,children:[
       const Text('Status Pelayanan Surat',style:TextStyle(fontWeight:FontWeight.bold,fontSize:18)),
       const SizedBox(height:15),const Text('Data belum tersedia. Silakan coba lagi.'),
       TextButton(onPressed:()=>Navigator.pop(dialog),child:const Text('Tutup'))]);
     if(!s.hasData)return const SizedBox(height:200,child:Center(child:CircularProgressIndicator()));
     final raw=Map<String,dynamic>.from(s.data!['counts'] as Map? ??{});
     int num(String k){final v=raw[k];return math.max(0,v is num?v.toInt():int.tryParse(v.toString())??0);}
     final masuk=num('masuk'),proses=num('proses'),selesai=num('selesai');
     final total=masuk+proses+selesai;
     final groups=[
      ('masuk','Surat Masuk',masuk,blue),
      ('proses','Diproses',proses,orange),
      ('selesai','Selesai',selesai,green),
     ];
     return SingleChildScrollView(child:Column(
      mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
       Row(children:[
        const Expanded(child:Text('Status Pelayanan Surat',
          style:TextStyle(fontWeight:FontWeight.w800,fontSize:18,color:Color(0xff10375f)))),
        IconButton(onPressed:()=>Navigator.pop(dialog),icon:const Icon(Icons.close)),
       ]),
       const Text('Grafik seluruh pengajuan surat',style:TextStyle(fontSize:12,color:Colors.blueGrey)),
       const SizedBox(height:12),
       Center(child:SizedBox(width:210,height:210,child:Stack(alignment:Alignment.center,children:[
        CustomPaint(size:const Size(210,210),painter:_LetterPiePainter(
          [masuk,proses,selesai],const [blue,orange,green])),
        Column(mainAxisSize:MainAxisSize.min,children:[
         Text(total.toString(),style:const TextStyle(fontSize:30,fontWeight:FontWeight.w900,
            color:Color(0xff10375f))),
         const Text('Total Surat',style:TextStyle(fontSize:11,color:Colors.blueGrey)),
        ]),
       ]))),
       const SizedBox(height:12),
       for(final group in groups)Padding(
        padding:const EdgeInsets.symmetric(vertical:5),
        child:InkWell(onTap:(){
          Navigator.pop(dialog);showPublicLetterStatus(context,api,category:group.$1);
        },child:Row(children:[
          Container(width:14,height:14,decoration:BoxDecoration(
            color:group.$4,borderRadius:BorderRadius.circular(3))),
          const SizedBox(width:9),
          Expanded(child:Text(group.$2,style:const TextStyle(fontWeight:FontWeight.w600))),
          Text(group.$3.toString(),style:const TextStyle(fontWeight:FontWeight.w800)),
          const SizedBox(width:9),
          Text(total>0?(100*group.$3/total).toStringAsFixed(1)+'%':'0%',
             style:const TextStyle(color:Colors.blueGrey,fontSize:12)),
          const Icon(Icons.chevron_right,size:17),
        ]))),
       const SizedBox(height:12),
       FilledButton.icon(onPressed:(){
        Navigator.pop(dialog);showPublicLetterStatus(context,api,category:'all');
       },icon:const Icon(Icons.list_alt_outlined),
        label:const Text('Lihat Daftar Nomor Surat')),
       const SizedBox(height:5),
       const Text('Hanya rekap jumlah dan nomor surat. Data pribadi serta lampiran tidak ditampilkan.',
          textAlign:TextAlign.center,style:TextStyle(fontSize:10,color:Colors.blueGrey)),
      ]));
    }),
   )),
 ));
}
class _LetterPiePainter extends CustomPainter{
 final List<int> values;
 final List<Color> colors;
 const _LetterPiePainter(this.values,this.colors);
 @override void paint(Canvas canvas,Size size){
  final total=values.fold<int>(0,(sum,n)=>sum+n);
  final rect=Rect.fromLTWH(15,15,size.width-30,size.height-30);
  final blank=Paint()..style=PaintingStyle.stroke..strokeWidth=27
   ..color=const Color(0xffe4ebf4);
  canvas.drawArc(rect,0,2*math.pi,false,blank);
  if(total==0)return;
  var start=-math.pi/2;
  for(var i=0;i<values.length;i++){
   if(values[i]==0)continue;
   final sweep=2*math.pi*values[i]/total;
   canvas.drawArc(rect,start,sweep,false,
     Paint()..style=PaintingStyle.stroke..strokeWidth=27..color=colors[i]);
   start+=sweep;
  }
 }
 @override bool shouldRepaint(covariant _LetterPiePainter old)=>!listEquals(values,old.values);
}
