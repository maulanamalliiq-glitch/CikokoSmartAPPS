import 'package:flutter/material.dart';

const Color homeNavy = Color(0xff10375f);
const Color homeBlue = Color(0xff226fda);
const Color homeMuted = Color(0xff657b91);
const Color homeBorder = Color(0xffe0e8f1);

/// Beranda native: visual konsisten dengan halaman depan website Kelurahan Cikoko.
class CikokoOfficeHero extends StatelessWidget {
  final VoidCallback onService;
  final VoidCallback onProfile;
  const CikokoOfficeHero({super.key, required this.onService, required this.onProfile});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 560;
      final copy = Padding(
        padding: EdgeInsets.fromLTRB(wide ? 23 : 17, 18, wide ? 13 : 17, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('PORTAL LAYANAN DIGITAL',
              style: TextStyle(fontSize: 9, color: Color(0xff1766c5),
                fontWeight: FontWeight.w800, letterSpacing: 1)),
            const SizedBox(height: 8),
            const Text('Cikoko Smart',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900,
                color: Color(0xff082d5e), height: 1.1)),
            const SizedBox(height: 4),
            const Text('Layanan dan Informasi',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                color: Color(0xff143e70), height: 1.20)),
            const Text('Kelurahan Cikoko',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                color: Color(0xff143e70), height: 1.20)),
            const SizedBox(height: 8),
            const Text('Kecamatan Pancoran, Jakarta Selatan. Informasi dan pelayanan dalam satu tempat.',
              maxLines: 3, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, height: 1.4,
                color: Color(0xff506c87))),
            const SizedBox(height: 14),
            Wrap(spacing: 7, runSpacing: 7, children: [
              FilledButton(
                onPressed: onService,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xff176de4),
                  minimumSize: const Size(0, 35),
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('Ajukan Layanan →',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
              ),
              OutlinedButton(
                onPressed: onProfile,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xff1557a6),
                  backgroundColor: Colors.white,
                  minimumSize: const Size(0, 35),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  side: const BorderSide(color: Color(0xffb9d4f1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('Lihat Profil',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
              ),
            ]),
          ],
        ),
      );
      final photo = ClipRRect(
        borderRadius: BorderRadius.circular(wide ? 0 : 11),
        child: Stack(fit: StackFit.expand, children: [
          Image.asset('assets/kantor-cikoko.jpg',
            fit: BoxFit.cover, alignment: Alignment.center),
          const DecoratedBox(decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter, end: Alignment.topCenter,
              colors: [Color(0x8822487c), Colors.transparent]))),
          const Positioned(left: 11, bottom: 8,
            child: Text('KANTOR KELURAHAN CIKOKO',
              style: TextStyle(color: Colors.white, fontSize: 8.5,
                fontWeight: FontWeight.w800))),
        ]),
      );
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xffe4f1ff),
          gradient: const LinearGradient(
            colors: [Color(0xffeaf4ff), Color(0xffd5eaff)]),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xffcfe2f5)),
          boxShadow: const [BoxShadow(
            color: Color(0x101b4d85), blurRadius: 11, offset: Offset(0, 3))]),
        clipBehavior: Clip.antiAlias,
        child: wide
          ? SizedBox(height: 274, child: Row(children: [
              Expanded(flex: 11, child: copy),
              Expanded(flex: 10, child: photo),
            ]))
          : Column(mainAxisSize: MainAxisSize.min, children: [
              copy,
              SizedBox(height: 126,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: photo)),
            ]),
      );
    },
  );
}

/// Kategori pelayanan pada website, diterjemahkan menjadi kartu Flutter.
class CikokoServiceTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  const CikokoServiceTile({super.key, required this.title, required this.description,
    required this.icon, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(13),
    child: InkWell(
      key: Key('service_$title'), onTap: onTap, borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(13),
          border: Border.all(color: homeBorder)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(width: 33, height: 37,
            decoration: BoxDecoration(color: accent.withValues(alpha: .11),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 19, color: accent)),
          const SizedBox(width: 8),
          Expanded(child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: homeNavy, fontSize: 11.3,
                fontWeight: FontWeight.w800, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(description, style: const TextStyle(color: homeMuted, fontSize: 9.6,
                height: 1.18), maxLines: 2, overflow: TextOverflow.ellipsis),
            ])),
          const SizedBox(width: 3),
          Icon(Icons.arrow_forward_ios_rounded, size: 11, color: accent),
        ]),
      ),
    ),
  );
}

class CikokoQuickMenu extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const CikokoQuickMenu({super.key,required this.title, required this.icon,required this.onTap});
  @override
  Widget build(BuildContext context) => CikokoServiceTile(
    title: title, description: 'Buka layanan', icon: icon, accent: homeBlue,
    onTap: onTap,
  );
}

/// Angka rekap dari API publik: tidak membocorkan identitas dan lampiran.
class CikokoLetterCounters extends StatelessWidget {
  final Map<String,int>? counts;
  final void Function(String) onStatusTap;
  const CikokoLetterCounters({super.key,required this.counts,required this.onStatusTap});
  @override
  Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[
      const Expanded(child:Text('Status Pelayanan Surat',
        style:TextStyle(fontWeight:FontWeight.w800,color:homeNavy,fontSize:13.5))),
      TextButton(onPressed:()=>onStatusTap('all'),
        child:const Text('Lihat Status →',style:TextStyle(fontSize:11.2,fontWeight:FontWeight.w700))),
    ]),
    Row(children:[
      for(final pair in const [
        ('masuk','Surat Masuk',Color(0xff2467ba)),
        ('proses','Diproses',Color(0xffd58823)),
        ('selesai','Selesai',Color(0xff17875a)),
      ]) ...[
        Expanded(child:InkWell(onTap:()=>onStatusTap(pair.$1),
          borderRadius:BorderRadius.circular(11),
          child:Container(
            padding:const EdgeInsets.symmetric(horizontal:10,vertical:9),
            decoration:BoxDecoration(color:Colors.white,border:Border.all(color:homeBorder),
              borderRadius:BorderRadius.circular(11)),
            child:Row(children:[
              Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text(counts==null?'—':'${counts![pair.$1]??0}',
                  style:TextStyle(color:pair.$3,fontSize:19,fontWeight:FontWeight.w900)),
                const SizedBox(height:2),
                Text(pair.$2,maxLines:1,overflow:TextOverflow.ellipsis,
                  style:const TextStyle(fontSize:9.6,color:homeNavy,fontWeight:FontWeight.w600)),
              ])),
              Icon(Icons.chevron_right_rounded,size:16,color:pair.$3),
            ]),
          ))),
        if(pair.$1!='selesai')const SizedBox(width:6),
      ],
    ]),
  ]);
}
