import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'api.dart';

/// Menampilkan Code View yang sudah dipublikasikan admin di dalam aplikasi,
/// bukan mengalihkan warga ke browser Chrome.
class CikokoInnovationDetailPage extends StatefulWidget {
 final CikokoApi api;
 final String slug;
 final String title;
 const CikokoInnovationDetailPage({super.key,required this.api,required this.slug,required this.title});
 @override State<CikokoInnovationDetailPage> createState()=>_CikokoInnovationDetailState();
}
class _CikokoInnovationDetailState extends State<CikokoInnovationDetailPage>{
 late Future<WebViewController> document;
 @override void initState(){super.initState();document=_fetch();}
 Future<WebViewController> _fetch()async{
  final payload=await widget.api.callWithQuery('v211_innovation_detail',{'slug':widget.slug});
  final html=(payload['html']??'').toString();
  if(html.isEmpty)throw const FormatException('Halaman inovasi belum diterbitkan.');
  final controller=WebViewController()
   ..setJavaScriptMode(JavaScriptMode.unrestricted)
   ..setBackgroundColor(const Color(0xfff3f7fb))
   ..setNavigationDelegate(NavigationDelegate(onNavigationRequest:(request){
     final uri=Uri.tryParse(request.url);
     if(uri==null)return NavigationDecision.prevent;
     if(request.url=='about:blank'||uri.scheme=='data'||
       (uri.scheme=='https'&&uri.host=='datawebs.my.id')){
        return NavigationDecision.navigate;
     }
     return NavigationDecision.prevent;
   }));
  await controller.loadHtmlString(html,baseUrl:'https://datawebs.my.id/');
  return controller;
 }
 @override Widget build(BuildContext context)=>Scaffold(
  appBar:AppBar(title:Text(widget.title,maxLines:1,overflow:TextOverflow.ellipsis)),
  body:FutureBuilder<WebViewController>(future:document,builder:(context,s){
   if(s.hasError)return Center(child:Padding(padding:const EdgeInsets.all(24),
    child:Column(mainAxisSize:MainAxisSize.min,children:[
     const Icon(Icons.cloud_off_outlined,size:42,color:Colors.blueGrey),
     const SizedBox(height:12),const Text('Detail inovasi belum bisa ditampilkan.',textAlign:TextAlign.center),
     const SizedBox(height:14),
     FilledButton.icon(onPressed:()=>setState(()=>document=_fetch()),icon:const Icon(Icons.refresh),label:const Text('Muat Ulang')),
    ])));
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   return WebViewWidget(controller:s.data!);
  }),
 );
}
