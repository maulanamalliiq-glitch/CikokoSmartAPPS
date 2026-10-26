import 'package:flutter/material.dart';
import 'api.dart';
import 'rt_rw_pdf_page.dart';
import 'rt_rw_signer_page.dart';

/// Alur verifikasi wilayah. Tidak menerbitkan TTE, stempel, atau PDF.
String cikokoAreaLabel(dynamic area) {
  final value = int.tryParse((area ?? '').toString());
  return value == null || value < 1 ? '-' : value.toString().padLeft(2, '0');
}
class RtRwLettersPage extends StatefulWidget {
  final CikokoApi api;
  const RtRwLettersPage({super.key, required this.api});
  @override
  State<RtRwLettersPage> createState() => _RtRwLettersState();
}

class _RtRwLettersState extends State<RtRwLettersPage> {
  final formKey = GlobalKey<FormState>();
  final form = <String,TextEditingController>{
    for(final k in const ['nama','tempat_lahir','tanggal_lahir','no_ktp_kk','agama',
      'kewarganegaraan','pendidikan','jenis_kelamin','status','pekerjaan',
      'alamat','maksud_keperluan']) k:TextEditingController(),
  };
  late Future<Map<String, dynamic>> requests;
  bool saving = false;

  String get role => '${widget.api.profile?['role'] ?? ''}';
  @override
  void initState() {
    super.initState();
    form['nama']!.text=''+(widget.api.profile?['name']??'').toString();
    form['alamat']!.text=''+(widget.api.profile?['address']??'').toString();
    form['no_ktp_kk']!.text=''+(widget.api.profile?['nik']??'').toString();
    form['kewarganegaraan']!.text='WNI';
    refresh();
  }
  @override
  void dispose() { for(final c in form.values){c.dispose();} super.dispose(); }
  Future<void> chooseBirthDate() async {
    final now=DateTime.now();
    final picked=await showDatePicker(
      context:context,initialDate:DateTime(now.year-20),
      firstDate:DateTime(1900),lastDate:now,helpText:'Tanggal Lahir');
    if(picked!=null) {
      form['tanggal_lahir']!.text=picked.year.toString().padLeft(4,'0')+'-'
        +picked.month.toString().padLeft(2,'0')+'-'
        +picked.day.toString().padLeft(2,'0');
    }
  }
  Widget formField(String key,String label,{int lines=1,bool date=false,TextInputType? keyboard})=>
    Padding(padding:const EdgeInsets.only(bottom:12),child:TextFormField(
      controller:form[key],readOnly:date,onTap:date?chooseBirthDate:null,
      keyboardType:keyboard??TextInputType.text,
      minLines:lines,maxLines:lines>1?4:1,
      decoration:InputDecoration(labelText:label,border:const OutlineInputBorder(),
        suffixIcon:date?const Icon(Icons.calendar_month_outlined):null),
      validator:(v) {
        if((v??'').trim().isEmpty)return label+' wajib diisi';
        if(key=='no_ktp_kk' && v!.trim().length<8)return 'Periksa No. KTP/KK';
        return null;
      },
    ));
  Widget genderField()=>Padding(padding:const EdgeInsets.only(bottom:12),
    child:DropdownButtonFormField<String>(
      initialValue:null,decoration:const InputDecoration(
        labelText:'Jenis Kelamin',border:OutlineInputBorder()),
      items:const [
        DropdownMenuItem(value:'Laki-laki',child:Text('Laki-laki')),
        DropdownMenuItem(value:'Perempuan',child:Text('Perempuan'))],
      validator:(v)=>v==null?'Jenis Kelamin wajib dipilih':null,
      onChanged:(v)=>form['jenis_kelamin']!.text=v??'',
    ));
  void refresh() { requests = widget.api.call('rt_rw_list'); }
  void flash(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
  String statusLabel(String status) {
    const labels = {
      'menunggu_rt': 'Menunggu Ketua RT',
      'menunggu_rw': 'Menunggu Ketua RW',
      'terverifikasi': 'Verifikasi RT dan RW selesai',
      'ditolak': 'Ditolak',
    };
    return labels[status] ?? status;
  }
  Future<void> submit() async {
    if (saving || !(formKey.currentState?.validate()??false)) return;
    setState(() => saving = true);
    try {
      await widget.api.call('rt_rw_submit',body:{
        'form':<String,String>{for(final f in form.entries)f.key:f.value.text.trim()},
      });
      if (mounted) setState(refresh);
      flash('Permohonan berhasil dikirim ke Ketua RT sesuai data profil.');
    } catch (e) { flash('$e'); }
    finally { if (mounted) setState(() => saving = false); }
  }

  Future<void> decide(Map<String, dynamic> letter) async {
    final reason = TextEditingController(), password = TextEditingController();
    String decision = 'approve';
    try {
      final approved = await showDialog<bool>(
        context: context,
        builder: (dialog) => StatefulBuilder(builder: (context, rebuild) => AlertDialog(
          title: const Text('Verifikasi Surat Pengantar'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text((letter['subject']??'').toString()),
            if(letter['form'] is Map)...[
              const SizedBox(height:12),
              for(final entry in const <String,String>{
                'nama':'Nama','tempat_lahir':'Tempat Lahir','tanggal_lahir':'Tanggal Lahir',
                'no_ktp_kk':'No. KTP/KK','agama':'Agama','kewarganegaraan':'Kewarganegaraan',
                'pendidikan':'Pendidikan','jenis_kelamin':'Jenis Kelamin','status':'Status',
                'pekerjaan':'Pekerjaan','alamat':'Alamat',
                'maksud_keperluan':'Maksud/Keperluan',
              }.entries)Padding(padding:const EdgeInsets.only(bottom:5),
                child:Text(entry.value+': '+(letter['form'][entry.key]??'').toString(),
                  style:const TextStyle(fontSize:12))),
            ],
            const SizedBox(height: 8),
            Text('RT '+cikokoAreaLabel(letter['rt'])+' / RW '+cikokoAreaLabel(letter['rw'])),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: decision,
              decoration: const InputDecoration(labelText: 'Keputusan'),
              items: const [
                DropdownMenuItem(value: 'approve', child: Text('Setujui tahap ini')),
                DropdownMenuItem(value: 'reject', child: Text('Tolak permohonan')),
              ],
              onChanged: (v) => rebuild(() => decision = v ?? 'approve'),
            ),
            const SizedBox(height: 10),
            TextField(controller: reason, maxLines: 2,
              decoration: InputDecoration(labelText: decision == 'reject' ? 'Alasan penolakan (wajib)' : 'Catatan (opsional)')),
            const SizedBox(height: 10),
            TextField(controller: password, obscureText: true,
              decoration: const InputDecoration(labelText: 'Konfirmasi password petugas')),
            const SizedBox(height: 8),
            const Text('Verifikasi ini bukan tanda tangan atau stempel elektronik.',
              style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Simpan Keputusan')),
          ],
        )),
      );
      if (approved != true) return;
      await widget.api.call('rt_rw_decide', body: {
        'id': letter['id'], 'decision': decision,
        'note': reason.text.trim(), 'current_password': password.text,
      });
      if (mounted) setState(refresh);
      flash('Verifikasi tersimpan.');
    } catch (e) { flash('$e'); }
    finally { reason.dispose(); password.dispose(); }
  }

  Future<void> reaffirmLegacy(Map<String,dynamic> letter) async {
    final password=TextEditingController();
    try{
      final submit=await showDialog<bool>(context:context,builder:(d)=>AlertDialog(
        title:const Text('Lengkapi TTD Surat Lama'),
        content:Column(mainAxisSize:MainAxisSize.min,children:[
          const Text('Berlaku hanya untuk surat yang telah Anda setujui sebelumnya. '
            'Unggah TTD/stempel Anda dahulu melalui menu petugas.'),
          const SizedBox(height:12),
          TextField(controller:password,obscureText:true,
            decoration:const InputDecoration(labelText:'Password akun')),
        ]),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('Batal')),
          FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('Sahkan Persetujuan Lama')),
        ],
      ));
      if(submit!=true)return;
      await widget.api.call('rt_rw_reaffirm',body:{
        'id':letter['id'],'decision':'approve','current_password':password.text,
      });
      if(mounted)setState(refresh);
      flash('TTD untuk persetujuan lama berhasil direkam.');
    }catch(e){flash('$e');}
    finally{password.dispose();}
  }

  @override
  Widget build(BuildContext context) {
    final isWarga = role == 'warga';
    final canVerify = role == 'rt' || role == 'rw';
    return ListView(padding: const EdgeInsets.all(14), children: [
      Text(isWarga ? 'Surat Pengantar RT/RW' : 'Permohonan Surat Wilayah',
        style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      const Text('Wilayah penerima mengikuti RT/RW yang tersimpan pada profil warga.'),
      const SizedBox(height: 12),
      if (canVerify) Padding(padding:const EdgeInsets.only(bottom:12),
        child:OutlinedButton.icon(
          onPressed:()=>Navigator.of(context).push(MaterialPageRoute<void>(
            builder:(_)=>RtRwSignerPage(api:widget.api))),
          icon:const Icon(Icons.draw_outlined),label:const Text('Atur TTD & Stempel Petugas'))),
      if (isWarga) Card(child: Padding(padding: const EdgeInsets.all(14), child:
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('RT '+cikokoAreaLabel(widget.api.profile?['rt'])+
               ' / RW '+cikokoAreaLabel(widget.api.profile?['rw']),
            style:const TextStyle(fontWeight:FontWeight.bold)),
          const SizedBox(height:10),
          Form(key:formKey,child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
            const Text('IDENTITAS PEMOHON',
              style:TextStyle(fontWeight:FontWeight.bold,fontSize:12)),
            const SizedBox(height:10),
            formField('nama','Nama'),
            formField('tempat_lahir','Tempat Lahir'),
            formField('tanggal_lahir','Tanggal Lahir',date:true),
            formField('no_ktp_kk','No. KTP/KK',keyboard:TextInputType.number),
            formField('agama','Agama'),
            formField('kewarganegaraan','Kewarganegaraan'),
            formField('pendidikan','Pendidikan'),
            genderField(),
            formField('status','Status'),
            formField('pekerjaan','Pekerjaan'),
            formField('alamat','Alamat',lines:2),
            const SizedBox(height:4),
            const Text('MAKSUD SURAT',
              style:TextStyle(fontWeight:FontWeight.bold,fontSize:12)),
            const SizedBox(height:10),
            formField('maksud_keperluan','Maksud/Keperluan',lines:2),
          ])),
          const SizedBox(height:12),
          FilledButton.icon(onPressed: saving ? null : submit, icon: const Icon(Icons.send_outlined),
            label: Text(saving ? 'Mengirim...' : 'Kirim ke Ketua RT Otomatis')),
          const SizedBox(height: 6),
          const Text('Jika RT/RW belum terisi, lengkapi Profil dengan konfirmasi password terlebih dahulu.',
            style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
        ]))),
      const SizedBox(height: 14),
      Text(isWarga ? 'Riwayat Surat Pengantar' : 'Daftar Surat yang Ditangani',
        style: Theme.of(context).textTheme.titleMedium),
      FutureBuilder<Map<String, dynamic>>(
        future: requests,
        builder: (context, result) {
          if (result.connectionState != ConnectionState.done) {
            return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
          }
          if (result.hasError) {
            return TextButton.icon(onPressed: () => setState(refresh),
              icon: const Icon(Icons.refresh), label: Text('Gagal memuat: ${result.error}. Coba lagi'));
          }
          final rows = List<Map<String, dynamic>>.from(
            (result.data?['items'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e as Map)));
          if (rows.isEmpty) return const ListTile(title: Text('Belum ada permohonan surat.'));
          return Column(children: [
            for (final letter in rows) Card(child: Padding(padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${letter['subject'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text((letter['applicant_name']??'').toString()+' • RT '+
                    cikokoAreaLabel(letter['rt'])+' / RW '+cikokoAreaLabel(letter['rw']),
                  style:const TextStyle(fontSize:12)),
                const SizedBox(height: 5),
                Text('${letter['notes'] ?? ''}', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                Text(statusLabel('${letter['status'] ?? ''}'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
                 if (canVerify && letter['requires_reaffirm']==true)
                   TextButton.icon(icon:const Icon(Icons.draw_outlined),
                     label:const Text('Lengkapi TTD Surat Lama'),
                     onPressed:()=>reaffirmLegacy(letter)),
                 if (letter['status']=='terverifikasi')
                   Wrap(spacing:8,children:[
                     TextButton.icon(icon:const Icon(Icons.picture_as_pdf_outlined),
                       label:const Text('Lihat PDF'),
                       onPressed:()=>Navigator.of(context).push(MaterialPageRoute<void>(
                         builder:(_)=>RtRwPdfPage(api:widget.api,
                           id:int.parse('${letter['id']}'))))),
                     OutlinedButton.icon(icon:const Icon(Icons.download_outlined),
                       label:const Text('Unduh PDF'),
                       onPressed:()=>Navigator.of(context).push(MaterialPageRoute<void>(
                         builder:(_)=>RtRwPdfPage(api:widget.api,
                           id:int.parse('${letter['id']}'))))),
                   ]),
                if (canVerify && ((role == 'rt' && letter['status'] == 'menunggu_rt') ||
                    (role == 'rw' && letter['status'] == 'menunggu_rw')))
                  Align(alignment: Alignment.centerRight, child: TextButton.icon(
                    onPressed: () => decide(letter),
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('Verifikasi'))),
              ]))),
          ]);
        },
      ),
      const SizedBox(height: 12),
      const Text('PDF tersedia setelah persetujuan RT dan RW dengan TTD/stempel dari petugas yang berwenang. '
        'Gambar TTD/cap tidak sama dengan TTE tersertifikasi; nomor REG adalah register sistem.',
        style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
    ]);
  }
}

/// Hak Admin Utama hanya menugaskan wilayah akun petugas, bukan memetakan warga.
class RtRwOfficerManager extends StatefulWidget {
  final CikokoApi api;
  const RtRwOfficerManager({super.key, required this.api});
  @override
  State<RtRwOfficerManager> createState() => _RtRwOfficerManagerState();
}
class _RtRwOfficerManagerState extends State<RtRwOfficerManager> {
  late Future<Map<String, dynamic>> officers;
  @override
  void initState() { super.initState(); reload(); }
  void reload() { officers = widget.api.call('rt_rw_officers'); }
  Future<void> edit(Map<String, dynamic> officer) async {
    final rt = TextEditingController(text: '${officer['rt'] ?? ''}');
    final rw = TextEditingController(text: '${officer['rw'] ?? ''}');
    try {
      final yes = await showDialog<bool>(context: context, builder: (d) => AlertDialog(
        title: Text('Wilayah ${officer['name'] ?? ''}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (officer['role'] == 'rt') TextField(controller: rt, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'RT')),
          const SizedBox(height: 10),
          TextField(controller: rw, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'RW')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Simpan')),
        ],
      ));
      if (yes != true) return;
      await widget.api.call('rt_rw_officer_assign', body: {
        'officer_id': officer['id'], 'rt': rt.text.trim(), 'rw': rw.text.trim(),
      });
      if (mounted) setState(reload);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wilayah Ketua RT/RW tersimpan.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally { rt.dispose(); rw.dispose(); }
  }
  @override Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: officers,
    builder: (context, response) {
      if (response.connectionState != ConnectionState.done)
        return const Center(child: CircularProgressIndicator());
      if (response.hasError)
        return Center(child: TextButton(onPressed: () => setState(reload),
          child: const Text('Muat ulang daftar Ketua RT/RW')));
      final rows = (response.data?['items'] as List<dynamic>? ?? [])
          .map((v) => Map<String, dynamic>.from(v as Map)).toList();
      return ListView(padding: const EdgeInsets.all(14), children: [
        Text('Wilayah Petugas RT/RW', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        const Text('Penugasan akun Ketua RT/RW resmi. Wilayah warga tetap dipilih saat mendaftar.'),
        const SizedBox(height: 12),
        if (rows.isEmpty) const ListTile(title: Text('Buat akun petugas berperan RT/RW terlebih dahulu.')),
        for (final officer in rows) Card(child: ListTile(
          title: Text('${officer['name'] ?? ''} (${(officer['role'] ?? '').toString().toUpperCase()})'),
          subtitle: Text('RT '+cikokoAreaLabel(officer['rt'])+' / RW '+cikokoAreaLabel(officer['rw'])+
            '${officer['active'] == true ? '' : ' • Tidak aktif'}'),
          trailing: const Icon(Icons.edit_location_alt_outlined),
          onTap: () => edit(officer),
        )),
      ]);
    },
  );
}
