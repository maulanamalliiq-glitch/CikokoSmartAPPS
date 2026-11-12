import 'package:flutter/material.dart';
import 'api.dart';
import 'cikoko_v6_showcase.dart';
import 'cikoko_header_editor.dart';
import 'cikoko_content_admin.dart';
import 'cikoko_appearance_admin.dart';
import 'cikoko_pages_admin.dart';

/// Every CMS tile opens a genuine native Flutter form, never a website link.
/// API operations still enforce administrator authorization on the server.
class CikokoAdminContentHub extends StatelessWidget {
 final CikokoApi api;
 final String role;
 final ValueChanged<String> openInApp;
 final VoidCallback? onPublished;
 const CikokoAdminContentHub({
  super.key,required this.api,required this.role,
  required this.openInApp,this.onPublished,
 });

 static const groups=<(
  String,String,List<(String,String,String,IconData)>
 )>[
  ('BERANDA & IDENTITAS','Atur foto, profil dan tampilan utama',[
   ('Ganti Foto Header','Dari kamera/galeri — sama dengan slideshow website',
    'beranda-aplikasi',Icons.photo_library_outlined),
   ('Tampilan Website','Logo, foto, dan pengaturan tampilan website',
    'tampilan',Icons.palette_outlined),
   ('CMS Halaman','Judul dan isi halaman situs','cms-halaman',
    Icons.description_outlined),
  ]),
  ('PUBLIKASI & MEDIA','Konten yang tampil pada website dan aplikasi',[
   ('Berita & Informasi','Tambah, edit, hapus berita resmi',
    'berita',Icons.newspaper_outlined),
   ('Pengumuman','Ubah pengumuman resmi','pengumuman',
    Icons.campaign_outlined),
   ('Galeri Kegiatan','Foto dan dokumentasi kegiatan','galeri-kegiatan',
    Icons.photo_library_outlined),
   ('Galeri Media','Kelola gambar dalam konten Galeri','galeri-media',
    Icons.collections_outlined),
   ('Inovasi Kelurahan','Edit judul, ringkasan dan isi inovasi',
    'inovasi',Icons.auto_awesome_outlined),
  ]),
  ('LAYANAN & WILAYAH','Informasi pelayanan dan profil daerah',[
   ('CMS Layanan','Judul dan uraian pelayanan website',
    'cms-layanan',Icons.assignment_outlined),
   ('Peta & Profil Wilayah','Judul dan data profil wilayah',
    'wilayah',Icons.map_outlined),
   ('PPID','Informasi keterbukaan publik','ppid',Icons.info_outline),
   ('Agenda Kegiatan','Informasi agenda kelurahan',
    'agenda',Icons.event_outlined),
   ('Profil Pimpinan','Keterangan pejabat dan pimpinan',
    'pimpinan',Icons.account_box_outlined),
   ('Kontak','Informasi dan kontak kelurahan',
    'kontak',Icons.contact_mail_outlined),
   ('Laporan Publik','Informasi dan publikasi laporan',
    'laporan-publik',Icons.assessment_outlined),
  ]),
 ];

 void openNativeEditor(BuildContext context,String slug) {
  if(role!='admin'){
   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
     content:Text('Edit semua halaman hanya tersedia untuk Admin Utama.')));
   return;
  }
  final Widget content;
  switch(slug){
   case 'beranda-aplikasi':
    content=CikokoHomeSlidesEditor(api:api,onPublished:onPublished);
   case 'tampilan':
    content=CikokoAppearanceAdmin(api:api,onPublished:onPublished);
   case 'berita':
    content=CikokoContentAdmin(api:api,contentType:'berita',
      onPublished:onPublished);
   case 'pengumuman':
    content=CikokoContentAdmin(api:api,contentType:'pengumuman',
      onPublished:onPublished);
   case 'galeri-kegiatan':
   case 'galeri-media':
    content=CikokoContentAdmin(api:api,contentType:'galeri',
      onPublished:onPublished);
   case 'cms-layanan':
    content=CikokoContentAdmin(api:api,contentType:'layanan',
      onPublished:onPublished);
   case 'inovasi':
    content=CikokoInnovationsAdmin(api:api,onPublished:onPublished);
   case 'wilayah':
   case 'ppid':
   case 'agenda':
   case 'pimpinan':
   case 'kontak':
   case 'laporan-publik':
    content=CikokoPagesAdmin(api:api,initialSlug:slug,
      onPublished:onPublished);
   default:
    content=CikokoPagesAdmin(api:api,onPublished:onPublished);
  }
  Navigator.of(context).push(MaterialPageRoute<void>(
   builder:(_)=>Scaffold(
    appBar:AppBar(title:const Text('Edit Halaman Cikoko')),
    body:content,
   ),
  ));
 }

 @override Widget build(BuildContext context) {
  final isAdmin=role=='admin'||role=='admin_kelurahan';
  if(!isAdmin)return const Center(child:Text(
   'Pengaturan halaman hanya tersedia untuk administrator.'));
  return ListView(key:const Key('cikoko_admin_content_hub'),
   padding:const EdgeInsets.all(14),children:[
    const V6PageHeader(title:'Kelola Semua Halaman',
     description:'Edit konten website & aplikasi dari dalam Cikoko Smart.',
     icon:Icons.dashboard_customize_outlined),
    const V6Panel(child:Row(children:[
     Icon(Icons.phone_android,color:V6.blue,size:20),
     SizedBox(width:10),
     Expanded(child:Text(
       'Semua menu editor di bawah terbuka di aplikasi, tanpa browser '
       'atau login website terpisah. Perubahan tersimpan setelah menekan Simpan. '
       'Fitur tertentu memerlukan Mobile API terbaru di cPanel.',
       style:TextStyle(fontSize:10.8,color:V6.secondary,height:1.4))),
    ])),
    const SizedBox(height:10),
    if(role!='admin')const V6Panel(child:Text(
      'Akun ini dapat melihat daftar modul; hanya Admin Utama '
      'yang dapat mengubah seluruh halaman.')),
    const SizedBox(height:10),
    V6Panel(padding:EdgeInsets.zero,child:ListTile(
     key:const Key('admin_push_menu'),
     onTap:()=>openInApp('Push Notifikasi'),
     leading:const Icon(Icons.notifications_active_outlined,color:V6.blue),
     title:const Text('Push Notifikasi',
       style:TextStyle(fontWeight:FontWeight.w900,fontSize:13,color:V6.ink)),
     subtitle:const Text('Kirim dari aplikasi, cek Firebase dan Cron.',
       style:TextStyle(color:V6.secondary,fontSize:10.5)),
     trailing:const Icon(Icons.chevron_right_rounded,color:V6.blue),
    )),
    const SizedBox(height:15),
    for(final group in groups)...[
     Padding(padding:const EdgeInsets.symmetric(vertical:7),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
       Text(group.$1,style:const TextStyle(color:V6.ink,
        fontSize:13.5,fontWeight:FontWeight.w900)),
       const SizedBox(height:3),
       Text(group.$2,style:const TextStyle(fontSize:10.8,color:V6.secondary)),
      ])),
     for(final entry in group.$3)Padding(
      padding:const EdgeInsets.only(bottom:8),
      child:Material(color:Colors.white,borderRadius:V6.radius(12),
       child:InkWell(
        key:Key('cms_'+entry.$3),
        onTap:()=>openNativeEditor(context,entry.$3),
        borderRadius:V6.radius(12),
        child:Container(
         padding:const EdgeInsets.symmetric(horizontal:12,vertical:11),
         decoration:BoxDecoration(border:Border.all(color:V6.border),
           borderRadius:V6.radius(12)),
         child:Row(children:[
          Container(width:39,height:39,
           decoration:BoxDecoration(color:V6.pale,
             borderRadius:V6.radius(10)),
           child:Icon(entry.$4,color:V6.blue,size:21)),
          const SizedBox(width:11),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
           children:[
            Text(entry.$1,style:const TextStyle(fontSize:12.5,
             fontWeight:FontWeight.w800,color:V6.ink)),
            const SizedBox(height:4),
            Text(entry.$2,style:const TextStyle(
             fontSize:10.5,color:V6.secondary,height:1.35)),
           ])),
          const Icon(Icons.chevron_right,color:V6.blue,size:18),
         ]),
        ),
       )),
     ),
     const SizedBox(height:8),
    ],
    if(role=='admin')...[
     const V6Section(title:'Pengelolaan Langsung Lainnya'),
     for(final entry in const [
      ('Kelola Layanan Terpadu','Logo, judul, dan tautan layanan DKI',
        'Kelola Layanan Terpadu',Icons.widgets_outlined),
      ('Kelola Akun Petugas','Akun dan kewenangan pengguna',
        'Kelola Akun Petugas',Icons.manage_accounts_outlined),
      ('Hak Akses Role','Atur izin untuk setiap peran',
        'Hak Akses Role',Icons.admin_panel_settings_outlined),
     ])Padding(padding:const EdgeInsets.only(bottom:8),
      child:V6Panel(padding:EdgeInsets.zero,child:ListTile(
       onTap:()=>openInApp(entry.$3),
       leading:Icon(entry.$4,color:V6.blue),
       title:Text(entry.$1,style:const TextStyle(fontSize:12.1,
         fontWeight:FontWeight.w800,color:V6.ink)),
       subtitle:Text(entry.$2,style:const TextStyle(fontSize:10.5)),
       trailing:const Icon(Icons.chevron_right_rounded,color:V6.blue),
      ))),
    ],
    const SizedBox(height:17),
   ],
  );
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
