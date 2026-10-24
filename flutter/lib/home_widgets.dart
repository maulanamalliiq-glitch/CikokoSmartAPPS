import 'package:flutter/material.dart';

const Color homeNavy = Color(0xff10375f);
const Color homeBlue = Color(0xff226fda);

/// Beranda Flutter native terinspirasi tampilan website Kelurahan Cikoko.
/// Aset banner dibundel dengan APK: tidak memerlukan WebView/koneksi untuk tampil.
class CikokoOfficeHero extends StatelessWidget {
  final VoidCallback onService;
  final VoidCallback onProfile;
  const CikokoOfficeHero({super.key, required this.onService, required this.onProfile});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(15),
    child: SizedBox(
      height: 190,
      width: double.infinity,
      child: Stack(fit: StackFit.expand, children: [
        Image.asset('assets/kantor-cikoko.jpg', fit: BoxFit.cover,
          alignment: const Alignment(0.15, 0.0)),
        const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.centerLeft, end: Alignment.centerRight,
          colors: [Color(0xe90b2e51), Color(0xab0b2e51), Color(0x340b2e51)],
          stops: [0, .68, 1],
        ))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('KELURAHAN CIKOKO',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 3),
            const Text('Kecamatan Pancoran · Jakarta Selatan',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Melayani dengan hati, membangun bersama untuk Cikoko yang lebih maju.',
              style: TextStyle(fontSize: 11, color: Color(0xffe9f2fa), height: 1.3), maxLines: 2),
            const Spacer(),
            Row(children: [
              SizedBox(height: 34, child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: homeBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  padding: const EdgeInsets.symmetric(horizontal: 11)),
                onPressed: onService,
                icon: const Icon(Icons.description_outlined, size: 15),
                label: const Text('Layanan Online', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              )),
              const SizedBox(width: 8),
              SizedBox(height: 34, child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xffe7f0fb)),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                ),
                onPressed: onProfile,
                child: const Text('Profil Kelurahan',style: TextStyle(fontSize: 11)),
              )),
            ]),
          ]),
        ),
      ]),
    ),
  );
}

class CikokoQuickMenu extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const CikokoQuickMenu({super.key,required this.title, required this.icon,required this.onTap});
  @override Widget build(BuildContext context)=>Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      key: Key('menu_$title'),
      borderRadius: BorderRadius.circular(12),onTap:onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 7),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),border: Border.all(color: const Color(0xffe0e9f4))),
        child: Row(children:[
          Container(width:33,height:33,decoration: BoxDecoration(color:const Color(0xffeaf3fd),borderRadius: BorderRadius.circular(10)),child:Icon(icon,size:19,color:homeBlue)),
          const SizedBox(width:9),
          Expanded(child:Text(title,maxLines:2,overflow:TextOverflow.ellipsis,
            style:const TextStyle(color:homeNavy,fontWeight:FontWeight.w700,fontSize:11.5,height:1.22))),
          const Icon(Icons.chevron_right,size:14,color:Color(0xff7190ad)),
        ]),
      ),
    ),
  );
}

/// Tidak memalsukan statistik publik: angka hanya tampil ketika sumber API valid.
class CikokoLetterCounters extends StatelessWidget {
  final Map<String,int>? counts;
  final bool guest;
  final VoidCallback onTap;
  const CikokoLetterCounters({super.key,required this.counts,required this.guest,required this.onTap});
  @override Widget build(BuildContext context) => Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[const Expanded(child:Text('Status Surat Saya',style:TextStyle(fontWeight:FontWeight.w800,color:homeNavy,fontSize:13))),
      TextButton(onPressed:onTap,child:Text(guest?'Login →':'Riwayat →',style:const TextStyle(fontSize:11)))]),
    Row(children: [
      for(final pair in const [
        ('masuk','Masuk',Color(0xff2467ba)),
        ('proses','Proses',Color(0xffd58823)),
        ('selesai','Selesai',Color(0xff17875a)),
      ]) ...[
        Expanded(child:Container(
          padding:const EdgeInsets.symmetric(horizontal:10,vertical:9),
          decoration:BoxDecoration(color:Colors.white,border:Border.all(color:const Color(0xffe1eaf4)),borderRadius:BorderRadius.circular(11)),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(guest||counts==null?'—':'${counts![pair.$1]??0}',style:TextStyle(color:pair.$3,fontSize:21,fontWeight:FontWeight.w800)),
            Text(pair.$2,style:const TextStyle(fontSize:10.5,color:homeNavy,fontWeight:FontWeight.w600))
          ]),
        )),
        if(pair.$1!='selesai')const SizedBox(width:7),
      ],
    ]),
  ]);
}
