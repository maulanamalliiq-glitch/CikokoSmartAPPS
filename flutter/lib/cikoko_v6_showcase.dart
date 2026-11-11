import 'package:flutter/material.dart';
import 'api.dart';
import 'role_catalog.dart';

/// Single design vocabulary based on the supplied Cikoko Smart V4 16-screen showcase.
/// Keep server values and permissions as the source of truth: no demo reports or fake service data.
abstract final class V6 {
 static const ink=Color(0xFF0C1A48);
 static const blue=Color(0xFF0967E7);
 static const blueDark=Color(0xFF054BA8);
 static const pale=Color(0xFFE9F3FF);
 static const background=Color(0xFFF8FBFF);
 static const border=Color(0xFFE0EAF5);
 static const secondary=Color(0xFF61748C);
 static const green=Color(0xFF159A58);
 static const amber=Color(0xFFDE8B16);
 static const red=Color(0xFFE34B5A);
 static const shadow=BoxShadow(color:Color(0x0A123A70),blurRadius:11,offset:Offset(0,3));
 static BorderRadius radius([double r=12])=>BorderRadius.circular(r);
}

class V6PageHeader extends StatelessWidget {
 final String title,description; final IconData? icon;
 const V6PageHeader({super.key,required this.title,required this.description,this.icon});
 @override Widget build(BuildContext context)=>Padding(
  padding:const EdgeInsets.fromLTRB(0,4,0,15),
  child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Row(children:[
    if(icon!=null)...[
      Container(height:33,width:33,decoration:BoxDecoration(color:V6.pale,borderRadius:V6.radius(9)),
        child:Icon(icon,color:V6.blue,size:20)),const SizedBox(width:9)],
    Expanded(child:Text(title,style:const TextStyle(fontSize:19,color:V6.ink,
      fontWeight:FontWeight.w800,letterSpacing:-.4))),
   ]),
   const SizedBox(height:5),
   Text(description,style:const TextStyle(color:V6.secondary,fontSize:11.5,height:1.4)),
  ]));
}

class V6Section extends StatelessWidget{
 final String title; final String? action; final VoidCallback? onAction;
 const V6Section({super.key,required this.title,this.action,this.onAction});
 @override Widget build(BuildContext context)=>Padding(
  padding:const EdgeInsets.only(top:6,bottom:11),
  child:Row(children:[
   Expanded(child:Text(title,style:const TextStyle(
     color:V6.ink,fontWeight:FontWeight.w800,fontSize:15,letterSpacing:-.15))),
   if(action!=null&&onAction!=null)TextButton(onPressed:onAction,
     style:TextButton.styleFrom(padding:const EdgeInsets.symmetric(horizontal:5),minimumSize:const Size(0,32)),
     child:Text('$action  →',style:const TextStyle(fontSize:10.5,fontWeight:FontWeight.w700,color:V6.blue))),
  ]));
}

class V6Panel extends StatelessWidget {
 final Widget child; final EdgeInsets padding;
 const V6Panel({super.key,required this.child,this.padding=const EdgeInsets.all(13)});
 @override Widget build(BuildContext context)=>Container(
   padding:padding,
   decoration:BoxDecoration(color:Colors.white,borderRadius:V6.radius(13),
     border:Border.all(color:V6.border),boxShadow:const [V6.shadow]),
   child:child);
}

class V6Skyline extends StatelessWidget {
 final double height;
 const V6Skyline({super.key,this.height=78});
 @override Widget build(BuildContext context)=>SizedBox(width:double.infinity,height:height,
   child:CustomPaint(painter:_V6SkylinePainter()));
}
class _V6SkylinePainter extends CustomPainter{
 @override void paint(Canvas canvas,Size size){
  final p=Paint()..style=PaintingStyle.fill;
  p.color=const Color(0xFFE8F4FF);canvas.drawRect(Rect.fromLTWH(0,size.height*.38,size.width,size.height*.62),p);
  final buildings=[
   (.02,.58,.075,.42),(.11,.44,.062,.56),(.20,.63,.065,.37),(.28,.33,.048,.67),
   (.35,.56,.075,.44),(.46,.46,.055,.54),(.56,.62,.07,.38),
   (.68,.42,.065,.58),(.77,.58,.05,.42),(.86,.38,.078,.62),(.95,.62,.055,.38)
  ];
  p.color=const Color(0xFF98CEFF);
  for(final b in buildings){
   final x=size.width*b.$1, w=size.width*b.$3, y=size.height*b.$2;
   canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,w,size.height*b.$4),
     const Radius.circular(2)),p);
  }
  p.color=const Color(0xFF57AEF4);
  final x=size.width*.59;
  canvas.drawRect(Rect.fromLTWH(x,size.height*.28,size.width*.022,size.height*.72),p);
  final monument=Path()..moveTo(x-size.width*.02,size.height*.42)
   ..lineTo(x+size.width*.031,size.height*.42)
   ..lineTo(x+size.width*.011,size.height*.22)
   ..lineTo(x,size.height*.22)..close();
  canvas.drawPath(monument,p);
  p.color=const Color(0xFFFFA92B);
  final flame=Path()..moveTo(x+size.width*.011,size.height*.10)
   ..quadraticBezierTo(x-size.width*.015,size.height*.19,x+size.width*.009,size.height*.25)
   ..quadraticBezierTo(x+size.width*.045,size.height*.18,x+size.width*.011,size.height*.10);
  canvas.drawPath(flame,p);
  p.color=const Color(0xFF6EC87E);
  for(final xx in [.06,.19,.72,.93]){
   canvas.drawCircle(Offset(size.width*xx,size.height*.82),size.height*.13,p);
  }
  p.color=const Color(0xFF73B0E2);canvas.drawRect(Rect.fromLTWH(0,size.height*.94,size.width,size.height*.06),p);
 }
 @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;
}

class V6BottomNavigation extends StatelessWidget {
 final int selected; final ValueChanged<int> onSelected;
 const V6BottomNavigation({super.key,required this.selected,required this.onSelected});
 @override Widget build(BuildContext context) {
  // Beranda remains precisely centered as previously requested; About is a real fifth page.
  const tabs=[
   ('Laporan',Icons.assignment_outlined,Icons.assignment_rounded),
   ('Layanan',Icons.widgets_outlined,Icons.widgets_rounded),
   ('Beranda',Icons.home_outlined,Icons.home_rounded),
   ('Berita',Icons.article_outlined,Icons.article_rounded),
   ('Tentang Kami',Icons.person_outline,Icons.person_rounded),
  ];
  return SafeArea(top:false,child:Container(
    height:67,
    decoration:const BoxDecoration(color:Colors.white,border:Border(top:BorderSide(color:V6.border)),
      boxShadow:[BoxShadow(color:Color(0x0A0C2455),blurRadius:12,offset:Offset(0,-3))]),
    child:Row(children:[
     for(var i=0;i<tabs.length;i++)Expanded(child:InkWell(
      key:Key('v6_nav_$i'),onTap:()=>onSelected(i),
      child:Semantics(selected:i==selected,label:tabs[i].$1,button:true,
       child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
        Container(width:43,height:32,
         decoration:BoxDecoration(color:selected==i?V6.pale:Colors.transparent,
           borderRadius:V6.radius(12)),
         alignment:Alignment.center,
         child:Icon(selected==i?tabs[i].$3:tabs[i].$2,size:21,color:selected==i?V6.blue:V6.secondary)),
        const SizedBox(height:4),
        Text(tabs[i].$1,maxLines:1,overflow:TextOverflow.ellipsis,
          style:TextStyle(fontSize:i==4?9:10.2,
            color:selected==i?V6.blue:V6.ink,
            fontWeight:selected==i?FontWeight.w800:FontWeight.w600)),
       ])),
     )),
    ]),
  ));
 }
}

class V6Hero extends StatelessWidget{
 final VoidCallback onServices,onAbout;
 const V6Hero({super.key,required this.onServices,required this.onAbout});
 @override Widget build(BuildContext context)=>Container(
  height:178,clipBehavior:Clip.antiAlias,
  decoration:BoxDecoration(borderRadius:V6.radius(15),border:Border.all(color:const Color(0xFFCFE4FA)),
   gradient:const LinearGradient(colors:[Color(0xFFEAF5FF),Color(0xFFD1E7FF)])),
  child:Stack(children:[
   const Positioned(left:0,right:0,bottom:0,child:V6Skyline(height:53)),
   Positioned(right:0,top:0,bottom:0,width:159,child:ClipRRect(
     borderRadius:const BorderRadius.only(topRight:Radius.circular(14),bottomRight:Radius.circular(14)),
     child:Image.asset('assets/kantor-cikoko.jpg',fit:BoxFit.cover,
       alignment:Alignment.center))),
   const Positioned(right:137,top:0,bottom:0,width:60,child:DecoratedBox(
     decoration:BoxDecoration(gradient:LinearGradient(colors:[
       Color(0xFFE5F3FF),Color(0xE2E5F3FF),Color(0x00E5F3FF)])))),
   Positioned(left:14,right:130,top:15,bottom:13,child:Column(
     crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Cikoko Smart',maxLines:1,overflow:TextOverflow.ellipsis,
       style:TextStyle(color:V6.ink,fontWeight:FontWeight.w900,fontSize:18)),
      const SizedBox(height:4),
      const Text('Layanan dan informasi\nKelurahan Cikoko',maxLines:2,
       style:TextStyle(color:V6.ink,fontSize:13.2,height:1.12,fontWeight:FontWeight.w800)),
      const SizedBox(height:5),
      const Text('Kecamatan Pancoran · Jakarta Selatan',
       maxLines:2,style:TextStyle(color:V6.secondary,fontSize:9.4,height:1.3)),
      const Spacer(),
      SizedBox(height:32,child:FilledButton(
       onPressed:onServices,
       style:FilledButton.styleFrom(padding:const EdgeInsets.symmetric(horizontal:10),
         shape:RoundedRectangleBorder(borderRadius:V6.radius(7))),
       child:const Text('Ajukan Layanan  →',style:TextStyle(fontSize:9.5,fontWeight:FontWeight.w800)))),
      const SizedBox(height:5),
      InkWell(onTap:onAbout,child:const Text('Lihat Profil Kelurahan  →',
       style:TextStyle(color:V6.blue,fontSize:9.2,fontWeight:FontWeight.w700))),
     ])),
  ]),
 );
}

class V6ReportPanel extends StatelessWidget{
 final String role;
 final bool guest;
 final List<RoleFeature> modules;
 final Map<String,int>? letterCounts;
 final void Function(String) navigate;
 final void Function(String) letterStatus;
 const V6ReportPanel({super.key,required this.role,required this.guest,
   required this.modules,required this.letterCounts,
   required this.navigate,required this.letterStatus});
 @override Widget build(BuildContext context){
  final isCitizen=role=='warga'||guest;
  final allowed=modules.map((x)=>x.route).toSet();
  final entries=isCitizen
   ?const [
     ('Laporan Jumantik','Laporan Jumantik',Icons.health_and_safety_outlined),
     ('Pengaduan Warga','Hubungi Kami',Icons.campaign_outlined),
     ('Riwayat Laporan','Riwayat',Icons.history_outlined)]
   :[
     for(final e in const [
       ('Laporan Kegiatan','Laporan Kegiatan',Icons.assignment_outlined),
       ('Laporan LPJ RT','Laporan LPJ RT',Icons.receipt_long_outlined),
       ('Laporan LPJ RW','Laporan LPJ RW',Icons.receipt_long_outlined),
       ('Verifikasi Laporan','Verifikasi Laporan',Icons.verified_user_outlined),
       ('Riwayat Laporan','Riwayat',Icons.history_outlined),
     ])if(allowed.contains(e.$2))e
    ];
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    V6Section(title:'Laporan Terpadu',action:'Lihat Semua',
      onAction:()=>navigate('Laporan Terpadu')),
    V6Panel(padding:const EdgeInsets.all(11),child:Column(children:[
      Row(children:[
       Container(width:32,height:32,decoration:BoxDecoration(color:V6.pale,borderRadius:V6.radius(9)),
         child:const Icon(Icons.assessment_outlined,color:V6.blue,size:19)),
       const SizedBox(width:8),
       const Expanded(child:Text('Laporan dan Pemantauan',
          style:TextStyle(color:V6.ink,fontWeight:FontWeight.w800,fontSize:12.5))),
       const Icon(Icons.verified_outlined,color:V6.green,size:17),
      ]),
      const SizedBox(height:8),
      for(final e in entries.take(4))Material(color:V6.background,child:InkWell(
       onTap:()=>navigate(e.$2),
       child:Padding(padding:const EdgeInsets.symmetric(vertical:8,horizontal:6),
         child:Row(children:[
           Icon(e.$3,color:V6.blue,size:17),const SizedBox(width:9),
           Expanded(child:Text(e.$1,style:const TextStyle(
             fontSize:11.5,fontWeight:FontWeight.w700,color:V6.ink))),
           const Icon(Icons.chevron_right_rounded,color:V6.secondary,size:18)
         ])))),
      if(letterCounts!=null)...[
        const Divider(height:18,color:V6.border),
        const Align(alignment:Alignment.centerLeft,child:Text('Status Pelayanan Surat',
         style:TextStyle(color:V6.ink,fontWeight:FontWeight.w800,fontSize:11.5))),
        const SizedBox(height:8),
        Row(children:[
         for(final e in const [
           ('masuk','Masuk',V6.blue),('proses','Diproses',V6.amber),('selesai','Selesai',V6.green)
         ])Expanded(child:Padding(padding:const EdgeInsets.symmetric(horizontal:3),child:InkWell(
          onTap:()=>letterStatus(e.$1),
          child:Container(padding:const EdgeInsets.symmetric(vertical:7),
           decoration:BoxDecoration(color:V6.background,borderRadius:V6.radius(9),
             border:Border.all(color:V6.border)),
           child:Column(children:[
             Text((letterCounts![e.$1]??0).toString(),style:TextStyle(
              fontSize:19,fontWeight:FontWeight.w900,color:e.$3)),
             Text(e.$2,style:const TextStyle(fontSize:9.2,color:V6.secondary)),
           ]))))),
        ]),
      ],
    ])),
  ]);
 }
}

class V6CitizenServices extends StatelessWidget{
 final void Function(String) navigate;
 const V6CitizenServices({super.key,required this.navigate});
 @override Widget build(BuildContext context){
  const entries=[
   ('Surat Ahli Waris','Surat Ahli Waris',Icons.description_outlined),
   ('Pengantar RT/RW','Surat Pengantar RT/RW',Icons.home_work_outlined),
   ('Layanan Online','Layanan Online',Icons.widgets_outlined),
   ('Pengaduan Warga','Hubungi Kami',Icons.chat_outlined),
  ];
  return Column(children:[
   V6Section(title:'Layanan Masyarakat',action:'Lihat Semua',
     onAction:()=>navigate('Layanan Online')),
   GridView.count(crossAxisCount:2,shrinkWrap:true,
    physics:const NeverScrollableScrollPhysics(),childAspectRatio:1.69,
    crossAxisSpacing:9,mainAxisSpacing:9,
    children:[
     for(final e in entries)Material(color:Colors.white,
       borderRadius:V6.radius(12),child:InkWell(
       onTap:()=>navigate(e.$2),borderRadius:V6.radius(12),
       child:Container(
        padding:const EdgeInsets.all(9),
        decoration:BoxDecoration(border:Border.all(color:V6.border),borderRadius:V6.radius(12)),
        child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
          Icon(e.$3,size:24,color:V6.blue),
          const SizedBox(height:8),
          Text(e.$1,textAlign:TextAlign.center,maxLines:2,overflow:TextOverflow.ellipsis,
           style:const TextStyle(fontSize:10.8,color:V6.ink,fontWeight:FontWeight.w800))
        ])))),
    ]),
  ]);
 }
}

class V6ArticleCard extends StatelessWidget{
 final Map<String,dynamic> item;
 final CikokoApi api;
 final VoidCallback onTap;
 const V6ArticleCard({super.key,required this.item,required this.api,required this.onTap});
 @override Widget build(BuildContext context){
  final url=api.media((item['image']??'').toString());
  return Container(margin:const EdgeInsets.only(bottom:9),
   decoration:BoxDecoration(color:Colors.white,borderRadius:V6.radius(11),
     border:Border.all(color:V6.border)),
   child:Material(color:Colors.transparent,child:InkWell(
    onTap:onTap,borderRadius:V6.radius(11),
    child:Padding(padding:const EdgeInsets.all(8),
    child:Row(children:[
      ClipRRect(borderRadius:V6.radius(8),child:url.isEmpty
       ?Container(width:93,height:74,color:V6.pale,
         child:const Icon(Icons.image_outlined,color:V6.blue))
       :Image.network(url,width:93,height:74,fit:BoxFit.cover,
         errorBuilder:(_,__,___)=>Container(width:93,height:74,color:V6.pale,
          child:const Icon(Icons.image_not_supported_outlined,color:V6.blue)))),
      const SizedBox(width:9),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text((item['type']??'berita').toString().toUpperCase(),style:const TextStyle(
          fontSize:9,color:V6.blue,fontWeight:FontWeight.w900)),
        const SizedBox(height:3),
        Text((item['title']??'Berita Kelurahan').toString(),maxLines:2,
         overflow:TextOverflow.ellipsis,style:const TextStyle(
           color:V6.ink,fontWeight:FontWeight.w800,fontSize:11.5,height:1.3)),
        const SizedBox(height:6),
        Text(cikokoDateOnly(item['created_at']??''),maxLines:1,
          overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:9.3,color:V6.secondary)),
      ])),
      const Icon(Icons.chevron_right_rounded,size:15,color:V6.secondary),
    ])))),
  );
 }
}

class V6Home extends StatelessWidget{
 final String role;
 final bool guest;
 final List<RoleFeature> modules;
 final CikokoApi api;
 final List<dynamic> items;
 final Map<String,int>? letterCounts;
 final void Function(String) navigate;
 final void Function(String) letterStatus;
 final void Function(Map<String,dynamic>) articleTap;
 final Future<void> Function() reload;
 const V6Home({super.key,required this.role,required this.guest,
  required this.modules,required this.api,required this.items,
  required this.letterCounts,required this.navigate,required this.letterStatus,
  required this.articleTap,required this.reload});
 @override Widget build(BuildContext context){
  final articles=items.where((row)=>row is Map && 
     (row['type']=='berita'||row['type']=='pengumuman')).take(3).toList();
  return RefreshIndicator(onRefresh:reload,child:ListView(
   key:const Key('v6_home'),padding:const EdgeInsets.fromLTRB(14,12,14,30),
   children:[
    V6Hero(onServices:()=>navigate('Layanan Online'),
      onAbout:()=>navigate('Tentang Kami')),
    const SizedBox(height:20),
    V6ReportPanel(role:role,guest:guest,modules:modules,
      letterCounts:letterCounts,navigate:navigate,letterStatus:letterStatus),
    const SizedBox(height:20),
    V6CitizenServices(navigate:navigate),
    const SizedBox(height:21),
    V6Section(title:'Berita & Informasi Terbaru',action:'Lihat Semua',
      onAction:()=>navigate('Berita & Kegiatan')),
    if(articles.isEmpty)const V6Panel(child:Text('Belum ada berita yang dipublikasikan.',
      style:TextStyle(color:V6.secondary,fontSize:11.5))),
    for(final item in articles)V6ArticleCard(
      item:Map<String,dynamic>.from(item as Map),api:api,
      onTap:()=>articleTap(Map<String,dynamic>.from(item))),
    const SizedBox(height:17),
    const V6Section(title:'Informasi & Kegiatan'),
    Wrap(spacing:7,runSpacing:7,children:[
      for(final item in const [
       ('Agenda',Icons.event_outlined,'Agenda'),
       ('Inovasi',Icons.auto_awesome_outlined,'Inovasi'),
       ('Galeri',Icons.photo_library_outlined,'Galeri'),
       ('Profil Wilayah',Icons.place_outlined,'Profil Wilayah')
      ])ActionChip(label:Text(item.$1,style:const TextStyle(fontSize:10.5)),
        avatar:Icon(item.$2,color:V6.blue,size:16),
        onPressed:()=>navigate(item.$3)),
    ]),
   ],
  ));
 }
}

class V6AdminHome extends StatelessWidget {
 final List<RoleFeature> modules;
 final String roleName;
 final Map<String,int>? counts;
 final int unread;
 final List<dynamic> events;
 final void Function(String) navigate;
 const V6AdminHome({super.key,required this.modules,required this.roleName,
   required this.counts,required this.unread,required this.events,required this.navigate});
 @override Widget build(BuildContext context) {
  final allowed=modules.map((m)=>m.route).toSet();
  const actions=[
   ('Verifikasi Laporan','Verifikasi Laporan',Icons.fact_check_outlined),
   ('Verifikasi Ahli Waris','Verifikasi Ahli Waris',Icons.verified_user_outlined),
   ('Kelola Layanan','Kelola Layanan Terpadu',Icons.widgets_outlined),
   ('Kelola Akun','Kelola Akun Petugas',Icons.manage_accounts_outlined),
   ('Tambah Berita','Tambah Berita',Icons.post_add_outlined),
   ('LPJ RT','Laporan LPJ RT',Icons.receipt_long_outlined),
   ('LPJ RW','Laporan LPJ RW',Icons.receipt_long_outlined),
   ('Pengumuman','Tambah Pengumuman',Icons.campaign_outlined),
  ];
  return ListView(padding:const EdgeInsets.fromLTRB(14,12,14,32),children:[
   Container(padding:const EdgeInsets.all(15),
    decoration:BoxDecoration(
      borderRadius:V6.radius(14),gradient:const LinearGradient(
       colors:[Color(0xFFEAF5FF),Color(0xFFD7EBFF)]),
      border:Border.all(color:V6.border)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Dashboard Admin',style:TextStyle(fontSize:20,color:V6.ink,fontWeight:FontWeight.w900)),
      const SizedBox(height:5),
      Text('Selamat datang · $roleName',style:const TextStyle(fontSize:11.4,color:V6.secondary)),
    ])),
   const SizedBox(height:17),
   const V6Section(title:'Ringkasan Pelayanan'),
   GridView.count(crossAxisCount:2,childAspectRatio:1.82,
    shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
    crossAxisSpacing:9,mainAxisSpacing:9,
    children:[
     for(final d in [
      ('Surat Masuk',counts?['masuk'],V6.blue,Icons.description_outlined),
      ('Diproses',counts?['proses'],V6.amber,Icons.timelapse_outlined),
      ('Selesai',counts?['selesai'],V6.green,Icons.check_circle_outline),
      ('Notifikasi',unread,V6.red,Icons.notifications_none_outlined),
     ])V6Panel(padding:const EdgeInsets.all(11),child:Row(children:[
       Icon(d.$4,color:d.$3,size:22),const SizedBox(width:9),
       Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,
         crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(d.$1,maxLines:1,overflow:TextOverflow.ellipsis,
             style:const TextStyle(fontSize:10,color:V6.secondary)),
          Text(d.$2?.toString()??'—',style:TextStyle(fontSize:21,
            fontWeight:FontWeight.w900,color:d.$3)),
       ])),
     ])),
    ]),
   const SizedBox(height:17),
   const V6Section(title:'Menu Cepat'),
   GridView.count(crossAxisCount:3,shrinkWrap:true,
    physics:const NeverScrollableScrollPhysics(),
    childAspectRatio:1.13,crossAxisSpacing:9,mainAxisSpacing:9,
    children:[
     for(final item in actions)if(allowed.contains(item.$2))
       Material(color:Colors.white,borderRadius:V6.radius(12),
        child:InkWell(onTap:()=>navigate(item.$2),
         child:Container(padding:const EdgeInsets.all(7),
          decoration:BoxDecoration(borderRadius:V6.radius(12),
           border:Border.all(color:V6.border)),
          child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
           Icon(item.$3,color:V6.blue,size:24),const SizedBox(height:9),
           Text(item.$1,maxLines:2,textAlign:TextAlign.center,
            overflow:TextOverflow.ellipsis,style:const TextStyle(
              fontSize:10.5,color:V6.ink,fontWeight:FontWeight.w800))
          ])))),
    ]),
   const SizedBox(height:18),
   V6Section(title:'Aktivitas Terbaru',action:'Lihat Semua',
      onAction:()=>navigate('Notifikasi')),
   for(final item in events.take(5))V6Panel(child:ListTile(
     dense:true,
     leading:const Icon(Icons.notifications_outlined,color:V6.blue),
     title:Text((item['title']??'Aktivitas').toString(),
       style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700)),
     subtitle:Text((item['created_at']??'').toString(),
       style:const TextStyle(fontSize:10,color:V6.secondary)))),
   if(events.isEmpty)const V6Panel(child:Text('Belum ada aktivitas.',
     style:TextStyle(fontSize:11.5,color:V6.secondary))),
  ]);
 }
}
