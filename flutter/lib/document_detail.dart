import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'api.dart';

// Bottom sheet preview: only details returned by authenticated PHP endpoint.
Future<void> showCikokoDocument(BuildContext context, CikokoApi api, {required int id, required String kind, VoidCallback? onChanged}) {
  return showModalBottomSheet<void>(
    context:context,isScrollControlled:true,useSafeArea:true,backgroundColor:Colors.white,
    shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(22))),
    builder:(ctx)=>SizedBox(height:MediaQuery.sizeOf(ctx).height*.86,
      child:DocumentDetailSheet(api:api,id:id,kind:kind,onChanged:onChanged)),
  );
}
class DocumentDetailSheet extends StatefulWidget {
  final CikokoApi api;
  final int id;
  final String kind;
  final VoidCallback? onChanged;
  const DocumentDetailSheet({super.key,required this.api,required this.id,required this.kind,this.onChanged});
  @override State<DocumentDetailSheet> createState()=>_DocumentDetailState();
}
class _DocumentDetailState extends State<DocumentDetailSheet> {
  late Future<Map<String,dynamic>> request;
  final reason=TextEditingController();
  final Set<String> selected={};
  final Map<String,String> replacementPhotos={};
  bool submitting=false;
  double progress=0;
  @override void initState(){super.initState();reload();}
  @override void dispose(){reason.dispose();super.dispose();}
  void reload(){request=widget.api.call('document_detail&id=${widget.id}&kind=${widget.kind}');if(mounted)setState((){});}
  String v(dynamic x)=>x==null||'$x'.trim().isEmpty?'—':'$x';
  Future<void> askCorrections()async{
    if(selected.isEmpty||reason.text.trim().isEmpty){message('Pilih dokumen yang kurang dan tulis catatan.',error:true);return;}
    setState(()=>submitting=true);
    try{
      await widget.api.call('waris_request_correction',body:{'id':widget.id,'codes':selected.toList(),'notes':reason.text.trim()});
      selected.clear();reason.clear();widget.onChanged?.call();reload();message('Permintaan perbaikan dikirim ke warga.');
    }catch(e){message('$e',error:true);}finally{if(mounted)setState(()=>submitting=false);}
  }
  Future<void> uploadCorrections()async{
    if(replacementPhotos.isEmpty){message('Pilih dokumen yang akan diunggah ulang.',error:true);return;}
    setState((){submitting=true;progress=0;});
    try {
      await widget.api.upload('waris_resubmit',{'application_id':'${widget.id}'},
        {for(final entry in replacementPhotos.entries) entry.key:[entry.value]},
        progress:(p){if(mounted)setState(()=>progress=p);});
      replacementPhotos.clear();widget.onChanged?.call();reload();message('Dokumen berhasil dikirim. Petugas akan memeriksa ulang.');
    }catch(e){message('$e',error:true);}finally{if(mounted)setState(()=>submitting=false);}
  }
  void message(String s,{bool error=false}){if(!mounted)return;ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s),backgroundColor:error?Colors.red.shade700:const Color(0xff165a8a)));}
  Widget pair(String label,dynamic val)=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:const TextStyle(fontSize:11,color:Colors.blueGrey)),Text(v(val),style:const TextStyle(fontWeight:FontWeight.w500,fontSize:13))]));
  Widget section(String text)=>Padding(padding:const EdgeInsets.fromLTRB(0,16,0,8),child:Text(text,style:const TextStyle(fontSize:16,fontWeight:FontWeight.bold,color:Color(0xff123d65))));
  @override Widget build(BuildContext context)=>Column(children:[
    Padding(padding:const EdgeInsets.fromLTRB(18,12,12,6),child:Row(children:[const Icon(Icons.description_outlined,color:Color(0xff226fda)),const SizedBox(width:8),const Expanded(child:Text('Detail & Progres Pengajuan',style:TextStyle(fontWeight:FontWeight.w800,fontSize:18))),IconButton(icon:const Icon(Icons.close),onPressed:()=>Navigator.pop(context))])),
    const Divider(height:2),
    Expanded(child:FutureBuilder<Map<String,dynamic>>(future:request,builder:(ctx,s){
      if(s.hasError)return Center(child:Padding(padding:const EdgeInsets.all(16),child:Text('Detail belum bisa dibuka: ${s.error}',textAlign:TextAlign.center)));
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      final data=s.data!, detail=Map<String,dynamic>.from(data['detail'] as Map);
      final timeline=List<dynamic>.from(data['timeline']??[]), docs=List<dynamic>.from(data['documents']??[]);
      final corrections=List<dynamic>.from(data['corrections']??[]);
      final labels=Map<String,dynamic>.from(data['labels']??{});
      final status='${detail['status']??'masuk'}';
      final pending=corrections.where((x)=>x['resolved_at']==null).toList();
      final isWaris=widget.kind=='waris';
      final canReview=data['can_review']==true;
      final isOwner=data['is_owner']==true&&status=='revisi';
      final stages=['masuk','proses','selesai'];
      final step=status=='selesai'?3:status=='masuk'?1:2;
      return ListView(padding:const EdgeInsets.fromLTRB(16,10,16,24),children:[
        Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:const Color(0xfff2f7ff),borderRadius:BorderRadius.circular(14)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(isWaris?'Surat Ahli Waris':'Laporan Kegiatan',style:const TextStyle(fontSize:16,fontWeight:FontWeight.bold)),
          Text(v(detail['reference_no']??detail['id']),style:const TextStyle(fontSize:12,color:Colors.blueGrey)),
          const SizedBox(height:8),
          Row(children:[const Text('Status: '),Chip(label:Text(status.toUpperCase(),style:const TextStyle(fontSize:12)),backgroundColor:status=='selesai'?Colors.green.shade100:status=='revisi'?Colors.orange.shade100:Colors.blue.shade100)]),
          const SizedBox(height:4),
          Row(children:[for(var i=0;i<stages.length;i++)Expanded(child:Column(children:[Icon(i+1<=step?Icons.check_circle:Icons.radio_button_unchecked,color:i+1<=step?Colors.blue:Colors.grey,size:22),Text(['Masuk','Diproses','Selesai'][i],style:const TextStyle(fontSize:10))]))]),
          if(status=='revisi')const Padding(padding:EdgeInsets.only(top:8),child:Text('Perlu perbaikan dokumen. Lihat daftar di bawah.',style:TextStyle(color:Colors.deepOrange,fontWeight:FontWeight.w600))),
        ])),
        section('Data Pengajuan'),
        if(isWaris)...[
          pair('Nama Pemohon',detail['applicant_name']),pair('NIK',detail['applicant_nik']),pair('Nomor HP',detail['applicant_phone']),pair('Alamat',detail['applicant_address']),pair('Hubungan dengan Pewaris',detail['relationship']),
          const Divider(),pair('Nama Pewaris',detail['deceased_name']),pair('Tempat / Tanggal Lahir', '${v(detail['deceased_birthplace'])} / ${v(detail['deceased_birthdate'])}'),pair('Tanggal Menikah',detail['deceased_marriage_date']),pair('Tanggal Meninggal',detail['deceased_deathdate']),pair('Status Perkawinan',detail['marital_status']),pair('Ahli Waris',detail['heirs']),
          for(final child in List<dynamic>.from(detail['children']??[]))pair('Anak ke-${child['number']}',child['name']),
        ]else...[
          pair('Pelapor',detail['user_name']),pair('Jenis Laporan',detail['kind']),pair('Alamat',detail['address']),pair('Keterangan',detail['notes']),
        ],
        section('Riwayat Progres'),
        for(final t in timeline)Card(margin:const EdgeInsets.only(bottom:7),child:ListTile(dense:true,leading:const Icon(Icons.timeline,color:Colors.blue),title:Text(v(t['new_status']).toUpperCase(),style:const TextStyle(fontWeight:FontWeight.w700,fontSize:12)),subtitle:Text('${v(t['created_at'])}\n${v(t['notes'])}',style:const TextStyle(fontSize:11)))),
        if(timeline.isEmpty)const Text('Belum ada riwayat perubahan status.'),
        if(isWaris)...[
          section('Dokumen yang Dikirim'),
          for(final f in docs)Card(margin:const EdgeInsets.only(bottom:8),child:ListTile(
            leading:ClipRRect(borderRadius:BorderRadius.circular(8),child:Image.network('${CikokoApi.root}?action=waris_attachment&id=${f['id']}',headers:{'Authorization':'Bearer ${widget.api.token}'},width:55,height:58,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const SizedBox(width:55,height:58,child:Icon(Icons.image_not_supported_outlined)))),
            title:Text('${labels[f['requirement_code']]??f['requirement_code']}',style:const TextStyle(fontSize:12,fontWeight:FontWeight.w600)),
            subtitle:Text(v(f['original_name']),maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10)),
            onTap:()=>showDialog<void>(context:context,builder:(c)=>Dialog(child:Column(mainAxisSize:MainAxisSize.min,children:[IconButton(onPressed:()=>Navigator.pop(c),icon:const Icon(Icons.close)),InteractiveViewer(child:Image.network('${CikokoApi.root}?action=waris_attachment&id=${f['id']}',headers:{'Authorization':'Bearer ${widget.api.token}'},fit:BoxFit.contain))]))),
          )),
          section('Kelengkapan Dokumen'),
          if(corrections.isEmpty)const Text('Belum ada permintaan perbaikan dokumen.',style:TextStyle(fontSize:12,color:Colors.blueGrey)),
          for(final p in corrections)Card(color:p['resolved_at']==null?Colors.orange.shade50:Colors.green.shade50,child:ListTile(dense:true,leading:Icon(p['resolved_at']==null?Icons.warning_amber_rounded:Icons.check_circle_outline,color:p['resolved_at']==null?Colors.orange:Colors.green),title:Text('${labels[p['requirement_code']]??p['requirement_code']}'),subtitle:Text('${p['reason']}\n${p['resolved_at']==null?'Belum diperbaiki':'Foto perbaikan telah dikirim'}'))),
          if(canReview&&status!='selesai'&&status!='ditolak')...[
            section('Minta Perbaikan kepada Warga'),
            const Text('Pilih persyaratan yang perlu diunggah ulang. Warga akan mendapat notifikasi.',style:TextStyle(fontSize:12,color:Colors.blueGrey)),
            Wrap(spacing:5,runSpacing:5,children:[for(final entry in labels.entries)FilterChip(label:Text(entry.value.toString(),style:const TextStyle(fontSize:11)),selected:selected.contains(entry.key),onSelected:(yes)=>setState((){if(yes){selected.add(entry.key);}else{selected.remove(entry.key);}}))]),
            const SizedBox(height:10),TextField(controller:reason,maxLines:2,decoration:const InputDecoration(labelText:'Alasan dan petunjuk untuk warga')),
            const SizedBox(height:10),FilledButton.icon(onPressed:submitting?null:askCorrections,icon:const Icon(Icons.send),label:Text(submitting?'Mengirim...':'Kirim Permintaan Perbaikan')),
          ],
          if(isOwner && pending.isNotEmpty)...[
            section('Unggah Ulang Dokumen yang Kurang'),
            const Text('Pilih Kamera atau Galeri. Hanya foto yang diminta petugas yang akan diperbarui.',style:TextStyle(fontSize:12)),
            for(final p in pending)CorrectionPhotoPicker(key:ValueKey(p['requirement_code']),label:'${labels[p['requirement_code']]??p['requirement_code']}',onSelected:(path)=>replacementPhotos['${p['requirement_code']}']=path),
            if(submitting)...[LinearProgressIndicator(value:progress),Text('Mengunggah ${(progress*100).round()}%')],
            FilledButton.icon(onPressed:submitting?null:uploadCorrections,icon:const Icon(Icons.cloud_upload_outlined),label:const Text('Kirim Foto Perbaikan')),
          ],
        ],
      ]);
    }))
  ]);
}
class CorrectionPhotoPicker extends StatefulWidget {
 final String label;final ValueChanged<String> onSelected;
 const CorrectionPhotoPicker({super.key,required this.label,required this.onSelected});
 @override State<CorrectionPhotoPicker> createState()=>_CorrectionPhotoPickerState();
}
class _CorrectionPhotoPickerState extends State<CorrectionPhotoPicker>{String? path;bool busy=false;
 Future<void> pick(ImageSource src)async{
   setState(()=>busy=true);
   try {
     final x=await ImagePicker().pickImage(source:src,maxWidth:1900,maxHeight:2400,imageQuality:78,requestFullMetadata:false);
     if(x==null)return;
     var finalPath=x.path;
     if(await File(finalPath).length()>1550000){
       for(final q in [75,62,52]){
         final bytes=await FlutterImageCompress.compressWithFile(x.path,quality:q,format:CompressFormat.jpeg,keepExif:false);
         if(bytes==null)break;
         final f=File('${Directory.systemTemp.path}/cikoko_revisi_${DateTime.now().microsecondsSinceEpoch}.jpg');await f.writeAsBytes(bytes);finalPath=f.path;
         if(bytes.length<=1550000)break;
       }
     }
     if(mounted){setState(()=>path=finalPath);widget.onSelected(finalPath);}
   }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Foto gagal dipilih: $e')));}
   finally{if(mounted)setState(()=>busy=false);}
 }
 @override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(10),child:Row(children:[if(path!=null)ClipRRect(borderRadius:BorderRadius.circular(8),child:Image.file(File(path!),width:53,height:56,fit:BoxFit.cover)),const SizedBox(width:7),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(widget.label,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:12)),Wrap(spacing:4,children:[TextButton.icon(onPressed:busy?null:()=>pick(ImageSource.camera),icon:const Icon(Icons.camera_alt_outlined,size:16),label:const Text('Kamera')),TextButton.icon(onPressed:busy?null:()=>pick(ImageSource.gallery),icon:const Icon(Icons.photo_library_outlined,size:16),label:const Text('Galeri'))])]))])));
}
