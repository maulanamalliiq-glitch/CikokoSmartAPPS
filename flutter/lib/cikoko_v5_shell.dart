import 'package:flutter/material.dart';
import 'api.dart';
import 'role_catalog.dart';

/// Cikoko Smart V5: one visual system for public and employee navigation.
/// The widgets intentionally reuse real API data and existing route names.
abstract final class CikokoV5 {
  static const navy = Color(0xFF082D5E);
  static const deep = Color(0xFF071E40);
  static const blue = Color(0xFF176BE7);
  static const canvas = Color(0xFFF1F6FD);
  static const line = Color(0xFFDCE8F6);
  static const muted = Color(0xFF68809B);
  static const ice = Color(0xFFE6F2FF);
}

class CikokoV5BottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;
  const CikokoV5BottomNav({super.key, required this.selected, required this.onSelected});
  @override Widget build(BuildContext context) {
    const labels = ['Laporan', 'Layanan', 'Beranda', 'Berita', 'Tentang Kami'];
    const icons = [
      Icons.assignment_outlined,
      Icons.widgets_outlined,
      Icons.home_rounded,
      Icons.article_outlined,
      Icons.info_outline_rounded,
    ];
    return SafeArea(top:false,child:Container(
      height:76,
      decoration:const BoxDecoration(
        color:Colors.white,
        border:Border(top:BorderSide(color:CikokoV5.line)),
        boxShadow:[BoxShadow(color:Color(0x140C376B),blurRadius:18,offset:Offset(0,-4))],
      ),
      child:Row(children: [
        for(var i=0;i<labels.length;i++) Expanded(child:Semantics(
          selected:i==selected,
          button:true,
          label:labels[i],
          child:InkWell(
            key:Key('v5_nav_$i'),
            onTap:()=>onSelected(i),
            child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
              if(i==2) Container(
                width:48,height:42,
                decoration:BoxDecoration(
                  gradient:const LinearGradient(colors:[CikokoV5.blue,CikokoV5.navy]),
                  borderRadius:BorderRadius.circular(15),
                  boxShadow:const [BoxShadow(color:Color(0x332675D9),blurRadius:10,offset:Offset(0,3))],
                ),
                child:Icon(icons[i],size:25,color:Colors.white),
              )
              else Container(
                width:40,height:35,
                decoration:BoxDecoration(
                  color:selected==i?CikokoV5.ice:Colors.transparent,
                  borderRadius:BorderRadius.circular(12)),
                child:Icon(icons[i],size:22,color:selected==i?CikokoV5.blue:CikokoV5.muted),
              ),
              const SizedBox(height:4),
              Text(labels[i],maxLines:1,overflow:TextOverflow.ellipsis,
                style:TextStyle(fontSize:i==4?9.2:10.4,height:1.1,
                  color:(i==selected||i==2)?CikokoV5.navy:CikokoV5.muted,
                  fontWeight:(i==selected||i==2)?FontWeight.w800:FontWeight.w600)),
            ]),
          ),
        )),
      ]),
    ));
  }
}

class CikokoV5SectionTitle extends StatelessWidget{
  final String title;
  final String? description;
  final String? action;
  final VoidCallback? onAction;
  const CikokoV5SectionTitle({super.key,required this.title,this.description,this.action,this.onAction});
  @override Widget build(BuildContext context)=>Padding(
    padding:const EdgeInsets.only(bottom:11),
    child:Row(crossAxisAlignment:CrossAxisAlignment.center,children:[
      Container(width:4,height:27,decoration:BoxDecoration(color:CikokoV5.blue,borderRadius:BorderRadius.circular(5))),
      const SizedBox(width:10),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(title,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800,color:CikokoV5.navy,letterSpacing:-.3)),
        if(description!=null)Text(description!,maxLines:2,overflow:TextOverflow.ellipsis,
          style:const TextStyle(fontSize:10.5,color:CikokoV5.muted,height:1.35)),
      ])),
      if(action!=null&&onAction!=null)TextButton(
        onPressed:onAction,
        style:TextButton.styleFrom(foregroundColor:CikokoV5.blue,
          textStyle:const TextStyle(fontSize:10.8,fontWeight:FontWeight.w800)),
        child:Text(action!)),
    ]),
  );
}

class CikokoV5Hero extends StatelessWidget{
  final VoidCallback onServices;
  final VoidCallback onAbout;
  const CikokoV5Hero({super.key,required this.onServices,required this.onAbout});
  @override Widget build(BuildContext context)=>Container(
    clipBehavior:Clip.antiAlias,
    decoration:BoxDecoration(
      color:Colors.white,borderRadius:BorderRadius.circular(20),
      border:Border.all(color:CikokoV5.line),
      boxShadow:const [BoxShadow(color:Color(0x110F4277),blurRadius:18,offset:Offset(0,5))],
    ),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      SizedBox(height:202,width:double.infinity,child:Stack(fit:StackFit.expand,children:[
        Image.asset('assets/kantor-cikoko.jpg',fit:BoxFit.cover,alignment:Alignment.center),
        const DecoratedBox(decoration:BoxDecoration(
          gradient:LinearGradient(begin:Alignment.bottomCenter,end:Alignment.topCenter,
            colors:[Color(0xE407244B),Color(0x800B3A70),Color(0x100A3974)]))),
        Positioned(left:17,right:18,bottom:16,child:Column(
          crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
          Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:4),
            decoration:BoxDecoration(color:const Color(0xDCFFFFFF),borderRadius:BorderRadius.circular(6)),
            child:const Text('PORTAL DIGITAL KELURAHAN CIKOKO',
              style:TextStyle(fontSize:8.5,letterSpacing:.5,fontWeight:FontWeight.w800,color:CikokoV5.navy))),
          const SizedBox(height:9),
          const Text('Cikoko Smart',style:TextStyle(
            color:Colors.white,fontSize:27,fontWeight:FontWeight.w900,height:1.1)),
          const SizedBox(height:2),
          const Text('Layanan dan Informasi\nKelurahan Cikoko',
            style:TextStyle(color:Colors.white,fontSize:14.5,fontWeight:FontWeight.w700,height:1.2)),
        ])),
      ])),
      Padding(padding:const EdgeInsets.fromLTRB(13,12,13,13),child:Row(children:[
        Expanded(child:FilledButton.icon(
          onPressed:onServices,
          style:FilledButton.styleFrom(minimumSize:const Size(0,42),
            padding:const EdgeInsets.symmetric(horizontal:7),
            shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(11))),
          icon:const Icon(Icons.arrow_forward_rounded,size:17),
          label:const Text('Ajukan Layanan',maxLines:1,style:TextStyle(fontSize:11.7)))),
        const SizedBox(width:9),
        Expanded(child:OutlinedButton.icon(
          onPressed:onAbout,
          style:OutlinedButton.styleFrom(minimumSize:const Size(0,42),
            padding:const EdgeInsets.symmetric(horizontal:7),
            side:const BorderSide(color:CikokoV5.line),
            shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(11))),
          icon:const Icon(Icons.info_outline_rounded,size:17),
          label:const Text('Tentang Kami',maxLines:1,style:TextStyle(fontSize:11.7)))),
      ])),
    ]),
  );
}

class CikokoV5Shortcut {
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final Color tint;
  const CikokoV5Shortcut(this.title,this.subtitle,this.route,this.icon,this.tint);
}

class CikokoV5ReportPanel extends StatelessWidget{
  final String role;
  final bool guest;
  final List<RoleFeature> modules;
  final Map<String,int>? letterCounts;
  final void Function(String) navigate;
  final void Function(String) onLetterStatus;
  final bool expanded;
  const CikokoV5ReportPanel({super.key,required this.role,required this.guest,
    required this.modules,required this.letterCounts,required this.navigate,
    required this.onLetterStatus,this.expanded=false});
  List<CikokoV5Shortcut> _actions(){
    if(guest||role=='warga')return const [
      CikokoV5Shortcut('Laporan Jumantik','Pemantauan lingkungan','Laporan Jumantik',
        Icons.health_and_safety_outlined,Color(0xFFE6F4FF)),
      CikokoV5Shortcut('Riwayat Pengajuan','Pantau laporan dan surat','Riwayat',
        Icons.fact_check_outlined,Color(0xFFE9F8EE)),
      CikokoV5Shortcut('Hubungi Petugas','Sampaikan keluhan','Hubungi Kami',
        Icons.forum_outlined,Color(0xFFFFF2E3)),
    ];
    const choices=[
      CikokoV5Shortcut('Laporan Kegiatan','Laporan petugas wilayah','Laporan Kegiatan',
        Icons.assignment_outlined,Color(0xFFE6F4FF)),
      CikokoV5Shortcut('Verifikasi Laporan','Tindak lanjut petugas','Verifikasi Laporan',
        Icons.verified_outlined,Color(0xFFE9F8EE)),
      CikokoV5Shortcut('LPJ RT','Laporan pertanggungjawaban RT','Laporan LPJ RT',
        Icons.receipt_long_outlined,Color(0xFFFFF2E3)),
      CikokoV5Shortcut('LPJ RW','Laporan pertanggungjawaban RW','Laporan LPJ RW',
        Icons.receipt_long_outlined,Color(0xFFF0E9FF)),
      CikokoV5Shortcut('Riwayat','Daftar laporan milik akun','Riwayat',
        Icons.history_rounded,Color(0xFFE6F4FF)),
    ];
    final allowed=modules.map((f)=>f.route).toSet();
    final result=choices.where((item)=>allowed.contains(item.route)).toList();
    if(result.isEmpty)result.add(const CikokoV5Shortcut('Riwayat','Laporan yang dapat diakses','Riwayat',
      Icons.history_rounded,Color(0xFFE6F4FF)));
    return result;
  }
  @override Widget build(BuildContext context){
    final actions=_actions();
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      CikokoV5SectionTitle(
        title:'Laporan Terpadu',
        description:'Pelaporan, pemantauan, dan tindak lanjut dalam satu tempat',
        action:expanded?null:'Semua Laporan',
        onAction:expanded?null:()=>navigate('Laporan Terpadu')),
      Container(
        padding:const EdgeInsets.all(12),
        decoration:BoxDecoration(color:Colors.white,
          border:Border.all(color:CikokoV5.line),borderRadius:BorderRadius.circular(16),
          boxShadow:const [BoxShadow(color:Color(0x0A0F447A),blurRadius:11,offset:Offset(0,3))]),
        child:Column(children:[
          Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:10),
            decoration:BoxDecoration(
              gradient:const LinearGradient(colors:[Color(0xFF0B3973),CikokoV5.navy]),
              borderRadius:BorderRadius.circular(11)),
            child:const Row(children:[
              Icon(Icons.assessment_outlined,color:Colors.white,size:21),
              SizedBox(width:9),
              Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text('Pusat Laporan Cikoko',
                  style:TextStyle(fontSize:12.8,fontWeight:FontWeight.w800,color:Colors.white)),
                Text('Akses laporan sesuai kewenangan akun Anda',
                  style:TextStyle(fontSize:10.2,color:Color(0xFFD6E8FF))),
              ])),
              Icon(Icons.arrow_forward_ios_rounded,color:Colors.white,size:13),
            ])),
          const SizedBox(height:11),
          for(var i=0;i<actions.length;i++)Padding(padding:EdgeInsets.only(bottom:i==actions.length-1?0:7),
            child:Material(color:CikokoV5.canvas,borderRadius:BorderRadius.circular(10),
              child:InkWell(onTap:()=>navigate(actions[i].route),
                borderRadius:BorderRadius.circular(10),
                child:Padding(padding:const EdgeInsets.symmetric(horizontal:9,vertical:9),
                  child:Row(children:[
                    Container(width:35,height:35,
                      decoration:BoxDecoration(color:actions[i].tint,borderRadius:BorderRadius.circular(9)),
                      child:Icon(actions[i].icon,color:CikokoV5.blue,size:20)),
                    const SizedBox(width:10),
                    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                      Text(actions[i].title,style:const TextStyle(fontSize:12.2,
                        fontWeight:FontWeight.w800,color:CikokoV5.navy)),
                      Text(actions[i].subtitle,maxLines:1,overflow:TextOverflow.ellipsis,
                        style:const TextStyle(fontSize:10.2,color:CikokoV5.muted)),
                    ])),
                    const Icon(Icons.chevron_right_rounded,color:CikokoV5.muted,size:18),
                  ]))))),
          if(letterCounts!=null)...[
            const SizedBox(height:8),
            const Divider(height:14,color:CikokoV5.line),
            const Align(alignment:Alignment.centerLeft,
              child:Text('Status Pelayanan Surat',style:TextStyle(fontSize:11.5,
                color:CikokoV5.navy,fontWeight:FontWeight.w800))),
            const SizedBox(height:7),
            Row(children:[
              for(final item in const [
                ('masuk','Masuk',Color(0xFF1268E5)),
                ('proses','Proses',Color(0xFFD9891B)),
                ('selesai','Selesai',Color(0xFF168E63)),
              ])Expanded(child:Padding(padding:const EdgeInsets.symmetric(horizontal:2),
                child:InkWell(onTap:()=>onLetterStatus(item.$1),
                  child:Container(
                    padding:const EdgeInsets.symmetric(vertical:8),
                    decoration:BoxDecoration(color:CikokoV5.canvas,
                      borderRadius:BorderRadius.circular(9)),
                    child:Column(children:[
                      Text((letterCounts![item.$1]??0).toString(),
                        style:TextStyle(fontSize:19,color:item.$3,fontWeight:FontWeight.w900)),
                      Text(item.$2,style:const TextStyle(fontSize:9.5,color:CikokoV5.muted)),
                    ]),
                  )))),
            ]),
          ],
        ]),
      ),
    ]);
  }
}

class CikokoV5ServicePanel extends StatelessWidget{
  final void Function(String) navigate;
  const CikokoV5ServicePanel({super.key,required this.navigate});
  @override Widget build(BuildContext context){
    const entries=[
      ('Ahli Waris',Icons.description_outlined,'Surat Ahli Waris'),
      ('Pengantar RT/RW',Icons.home_work_outlined,'Surat Pengantar RT/RW'),
      ('Layanan Online',Icons.widgets_outlined,'Layanan Online'),
      ('Pengaduan',Icons.campaign_outlined,'Hubungi Kami'),
      ('Inovasi',Icons.auto_awesome_outlined,'Inovasi'),
      ('Galeri',Icons.photo_library_outlined,'Galeri'),
    ];
    return Column(children:[
      CikokoV5SectionTitle(title:'Layanan Masyarakat',
        description:'Layanan digital untuk warga Kelurahan Cikoko',
        action:'Lihat Semua',onAction:()=>navigate('Layanan Online')),
      LayoutBuilder(builder:(ctx,constraints)=>GridView.count(
        crossAxisCount:constraints.maxWidth>=640?6:3,
        crossAxisSpacing:8,mainAxisSpacing:8,
        childAspectRatio:constraints.maxWidth>=640?1.1:.93,
        physics:const NeverScrollableScrollPhysics(),shrinkWrap:true,
        children:[
          for(final entry in entries)Material(
            color:Colors.white,borderRadius:BorderRadius.circular(13),
            child:InkWell(
              onTap:()=>navigate(entry.$3),borderRadius:BorderRadius.circular(13),
              child:Container(
                padding:const EdgeInsets.symmetric(horizontal:5,vertical:10),
                decoration:BoxDecoration(borderRadius:BorderRadius.circular(13),
                  border:Border.all(color:CikokoV5.line)),
                child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
                  Container(width:43,height:43,
                    decoration:BoxDecoration(color:CikokoV5.ice,borderRadius:BorderRadius.circular(13)),
                    child:Icon(entry.$2,color:CikokoV5.blue,size:24)),
                  const SizedBox(height:8),
                  Text(entry.$1,maxLines:2,textAlign:TextAlign.center,overflow:TextOverflow.ellipsis,
                    style:const TextStyle(fontWeight:FontWeight.w800,color:CikokoV5.navy,fontSize:10.8,height:1.2)),
                ]),
              ))),
        ]),
      ),
    ]);
  }
}

class CikokoV5Home extends StatelessWidget{
  final String role;
  final bool guest;
  final List<RoleFeature> modules;
  final CikokoApi api;
  final List<dynamic> items;
  final List<dynamic> events;
  final Map<String,int>? letterCounts;
  final void Function(String) navigate;
  final void Function(String) letterStatus;
  final void Function(Map<String,dynamic>) newsTap;
  final VoidCallback openLogin;
  final Future<void> Function() onRefresh;
  const CikokoV5Home({super.key,required this.role,required this.guest,
    required this.modules,required this.api,required this.items,required this.events,
    required this.letterCounts,required this.navigate,required this.letterStatus,
    required this.newsTap,required this.openLogin,required this.onRefresh});
  @override Widget build(BuildContext context){
    final news=items.where((v)=>v is Map &&
      (v['type']=='berita'||v['type']=='pengumuman')).take(3).toList();
    return RefreshIndicator(onRefresh:onRefresh,child:ListView(
      key:const Key('cikoko_v5_home'),
      padding:const EdgeInsets.fromLTRB(14,12,14,28),
      children:[
        CikokoV5Hero(onServices:()=>navigate('Layanan Online'),
          onAbout:()=>navigate('Tentang Kami')),
        if(guest)Padding(padding:const EdgeInsets.only(top:10),
          child:Material(color:CikokoV5.ice,borderRadius:BorderRadius.circular(10),
            child:ListTile(dense:true,
              leading:const Icon(Icons.lock_open_rounded,color:CikokoV5.blue,size:21),
              title:const Text('Masuk untuk mengajukan surat dan laporan',
                style:TextStyle(fontSize:11.6,fontWeight:FontWeight.w700)),
              trailing:TextButton(onPressed:openLogin,child:const Text('Masuk'))))),
        const SizedBox(height:19),
        CikokoV5ReportPanel(role:role,guest:guest,modules:modules,
          letterCounts:letterCounts,navigate:navigate,onLetterStatus:letterStatus),
        const SizedBox(height:24),
        CikokoV5ServicePanel(navigate:navigate),
        const SizedBox(height:23),
        CikokoV5SectionTitle(title:'Berita & Informasi',
          description:'Publikasi dan kegiatan terbaru dari kelurahan',
          action:'Lihat Semua',onAction:()=>navigate('Berita & Kegiatan')),
        if(news.isEmpty)Container(
          padding:const EdgeInsets.all(18),
          decoration:BoxDecoration(color:Colors.white,
            borderRadius:BorderRadius.circular(13),border:Border.all(color:CikokoV5.line)),
          child:const Text('Belum ada berita yang dipublikasikan.',
            style:TextStyle(fontSize:12,color:CikokoV5.muted))),
        for(final raw in news)...[
          _CikokoV5NewsTile(item:Map<String,dynamic>.from(raw as Map),api:api,
            onTap:()=>newsTap(Map<String,dynamic>.from(raw))),
          const SizedBox(height:8),
        ],
        const SizedBox(height:16),
        CikokoV5SectionTitle(title:'Jelajahi Cikoko',description:'Informasi, agenda, dan profil wilayah'),
        Wrap(spacing:8,runSpacing:8,children:[
          for(final item in const [
            ('Agenda',Icons.calendar_month_outlined,'Agenda'),
            ('Inovasi',Icons.auto_awesome_outlined,'Inovasi'),
            ('Galeri',Icons.photo_library_outlined,'Galeri'),
            ('Profil Wilayah',Icons.location_on_outlined,'Profil Wilayah'),
          ])ActionChip(avatar:Icon(item.$2,size:17,color:CikokoV5.blue),
            label:Text(item.$1,style:const TextStyle(fontSize:11.5)),
            onPressed:()=>navigate(item.$3)),
        ]),
        if(!guest&&events.isNotEmpty)...[
          const SizedBox(height:21),
          CikokoV5SectionTitle(title:'Notifikasi Terbaru',
            action:'Lihat Semua',onAction:()=>navigate('Notifikasi')),
          for(final event in events.take(2))Card(child:ListTile(
            leading:const Icon(Icons.notifications_active_outlined,color:CikokoV5.blue),
            title:Text((event['title']??'Aktivitas').toString(),
              style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700)),
            subtitle:Text((event['created_at']??'').toString(),
              style:const TextStyle(fontSize:10,color:CikokoV5.muted)),
          )),
        ],
      ],
    ));
  }
}

class _CikokoV5NewsTile extends StatelessWidget{
  final Map<String,dynamic> item;
  final CikokoApi api;
  final VoidCallback onTap;
  const _CikokoV5NewsTile({required this.item,required this.api,required this.onTap});
  @override Widget build(BuildContext context) {
    final image=api.media((item['image']??'').toString());
    return Material(color:Colors.white,borderRadius:BorderRadius.circular(13),
      child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(13),
        child:Container(
          padding:const EdgeInsets.all(9),
          decoration:BoxDecoration(borderRadius:BorderRadius.circular(13),
            border:Border.all(color:CikokoV5.line)),
          child:Row(children:[
            ClipRRect(borderRadius:BorderRadius.circular(10),child:image.isEmpty
              ?Container(width:93,height:83,color:CikokoV5.ice,
                child:const Icon(Icons.newspaper_outlined,color:CikokoV5.blue))
              :Image.network(image,width:93,height:83,fit:BoxFit.cover,
                errorBuilder:(_,__,___)=>Container(width:93,height:83,
                  color:CikokoV5.ice,child:const Icon(Icons.image_outlined,color:CikokoV5.blue)))),
            const SizedBox(width:11),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text((item['type']??'berita').toString().toUpperCase(),
                style:const TextStyle(color:CikokoV5.blue,fontSize:9.5,fontWeight:FontWeight.w800)),
              const SizedBox(height:4),
              Text((item['title']??'Publikasi Kelurahan').toString(),maxLines:2,
                overflow:TextOverflow.ellipsis,
                style:const TextStyle(fontSize:12.6,fontWeight:FontWeight.w800,
                  height:1.25,color:CikokoV5.navy)),
              const SizedBox(height:7),
              Text((item['created_at']??'Baca selengkapnya').toString(),
                maxLines:1,overflow:TextOverflow.ellipsis,
                style:const TextStyle(fontSize:10.2,color:CikokoV5.muted)),
            ])),
            const Icon(Icons.chevron_right_rounded,color:CikokoV5.muted,size:17),
          ]),
        ),
      ),
    );
  }
}

class CikokoV5ReportsHub extends StatelessWidget{
  final String role;
  final bool guest;
  final List<RoleFeature> modules;
  final Map<String,int>? letterCounts;
  final void Function(String) navigate;
  final void Function(String) onLetterStatus;
  const CikokoV5ReportsHub({super.key,required this.role,required this.guest,
    required this.modules,required this.letterCounts,required this.navigate,
    required this.onLetterStatus});
  @override Widget build(BuildContext context)=>ListView(
    padding:const EdgeInsets.all(14),
    children:[
      const SizedBox(height:6),
      CikokoV5ReportPanel(role:role,guest:guest,modules:modules,
        letterCounts:letterCounts,navigate:navigate,
        onLetterStatus:onLetterStatus,expanded:true),
      const SizedBox(height:20),
      CikokoV5ServicePanel(navigate:navigate),
    ]);
}

class CikokoV5About extends StatelessWidget{
  final bool guest;
  final void Function(String) navigate;
  const CikokoV5About({super.key,required this.guest,required this.navigate});
  @override Widget build(BuildContext context)=>ListView(
    key:const Key('cikoko_v5_about'),
    padding:const EdgeInsets.all(14),children:[
      ClipRRect(borderRadius:BorderRadius.circular(17),
        child:Stack(children:[
          Image.asset('assets/kantor-cikoko.jpg',height:182,width:double.infinity,fit:BoxFit.cover),
          Positioned(bottom:0,left:0,right:0,child:Container(
            padding:const EdgeInsets.all(15),
            decoration:const BoxDecoration(gradient:LinearGradient(
              begin:Alignment.bottomCenter,end:Alignment.topCenter,
              colors:[Color(0xDD07274F),Colors.transparent])),
            child:const Text('Tentang Kelurahan Cikoko',
              style:TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.w900)))),
        ])),
      const SizedBox(height:14),
      Container(padding:const EdgeInsets.all(16),
        decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(14),
          border:Border.all(color:CikokoV5.line)),
        child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('Cikoko Smart',style:TextStyle(color:CikokoV5.navy,
            fontSize:20,fontWeight:FontWeight.w900)),
          SizedBox(height:7),
          Text('Portal layanan dan informasi Kelurahan Cikoko, Kecamatan Pancoran, Kota Administrasi Jakarta Selatan.',
            style:TextStyle(color:CikokoV5.muted,fontSize:12.5,height:1.5)),
          SizedBox(height:12),
          Text('Melalui aplikasi ini, warga dapat mengakses informasi publik dan layanan digital yang tersedia sesuai kewenangan akun.',
            style:TextStyle(color:CikokoV5.muted,fontSize:12.5,height:1.5)),
        ])),
      const SizedBox(height:19),
      const CikokoV5SectionTitle(title:'Jelajahi Informasi',
        description:'Profil wilayah, publikasi, dan kegiatan kelurahan'),
      for(final item in const [
        ('Profil Wilayah','Informasi tentang Kelurahan Cikoko',Icons.place_outlined,'Profil Wilayah'),
        ('Berita & Informasi','Publikasi terbaru',Icons.article_outlined,'Berita & Kegiatan'),
        ('Agenda Kegiatan','Agenda yang dipublikasikan',Icons.calendar_month_outlined,'Agenda'),
        ('Inovasi Kelurahan','Program inovasi kelurahan',Icons.auto_awesome_outlined,'Inovasi'),
        ('Galeri Kegiatan','Dokumentasi kegiatan',Icons.photo_library_outlined,'Galeri'),
        ('Profil Akun','Pengaturan akun pengguna',Icons.person_outline,'Profil'),
      ])Card(child:ListTile(
        onTap:()=>navigate(item.$4),
        leading:Container(width:39,height:39,decoration:BoxDecoration(
          color:CikokoV5.ice,borderRadius:BorderRadius.circular(10)),
          child:Icon(item.$3,color:CikokoV5.blue,size:21)),
        title:Text(item.$1,style:const TextStyle(
          color:CikokoV5.navy,fontWeight:FontWeight.w800,fontSize:12.5)),
        subtitle:Text(item.$2,style:const TextStyle(fontSize:10.7)),
        trailing:const Icon(Icons.chevron_right_rounded,color:CikokoV5.muted))),
    ]);
}


class CikokoV5AdminHome extends StatelessWidget{
  final List<RoleFeature> modules;
  final String roleLabel;
  final Map<String,int>? letterCounts;
  final int unreadCount;
  final List<dynamic> events;
  final void Function(String) navigate;
  const CikokoV5AdminHome({super.key,required this.modules,
    required this.roleLabel,required this.letterCounts,
    required this.unreadCount,required this.events,required this.navigate});
  @override Widget build(BuildContext context){
    final allowed=modules.map((m)=>m.route).toSet();
    final actions=[
      for(final action in const [
        ('Verifikasi Laporan',Icons.verified_user_outlined,'Verifikasi Laporan'),
        ('Ahli Waris',Icons.fact_check_outlined,'Verifikasi Ahli Waris'),
        ('Kelola Layanan',Icons.widgets_outlined,'Kelola Layanan Terpadu'),
        ('Berita',Icons.newspaper_outlined,'Tambah Berita'),
        ('Pengumuman',Icons.campaign_outlined,'Tambah Pengumuman'),
        ('LPJ RT',Icons.receipt_long_outlined,'Laporan LPJ RT'),
        ('LPJ RW',Icons.receipt_long_outlined,'Laporan LPJ RW'),
        ('Kelola Akun',Icons.manage_accounts_outlined,'Kelola Akun Petugas'),
      ])if(allowed.contains(action.$3))action,
    ];
    final metrics=[
      ('Surat Masuk',letterCounts?['masuk'],Icons.description_outlined,const Color(0xFF216AE7)),
      ('Diproses',letterCounts?['proses'],Icons.timelapse_outlined,const Color(0xFFDC8F26)),
      ('Selesai',letterCounts?['selesai'],Icons.check_circle_outline,const Color(0xFF199460)),
      ('Notifikasi',unreadCount,Icons.notifications_outlined,const Color(0xFF935AE4)),
    ];
    return ListView(padding:const EdgeInsets.all(14),children:[
      Container(padding:const EdgeInsets.all(17),
        decoration:BoxDecoration(
          gradient:const LinearGradient(colors:[CikokoV5.navy,Color(0xFF1761B4)]),
          borderRadius:BorderRadius.circular(17)),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('Dashboard '+roleLabel,
            style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:21)),
          const SizedBox(height:5),
          const Text('Pusat pengelolaan dan pemantauan Kelurahan Cikoko',
            style:TextStyle(fontSize:11.2,color:Color(0xFFDEEDFF))),
          const SizedBox(height:12),
          const Row(children:[
            Icon(Icons.shield_outlined,color:Colors.white70,size:17),
            SizedBox(width:6),
            Text('Data dari sistem layanan terhubung',
              style:TextStyle(fontSize:10.4,color:Colors.white70)),
          ]),
        ])),
      const SizedBox(height:18),
      const CikokoV5SectionTitle(title:'Ringkasan Pelayanan',
        description:'Status pelayanan surat dan aktivitas akun'),
      GridView.count(crossAxisCount:2,childAspectRatio:1.93,
        physics:const NeverScrollableScrollPhysics(),shrinkWrap:true,
        crossAxisSpacing:9,mainAxisSpacing:9,
        children:[
          for(final metric in metrics)Container(
            decoration:BoxDecoration(
              color:Colors.white,borderRadius:BorderRadius.circular(13),
              border:Border.all(color:CikokoV5.line)),
            padding:const EdgeInsets.all(10),
            child:Row(children:[
              Container(width:35,height:35,decoration:BoxDecoration(
                color:metric.$4.withValues(alpha:.12),borderRadius:BorderRadius.circular(10)),
                child:Icon(metric.$3,color:metric.$4,size:19)),
              const SizedBox(width:9),
              Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
                mainAxisAlignment:MainAxisAlignment.center,children:[
                  Text(metric.$1,maxLines:1,overflow:TextOverflow.ellipsis,
                    style:const TextStyle(fontSize:10.2,color:CikokoV5.muted)),
                  Text(metric.$2==null?'—':metric.$2.toString(),
                    style:const TextStyle(fontWeight:FontWeight.w900,
                      fontSize:21,color:CikokoV5.navy)),
                ])),
            ]),
          ),
        ]),
      const SizedBox(height:19),
      CikokoV5SectionTitle(title:'Manajemen Terpadu',
        description:'Akses menu sesuai hak akun'),
      if(actions.isEmpty)const Text('Menu pengelolaan belum tersedia untuk akun ini.',
        style:TextStyle(color:CikokoV5.muted,fontSize:12)),
      GridView.count(crossAxisCount:3,childAspectRatio:1.0,
        physics:const NeverScrollableScrollPhysics(),shrinkWrap:true,
        crossAxisSpacing:8,mainAxisSpacing:8,
        children:[
          for(final action in actions)Material(
            color:Colors.white,borderRadius:BorderRadius.circular(12),
            child:InkWell(onTap:()=>navigate(action.$3),
              borderRadius:BorderRadius.circular(12),
              child:Container(padding:const EdgeInsets.all(8),
                decoration:BoxDecoration(border:Border.all(color:CikokoV5.line),
                  borderRadius:BorderRadius.circular(12)),
                child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
                  Icon(action.$2,color:CikokoV5.blue,size:27),
                  const SizedBox(height:9),
                  Text(action.$1,textAlign:TextAlign.center,maxLines:2,
                    overflow:TextOverflow.ellipsis,
                    style:const TextStyle(color:CikokoV5.navy,
                      fontWeight:FontWeight.w800,fontSize:10.8)),
                ]),
              ))),
        ]),
      const SizedBox(height:19),
      CikokoV5SectionTitle(title:'Aktivitas Terbaru',
        action:'Semua',onAction:()=>navigate('Notifikasi')),
      if(events.isEmpty)const Padding(padding:EdgeInsets.all(14),
        child:Text('Belum ada aktivitas terbaru.',
          style:TextStyle(color:CikokoV5.muted,fontSize:12))),
      for(final item in events.take(5))Card(child:ListTile(
        leading:const Icon(Icons.notifications_none,color:CikokoV5.blue),
        title:Text((item['title']??'Aktivitas').toString(),
          style:const TextStyle(fontSize:12.4,fontWeight:FontWeight.w800)),
        subtitle:Text((item['created_at']??'').toString(),
          style:const TextStyle(fontSize:10.4,color:CikokoV5.muted)),
      )),
    ]);
  }
}


class CikokoV5NewsFeed extends StatefulWidget{
  final CikokoApi api;
  final List<dynamic> items;
  final void Function(Map<String,dynamic>) onArticle;
  const CikokoV5NewsFeed({super.key,required this.api,
    required this.items,required this.onArticle});
  @override State<CikokoV5NewsFeed> createState()=>_CikokoV5NewsFeedState();
}
class _CikokoV5NewsFeedState extends State<CikokoV5NewsFeed>{
  String type='Semua';
  String query='';
  @override Widget build(BuildContext context){
    final entries=widget.items.where((raw){
      if(raw is! Map)return false;
      final category=(raw['type']??'').toString();
      if(category!='berita'&&category!='pengumuman')return false;
      if(type=='Berita'&&category!='berita')return false;
      if(type=='Pengumuman'&&category!='pengumuman')return false;
      return (raw['title']??'').toString().toLowerCase().contains(query.toLowerCase());
    }).toList();
    return ListView(padding:const EdgeInsets.all(14),children:[
      const CikokoV5SectionTitle(title:'Berita & Informasi',
        description:'Publikasi resmi dan kegiatan Kelurahan Cikoko'),
      Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:3),
        decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(11),
          border:Border.all(color:CikokoV5.line)),
        child:TextField(onChanged:(v)=>setState(()=>query=v),
          decoration:const InputDecoration(
            prefixIcon:Icon(Icons.search_rounded,color:CikokoV5.blue),
            hintText:'Cari berita dan informasi…',
            border:InputBorder.none,enabledBorder:InputBorder.none,
            focusedBorder:InputBorder.none,filled:false))),
      const SizedBox(height:11),
      Wrap(spacing:7,children:[
        for(final item in const ['Semua','Berita','Pengumuman'])
          ChoiceChip(label:Text(item,style:const TextStyle(fontSize:10.8)),
            selected:type==item,onSelected:(_)=>setState(()=>type=item)),
      ]),
      const SizedBox(height:12),
      if(entries.isEmpty)Container(
        padding:const EdgeInsets.all(18),decoration:BoxDecoration(
          color:Colors.white,borderRadius:BorderRadius.circular(13),
          border:Border.all(color:CikokoV5.line)),
        child:const Text('Belum ada informasi sesuai pilihan.',
          style:TextStyle(color:CikokoV5.muted,fontSize:12))),
      for(final raw in entries)...[
        _CikokoV5NewsTile(
          item:Map<String,dynamic>.from(raw as Map),
          api:widget.api,
          onTap:()=>widget.onArticle(Map<String,dynamic>.from(raw))),
        const SizedBox(height:9),
      ],
    ]);
  }
}

class CikokoV5ServicesHub extends StatefulWidget{
  final bool guest;
  final void Function(String) navigate;
  const CikokoV5ServicesHub({super.key,required this.guest,required this.navigate});
  @override State<CikokoV5ServicesHub> createState()=>_CikokoV5ServicesHubState();
}
class _CikokoV5ServicesHubState extends State<CikokoV5ServicesHub>{
  String query='';
  String filter='Semua';
  static const entries=[
    ('Surat Ahli Waris','Pengajuan dan informasi persyaratan','Surat','Surat Ahli Waris',Icons.description_outlined),
    ('Pengantar RT/RW','Pengajuan pengantar melalui wilayah RT/RW','Surat','Surat Pengantar RT/RW',Icons.home_work_outlined),
    ('Pelaporan Jumantik','Pemantauan kondisi lingkungan','Laporan','Laporan Jumantik',Icons.health_and_safety_outlined),
    ('Riwayat Pengajuan','Pantau perkembangan pengajuan Anda','Laporan','Riwayat',Icons.fact_check_outlined),
    ('Pengaduan Warga','Hubungi petugas Kelurahan Cikoko','Laporan','Hubungi Kami',Icons.campaign_outlined),
    ('Layanan Pemerintahan','Daftar layanan instansi terkait','Lainnya','Katalog DKI',Icons.account_balance_outlined),
  ];
  @override Widget build(BuildContext context){
    final visible=entries.where((e)=>(filter=='Semua'||e.$3==filter)&&
      (e.$1.toLowerCase().contains(query.toLowerCase())||
       e.$2.toLowerCase().contains(query.toLowerCase()))).toList();
    return ListView(padding:const EdgeInsets.all(14),children:[
      const CikokoV5SectionTitle(title:'Layanan Online',
        description:'Pelayanan digital Kelurahan Cikoko'),
      Container(
        padding:const EdgeInsets.symmetric(horizontal:9),
        decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(11),
          border:Border.all(color:CikokoV5.line)),
        child:TextField(onChanged:(value)=>setState(()=>query=value),
          decoration:const InputDecoration(
            prefixIcon:Icon(Icons.search_rounded,color:CikokoV5.blue),
            hintText:'Cari layanan kelurahan…',
            border:InputBorder.none,enabledBorder:InputBorder.none,
            focusedBorder:InputBorder.none,filled:false))),
      const SizedBox(height:11),
      Wrap(spacing:7,runSpacing:7,children:[
        for(final item in const ['Semua','Surat','Laporan','Lainnya'])
          ChoiceChip(label:Text(item,style:const TextStyle(fontSize:10.5)),
            selected:filter==item,onSelected:(_)=>setState(()=>filter=item)),
      ]),
      const SizedBox(height:12),
      for(final entry in visible)Card(
        margin:const EdgeInsets.only(bottom:8),
        child:ListTile(contentPadding:const EdgeInsets.symmetric(horizontal:13,vertical:5),
          leading:Container(width:43,height:43,
            decoration:BoxDecoration(color:CikokoV5.ice,borderRadius:BorderRadius.circular(11)),
            child:Icon(entry.$5,color:CikokoV5.blue,size:23)),
          title:Text(entry.$1,style:const TextStyle(
            color:CikokoV5.navy,fontSize:12.8,fontWeight:FontWeight.w800)),
          subtitle:Text(entry.$2,style:const TextStyle(
            color:CikokoV5.muted,fontSize:10.5)),
          trailing:const Icon(Icons.chevron_right_rounded,color:CikokoV5.blue),
          onTap:()=>widget.navigate(entry.$4))),
      if(visible.isEmpty)const Padding(padding:EdgeInsets.all(18),
        child:Text('Layanan tidak ditemukan.',
          style:TextStyle(color:CikokoV5.muted))),
      if(widget.guest)const Padding(padding:EdgeInsets.only(top:11),
        child:Text('Masuk dengan akun warga untuk mengajukan layanan.',
          style:TextStyle(fontSize:11,color:CikokoV5.muted))),
    ]);
  }
}
