import 'package:flutter/material.dart';
import 'api.dart';

/// Publikasi informasi terintegrasi. Laporan yang tampil hanya yang disetujui
/// untuk publikasi oleh admin (endpoint public_reports), bukan laporan privat.
class CikokoInformationPage extends StatefulWidget {
  final CikokoApi api;
  final void Function(Map<String, dynamic>) onOpenNews;
  const CikokoInformationPage({super.key,required this.api,required this.onOpenNews});
  @override
  State<CikokoInformationPage> createState() => _CikokoInformationPageState();
}

class _CikokoInformationPageState extends State<CikokoInformationPage> {
  late Future<List<List<Map<String,dynamic>>>> future;
  @override
  void initState(){super.initState();future=_fetch();}
  Future<List<List<Map<String,dynamic>>>> _fetch() async {
    final content=await widget.api.callCachedPublic('content');
    final all=List<dynamic>.from(content['items']??[])
      .whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();
    List<Map<String,dynamic>> reports=[];
    try {
      final response=await widget.api.call('public_reports');
      reports=List<dynamic>.from(response['items']??[])
        .whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();
    }catch(_){ /* API laporan publik di server lama mungkin belum dipasang. */ }
    return [
      all.where((e)=>e['type']=='berita').toList(),
      all.where((e)=>e['type']=='pengumuman').toList(),
      reports,
    ];
  }
  Future<void> _refresh() async {setState(()=>future=_fetch());await future;}
  void _open(Map<String,dynamic> item,String kind) {
    if(kind=='Berita'){widget.onOpenNews(item);return;}
    showModalBottomSheet<void>(context:context,isScrollControlled:true,showDragHandle:true,
      useSafeArea:true,builder:(ctx)=>FractionallySizedBox(heightFactor:.76,
        child:ListView(padding:const EdgeInsets.fromLTRB(18,5,18,22),children:[
          Text(kind.toUpperCase(),style:const TextStyle(fontSize:11,fontWeight:FontWeight.w800,color:Color(0xff246ed5))),
          const SizedBox(height:9),Text('${item['title']??''}',style:const TextStyle(color:Color(0xff12375c),fontSize:20,fontWeight:FontWeight.w800)),
          const SizedBox(height:14),_PhotoSlider(api:widget.api,item:item,height:215),
          const SizedBox(height:15),Text('${item['body']??''}',style:const TextStyle(fontSize:14,height:1.55)),
          if(kind=='Laporan Petugas')const Padding(padding:EdgeInsets.only(top:12),
            child:Text('Hanya data kegiatan yang telah disetujui untuk publikasi.',
              style:TextStyle(color:Colors.blueGrey,fontSize:11))),
        ])));
  }
  @override
  Widget build(BuildContext context)=>FutureBuilder<List<List<Map<String,dynamic>>>>(
    future:future,builder:(ctx,s){
      if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
      if(s.hasError)return Center(child:Padding(padding:const EdgeInsets.all(20),
        child:Column(mainAxisSize:MainAxisSize.min,children:[
          const Icon(Icons.wifi_off_outlined,size:36,color:Colors.blueGrey),
          const SizedBox(height:12),const Text('Informasi belum dapat dimuat.'),
          TextButton.icon(onPressed:_refresh,icon:const Icon(Icons.refresh),label:const Text('Coba lagi')),
        ])));
      final data=s.data!;
      return RefreshIndicator(onRefresh:_refresh,child:ListView(padding:const EdgeInsets.all(14),children:[
        const Text('Pusat Informasi Cikoko',style:TextStyle(fontSize:21,fontWeight:FontWeight.w800,color:Color(0xff10375f))),
        const SizedBox(height:5),const Text('Berita, pengumuman dan laporan kegiatan publik dalam satu halaman.',
          style:TextStyle(color:Colors.blueGrey,fontSize:12)),const SizedBox(height:12),
        for(var i=0;i<3;i++)_section(data[i],const ['Berita','Pengumuman','Laporan Petugas'][i]),
        const SizedBox(height:45),
      ]));
    });
  Widget _section(List<Map<String,dynamic>> items,String kind)=>Padding(
    padding:const EdgeInsets.only(bottom:18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[const Icon(Icons.article_outlined,color:Color(0xff246ed5),size:19),const SizedBox(width:8),
        Expanded(child:Text(kind,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w800,color:Color(0xff12375c)))),
        Text('${items.length} informasi',style:const TextStyle(color:Colors.blueGrey,fontSize:11))]),
      const SizedBox(height:9),
      if(items.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(18),
        child:Text('Belum ada informasi yang dipublikasikan.',style:TextStyle(color:Colors.blueGrey)))),
      LayoutBuilder(builder:(ctx,box){
        final w=box.maxWidth<600?box.maxWidth:(box.maxWidth-12)/2;
        return Wrap(spacing:12,runSpacing:12,children:[
          for(final item in items) SizedBox(width:w,child:Card(
            clipBehavior:Clip.antiAlias,margin:EdgeInsets.zero,
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              _PhotoSlider(api:widget.api,item:item,height:box.maxWidth<600?172:155),
              Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text('${item['title']??''}',maxLines:2,overflow:TextOverflow.ellipsis,
                  style:const TextStyle(fontSize:14,fontWeight:FontWeight.w800,color:Color(0xff12375c))),
                const SizedBox(height:6),Text('${item['created_at']??''}',style:const TextStyle(fontSize:10,color:Colors.blueGrey)),
                const SizedBox(height:7),
                Text('${item['body']??''}',maxLines:2,overflow:TextOverflow.ellipsis,
                  style:const TextStyle(fontSize:11.5,color:Color(0xff516a82))),
                Align(alignment:Alignment.centerRight,child:TextButton(
                  onPressed:()=>_open(item,kind),child:const Text('Lihat Selengkapnya →'))),
              ])),
            ]))),
        ]);
      }),
    ]));
}

class _PhotoSlider extends StatefulWidget {
  final CikokoApi api;final Map<String,dynamic> item;final double height;
  const _PhotoSlider({required this.api,required this.item,required this.height});
  @override State<_PhotoSlider> createState()=>_PhotoSliderState();
}
class _PhotoSliderState extends State<_PhotoSlider> {
  int page=0;
  @override Widget build(BuildContext context){
    final images=List<dynamic>.from(widget.item['images']??[]);
    final first='${widget.item['image']??''}';
    if(first.isNotEmpty&&!images.contains(first))images.insert(0,first);
    final urls=images.map((v)=>widget.api.media(v.toString())).where((v)=>v.isNotEmpty).take(5).toList();
    return SizedBox(height:widget.height,width:double.infinity,child:Stack(children:[
      if(urls.isNotEmpty)PageView.builder(
        itemCount:urls.length,onPageChanged:(v)=>setState(()=>page=v),
        itemBuilder:(ctx,i)=>Image.network(urls[i],fit:BoxFit.cover,width:double.infinity,
          errorBuilder:(_,__,___)=>const Center(child:Icon(Icons.broken_image_outlined,size:35,color:Colors.blueGrey))))
      else const ColoredBox(color:Color(0xffe5effa),child:Center(child:Icon(Icons.image_outlined,size:39,color:Color(0xff2670ca)))),
      if(urls.length>1)Positioned(right:8,bottom:8,child:DecoratedBox(
        decoration:BoxDecoration(color:const Color(0xc710375f),borderRadius:BorderRadius.circular(8)),
        child:Padding(padding:const EdgeInsets.symmetric(horizontal:9,vertical:5),
          child:Text('${page+1}/${urls.length}',style:const TextStyle(color:Colors.white,fontSize:11))))),
    ]));
  }
}
