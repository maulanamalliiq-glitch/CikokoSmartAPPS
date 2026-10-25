import 'package:flutter/material.dart';

const homeIcons=<String,IconData>{
 'badge':Icons.badge_outlined,'description':Icons.description_outlined,
 'receipt':Icons.receipt_long_outlined,'support':Icons.support_agent_outlined,
 'newspaper':Icons.newspaper_outlined,'apps':Icons.apps_outlined,
 'home':Icons.home_outlined,'calendar':Icons.calendar_month_outlined,
 'phone':Icons.phone_outlined,'map':Icons.place_outlined,'heart':Icons.favorite_border,
 'school':Icons.school_outlined,'shield':Icons.shield_outlined,
 'photo':Icons.photo_library_outlined,'users':Icons.groups_outlined,
 'chat':Icons.chat_bubble_outline,'leaf':Icons.eco_outlined,
};
final defaultHomeServices=<Map<String,dynamic>>[
 {'title':'Administrasi Kependudukan','subtitle':'Informasi KTP dan KK','icon':'badge','color':'#2868c9','target':'route:Layanan Online'},
 {'title':'Surat Keterangan','subtitle':'Ahli waris dan lainnya','icon':'description','color':'#15966d','target':'route:Surat Ahli Waris'},
 {'title':'Layanan PBB','subtitle':'Informasi pajak daerah','icon':'receipt','color':'#386bd9','target':'route:Layanan Online'},
 {'title':'Pengaduan','subtitle':'Kirim pesan ke petugas','icon':'support','color':'#e88a25','target':'route:Hubungi Kami'},
 {'title':'Informasi Publik','subtitle':'Berita dan kegiatan','icon':'newspaper','color':'#6554cb','target':'route:Pusat Informasi'},
 {'title':'Layanan Lainnya','subtitle':'Jelajahi semua layanan','icon':'apps','color':'#54738d','target':'route:Menu Cikoko'},
];
Color homeColor(dynamic text){
 final hex=(text??'').toString().replaceAll('#','');
 if(!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex))return const Color(0xff2868c9);
 return Color(int.parse('FF$hex',radix:16));
}
