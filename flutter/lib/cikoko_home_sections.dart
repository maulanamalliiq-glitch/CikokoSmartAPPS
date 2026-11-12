import 'package:flutter/material.dart';
import 'api.dart';
import 'cikoko_v6_showcase.dart';

/// Home-only sections. These use real status and service links supplied by
/// the existing Cikoko API; no sample counters or invented service URLs.
class V6LetterStatusStrip extends StatelessWidget {
 final Map<String,int>? counts;
 final ValueChanged<String> onStatus;
 const V6LetterStatusStrip({super.key,required this.counts,required this.onStatus});

 @override Widget build(BuildContext context)=>Column(
  key:const Key('v6_home_letter_status'),
  crossAxisAlignment:CrossAxisAlignment.start,children:[
   const V6Section(title:'Status Pelayanan Surat'),
   Row(children:[
    for(final item in const [
     ('masuk','Surat Masuk',V6.blue,Icons.markunread_mailbox_outlined),
     ('proses','Diproses',V6.amber,Icons.timelapse_outlined),
     ('selesai','Selesai',V6.green,Icons.check_circle_outline),
    ])Expanded(child:Padding(
      padding:const EdgeInsets.symmetric(horizontal:3),
      child:Material(color:Colors.white,borderRadius:V6.radius(12),
       child:InkWell(
        key:Key('v6_status_'+item.$1),
        onTap:()=>onStatus(item.$1),
        borderRadius:V6.radius(12),
        child:Container(
         padding:const EdgeInsets.symmetric(horizontal:5,vertical:13),
         decoration:BoxDecoration(border:Border.all(color:V6.border),
           borderRadius:V6.radius(12)),
         child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
          Icon(item.$4,size:18,color:item.$3),
          const SizedBox(height:5),
          Text(counts==null?'—':(counts![item.$1]??0).toString(),
           style:TextStyle(color:item.$3,fontSize:21,fontWeight:FontWeight.w900)),
          const SizedBox(height:2),
          Text(item.$2,maxLines:1,textAlign:TextAlign.center,
           overflow:TextOverflow.ellipsis,
           style:const TextStyle(color:V6.ink,fontWeight:FontWeight.w700,fontSize:10)),
         ]),
        ),
       )),
    )),
   ]),
 ]);
}

class V6IntegratedServiceGrid extends StatelessWidget{
 final List<Map<String,dynamic>> entries;
 final ValueChanged<Map<String,dynamic>> onOpen;
 const V6IntegratedServiceGrid({super.key,required this.entries,required this.onOpen});

 @override Widget build(BuildContext context){
  final visible=entries.where((e)=>e['active']!=false).toList();
  return Column(
   key:const Key('v6_home_integrated_services'),
   crossAxisAlignment:CrossAxisAlignment.start,
   children:[
    const V6Section(title:'Layanan Masyarakat Terpadu'),
    if(visible.isEmpty)
     const V6Panel(child:Text('Belum ada layanan terpadu yang tersedia.',
       style:TextStyle(fontSize:11.5,color:V6.secondary))),
    if(visible.isNotEmpty)
     GridView.builder(
      shrinkWrap:true,
      physics:const NeverScrollableScrollPhysics(),
      itemCount:visible.length,
      gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(
       crossAxisCount:3,crossAxisSpacing:9,mainAxisSpacing:9,mainAxisExtent:119),
      itemBuilder:(ctx,i){
       final service=visible[i];
       final title=(service['title']??'Layanan').toString();
       final logo=(service['logo_url']??'').toString().trim();
       final uri=Uri.tryParse(logo);
       final hasLogo=uri!=null&&uri.scheme=='https'&&uri.host.isNotEmpty;
       return Material(color:Colors.white,borderRadius:V6.radius(12),
        child:InkWell(
         key:Key('v6_integrated_'+i.toString()),
         onTap:()=>onOpen(service),
         borderRadius:V6.radius(12),
         child:Container(
          decoration:BoxDecoration(
           border:Border.all(color:V6.border),
           borderRadius:V6.radius(12)),
          padding:const EdgeInsets.symmetric(horizontal:5,vertical:9),
          child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
           SizedBox(
            width:65,height:65,
            child:hasLogo
             ?Image.network(logo,fit:BoxFit.contain,
               errorBuilder:(_,__,___)=>const Icon(
                 Icons.account_balance_outlined,color:V6.blue,size:30))
             :const Icon(Icons.account_balance_outlined,color:V6.blue,size:30)),
           const SizedBox(height:5),
           Text(title,maxLines:2,textAlign:TextAlign.center,
             overflow:TextOverflow.ellipsis,
             style:const TextStyle(
               color:V6.ink,fontWeight:FontWeight.w800,fontSize:10.3,height:1.16)),
          ]),
         ),
        ),
       );
      },
     ),
   ],
  );
 }
}

class V6InnovationPreview extends StatefulWidget{
 final CikokoApi api;
 final VoidCallback onAll;
 const V6InnovationPreview({super.key,required this.api,required this.onAll});
 @override State<V6InnovationPreview> createState()=>_V6InnovationPreviewState();
}
class _V6InnovationPreviewState extends State<V6InnovationPreview>{
 late Future<Map<String,dynamic>> pending;
 @override void initState(){super.initState();pending=widget.api.call('v211_innovations');}
 void retry()=>setState(()=>pending=widget.api.call('v211_innovations'));
 @override Widget build(BuildContext context)=>Column(
  key:const Key('v6_home_innovations'),
  crossAxisAlignment:CrossAxisAlignment.start,children:[
   V6Section(title:'Inovasi Kelurahan',action:'Lihat Semua',onAction:widget.onAll),
   FutureBuilder<Map<String,dynamic>>(future:pending,builder:(ctx,s){
    if(s.connectionState!=ConnectionState.done)return const Padding(
     padding:EdgeInsets.symmetric(vertical:14),
     child:Center(child:SizedBox(width:22,height:22,
       child:CircularProgressIndicator(strokeWidth:2.5))));
    if(s.hasError)return V6Panel(padding:const EdgeInsets.all(10),child:Row(children:[
     const Expanded(child:Text('Inovasi belum dapat dimuat.',
       style:TextStyle(color:V6.secondary,fontSize:11.5))),
     TextButton.icon(onPressed:retry,icon:const Icon(Icons.refresh,size:16),
       label:const Text('Ulangi')),
    ]));
    final rows=List<dynamic>.from(s.data?['items']??[]).whereType<Map>().take(3).toList();
    if(rows.isEmpty)return const V6Panel(child:Text(
      'Belum ada inovasi yang diterbitkan.',
      style:TextStyle(color:V6.secondary,fontSize:11.5)));
    return Column(children:[
     for(final raw in rows)Padding(padding:const EdgeInsets.only(bottom:9),
      child:Material(color:Colors.white,borderRadius:V6.radius(12),
       child:InkWell(
        onTap:widget.onAll,borderRadius:V6.radius(12),
        child:Container(
         padding:const EdgeInsets.all(8),
         decoration:BoxDecoration(border:Border.all(color:V6.border),
           borderRadius:V6.radius(12)),
         child:Row(children:[
          ClipRRect(borderRadius:V6.radius(9),
           child:_innovationImage(Map<String,dynamic>.from(raw))),
          const SizedBox(width:10),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
           Text((raw['title']??'Inovasi Kelurahan').toString(),maxLines:2,
            overflow:TextOverflow.ellipsis,
            style:const TextStyle(color:V6.ink,fontSize:11.7,
              fontWeight:FontWeight.w900)),
           const SizedBox(height:4),
           Text((raw['summary']??'').toString(),maxLines:2,
            overflow:TextOverflow.ellipsis,
            style:const TextStyle(color:V6.secondary,fontSize:10.4)),
          ])),
          const Icon(Icons.chevron_right_rounded,color:V6.blue,size:19),
         ]),
        ),
       )),
     ),
    ]);
   }),
  ]);
 Widget _innovationImage(Map<String,dynamic> item){
  var path=(item['image']??'').toString();
  if(path.isEmpty&&item['images'] is List && (item['images'] as List).isNotEmpty){
   path=(item['images'] as List).first.toString();
  }
  final url=widget.api.media(path);
  return url.isEmpty
   ?Container(width:78,height:67,color:V6.pale,
      child:const Icon(Icons.auto_awesome_outlined,color:V6.blue,size:25))
   :Image.network(url,width:78,height:67,fit:BoxFit.cover,
     errorBuilder:(_,__,___)=>Container(width:78,height:67,color:V6.pale,
       child:const Icon(Icons.image_not_supported_outlined,color:V6.blue,size:25)));
 }
}
