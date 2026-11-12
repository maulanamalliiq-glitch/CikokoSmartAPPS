import 'package:flutter/material.dart';
import 'api.dart';
import 'cikoko_v6_showcase.dart';
import 'cikoko_kelurahan_profile.dart';
import 'role_catalog.dart';

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
      ]));
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


class V6AgendaPage extends StatefulWidget{
 final List<dynamic> content;
 const V6AgendaPage({super.key,required this.content});
 @override State<V6AgendaPage> createState()=>_V6AgendaState();
}
class _V6AgendaState extends State<V6AgendaPage>{
 String filter='Semua';
 @override Widget build(BuildContext context){
  final rows=widget.content.where((r)=>r is Map &&
    (r['type']=='agenda'||r['type']=='kegiatan')).toList();
  final now=DateTime.now();
  final visible=rows.where((raw){
    if(filter=='Semua')return true;
    final value=(raw['event_date']??raw['date']??raw['created_at']??'').toString();
    final date=DateTime.tryParse(value);
    if(date==null)return false;
    if(filter=='Mendatang')return !date.isBefore(DateTime(now.year,now.month,now.day));
    return date.isBefore(DateTime(now.year,now.month,now.day));
  }).toList();
  return ListView(padding:const EdgeInsets.all(14),children:[
    const V6PageHeader(title:'Agenda Kegiatan',
      description:'Agenda dan kegiatan yang dipublikasikan kelurahan.',icon:Icons.calendar_month_outlined),
    Row(children:[for(final tab in const ['Semua','Mendatang','Selesai'])Padding(
      padding:const EdgeInsets.only(right:7),
      child:ChoiceChip(label:Text(tab,style:const TextStyle(fontSize:10.6)),
        selected:filter==tab,onSelected:(_)=>setState(()=>filter=tab)))]),
    const SizedBox(height:11),
    for(final raw in visible)Padding(padding:const EdgeInsets.only(bottom:9),child:V6Panel(
      child:Row(children:[
        Container(width:54,height:60,decoration:BoxDecoration(color:V6.pale,borderRadius:V6.radius(9)),
          child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
            const Icon(Icons.event_available_outlined,color:V6.blue,size:23),
            Text(cikokoDateOnly(raw['event_date']??raw['date']??raw['created_at']??'').split(' ').take(2).join(' '),
              style:const TextStyle(fontSize:9.8,color:V6.ink,fontWeight:FontWeight.w800)),
          ])),
        const SizedBox(width:10),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
         Text((raw['title']??'Agenda Kelurahan').toString(),style:const TextStyle(
           fontSize:12,color:V6.ink,fontWeight:FontWeight.w800)),
         const SizedBox(height:4),
         Text((raw['summary']??raw['location']??'').toString(),
          maxLines:2,overflow:TextOverflow.ellipsis,
          style:const TextStyle(fontSize:10.4,color:V6.secondary)),
        ])),
      ]))),
    if(visible.isEmpty)const V6Panel(child:Text('Belum ada agenda yang dipublikasikan untuk pilihan ini.',
       style:TextStyle(fontSize:11.5,color:V6.secondary))),
  ]);
 }
}

class V6GalleryPage extends StatefulWidget{
 final CikokoApi api; final List<dynamic> content;
 const V6GalleryPage({super.key,required this.api,required this.content});
 @override State<V6GalleryPage> createState()=>_V6GalleryState();
}
class _V6GalleryState extends State<V6GalleryPage>{
 String filter='Semua';
 @override Widget build(BuildContext context){
  final rows=widget.content.where((raw)=>raw is Map && raw['type']=='galeri').toList();
  final categories=<String>{'Semua'};
  for(final r in rows){final c=(r['category']??'').toString().trim();if(c.isNotEmpty)categories.add(c);}
  final shown=rows.where((r)=>filter=='Semua'||(r['category']??'').toString()==filter).toList();
  return ListView(padding:const EdgeInsets.all(14),children:[
   const V6PageHeader(title:'Galeri Kegiatan',
     description:'Dokumentasi kegiatan Kelurahan Cikoko.',icon:Icons.photo_library_outlined),
   if(categories.length>1)SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[
    for(final cat in categories)Padding(padding:const EdgeInsets.only(right:7),
      child:ChoiceChip(label:Text(cat),selected:cat==filter,onSelected:(_)=>setState(()=>filter=cat))),
   ])),
   const SizedBox(height:9),
   if(shown.isEmpty)const V6Panel(child:Text('Belum ada foto kegiatan.',
       style:TextStyle(fontSize:12,color:V6.secondary))),
   GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
     itemCount:shown.length,
     gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:2,mainAxisSpacing:10,crossAxisSpacing:10,childAspectRatio:.93),
     itemBuilder:(context,index){
      final r=shown[index] as Map;
      final image=widget.api.media((r['image']??'').toString());
      final title=(r['title']??'Dokumentasi Kegiatan').toString();
      return InkWell(onTap:()=>showDialog<void>(context:context,builder:(ctx)=>AlertDialog(
       title:Text(title),content:image.isEmpty?const Icon(Icons.image_outlined):
        Image.network(image,errorBuilder:(_,__,___)=>const Icon(Icons.image_not_supported_outlined)),
       actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Tutup'))])),
       child:Container(clipBehavior:Clip.antiAlias,
        decoration:BoxDecoration(color:Colors.white,borderRadius:V6.radius(11),
          border:Border.all(color:V6.border)),
        child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          Expanded(child:image.isEmpty?const ColoredBox(color:V6.pale,
            child:Icon(Icons.photo_outlined,color:V6.blue,size:32)):
            Image.network(image,fit:BoxFit.cover,
              errorBuilder:(_,__,___)=>const ColoredBox(color:V6.pale,
                child:Icon(Icons.image_not_supported_outlined,color:V6.blue)))),
          Padding(padding:const EdgeInsets.all(8),child:Text(title,maxLines:2,
            overflow:TextOverflow.ellipsis,
            style:const TextStyle(fontSize:10.6,fontWeight:FontWeight.w800,color:V6.ink))),
        ])),
      );
     }),
  ]);
 }
}

class V6AboutPage extends StatelessWidget{
 final CikokoApi api;
 final void Function(String) navigate;
 const V6AboutPage({super.key,required this.api,required this.navigate});
 @override Widget build(BuildContext context)=>CikokoKelurahanProfilePage(
   api:api,title:'Tentang Kami',navigate:navigate);
}

class V6NotificationPage extends StatelessWidget{
 final bool guest; final List<dynamic> events;
 final void Function(Map<String,dynamic>) onOpen; final VoidCallback login;
 const V6NotificationPage({super.key,required this.guest,
  required this.events,required this.onOpen,required this.login});
 @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(14),children:[
   const V6PageHeader(title:'Notifikasi',
      description:'Pemberitahuan mengenai aktivitas dan pengajuan.',icon:Icons.notifications_none),
   if(guest)V6Panel(child:Column(children:[
     const Text('Masuk untuk membaca notifikasi Anda.'),
     const SizedBox(height:10),
     FilledButton(onPressed:login,child:const Text('Masuk')),
   ]))
   else if(events.isEmpty)const V6Panel(child:Text('Belum ada notifikasi.',
     style:TextStyle(color:V6.secondary,fontSize:11.5)))
   else for(final e in events)Padding(padding:const EdgeInsets.only(bottom:9),child:V6Panel(
     padding:EdgeInsets.zero,child:ListTile(
       onTap:()=>onOpen(Map<String,dynamic>.from(e)),
       leading:CircleAvatar(backgroundColor:V6.pale,child:Icon(
         (e['is_read']==true||(e['is_read']??0).toString()=='1')
          ?Icons.notifications_none:Icons.notifications_active_outlined,color:V6.blue,size:19)),
       title:Text((e['title']??'Pemberitahuan').toString(),
         style:const TextStyle(fontSize:12.2,fontWeight:FontWeight.w800,color:V6.ink)),
       subtitle:Text((e['message']??'').toString()+'\n'+cikokoDateOnly(e['created_at']??''),
         maxLines:3,overflow:TextOverflow.ellipsis,
         style:const TextStyle(fontSize:10.5,color:V6.secondary)),
       trailing:const Icon(Icons.chevron_right_rounded,color:V6.blue,size:18),
     ))),
 ]);
}

class V6FormHeading extends StatelessWidget{
 final String title,description;
 const V6FormHeading({super.key,required this.title,required this.description});
 @override Widget build(BuildContext context)=>Padding(
  padding:const EdgeInsets.fromLTRB(13,12,13,2),
  child:V6Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(title,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w900,color:V6.ink)),
    const SizedBox(height:5),
    Text(description,style:const TextStyle(fontSize:11,color:V6.secondary)),
    const SizedBox(height:13),
    Row(children:[
     for(final stage in const [
       ('1','Data'),('2','Dokumen'),('3','Verifikasi')
     ])Expanded(child:Row(children:[
       CircleAvatar(radius:12,backgroundColor:stage.$1=='1'?V6.blue:V6.pale,
        child:Text(stage.$1,style:TextStyle(fontSize:10.5,fontWeight:FontWeight.w800,
          color:stage.$1=='1'?Colors.white:V6.blue))),
       const SizedBox(width:4),
       Expanded(child:Text(stage.$2,maxLines:1,overflow:TextOverflow.ellipsis,
         style:const TextStyle(fontSize:10,color:V6.ink))),
     ]))
    ]),
  ])),
 );
}

class V6Onboarding extends StatefulWidget{
 const V6Onboarding({super.key});
 @override State<V6Onboarding> createState()=>_V6OnboardingState();
}
class _V6OnboardingState extends State<V6Onboarding>{
 int current=0; final pager=PageController();
 static const pages=[
  ('Layanan Kelurahan\nLebih Dekat & Mudah','Ajukan layanan, pantau progres, dan dapatkan informasi dalam satu aplikasi.'),
  ('Pengajuan Lebih Tertata','Kirim pengajuan melalui akun Anda dan pantau hasilnya dengan mudah.'),
  ('Informasi Resmi Cikoko','Akses berita, inovasi, agenda, dan dokumentasi kegiatan kelurahan.'),
 ];
 @override void dispose(){pager.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Scaffold(
  appBar:AppBar(actions:[TextButton(onPressed:()=>Navigator.pop(context),
    child:const Text('Lewati'))]),
  body:SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(18,16,18,18),
   child:Column(children:[
    Expanded(child:PageView(controller:pager,onPageChanged:(index)=>setState(()=>current=index),
      children:[for(final page in pages)Column(children:[
        Expanded(child:ClipRRect(borderRadius:V6.radius(20),
          child:Stack(fit:StackFit.expand,children:[
           const ColoredBox(color:Color(0xFFE9F4FF)),
           Image.asset('assets/kantor-cikoko.jpg',fit:BoxFit.contain),
           const Positioned(left:0,right:0,bottom:0,child:V6Skyline(height:77)),
          ]))),
        const SizedBox(height:22),
        Text(page.$1,textAlign:TextAlign.center,style:const TextStyle(
          color:V6.ink,fontSize:23,fontWeight:FontWeight.w900,height:1.15)),
        const SizedBox(height:12),
        Text(page.$2,textAlign:TextAlign.center,
          style:const TextStyle(fontSize:12,color:V6.secondary,height:1.55)),
        const SizedBox(height:32),
      ])])),
    Row(mainAxisAlignment:MainAxisAlignment.center,children:[
     for(var i=0;i<pages.length;i++)Container(
      width:current==i?21:7,height:6,margin:const EdgeInsets.symmetric(horizontal:3),
      decoration:BoxDecoration(color:current==i?V6.blue:V6.border,
        borderRadius:V6.radius(3))),
    ]),
    const SizedBox(height:17),
    SizedBox(width:double.infinity,child:FilledButton(
      onPressed:current==pages.length-1?()=>Navigator.pop(context):
       ()=>pager.nextPage(duration:const Duration(milliseconds:260),curve:Curves.easeOut),
      child:Text(current==pages.length-1?'Mulai Menggunakan':'Lanjutkan  →'))),
   ]))),
 );
}



class V6RegionPage extends StatelessWidget{
 final CikokoApi api;
 final void Function(String) navigate;
 const V6RegionPage({super.key,required this.api,required this.navigate});
 @override Widget build(BuildContext context)=>CikokoKelurahanProfilePage(
   api:api,title:'Profil Wilayah',navigate:navigate);
}

class V6ReportsHub extends StatelessWidget{
 final String role; final bool guest;
 final List<RoleFeature> modules; final Map<String,int>? counts;
 final void Function(String) navigate;
 final void Function(String) letterStatus;
 const V6ReportsHub({super.key,required this.role,required this.guest,
  required this.modules,required this.counts,required this.navigate,required this.letterStatus});
 @override Widget build(BuildContext context)=>ListView(
  padding:const EdgeInsets.all(14),children:[
    const V6PageHeader(title:'Laporan Terpadu',
      description:'Pelaporan, status dan pengelolaan di satu tempat.',
      icon:Icons.assignment_outlined),
    V6ReportPanel(role:role,guest:guest,modules:modules,
      letterCounts:counts,navigate:navigate,letterStatus:letterStatus),
    const SizedBox(height:18),
    const V6Section(title:'Pengajuan dan Riwayat'),
    V6Panel(padding:EdgeInsets.zero,child:ListTile(
      onTap:()=>navigate('Riwayat'),
      leading:const Icon(Icons.fact_check_outlined,color:V6.blue),
      title:const Text('Status Pengajuan',
       style:TextStyle(color:V6.ink,fontWeight:FontWeight.w800,fontSize:12.5)),
      subtitle:const Text('Pantau surat dan laporan yang sudah diajukan',
       style:TextStyle(color:V6.secondary,fontSize:10.7)),
      trailing:const Icon(Icons.chevron_right_rounded,color:V6.blue),
    )),
  ]);
}
