import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api.dart';
import 'cikoko_v6_showcase.dart';

class CikokoLiveChat extends StatefulWidget{
 final CikokoApi api;
 final String? userId;
 final String title;
 const CikokoLiveChat({super.key,required this.api,this.userId,this.title='Chat Kelurahan Cikoko'});
 @override State<CikokoLiveChat> createState()=>_CikokoLiveChatState();
}
class _CikokoLiveChatState extends State<CikokoLiveChat> with WidgetsBindingObserver{
 final input=TextEditingController(),scroll=ScrollController();
 List<Map<String,dynamic>> data=[];
 Timer? timer;
 bool loading=false,sending=false,foreground=true;
 String? error;
 bool get isStaff=>widget.userId!=null;
 @override void initState(){super.initState();
  WidgetsBinding.instance.addObserver(this);reload();
  timer=Timer.periodic(const Duration(seconds:2),(_){if(foreground)reload();});
 }
 @override void didChangeAppLifecycleState(AppLifecycleState s){
  foreground=s==AppLifecycleState.resumed;if(foreground)reload();
 }
 @override void dispose(){timer?.cancel();input.dispose();scroll.dispose();
  WidgetsBinding.instance.removeObserver(this);super.dispose();}
 Future<void> reload()async{
  if(loading)return;loading=true;
  try{
   final r=await widget.api.callWithParams('chat_v2548_thread',{
    if(isStaff)'user_id':widget.userId!,
   });
   final next=List<dynamic>.from(r['messages']??[])
    .whereType<Map>().map((v)=>Map<String,dynamic>.from(v)).toList();
   final previousLast=data.isEmpty?'':(data.last['id']??'').toString();
   final nextLast=next.isEmpty?'':(next.last['id']??'').toString();
   final changed=next.length!=data.length || next.asMap().entries.any((entry){
    final i=entry.key;if(i>=data.length)return true;
    return entry.value['delivery_status']!=data[i]['delivery_status'] ||
     entry.value['message']!=data[i]['message'] ||
     entry.value['has_photo']!=data[i]['has_photo'];
   });
   if(changed&&mounted){
    setState((){data=next;error=null;});
    if(previousLast!=nextLast)WidgetsBinding.instance.addPostFrameCallback((_){
      if(mounted&&scroll.hasClients)scroll.animateTo(scroll.position.maxScrollExtent,
       duration:const Duration(milliseconds:180),curve:Curves.easeOut);
    });
   }
  }catch(e){if(mounted&&data.isEmpty)setState(()=>error='Percakapan belum dapat dimuat: '+e.toString());}
  finally{loading=false;}
 }
 Future<void> send()async{
  final msg=input.text.trim();
  if(sending||msg.isEmpty)return;
  setState(()=>sending=true);
  try{
   await widget.api.call('chat_v2548_send',body:{
    'message':msg,if(isStaff)'user_id':widget.userId,
   });
   input.clear();await reload();
  }catch(e){if(mounted)setState(()=>error='Pesan gagal dikirim: '+e.toString());}
  finally{if(mounted)setState(()=>sending=false);}
 }
 Future<void> pick(ImageSource source)async{
  if(sending)return;
  try{
   final image=await ImagePicker().pickImage(source:source,maxWidth:1920,imageQuality:80);
   if(image==null||!mounted)return;
   setState(()=>sending=true);
   await widget.api.upload('chat_v2548_upload',{
    if(isStaff)'user_id':widget.userId!,
    'caption':input.text.trim(),
   },{'photo':[image.path]});
   input.clear();await reload();
  }catch(e){if(mounted)setState(()=>error='Foto gagal dikirim: '+e.toString());}
  finally{if(mounted)setState(()=>sending=false);}
 }
 void attach(){
  showModalBottomSheet<void>(context:context,showDragHandle:true,builder:(c)=>
   SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[
    ListTile(leading:const Icon(Icons.photo_library_outlined,color:V6.blue),
     title:const Text('Pilih dari Galeri'),
     onTap:(){Navigator.pop(c);pick(ImageSource.gallery);}),
    ListTile(leading:const Icon(Icons.camera_alt_outlined,color:V6.blue),
     title:const Text('Ambil Foto dengan Kamera'),
     onTap:(){Navigator.pop(c);pick(ImageSource.camera);}),
   ])));
 }
 String photoUrl(int id)=>CikokoApi.root.replaceFirst('index.php','chat_v2548.php')+
    '?action=chat_v2548_photo&id='+id.toString();
 Widget photo(int id){
  Widget image=Image.network(photoUrl(id),headers:widget.api.authHeaders(),
   width:215,height:165,fit:BoxFit.cover,
   errorBuilder:(_,__,___)=>const SizedBox(height:90,width:190,
    child:Center(child:Text('Foto belum tersedia'))));
  return GestureDetector(onTap:()=>showDialog<void>(context:context,builder:(c)=>Dialog(
    child:Stack(children:[
      InteractiveViewer(child:Image.network(photoUrl(id),
         headers:widget.api.authHeaders(),fit:BoxFit.contain)),
      Positioned(top:2,right:2,child:IconButton(
         onPressed:()=>Navigator.pop(c),icon:const Icon(Icons.close))),
    ])),
  ),child:ClipRRect(borderRadius:BorderRadius.circular(10),child:image));
 }
 Widget bubble(Map<String,dynamic> m){
  final mine=isStaff?m['sender']=='admin':m['sender']=='warga';
  final id=int.tryParse((m['id']??'').toString())??0;
  final status=(m['delivery_status']??'sent').toString();
  final read=status=='read'||status=='read_legacy';
  final delivered=status=='delivered'||read;
  return Align(alignment:mine?Alignment.centerRight:Alignment.centerLeft,
   child:Container(
    margin:const EdgeInsets.symmetric(vertical:4),
    constraints:BoxConstraints(maxWidth:MediaQuery.sizeOf(context).width*.8),
    decoration:BoxDecoration(color:mine?const Color(0xffe5f1ff):Colors.white,
     border:Border.all(color:V6.border),borderRadius:BorderRadius.circular(13)),
    padding:const EdgeInsets.symmetric(horizontal:11,vertical:9),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     if(m['has_photo']==true&&id>0)...[photo(id),const SizedBox(height:5)],
     if(m['has_photo']!=true||(m['message']??'').toString()!='📷 Foto')
       Text((m['message']??'').toString(),style:const TextStyle(color:V6.ink,fontSize:12.5)),
     const SizedBox(height:5),
     Row(mainAxisSize:MainAxisSize.min,children:[
      Text((m['created_at']??'').toString().split(' ').last,
       style:const TextStyle(fontSize:9.5,color:V6.secondary)),
      if(mine)...[
       const SizedBox(width:7),
       Icon(delivered?Icons.done_all_rounded:Icons.check_rounded,size:16,
         color:read?const Color(0xff139a4a):V6.secondary),
       const SizedBox(width:3),
       Text(read?'Dibaca':delivered?'Diterima':'Terkirim',
        style:TextStyle(fontSize:9.5,fontWeight:FontWeight.w700,
         color:read?const Color(0xff139a4a):V6.secondary)),
      ],
     ]),
    ]),
  ));
 }
 @override Widget build(BuildContext context)=>Column(children:[
  Container(color:Colors.white,padding:const EdgeInsets.all(13),
   child:Row(children:[
    const Icon(Icons.chat_bubble_outline,color:V6.blue),
    const SizedBox(width:8),
    Expanded(child:Text(widget.title,style:const TextStyle(color:V6.ink,
     fontWeight:FontWeight.w900,fontSize:13))),
    IconButton(onPressed:reload,icon:const Icon(Icons.refresh,color:V6.blue)),
   ])),
  if(error!=null)Padding(padding:const EdgeInsets.all(8),
   child:Text(error!,style:const TextStyle(color:V6.red,fontSize:11))),
  Expanded(child:RefreshIndicator(onRefresh:reload,
   child:ListView.builder(controller:scroll,key:const Key('cikoko_live_chat'),
    padding:const EdgeInsets.all(10),itemCount:data.isEmpty?1:data.length,
    itemBuilder:(c,i)=>data.isEmpty?
      const Padding(padding:EdgeInsets.all(18),
       child:Center(child:Text('Belum ada pesan. Tulis untuk memulai percakapan.'))):
      bubble(data[i])))),
  SafeArea(top:false,child:Container(color:Colors.white,
   padding:const EdgeInsets.symmetric(horizontal:6,vertical:8),
   child:Row(children:[
    IconButton(key:const Key('chat_attach'),tooltip:'Foto Galeri / Kamera',
      onPressed:sending?null:attach,
      icon:const Icon(Icons.add_photo_alternate_outlined,color:V6.blue)),
    Expanded(child:TextField(controller:input,minLines:1,maxLines:4,
      decoration:const InputDecoration(isDense:true,
       hintText:'Tulis pesan atau kirim foto…',border:OutlineInputBorder()))),
    IconButton(key:const Key('chat_send'),tooltip:'Kirim',
      onPressed:sending?null:send,
      icon:sending?const SizedBox(width:20,height:20,
       child:CircularProgressIndicator(strokeWidth:2)):
       const Icon(Icons.send_rounded,color:V6.blue)),
   ]))),
 ]);
}

class CikokoLiveChatInbox extends StatefulWidget{
 final CikokoApi api;
 const CikokoLiveChatInbox({super.key,required this.api});
 @override State<CikokoLiveChatInbox> createState()=>_CikokoLiveChatInboxState();
}
class _CikokoLiveChatInboxState extends State<CikokoLiveChatInbox> with WidgetsBindingObserver{
 List<Map<String,dynamic>> threads=[];
 Timer?timer;bool foreground=true,loading=false;
 String? error;
 @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);
  refresh();timer=Timer.periodic(const Duration(seconds:4),(_){if(foreground)refresh();});}
 @override void didChangeAppLifecycleState(AppLifecycleState s){
  foreground=s==AppLifecycleState.resumed;if(foreground)refresh();}
 @override void dispose(){timer?.cancel();WidgetsBinding.instance.removeObserver(this);super.dispose();}
 Future<void> refresh()async{
  if(loading)return;loading=true;
  try{
   final r=await widget.api.call('chat_threads');
   final next=List<dynamic>.from(r['threads']??[])
    .whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).toList();
   if(mounted)setState((){threads=next;error=null;});
  }catch(e){if(mounted)setState(()=>error='Percakapan belum dimuat: '+e.toString());}
  finally{loading=false;}
 }
 Future<void> open(Map<String,dynamic> row)async{
  final id=(row['user_id']??'').toString();
  if(id.isEmpty)return;
  await Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>Scaffold(
   appBar:AppBar(title:const Text('Chat Warga')),
   body:CikokoLiveChat(api:widget.api,userId:id,title:(row['name']??'Warga').toString()))));
  await refresh();
 }
 @override Widget build(BuildContext c)=>RefreshIndicator(onRefresh:refresh,
  child:ListView(key:const Key('cikoko_live_chat_inbox'),children:[
   if(error!=null)Padding(padding:const EdgeInsets.all(12),
    child:Text(error!,style:const TextStyle(color:V6.red))),
   for(final row in threads)ListTile(
    leading:const CircleAvatar(child:Icon(Icons.person_outline)),
    title:Text((row['name']??'Warga').toString()),
    subtitle:Text((row['message']??'').toString(),
      maxLines:1,overflow:TextOverflow.ellipsis),
    trailing:const Icon(Icons.chevron_right_rounded,color:V6.blue),
    onTap:()=>open(row)),
   if(threads.isEmpty)const ListTile(title:Text('Belum ada pesan masuk.')),
  ]));
}
