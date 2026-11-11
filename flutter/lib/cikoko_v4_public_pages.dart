import 'package:flutter/material.dart';
import 'api.dart';

const Color civicV4Blue = Color(0xFF1268E5);
const Color civicV4Navy = Color(0xFF082D5E);
const Color civicV4Muted = Color(0xFF667E98);
const Color civicV4Line = Color(0xFFDCE8F5);

class CivicV4Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const CivicV4Header({super.key,required this.title,required this.subtitle,required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors:[Color(0xFFE4F1FF),Color(0xFFF5FAFF)]),
      border: Border.all(color: civicV4Line),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(children: [
      Container(width:43,height:43,decoration:BoxDecoration(
        color:Colors.white,borderRadius:BorderRadius.circular(12)),
        child:Icon(icon,color:civicV4Blue,size:24)),
      const SizedBox(width:12),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(title,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:19,color:civicV4Navy)),
        const SizedBox(height:3),
        Text(subtitle,style:const TextStyle(fontSize:11,color:civicV4Muted)),
      ])),
    ]),
  );
}

class CivicV4Empty extends StatelessWidget {
  final String message;
  final IconData icon;
  const CivicV4Empty({super.key,required this.message,this.icon=Icons.inbox_outlined});
  @override Widget build(BuildContext context)=>Padding(
    padding:const EdgeInsets.symmetric(vertical:25,horizontal:18),
    child:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[
      Icon(icon,color:const Color(0xFF91ADCD),size:38),
      const SizedBox(height:8),
      Text(message,textAlign:TextAlign.center,
        style:const TextStyle(color:civicV4Muted,fontSize:12)),
    ])),
  );
}

class CikokoV4Services extends StatelessWidget {
  final bool guest;
  final void Function(String route) navigate;
  const CikokoV4Services({super.key,required this.guest,required this.navigate});
  static const options=[
    ('Surat Pengantar Ahli Waris','Informasi persyaratan dan pengajuan ahli waris',Icons.description_outlined,'Surat Ahli Waris'),
    ('Pengantar RT/RW','Pengajuan pengantar melalui RT dan RW',Icons.home_work_outlined,'Surat Pengantar RT/RW'),
    ('Laporan Jumantik','Pelaporan pemantauan jentik lingkungan',Icons.health_and_safety_outlined,'Laporan Jumantik'),
    ('Riwayat Pengajuan','Pantau laporan dan surat yang Anda ajukan',Icons.fact_check_outlined,'Riwayat'),
    ('Layanan Terpadu DKI','Akses berbagai layanan pemerintahan terkait',Icons.account_balance_outlined,'Katalog DKI'),
  ];
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(14),children:[
    const CivicV4Header(title:'Layanan Online',subtitle:'Pilih pelayanan sesuai kebutuhan Anda',icon:Icons.widgets_outlined),
    const SizedBox(height:13),
    Container(padding:const EdgeInsets.symmetric(horizontal:13,vertical:12),
      decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(11),
        border:Border.all(color:civicV4Line)),
      child:const Row(children:[Icon(Icons.search,color:civicV4Muted,size:19),SizedBox(width:9),
        Expanded(child:Text('Layanan Kelurahan Cikoko',style:TextStyle(fontSize:12,color:civicV4Muted)))])),
    const SizedBox(height:12),
    for(final option in options)Card(
      margin:const EdgeInsets.only(bottom:9),
      child:ListTile(
        contentPadding:const EdgeInsets.symmetric(horizontal:12,vertical:5),
        leading:Container(width:42,height:42,decoration:BoxDecoration(
          borderRadius:BorderRadius.circular(11),color:const Color(0xFFE8F2FF)),
          child:Icon(option.$3,color:civicV4Blue)),
        title:Text(option.$1,style:const TextStyle(fontSize:13,fontWeight:FontWeight.w800,color:civicV4Navy)),
        subtitle:Text(option.$2,style:const TextStyle(fontSize:11,color:civicV4Muted)),
        trailing:const Icon(Icons.chevron_right_rounded,color:civicV4Blue),
        onTap:()=>navigate(option.$4),
      ),
    ),
    if(guest)const Padding(padding:EdgeInsets.only(top:8),
      child:Text('Untuk mengajukan surat, silakan masuk menggunakan akun Anda.',
        style:TextStyle(color:civicV4Muted,fontSize:11))),
  ]);
}

class CikokoV4Agenda extends StatelessWidget {
  final List<dynamic> content;
  const CikokoV4Agenda({super.key,required this.content});

  @override Widget build(BuildContext context){
    final entries=content.where((e)=>e is Map &&
      (e['type']=='agenda'||e['type']=='kegiatan')).toList();
    return ListView(padding:const EdgeInsets.all(14),children:[
      const CivicV4Header(title:'Agenda Kegiatan',subtitle:'Kegiatan dan informasi agenda Kelurahan Cikoko',icon:Icons.calendar_month_outlined),
      const SizedBox(height:13),
      if(entries.isEmpty)const CivicV4Empty(message:'Belum ada agenda yang dipublikasikan.',icon:Icons.event_busy_outlined),
      for(final raw in entries)Card(child:ListTile(
        contentPadding:const EdgeInsets.all(12),
        leading:Container(width:49,height:54,alignment:Alignment.center,
          decoration:BoxDecoration(color:const Color(0xFFE8F2FF),
            borderRadius:BorderRadius.circular(9)),
          child:const Icon(Icons.event_available_outlined,color:civicV4Blue,size:26)),
        title:Text((raw['title']??'Agenda Kelurahan').toString(),
          style:const TextStyle(color:civicV4Navy,fontSize:13,fontWeight:FontWeight.w800)),
        subtitle:Text((raw['created_at']??'').toString(),
          style:const TextStyle(color:civicV4Muted,fontSize:11)),
      )),
    ]);
  }
}

class CikokoV4Gallery extends StatelessWidget {
  final List<dynamic> content;
  final CikokoApi api;
  const CikokoV4Gallery({super.key,required this.content,required this.api});
  @override Widget build(BuildContext context){
    final rows=content.where((e)=>e is Map && e['type']=='galeri').toList();
    return ListView(padding:const EdgeInsets.all(14),children:[
      const CivicV4Header(title:'Galeri Kegiatan',subtitle:'Dokumentasi resmi kegiatan Kelurahan Cikoko',icon:Icons.photo_library_outlined),
      const SizedBox(height:13),
      if(rows.isEmpty)const CivicV4Empty(message:'Belum ada dokumentasi kegiatan.',icon:Icons.photo_library_outlined),
      GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
        itemCount:rows.length,
        gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:2,crossAxisSpacing:10,mainAxisSpacing:10,childAspectRatio:0.92),
        itemBuilder:(ctx,i){
          final row=rows[i] as Map;
          final src=api.media((row['image']??'').toString());
          final title=(row['title']??'Kegiatan Kelurahan').toString();
          return Card(clipBehavior:Clip.antiAlias,margin:EdgeInsets.zero,child:InkWell(
            onTap:()=>showDialog<void>(context:ctx,builder:(dialog)=>AlertDialog(
              title:Text(title),content:src.isEmpty?Text(title):Image.network(src,
                errorBuilder:(_,__,___)=>Text(title)),
              actions:[TextButton(onPressed:()=>Navigator.pop(dialog),child:const Text('Tutup'))])),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Expanded(child:SizedBox(width:double.infinity,
                child:src.isEmpty?const ColoredBox(color:Color(0xFFEAF3FF),
                  child:Icon(Icons.image_outlined,color:civicV4Blue,size:35)):
                Image.network(src,fit:BoxFit.cover,
                  errorBuilder:(_,__,___)=>const ColoredBox(color:Color(0xFFEAF3FF),
                    child:Icon(Icons.image_not_supported_outlined,color:civicV4Blue))))),
              Padding(padding:const EdgeInsets.all(8),child:Text(title,maxLines:2,
                overflow:TextOverflow.ellipsis,
                style:const TextStyle(fontWeight:FontWeight.w700,fontSize:11,color:civicV4Navy))),
            ]),
          ));
        }),
    ]);
  }
}

class CikokoV4Region extends StatelessWidget {
  final void Function(String route) navigate;
  const CikokoV4Region({super.key,required this.navigate});
  @override Widget build(BuildContext context)=>ListView(
    padding:const EdgeInsets.all(14),children:[
      const CivicV4Header(title:'Profil Wilayah',subtitle:'Kelurahan Cikoko · Kecamatan Pancoran',icon:Icons.place_outlined),
      const SizedBox(height:12),
      ClipRRect(borderRadius:BorderRadius.circular(13),
        child:Image.asset('assets/kantor-cikoko.jpg',height:165,width:double.infinity,fit:BoxFit.cover)),
      const SizedBox(height:12),
      const Card(child:Padding(padding:EdgeInsets.all(15),child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('Kelurahan Cikoko',style:TextStyle(color:civicV4Navy,
            fontWeight:FontWeight.w800,fontSize:17)),
          SizedBox(height:5),
          Text('Kelurahan Cikoko berada di Kecamatan Pancoran, Kota Administrasi Jakarta Selatan.',
            style:TextStyle(color:civicV4Muted,fontSize:12,height:1.5)),
        ]))),
      for(final section in const [
        ('Tentang Kelurahan',Icons.info_outline,'Profil layanan dan informasi kelurahan'),
        ('Kecamatan Pancoran',Icons.location_city_outlined,'Kota Administrasi Jakarta Selatan'),
      ])Card(child:ListTile(leading:Icon(section.$2,color:civicV4Blue),
        title:Text(section.$1,style:const TextStyle(fontSize:13,fontWeight:FontWeight.w800)),
        subtitle:Text(section.$3,style:const TextStyle(fontSize:11)))),
      const SizedBox(height:9),
      FilledButton.icon(onPressed:()=>navigate('Layanan Online'),
        icon:const Icon(Icons.widgets_outlined),label:const Text('Lihat Layanan Kelurahan')),
    ]);
}
