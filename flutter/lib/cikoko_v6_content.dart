import 'package:flutter/material.dart';
import 'api.dart';
import 'cikoko_v6_showcase.dart';

class V6ServicesPage extends StatefulWidget{
 final bool guest; final void Function(String) onOpen;
 const V6ServicesPage({super.key,required this.guest,required this.onOpen});
 @override State<V6ServicesPage> createState()=>_V6ServicesState();
}
class _V6ServicesState extends State<V6ServicesPage>{
 String query='',category='Semua';
 static const services=[
  ('Surat Ahli Waris','Pengajuan surat ahli waris','Surat','Surat Ahli Waris',Icons.description_outlined),
  ('Pengantar RT/RW','Pengajuan pengantar tingkat RT dan RW','Surat','Surat Pengantar RT/RW',Icons.home_work_outlined),
  ('Laporan Jumantik','Pemantauan lingkungan dan jentik','Laporan','Laporan Jumantik',Icons.health_and_safety_outlined),
  ('Pengaduan Warga','Komunikasi dengan petugas kelurahan','Pengaduan','Hubungi Kami',Icons.forum_outlined),
  ('Riwayat Pengajuan','Pantau status surat dan laporan','Surat','Riwayat',Icons.fact_check_outlined),
  ('Layanan Pemerintah','Akses katalog layanan terkait','Lainnya','Katalog DKI',Icons.account_balance_outlined),
 ];
 @override Widget build(BuildContext context){
  final filtered=services.where((s)=>
    (category=='Semua'||category==s.$3) &&
    ((s.$1+' '+s.$2).toLowerCase().contains(query.toLowerCase()))).toList();
  return ListView(key:const Key('v6_services'),padding:const EdgeInsets.all(14),children:[
    const V6PageHeader(title:'Layanan Online',description:'Pilih pelayanan sesuai kebutuhan warga.',icon:Icons.widgets_outlined),
    TextField(onChanged:(v)=>setState(()=>query=v),
     decoration:const InputDecoration(hintText:'Cari layanan…',
       prefixIcon:Icon(Icons.search,color:V6.blue))),
    const SizedBox(height:10),
    Wrap(spacing:7,runSpacing:7,children:[
      for(final item in const ['Semua','Surat','Pengaduan','Laporan','Lainnya'])
        ChoiceChip(label:Text(item,style:const TextStyle(fontSize:10.7)),
          selected:category==item,onSelected:(_)=>setState(()=>category=item)),
    ]),
    const SizedBox(height:12),
    for(final service in filtered)Padding(padding:const EdgeInsets.only(bottom:9),
      child:V6Panel(padding:EdgeInsets.zero,child:InkWell(
       onTap:()=>widget.onOpen(service.$4),
       borderRadius:V6.radius(12),child:Padding(
         padding:const EdgeInsets.all(12),child:Row(children:[
          Container(width:40,height:42,
            decoration:BoxDecoration(color:V6.pale,borderRadius:V6.radius(10)),
            child:Icon(service.$5,color:V6.blue,size:21)),
          const SizedBox(width:11),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(service.$1,style:const TextStyle(color:V6.ink,
              fontWeight:FontWeight.w800,fontSize:12)),
            const SizedBox(height:3),
            Text(service.$2,maxLines:2,overflow:TextOverflow.ellipsis,
              style:const TextStyle(color:V6.secondary,fontSize:10.5)),
          ])),
          const Icon(Icons.chevron_right_rounded,color:V6.blue),
         ]),
       )))),
    if(filtered.isEmpty)const V6Panel(child:Text('Layanan tidak ditemukan.',
      style:TextStyle(fontSize:12,color:V6.secondary))),
    if(widget.guest)const Padding(padding:EdgeInsets.only(top:15),
      child:Text('Silakan masuk ke akun Anda untuk membuat pengajuan.',
        style:TextStyle(color:V6.secondary,fontSize:11))),
  ]);
 }
}

class V6ServiceDetail extends StatelessWidget{
 final String title,description; final IconData icon;
 final VoidCallback onApply; final VoidCallback? onRequirements;
 const V6ServiceDetail({super.key,required this.title,required this.description,
  required this.icon,required this.onApply,this.onRequirements});
 @override Widget build(BuildContext context)=>Scaffold(
  appBar:AppBar(title:const Text('Detail Layanan')),
  body:SafeArea(child:ListView(padding:const EdgeInsets.all(15),children:[
    V6Panel(child:Row(children:[
      Container(width:58,height:58,decoration:BoxDecoration(color:V6.pale,
        borderRadius:V6.radius(12)),child:Icon(icon,color:V6.blue,size:32)),
      const SizedBox(width:13),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(title,style:const TextStyle(fontSize:17,
          fontWeight:FontWeight.w900,color:V6.ink)),
        const SizedBox(height:6),
        Text(description,style:const TextStyle(
          fontSize:11.7,color:V6.secondary,height:1.4)),
      ])),
    ])),
    const SizedBox(height:17),
    const V6Section(title:'Alur Pelayanan'),
    V6Panel(child:Column(children:[
      for(final step in const [
        ('1','Buka Formulir','Isi data pengajuan sesuai identitas'),
        ('2','Lengkapi Persyaratan','Unggah dokumen yang diminta dalam formulir'),
        ('3','Kirim dan Pantau','Pantau perkembangan melalui Riwayat Pengajuan'),
      ])Padding(padding:const EdgeInsets.symmetric(vertical:8),
       child:Row(children:[
        CircleAvatar(radius:14,backgroundColor:V6.pale,
         child:Text(step.$1,style:const TextStyle(
           color:V6.blue,fontWeight:FontWeight.w900,fontSize:11))),
        const SizedBox(width:10),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
         Text(step.$2,style:const TextStyle(
          color:V6.ink,fontWeight:FontWeight.w800,fontSize:12)),
         Text(step.$3,style:const TextStyle(
          color:V6.secondary,fontSize:10.7)),
        ]))
       ])),
    ])),
    const SizedBox(height:13),
    if(onRequirements!=null)OutlinedButton.icon(
      onPressed:onRequirements,icon:const Icon(Icons.fact_check_outlined,size:19),
      label:const Text('Lihat Persyaratan Layanan')),
    const SizedBox(height:7),
    const Text('Dokumen dan waktu pelayanan mengikuti persyaratan yang ditampilkan pada formulir resmi.',
       style:TextStyle(color:V6.secondary,fontSize:10.7,height:1.45)),
  ])),
  bottomNavigationBar:SafeArea(top:false,
    child:Padding(padding:const EdgeInsets.fromLTRB(15,9,15,13),
      child:FilledButton.icon(onPressed:onApply,
        icon:const Icon(Icons.arrow_forward_rounded,size:18),
        label:const Text('Ajukan Layanan')))),
 );
}

class V6HistoryPage extends StatefulWidget {
 final CikokoApi api; final void Function(Map<String,dynamic>) onOpen;
 const V6HistoryPage({super.key,required this.api,required this.onOpen});
 @override State<V6HistoryPage> createState()=>_V6HistoryState();
}
class _V6HistoryState extends State<V6HistoryPage>{
 late Future<Map<String,dynamic>> pending;
 String filter='Semua';
 @override void initState(){super.initState();reload();}
 void reload(){pending=widget.api.call('history');}
 bool _fits(String value){
  final s=value.toLowerCase();
  if(filter=='Semua')return true;
  if(filter=='Diproses')return s.contains('proses')||s.contains('pending')||s.contains('menunggu')||s.contains('verifikasi');
  if(filter=='Selesai')return s.contains('selesai')||s.contains('approved')||s.contains('disetujui')||s.contains('terbit');
  return s.contains('tolak')||s.contains('rejected');
 }
 Color _color(String value){
  final s=value.toLowerCase();
  if(s.contains('selesai')||s.contains('approved')||s.contains('disetujui'))return V6.green;
  if(s.contains('tolak')||s.contains('rejected'))return V6.red;
  return V6.amber;
 }
 @override Widget build(BuildContext context)=>FutureBuilder<Map<String,dynamic>>(
   future:pending,builder:(context,s){
    if(!s.hasData && !s.hasError)return const Center(child:CircularProgressIndicator());
    if(s.hasError)return Center(child:Column(mainAxisSize:MainAxisSize.min,children:[
     const Text('Riwayat belum dapat dimuat.'),
     TextButton.icon(onPressed:()=>setState(reload),icon:const Icon(Icons.refresh),
       label:const Text('Muat Ulang')),
    ]));
    final rows=List<dynamic>.from(s.data?['items']??[])
      .where((x)=>x is Map && _fits((x['status']??'').toString())).toList();
    return RefreshIndicator(onRefresh:()async{setState(reload);try{await pending;}catch(_){ }},
      child:ListView(padding:const EdgeInsets.all(14),children:[
        const V6PageHeader(title:'Status Pengajuan',
          description:'Pantau surat dan laporan yang diajukan.',icon:Icons.fact_check_outlined),
        SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[
         for(final tab in const ['Semua','Diproses','Selesai','Ditolak'])Padding(
          padding:const EdgeInsets.only(right:6),
          child:ChoiceChip(label:Text(tab,style:const TextStyle(fontSize:10.7)),
           selected:filter==tab,onSelected:(_)=>setState(()=>filter=tab))),
        ])),
        const SizedBox(height:12),
        for(final raw in rows)Padding(padding:const EdgeInsets.only(bottom:9),
          child:V6Panel(padding:const EdgeInsets.all(12),child:InkWell(
            onTap:()=>widget.onOpen(Map<String,dynamic>.from(raw)),
            child:Row(children:[
             Container(width:39,height:39,decoration:BoxDecoration(
               color:V6.pale,borderRadius:V6.radius(9)),
               child:const Icon(Icons.description_outlined,color:V6.blue,size:21)),
             const SizedBox(width:10),
             Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
               Text((raw['title']??raw['reference']??'Pengajuan').toString(),
                 maxLines:2,overflow:TextOverflow.ellipsis,
                 style:const TextStyle(fontSize:12,fontWeight:FontWeight.w800,color:V6.ink)),
               const SizedBox(height:3),
               Text((raw['reference']??'').toString(),style:const TextStyle(
                 color:V6.secondary,fontSize:10)),
               Text(cikokoDateOnly(raw['created_at']??''),style:const TextStyle(
                 color:V6.secondary,fontSize:9.5)),
             ])),
             Column(mainAxisAlignment:MainAxisAlignment.center,children:[
              Container(padding:const EdgeInsets.symmetric(horizontal:7,vertical:5),
                decoration:BoxDecoration(color:_color((raw['status']??'').toString()).withValues(alpha:.12),
                  borderRadius:V6.radius(7)),
                child:Text((raw['status']??'Belum diproses').toString(),
                  style:TextStyle(fontWeight:FontWeight.w800,fontSize:9.5,
                    color:_color((raw['status']??'').toString())))),
              const SizedBox(height:6),
              const Icon(Icons.chevron_right_rounded,size:16,color:V6.secondary),
             ]),
            ])))),
        if(rows.isEmpty)const V6Panel(child:Text('Belum ada pengajuan pada status ini.',
          style:TextStyle(fontSize:11.5,color:V6.secondary))),
      ])));
 });
}

class V6NewsPage extends StatefulWidget{
 final CikokoApi api; final List<dynamic> content;
 final void Function(Map<String,dynamic>) onOpen;
 const V6NewsPage({super.key,required this.api,required this.content,required this.onOpen});
 @override State<V6NewsPage> createState()=>_V6NewsState();
}
class _V6NewsState extends State<V6NewsPage>{
 String query='',type='Semua';
 @override Widget build(BuildContext context){
  final rows=widget.content.where((raw){
    if(raw is! Map)return false;
    final cat=(raw['type']??'').toString();
    if(cat!='berita'&&cat!='pengumuman')return false;
    if(type=='Berita'&&cat!='berita')return false;
    if(type=='Pengumuman'&&cat!='pengumuman')return false;
    return (raw['title']??'').toString().toLowerCase().contains(query.toLowerCase());
  }).toList();
  return ListView(key:const Key('v6_news'),padding:const EdgeInsets.all(14),children:[
    const V6PageHeader(title:'Berita & Informasi',
      description:'Berita dan informasi terbaru Kelurahan Cikoko.',icon:Icons.newspaper_outlined),
    TextField(onChanged:(s)=>setState(()=>query=s),
      decoration:const InputDecoration(prefixIcon:Icon(Icons.search,color:V6.blue),
        hintText:'Cari berita atau informasi…')),
    const SizedBox(height:10),
    Row(children:[for(final tab in const ['Semua','Berita','Pengumuman'])Padding(
      padding:const EdgeInsets.only(right:7),
      child:ChoiceChip(label:Text(tab,style:const TextStyle(fontSize:10.7)),
        selected:type==tab,onSelected:(_)=>setState(()=>type=tab)))]),
    const SizedBox(height:10),
    for(final raw in rows)V6ArticleCard(api:widget.api,
      item:Map<String,dynamic>.from(raw),onTap:()=>widget.onOpen(Map<String,dynamic>.from(raw))),
    if(rows.isEmpty)const V6Panel(child:Text('Belum ada publikasi yang sesuai.',
      style:TextStyle(color:V6.secondary,fontSize:11.5))),
  ]);
 }
}
