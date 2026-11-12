import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'cikoko_v6_showcase.dart';

/// Authorized staff navigation to existing, authenticated website CMS pages.
/// A browser session is required. This never transfers the Flutter bearer token
/// into a URL or pretends that an editor endpoint exists.
class CikokoAdminContentHub extends StatelessWidget {
 final String role;
 final ValueChanged<String> openInApp;
 const CikokoAdminContentHub({
  super.key,required this.role,required this.openInApp});

 static const groups=<(
  String,String,List<(String,String,String,IconData)>
 )>[
  ('BERANDA & IDENTITAS','Susunan dan tampilan halaman utama',[
   ('Beranda Aplikasi','Foto header, kartu utama, dan susunan beranda','beranda-aplikasi',Icons.home_outlined),
   ('Tampilan Website','Logo, warna, dan tampilan seluruh halaman','tampilan',Icons.palette_outlined),
   ('CMS Halaman','Judul, deskripsi, dan isi halaman website','cms-halaman',Icons.description_outlined),
  ]),
  ('PUBLIKASI & MEDIA','Konten publik yang dapat dibaca berbagai akun',[
   ('Berita & Informasi','Tambah, ubah, dan terbitkan detail berita','berita',Icons.newspaper_outlined),
   ('Pengumuman','Kelola pengumuman resmi','pengumuman',Icons.campaign_outlined),
   ('Galeri Kegiatan','Foto, keterangan, dan dokumentasi kegiatan','galeri-kegiatan',Icons.photo_library_outlined),
   ('Galeri Media','Perpustakaan gambar dan media','galeri-media',Icons.collections_outlined),
   ('Inovasi Kelurahan','Daftar dan detail inovasi yang diterbitkan','inovasi',Icons.auto_awesome_outlined),
  ]),
  ('LAYANAN & WILAYAH','Informasi layanan dan profil kelurahan',[
   ('CMS Layanan','Detail, syarat, dan uraian pelayanan','cms-layanan',Icons.assignment_outlined),
   ('Peta & Profil Wilayah','Peta, data wilayah, dan informasi Cikoko','wilayah',Icons.map_outlined),
   ('Laporan Publik','Publikasi laporan dan informasi terkait','laporan-publik',Icons.assessment_outlined),
  ]),
 ];

 Future<void> openWebsiteEditor(BuildContext context,String slug) async{
  final target=Uri.https('datawebs.my.id','/admin/$slug');
  try{
   final ok=await launchUrl(target,mode:LaunchMode.externalApplication);
   if(!ok&&context.mounted)_feedback(context,'Halaman pengelolaan belum dapat dibuka.');
  }catch(_){
   if(context.mounted)_feedback(context,'Gagal membuka halaman admin. Periksa koneksi internet.');
  }
 }
 void _feedback(BuildContext context,String message){
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(message)));
 }
 @override Widget build(BuildContext context){
  final isMain=role=='admin';
  final isAdmin=isMain||role=='admin_kelurahan';
  if(!isAdmin)return const Center(child:Text(
   'Pengaturan halaman hanya tersedia untuk administrator.'));
  return ListView(key:const Key('cikoko_admin_content_hub'),
    padding:const EdgeInsets.all(14),children:[
    const V6PageHeader(title:'Kelola Semua Halaman',
      description:'Pusat pengelolaan konten dan tampilan untuk website serta aplikasi Cikoko Smart.',
      icon:Icons.dashboard_customize_outlined),
    const V6Panel(child:Row(children:[
     Icon(Icons.info_outline,color:V6.blue,size:20),
     SizedBox(width:10),
     Expanded(child:Text(
      'Editor konten website dibuka melalui panel admin resmi. Login website diperlukan dan hak akses diperiksa kembali oleh server. Perubahan konten yang terhubung API akan tampil di aplikasi.',
      style:TextStyle(fontSize:10.8,color:V6.secondary,height:1.4))),
    ])),
    const SizedBox(height:15),
    for(final group in groups)...[
     Padding(padding:const EdgeInsets.symmetric(vertical:7),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
       Text(group.$1,style:const TextStyle(color:V6.ink,
        fontSize:13.5,fontWeight:FontWeight.w900)),
       const SizedBox(height:3),
       Text(group.$2,style:const TextStyle(fontSize:10.8,color:V6.secondary)),
      ])),
     for(final entry in group.$3)Padding(padding:const EdgeInsets.only(bottom:8),
      child:Material(color:Colors.white,borderRadius:V6.radius(12),
       child:InkWell(
        key:Key('cms_'+entry.$3),
        onTap:()=>openWebsiteEditor(context,entry.$3),
        borderRadius:V6.radius(12),
        child:Container(
         padding:const EdgeInsets.symmetric(horizontal:12,vertical:11),
         decoration:BoxDecoration(border:Border.all(color:V6.border),
           borderRadius:V6.radius(12)),
         child:Row(children:[
          Container(width:39,height:39,
            decoration:BoxDecoration(color:V6.pale,borderRadius:V6.radius(10)),
            child:Icon(entry.$4,color:V6.blue,size:21)),
          const SizedBox(width:11),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
           Text(entry.$1,style:const TextStyle(fontSize:12.5,
             fontWeight:FontWeight.w800,color:V6.ink)),
           const SizedBox(height:4),
           Text(entry.$2,style:const TextStyle(
             fontSize:10.5,color:V6.secondary,height:1.35)),
          ])),
          const Icon(Icons.open_in_new,color:V6.blue,size:17),
         ]),
        ),
       )),
     ),
     const SizedBox(height:8),
    ],
    if(isMain)...[
     const SizedBox(height:8),
     const V6Section(title:'Pengelolaan Langsung dari Aplikasi'),
     for(final entry in const [
      ('Kelola Layanan Terpadu','Logo, judul, tautan, dan layanan DKI',
        'Kelola Layanan Terpadu',Icons.widgets_outlined),
      ('Kelola Akun Petugas','Akun dan kewenangan pengguna',
        'Kelola Akun Petugas',Icons.manage_accounts_outlined),
      ('Hak Akses Role','Atur izin menu untuk setiap jenis akun',
        'Hak Akses Role',Icons.admin_panel_settings_outlined),
     ])Padding(padding:const EdgeInsets.only(bottom:8),child:V6Panel(
      padding:EdgeInsets.zero,child:ListTile(
       onTap:()=>openInApp(entry.$3),
       leading:Icon(entry.$4,color:V6.blue),
       title:Text(entry.$1,style:const TextStyle(fontSize:12.1,
         fontWeight:FontWeight.w800,color:V6.ink)),
       subtitle:Text(entry.$2,style:const TextStyle(fontSize:10.5)),
       trailing:const Icon(Icons.chevron_right_rounded,color:V6.blue),
      ))),
    ],
    const SizedBox(height:17),
   ]);
 }
}

class CikokoAdminBottomNav extends StatelessWidget {
 final int selected;
 final ValueChanged<int> onSelected;
 const CikokoAdminBottomNav({super.key,required this.selected,required this.onSelected});
 @override Widget build(BuildContext context){
  const options=[
   ('Kelola',Icons.dashboard_customize_outlined),
   ('Layanan',Icons.widgets_outlined),
   ('Beranda',Icons.home_outlined),
   ('Laporan',Icons.fact_check_outlined),
   ('Akun',Icons.person_outline),
  ];
  return SafeArea(top:false,child:Container(height:68,
   decoration:const BoxDecoration(color:Colors.white,
    border:Border(top:BorderSide(color:V6.border))),
   child:Row(children:[
    for(var i=0;i<options.length;i++)Expanded(child:InkWell(
      key:Key('admin_nav_$i'),
      onTap:()=>onSelected(i),
      child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
       Container(height:33,width:43,
        decoration:BoxDecoration(color:i==selected?V6.pale:Colors.transparent,
          borderRadius:V6.radius(11)),
        child:Icon(options[i].$2,size:22,color:i==selected?V6.blue:V6.secondary)),
       const SizedBox(height:4),
       Text(options[i].$1,style:TextStyle(fontSize:10.2,
         color:i==selected?V6.blue:V6.ink,
         fontWeight:i==selected?FontWeight.w800:FontWeight.w600)),
      ]),
    )),
   ]),
  ));
 }
}
