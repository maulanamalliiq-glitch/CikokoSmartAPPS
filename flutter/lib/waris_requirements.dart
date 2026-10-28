import 'package:flutter/material.dart';

const _headingColor = Color(0xff10375f);
const _actionColor = Color(0xff226fda);

class WarisRequirementCategory {
  final String title;
  final List<String> requirements;
  final bool allowApply;
  const WarisRequirementCategory(this.title,this.requirements,{this.allowApply=false});
}

/// Informational checklist only. No user documents are loaded or submitted.
const cikokoWarisRequirements = <WarisRequirementCategory>[
  WarisRequirementCategory('Ahli Waris',[
    'Asli dan Foto KTP Pemohon',
    'Asli dan Foto KK Pemohon',
    'Asli dan Foto Surat Pengantar RT RW',
    'Asli dan Foto Surat atau Akta Kematian',
    'Asli dan Foto Buku Nikah',
    'Asli dan Foto KTP Para Ahli Waris',
    'Asli dan Foto KK Para Ahli Waris',
    'Asli dan Foto Akta Lahir Para Ahli Waris',
    'Asli dan Foto KTP 2 Orang Saksi',
  ],allowApply:true),
  WarisRequirementCategory('Surat Permohonan Hak atas Negara',[
    'Asli dan Foto KTP Pemohon',
    'Asli dan Foto KK Pemohon',
    'Asli dan Foto Surat atau Dokumen Asal Usul Tanah',
    'Asli dan Foto Pernyataan dan Hibah Waris Jika Tanah Warisan',
    'Asli dan Foto SPPT PBB Tahun Berjalan dan Bukti Pelunasan',
    'Asli dan Foto Surat Batar Rumah Pemohon',
    'Asli dan Foto KTP 2 Orang Saksi',
  ]),
  WarisRequirementCategory('Surat Peningkatan Hak dari SHGB ke SHM',[
    'Asli dan Foto KTP Pemohon',
    'Asli dan Foto KK Pemohon',
    'Asli dan Foto Sertifikat Tanah SHGB',
    'Asli dan Foto Surat SPPT PBB Tahun Berjalan dan Bukti Pelunasan',
    'Asli dan Foto Rumah',
    'Asli dan Foto Plang Rumah',
    'Asli dan Foto Surat Kuasa Asli dan KTP Penerima Kuasa (Jika dikuasakan)',
    'Asli dan Foto KTP 2 Orang Saksi',
    'Asli dan Foto Surat Pengantar RT RW',
  ]),
];

Future<void> showCikokoWarisRequirements(
  BuildContext context, {required VoidCallback onApply}
) {
  return showGeneralDialog<void>(
    context:context,
    barrierDismissible:true,
    barrierLabel:'Tutup Persyaratan Ahli Waris',
    barrierColor:Colors.black54,
    transitionDuration:const Duration(milliseconds:260),
    pageBuilder:(popup,_,__)=>Align(
      alignment:Alignment.centerRight,
      child:ConstrainedBox(
        constraints:const BoxConstraints(maxWidth:680),
        child:SizedBox(
          width:MediaQuery.sizeOf(popup).width*.94,
          height:double.infinity,
          child:Material(
            color:const Color(0xfff5f8fc),
            elevation:14,
            child:SafeArea(child:Column(children:[
              Container(color:Colors.white,padding:const EdgeInsets.fromLTRB(18,14,9,14),
                child:Row(children:[
                  const Icon(Icons.fact_check_outlined,color:_actionColor),
                  const SizedBox(width:10),
                  const Expanded(child:Text('Persyaratan Pelayanan Surat',
                    style:TextStyle(fontSize:17,fontWeight:FontWeight.w800,color:_headingColor))),
                  IconButton(tooltip:'Tutup',onPressed:()=>Navigator.of(popup).pop(),
                    icon:const Icon(Icons.close)),
                ])),
              Expanded(child:ListView(
                padding:const EdgeInsets.fromLTRB(12,14,12,24),
                children:[
                  const Text('Informasi dokumen yang perlu disiapkan sebelum mengajukan layanan.',
                    style:TextStyle(fontSize:12,color:Colors.blueGrey)),
                  const SizedBox(height:12),
                  for(final group in cikokoWarisRequirements)
                    Card(margin:const EdgeInsets.only(bottom:14),child:Padding(
                      padding:const EdgeInsets.all(12),child:Column(
                      crossAxisAlignment:CrossAxisAlignment.start,children:[
                        Text('Persyaratan ${group.title}',
                          style:const TextStyle(fontWeight:FontWeight.w800,
                            color:_headingColor,fontSize:14)),
                        const SizedBox(height:10),
                        Table(
                          border:TableBorder.all(color:const Color(0xffdbe5f0)),
                          columnWidths:const {0:FixedColumnWidth(40),1:FlexColumnWidth()},
                          children:[
                            const TableRow(decoration:BoxDecoration(color:Color(0xffe7eff9)),
                              children:[
                                Padding(padding:EdgeInsets.all(8),
                                  child:Text('No.',style:TextStyle(fontWeight:FontWeight.bold))),
                                Padding(padding:EdgeInsets.all(8),
                                  child:Text('Dokumen Persyaratan',style:TextStyle(fontWeight:FontWeight.bold))),
                              ]),
                            for(var i=0;i<group.requirements.length;i++)
                              TableRow(children:[
                                Padding(padding:const EdgeInsets.all(8),
                                  child:Text('${i+1}.',style:const TextStyle(fontSize:11))),
                                Padding(padding:const EdgeInsets.all(8),
                                  child:Text(group.requirements[i],
                                    style:const TextStyle(fontSize:11.5))),
                              ]),
                          ],
                        ),
                        if(group.allowApply)...[
                          const SizedBox(height:12),
                          SizedBox(width:double.infinity,child:FilledButton.icon(
                            icon:const Icon(Icons.edit_note),
                            label:const Text('Ajukan Surat'),
                            onPressed:(){
                              Navigator.of(popup).pop();
                              WidgetsBinding.instance.addPostFrameCallback((_)=>onApply());
                            },
                          )),
                        ],
                      ]))),
                ])),
            ])),
          ),
        ),
      ),
    ),
    transitionBuilder:(ctx,animation,secondary,child)=>SlideTransition(
      position:Tween<Offset>(begin:const Offset(1,0),end:Offset.zero)
        .animate(CurvedAnimation(parent:animation,curve:Curves.easeOutCubic)),
      child:child,
    ),
  );
}
