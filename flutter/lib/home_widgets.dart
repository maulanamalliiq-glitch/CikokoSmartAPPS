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
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: SizedBox(
      height: 204,
      width: double.infinity,
      child: Stack(fit: StackFit.expand, children: [
        Image.asset('assets/kantor-cikoko.jpg', fit: BoxFit.cover,
          alignment: const Alignment(.18, 0)),
        const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.centerLeft, end: Alignment.centerRight,
          colors: [Color(0xee0b2b4b), Color(0xcb102e4c), Color(0x5b0c2748)],
          stops: [0, .68, 1],
        ))),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: const Color(0x443ca8f5), borderRadius: BorderRadius.circular(7),
                border: Border.all(color: const Color(0x668bc1ee))),
              child: const Text('LAYANAN DIGITAL KELURAHAN',
                style: TextStyle(fontSize: 9.5, letterSpacing: .65, fontWeight: FontWeight.w700, color: Color(0xffe2f1ff)))),
            const SizedBox(height: 10),
            const Text('Kelurahan Cikoko',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: Colors.white, height: 1.12)),
            const SizedBox(height: 3),
            const Text('Kecamatan Pancoran · Jakarta Selatan',
              style: TextStyle(fontSize: 10.6, fontWeight: FontWeight.w600, color: Color(0xffe4eef8))),
            const SizedBox(height: 9),
            const Text('Melayani dengan hati, membangun bersama untuk Cikoko yang lebih maju, bersih dan sejahtera.',
              style: TextStyle(fontSize: 11.2, height: 1.4, color: Color(0xffe3edf8)), maxLines: 2,
              overflow: TextOverflow.ellipsis),
            const Spacer(),
            Row(children: [
              Flexible(child: SizedBox(height: 33, child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: homeBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  padding: const EdgeInsets.symmetric(horizontal: 10)),
                onPressed: onService,
                icon: const Icon(Icons.widgets_outlined, size: 14),
                label: const Text('Layanan Online', maxLines: 1, style: TextStyle(fontSize: 10.3, fontWeight: FontWeight.w700)),
              ))),
              const SizedBox(width: 7),
              Flexible(child: SizedBox(height: 33, child: OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0x99e7f0fb)),
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
                onPressed: onProfile,
                child: const Text('Profil Kelurahan', maxLines: 1, style: TextStyle(fontSize: 10.2, fontWeight: FontWeight.w700)),
              ))),
            ]),
          ]),
        ),
      ]),
    ),
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

/// Angka dari API saja. Pengguna publik tidak melihat angka milik orang lain.
class CikokoLetterCounters extends StatelessWidget {
  final Map<String,int>? counts;
  final bool guest;
  final VoidCallback onTap;
  const CikokoLetterCounters({super.key,required this.counts,required this.guest,required this.onTap});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment:CrossAxisAlignment.start, children: [
    Row(children: [
      const Expanded(child: Text('Status Pelayanan Surat',
        style: TextStyle(fontWeight: FontWeight.w800, color: homeNavy, fontSize: 13.5))),
      TextButton(onPressed:onTap, child:Text(guest?'Login →':'Riwayat →',
        style:const TextStyle(fontSize:11.2,fontWeight:FontWeight.w700))),
    ]),
    Row(children: [
      for (final pair in const [
        ('masuk','Surat Masuk',Color(0xff2467ba)),
        ('proses','Diproses',Color(0xffd58823)),
        ('selesai','Selesai',Color(0xff17875a)),
      ]) ...[
        Expanded(child: InkWell(onTap:onTap,borderRadius:BorderRadius.circular(11),child:Container(
          padding:const EdgeInsets.symmetric(horizontal:10,vertical:9),
          decoration:BoxDecoration(color:Colors.white,border:Border.all(color:homeBorder),
            borderRadius:BorderRadius.circular(11)),
          child:Row(children:[
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
              Text(guest||counts==null?'—':'${counts![pair.$1]??0}',style:TextStyle(
                color:pair.$3,fontSize:19,fontWeight:FontWeight.w900)),
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
