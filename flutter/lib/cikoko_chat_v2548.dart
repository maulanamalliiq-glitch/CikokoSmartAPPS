import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api.dart';
import 'cikoko_v6_showcase.dart';

// Only fall back after the old server explicitly says a thread or API
// is missing. Authentication and authorization errors must never fall back.
bool cikokoLegacyChatFallbackAllowed(ApiError error){
 final msg=error.message.toLowerCase();
 return msg.contains('percakapan belum tersedia')||
   msg.contains('percakapan warga tidak ditemukan')||
   msg.contains('aksi chat tidak tersedia');
}

class CikokoLiveChat extends StatefulWidget{
 final CikokoApi api;
 final String? userId;
 final int? inboxLastId;
 final String title;
 const CikokoLiveChat({super.key,required this.api,this.userId,
   this.inboxLastId,this.title='Chat Kelurahan Cikoko'});
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
   Map<String,dynamic> r;
   try{
    r=await widget.api.callWithParams('chat_v2548_thread',{
     if(isStaff)'user_id':widget.userId!,
     if(isStaff&&widget.inboxLastId!=null&&widget.inboxLastId! > 0)
      'last_id':widget.inboxLastId.toString(),
    });
    // If the new thread PHP and the legacy inbox target different deployed
    // implementations, a valid inbox row must never silently appear empty.
    if(isStaff&&(r['messages'] as List?)?.isEmpty==true){
      try{
       final old=await widget.api.callWithParams('support_admin_thread',{
        'user_id':widget.userId!,
       });
       if((old['messages'] as List?)?.isNotEmpty==true)r=old;
      }catch(_){/* Keep the primary authenticated response. */}
    }
   }on ApiError catch(e){
    if(!cikokoLegacyChatFallbackAllowed(e))rethrow;
    r=isStaff
      ?await widget.api.callWithParams('support_admin_thread',{
         'user_id':widget.userId!,
       })
      :await widget.api.call('chat');
   }
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
   }else if(error!=null&&mounted){
    // Clear a stale network error after a successful empty or unchanged poll.
    setState(()=>error=null);
   }
  }catch(e){
   if(mounted&&data.isEmpty)setState(()=>
    error=isStaff&&e.toString().contains('Percakapan belum tersedia')
      ?'Percakapan belum tersedia pada server. Buka kembali dari Pesan Masuk.'
      :'Percakapan belum dapat dimuat: '+e.toString());
  }
  finally{loading=false;}
 }
 Future<void> send()async{
  final msg=input.text.trim();
  if(sending||msg.isEmpty)return;
  setState(()=>sending=true);
  try{
   try{
    await widget.api.call('chat_v2548_send',body:{
     'message':msg,if(isStaff)'user_id':widget.userId,
    });
   }on ApiError catch(e){
    // Fallback only after an explicit "not available / missing thread"
    // response. Never retry after a timeout or ambiguous write failure,
    // which could duplicate an already-stored message.
    if(!cikokoLegacyChatFallbackAllowed(e))rethrow;
    if(isStaff){
     await widget.api.call('chat_reply',body:{
      'user_id':widget.userId,'message':msg,
     });
    }else{
     await widget.api.call('chat_send',body:{'message':msg});
    }
   }
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
  Container(key:const Key('v2562_chat_header'),
   margin:const EdgeInsets.fromLTRB(12,12,12,8),
   padding:const EdgeInsets.symmetric(horizontal:14,vertical:13),
   decoration:BoxDecoration(
    borderRadius:V6.radius(16),
    gradient:const LinearGradient(
     colors:[Color(0xFF06439B),Color(0xFF0A7DE8)],
     begin:Alignment.topLeft,end:Alignment.bottomRight)),
   child:Row(children:[
    Container(width:39,height:39,
     decoration:BoxDecoration(color:const Color(0x28FFFFFF),
       borderRadius:V6.radius(12)),
     child:const Icon(Icons.chat_bubble_outline_rounded,color:Colors.white,size:21)),
    const SizedBox(width:10),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Text(widget.title,style:const TextStyle(color:Colors.white,
      fontWeight:FontWeight.w900,fontSize:15)),
     const SizedBox(height:3),
     const Text('Komunikasi langsung dengan petugas kelurahan',
      maxLines:2,overflow:TextOverflow.ellipsis,
      style:TextStyle(color:Color(0xFFE7F4FF),fontSize:10.3)),
    ])),
    IconButton(onPressed:reload,tooltip:'Muat ulang chat',
     icon:const Icon(Icons.refresh_rounded,color:Colors.white)),
   ])),
  if(error!=null)Padding(padding:const EdgeInsets.all(8),
   child:Row(children:[
    const Icon(Icons.error_outline_rounded,color:V6.red,size:18),
    const SizedBox(width:7),
    Expanded(child:Text(error!,style:const TextStyle(
     color:V6.red,fontSize:11))),
    TextButton(onPressed:reload,child:const Text('Coba Lagi')),
   ])),
  Expanded(child:RefreshIndicator(onRefresh:reload,
   child:ListView.builder(controller:scroll,key:const Key('cikoko_live_chat'),
    padding:const EdgeInsets.all(10),itemCount:data.isEmpty?1:data.length,
    itemBuilder:(c,i)=>data.isEmpty?
      Padding(padding:const EdgeInsets.all(18),
       child:Center(child:Text(
        error!=null?'Pesan belum dapat ditampilkan. Coba muat ulang.':
        'Belum ada pesan. Tulis untuk memulai percakapan.',
        textAlign:TextAlign.center,
        style:const TextStyle(color:V6.secondary,fontSize:12)))):
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

/// Canonical account ID is the only safe thread identity. A display name can
/// belong to multiple accounts; merging by name would expose private messages.
List<Map<String,dynamic>> cikokoDistinctChatThreads(Iterable<dynamic> incoming){
 final latest=<String,Map<String,dynamic>>{};
 for(final item in incoming){
  if(item is! Map)continue;
  final row=Map<String,dynamic>.from(item);
  final owner=(row['user_id']??'').toString().trim();
  if(owner.isEmpty)continue;
  final id=int.tryParse((row['last_id']??row['id']??0).toString())??0;
  final existing=latest[owner];
  final oldId=existing==null? -1:
    (int.tryParse((existing['last_id']??existing['id']??0).toString())??0);
  if(existing==null||id>oldId)latest[owner]=row;
 }
 final rows=latest.values.toList();
 rows.sort((a,b){
  final ai=int.tryParse((a['last_id']??a['id']??0).toString())??0;
  final bi=int.tryParse((b['last_id']??b['id']??0).toString())??0;
  return bi.compareTo(ai);
 });
 return rows;
}
int cikokoChatUnreadCount(Map<String,dynamic> row){
 final count=int.tryParse((row['unread_count']??0).toString())??0;
 return count<0?0:(count>99999?99999:count);
}

class CikokoLiveChatInbox extends StatefulWidget{
 final CikokoApi api;
 final ValueChanged<int>? onUnreadChanged;
 const CikokoLiveChatInbox({super.key,required this.api,this.onUnreadChanged});
 @override State<CikokoLiveChatInbox> createState()=>_CikokoLiveChatInboxState();
}
class _CikokoLiveChatInboxState extends State<CikokoLiveChatInbox>
    with WidgetsBindingObserver{
 final search=TextEditingController();
 List<Map<String,dynamic>> threads=[];
 Timer? timer;
 bool foreground=true,loading=false;
 int unreadTotal=0;
 String? error;

 @override void initState(){
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  refresh();
  timer=Timer.periodic(const Duration(seconds:4),(_){
   if(foreground)refresh();
  });
 }
 @override void didChangeAppLifecycleState(AppLifecycleState state){
  foreground=state==AppLifecycleState.resumed;
  if(foreground)refresh();
 }
 @override void dispose(){
  timer?.cancel();search.dispose();
  WidgetsBinding.instance.removeObserver(this);
  super.dispose();
 }
 Future<void> refresh()async{
  if(loading)return;
  loading=true;
  try{
   Map<String,dynamic> response;
   try{
    // Canonical v2563 inbox lives beside the chat thread endpoint, with the
    // same database, identity and permission checks.
    response=await widget.api.call('chat_v2548_threads');
   }catch(_){
    // Rolling cPanel deployments may still have the previous index API.
    // Normalize the legacy response without ever merging different accounts.
    response=await widget.api.call('chat_threads');
   }
   final next=cikokoDistinctChatThreads(
     List<dynamic>.from(response['threads']??[]));
   final total=next.fold<int>(0,
     (value,row)=>value+cikokoChatUnreadCount(row));
   if(!mounted)return;
   final notify=total!=unreadTotal;
   setState((){
    threads=next;
    unreadTotal=total;
    error=null;
   });
   if(notify)widget.onUnreadChanged?.call(total);
  }catch(e){
   if(mounted)setState(()=>
     error='Inbox belum dapat dimuat. Periksa koneksi atau API chat.');
  }finally{loading=false;}
 }
 Future<void> open(Map<String,dynamic> row)async{
  final id=(row['user_id']??'').toString().trim();
  if(id.isEmpty)return;
  final name=(row['name']??'Warga Cikoko').toString();
  await Navigator.of(context).push(MaterialPageRoute<void>(
    builder:(_)=>Scaffold(
     appBar:AppBar(title:Text(name,
       maxLines:1,overflow:TextOverflow.ellipsis)),
     body:CikokoLiveChat(api:widget.api,userId:id,title:name,
       inboxLastId:int.tryParse(
         (row['last_id']??row['id']??0).toString())),
    )));
  if(mounted)await refresh();
 }
 String shortAccount(String id){
  if(id.length<=11)return id;
  return id.substring(0,5)+'…'+id.substring(id.length-4);
 }
 String shortTime(String raw){
  if(raw.isEmpty)return '';
  final parsed=DateTime.tryParse(raw.replaceFirst(' ','T'));
  if(parsed==null)return raw.length>=16?raw.substring(11,16):raw;
  final now=DateTime.now();
  if(now.year==parsed.year&&now.month==parsed.month&&now.day==parsed.day){
   return parsed.hour.toString().padLeft(2,'0')+':'+
     parsed.minute.toString().padLeft(2,'0');
  }
  return parsed.day.toString().padLeft(2,'0')+'/'+
    parsed.month.toString().padLeft(2,'0');
 }
 @override Widget build(BuildContext context){
  final term=search.text.trim().toLowerCase();
  final visible=threads.where((row){
   if(term.isEmpty)return true;
   return ['name','user_id','message'].any(
     (k)=>(row[k]??'').toString().toLowerCase().contains(term));
  }).toList();

  return Column(children:[
   Container(
    key:const Key('cikoko_admin_inbox_header'),
    margin:const EdgeInsets.fromLTRB(12,12,12,10),
    padding:const EdgeInsets.symmetric(horizontal:15,vertical:14),
    decoration:BoxDecoration(
     borderRadius:V6.radius(15),
     gradient:const LinearGradient(
      colors:[Color(0xFF063D92),Color(0xFF107BEF)],
      begin:Alignment.topLeft,end:Alignment.bottomRight)),
    child:Row(children:[
     Container(width:41,height:41,alignment:Alignment.center,
      decoration:BoxDecoration(
       color:const Color(0x25FFFFFF),borderRadius:V6.radius(12)),
      child:const Icon(Icons.forum_outlined,
       size:24,color:Colors.white)),
     const SizedBox(width:11),
     Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Pesan Masuk',style:TextStyle(
       fontSize:16,color:Colors.white,fontWeight:FontWeight.w900)),
      const SizedBox(height:3),
      Text(threads.length.toString()+' percakapan · '+
       unreadTotal.toString()+' pesan belum dibaca',
       maxLines:2,overflow:TextOverflow.ellipsis,
       style:const TextStyle(fontSize:10.5,color:Color(0xFFE8F5FF))),
     ])),
     IconButton(
      tooltip:'Segarkan inbox',onPressed:refresh,
      icon:const Icon(Icons.refresh_rounded,color:Colors.white)),
    ])),
   Padding(padding:const EdgeInsets.fromLTRB(13,0,13,8),
    child:TextField(
     key:const Key('cikoko_admin_inbox_search'),
     controller:search,
     onChanged:(_)=>setState((){}),
     decoration:InputDecoration(
      hintText:'Cari nama, akun, atau isi pesan',
      prefixIcon:const Icon(Icons.search_rounded,color:V6.blue),
      suffixIcon:search.text.isEmpty?null:IconButton(
       tooltip:'Hapus pencarian',
       onPressed:(){search.clear();setState((){});},
       icon:const Icon(Icons.close_rounded,color:V6.secondary)),
     ))),
   if(error!=null)Padding(
    padding:const EdgeInsets.symmetric(horizontal:13,vertical:7),
    child:Row(children:[
     const Icon(Icons.error_outline_rounded,color:V6.red,size:18),
     const SizedBox(width:8),
     Expanded(child:Text(error!,style:const TextStyle(
      color:V6.red,fontSize:11.5))),
     TextButton(onPressed:refresh,child:const Text('Coba Lagi')),
    ])),
   Expanded(child:RefreshIndicator(onRefresh:refresh,
    child:ListView.builder(
     key:const Key('cikoko_live_chat_inbox'),
     physics:const AlwaysScrollableScrollPhysics(),
     padding:const EdgeInsets.fromLTRB(12,2,12,18),
     itemCount:visible.isEmpty?1:visible.length,
     itemBuilder:(ctx,i){
      if(visible.isEmpty)return Padding(
       padding:const EdgeInsets.symmetric(vertical:38,horizontal:15),
       child:Center(child:Text(
        error!=null?'Belum dapat menampilkan percakapan':
         term.isNotEmpty?'Tidak ada percakapan yang sesuai':
         'Belum ada pesan masuk',
        textAlign:TextAlign.center,
        style:const TextStyle(color:V6.secondary,fontSize:12))));
      final row=visible[i];
      final owner=(row['user_id']??'').toString();
      final name=(row['name']??'Warga Cikoko').toString().trim();
      final last=(row['message']??'').toString().trim();
      final fromStaff=(row['sender']??'').toString()=='admin';
      final unread=cikokoChatUnreadCount(row);
      final initial=name.isEmpty?'W':name.substring(0,1).toUpperCase();
      return Padding(padding:const EdgeInsets.only(bottom:7),
       child:Material(color:Colors.white,
        shape:RoundedRectangleBorder(
         side:BorderSide(color:unread>0?
           const Color(0xFFB9D8FF):V6.border),
         borderRadius:V6.radius(13)),
        child:InkWell(
         key:Key('cikoko_inbox_thread_'+owner),
         onTap:()=>open(row),borderRadius:V6.radius(13),
         child:Padding(padding:const EdgeInsets.all(11),
          child:Row(children:[
           CircleAvatar(radius:23,backgroundColor:V6.pale,
            child:Text(initial,style:const TextStyle(
             color:V6.blue,fontWeight:FontWeight.w900,fontSize:17))),
           const SizedBox(width:11),
           Expanded(child:Column(
            crossAxisAlignment:CrossAxisAlignment.start,children:[
             Row(children:[
              Expanded(child:Text(name.isEmpty?'Warga Cikoko':name,
               maxLines:1,overflow:TextOverflow.ellipsis,
               style:TextStyle(color:V6.ink,fontSize:13,
                fontWeight:unread>0?FontWeight.w900:FontWeight.w700))),
              Text(shortTime((row['created_at']??'').toString()),
               style:const TextStyle(color:V6.secondary,fontSize:10)),
             ]),
             const SizedBox(height:3),
             Text((fromStaff?'Anda: ':'')+(last.isEmpty?'📷 Foto':last),
              maxLines:1,overflow:TextOverflow.ellipsis,
              style:TextStyle(color:unread>0?V6.ink:V6.secondary,
               fontSize:11.5,fontWeight:unread>0?
                FontWeight.w700:FontWeight.w400)),
             const SizedBox(height:4),
             Text('ID akun: '+shortAccount(owner),
              maxLines:1,overflow:TextOverflow.ellipsis,
              style:const TextStyle(fontSize:9.5,color:V6.secondary)),
            ])),
           const SizedBox(width:8),
           if(unread>0)Container(
            constraints:const BoxConstraints(minWidth:23,minHeight:23),
            alignment:Alignment.center,
            padding:const EdgeInsets.symmetric(horizontal:5,vertical:2),
            decoration:BoxDecoration(color:V6.blue,
             borderRadius:V6.radius(14)),
            child:Text(unread>99?'99+':unread.toString(),
             style:const TextStyle(color:Colors.white,
              fontSize:10,fontWeight:FontWeight.w900))),
           const Icon(Icons.chevron_right_rounded,
            color:V6.secondary,size:18),
          ])),
        )));
     },
    ))),
  ]);
 }
}
