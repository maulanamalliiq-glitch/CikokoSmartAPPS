import 'package:flutter/material.dart';
import 'api.dart';
import 'cikoko_v6_showcase.dart';

/// Profil Kelurahan shared by Tentang Kami and Profil Wilayah.
/// Map and organization assets are supplied by the public mobile-api patch.
class CikokoKelurahanProfilePage extends StatefulWidget {
  final CikokoApi api;
  final String title;
  final void Function(String) navigate;
  const CikokoKelurahanProfilePage({
    super.key,
    required this.api,
    required this.title,
    required this.navigate,
  });
  @override State<CikokoKelurahanProfilePage> createState()=>_CikokoKelurahanProfileState();
}

class _CikokoKelurahanProfileState extends State<CikokoKelurahanProfilePage>{
  late Future<Map<String,dynamic>> pending;
  static const mediaBase='https://datawebs.my.id/mobile-api/civic-assets/profile/';
  @override void initState(){
    super.initState();
    pending=widget.api.call('profile_kelurahan_public');
  }
  void refresh(){
    setState(()=>pending=widget.api.call('profile_kelurahan_public'));
  }
  @override Widget build(BuildContext context)=>FutureBuilder<Map<String,dynamic>>(
    future:pending,
    builder:(context,snapshot){
      final data=snapshot.data??<String,dynamic>{};
      final map=snapshot.hasData
        ?(data['map_image']??'').toString()
        :mediaBase+'peta-wilayah-cikoko.jpg';
      final structure=snapshot.hasData
        ?(data['organization_image']??'').toString()
        :mediaBase+'struktur-organisasi-cikoko.jpg';
      final description=(data['description']??'Kelurahan Cikoko berada di Kecamatan Pancoran, Kota Administrasi Jakarta Selatan.').toString();
      return RefreshIndicator(onRefresh:()async{
        refresh();
        try{await pending;}catch(_){/* Existing profile remains visible. */}
      },child:ListView(
        key:const Key('cikoko_profile_map_first'),
        padding:const EdgeInsets.fromLTRB(14,13,14,24),
        children:[
          V6PageHeader(title:widget.title,
            description:'Profil wilayah dan struktur organisasi Kelurahan Cikoko.',
            icon:Icons.location_on_outlined),
          const V6Section(title:'Peta Wilayah Cikoko'),
          V6Panel(padding:const EdgeInsets.all(8),child:Column(
            crossAxisAlignment:CrossAxisAlignment.start,
            children:[
              _CikokoPhoto(
                key:const Key('cikoko_profile_map_image'),
                url:map,
                aspect:738/300,
                alternate:'Peta wilayah belum tersedia pada server.',
                onTap:()=>_showZoom(context,map,'Peta Wilayah Kelurahan Cikoko'),
              ),
              const SizedBox(height:7),
              const Padding(
                padding:EdgeInsets.symmetric(horizontal:3),
                child:Text('Peta wilayah Kelurahan Cikoko, Kecamatan Pancoran',
                  style:TextStyle(color:V6.secondary,fontSize:10.5)),
              ),
            ],
          )),
          const SizedBox(height:18),
          const V6Section(title:'Tentang Kelurahan Cikoko'),
          V6Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('Profil Kelurahan Cikoko',
              style:TextStyle(color:V6.ink,fontWeight:FontWeight.w900,fontSize:15)),
            const SizedBox(height:9),
            Text(description,
              style:const TextStyle(color:V6.secondary,fontSize:12,height:1.55)),
            const SizedBox(height:14),
            const Row(children:[
              Icon(Icons.location_city_outlined,color:V6.blue,size:19),
              SizedBox(width:9),
              Expanded(child:Text('Kecamatan Pancoran · Jakarta Selatan',
                style:TextStyle(color:V6.ink,fontWeight:FontWeight.w800,fontSize:11.5))),
            ]),
          ])),
          const SizedBox(height:19),
          const V6Section(title:'Pimpinan & Struktur Organisasi'),
          V6Panel(padding:const EdgeInsets.all(9),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              _CikokoPhoto(
                key:const Key('cikoko_profile_structure_image'),
                url:structure,
                aspect:2048/1448,
                alternate:'Bagan struktur organisasi belum tersedia pada server.',
                onTap:()=>_showZoom(context,structure,'Struktur Organisasi Kelurahan Cikoko'),
              ),
              const SizedBox(height:8),
              const Text('Ketuk gambar untuk melihat nama, jabatan, dan foto pejabat dalam ukuran lebih besar.',
                style:TextStyle(color:V6.secondary,fontSize:10.6,height:1.45)),
            ])),
          const SizedBox(height:18),
          const V6Section(title:'Informasi Terkait'),
          for(final entry in const [
            ('Berita & Informasi','Berita & Kegiatan',Icons.newspaper_outlined),
            ('Agenda Kegiatan','Agenda',Icons.calendar_month_outlined),
            ('Inovasi Kelurahan','Inovasi',Icons.auto_awesome_outlined),
            ('Galeri Kegiatan','Galeri',Icons.photo_library_outlined),
          ])Padding(padding:const EdgeInsets.only(bottom:8),
            child:V6Panel(padding:EdgeInsets.zero,child:ListTile(
              onTap:()=>widget.navigate(entry.$2),
              leading:Icon(entry.$3,color:V6.blue,size:22),
              title:Text(entry.$1,style:const TextStyle(
                color:V6.ink,fontWeight:FontWeight.w800,fontSize:12.2)),
              trailing:const Icon(Icons.chevron_right_rounded,color:V6.secondary,size:20),
            ))),
          if(snapshot.hasError)Padding(
            padding:const EdgeInsets.only(top:6),
            child:TextButton.icon(onPressed:refresh,
              icon:const Icon(Icons.refresh,size:17),
              label:const Text('Perbarui informasi profil')),
          ),
        ],
      ));
    },
  );
  void _showZoom(BuildContext context,String url,String title){
    final uri=Uri.tryParse(url);
    if(uri==null||uri.scheme!='https')return;
    showDialog<void>(context:context,
      builder:(dialog)=>Dialog(
        insetPadding:const EdgeInsets.all(8),
        backgroundColor:Colors.white,
        child:Column(mainAxisSize:MainAxisSize.min,children:[
          Padding(padding:const EdgeInsets.fromLTRB(12,7,5,5),child:Row(children:[
            Expanded(child:Text(title,style:const TextStyle(
              color:V6.ink,fontWeight:FontWeight.w800,fontSize:12.4))),
            IconButton(onPressed:()=>Navigator.of(dialog).pop(),
              icon:const Icon(Icons.close)),
          ])),
          SizedBox(
            height:MediaQuery.sizeOf(dialog).height*.67,
            width:MediaQuery.sizeOf(dialog).width*.93,
            child:InteractiveViewer(
              minScale:1,maxScale:5,
              child:Image.network(url,fit:BoxFit.contain,
                errorBuilder:(_,__,___)=>const Center(
                  child:Text('Gambar belum tersedia pada server.'))),
            ),
          ),
        ]),
      ));
  }
}

class _CikokoPhoto extends StatelessWidget{
  final String url;
  final double aspect;
  final String alternate;
  final VoidCallback onTap;
  const _CikokoPhoto({
    super.key,required this.url,required this.aspect,
    required this.alternate,required this.onTap,
  });
  @override Widget build(BuildContext context){
    final valid=Uri.tryParse(url);
    return AspectRatio(aspectRatio:aspect,child:Material(
      color:V6.pale,borderRadius:V6.radius(10),
      child:InkWell(onTap:onTap,borderRadius:V6.radius(10),
        child:ClipRRect(borderRadius:V6.radius(10),
          child:valid?.scheme!='https'
            ?_noImage()
            :Image.network(url,fit:BoxFit.contain,
              errorBuilder:(_,__,___)=>_noImage()),
        )),
    ));
  }
  Widget _noImage()=>Center(child:Padding(
    padding:const EdgeInsets.all(12),child:Column(
      mainAxisAlignment:MainAxisAlignment.center,children:[
      const Icon(Icons.map_outlined,color:V6.blue,size:26),
      const SizedBox(height:7),
      Text(alternate,textAlign:TextAlign.center,
        style:const TextStyle(color:V6.secondary,fontSize:11)),
    ]),
  ));
}
