import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'api.dart';

/// LPJ uses civic_* endpoints: do not submit LPJ through the legacy photo report API.
const lpjLabels = <String,String>{
  'lpj_rt': 'Laporan LPJ RT',
  'lpj_rw': 'Laporan LPJ RW',
  'lpj_lmk_a': 'LPJ LMK • Modul A',
  'lpj_lmk_b': 'LPJ LMK • Modul B',
};
const lpjDuties = <String,String>{
  'lpj_rt': 'bendahara_rt',
  'lpj_rw': 'bendahara_rw',
  'lpj_lmk_a': 'lmk',
  'lpj_lmk_b': 'lmk',
};

class LpjLmkMenu extends StatelessWidget {
  final void Function(String route) onOpen;
  const LpjLmkMenu({super.key,required this.onOpen});
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(16),children:[
    Text('Laporan LPJ LMK',style:Theme.of(context).textTheme.titleLarge),
    const SizedBox(height:8),
    const Text('Pilih format laporan sesuai dokumen pertanggungjawaban LMK. Setiap modul memiliki riwayat terpisah.'),
    const SizedBox(height:16),
    for(final mod in const [('Modul A','Laporan LPJ LMK A'),('Modul B','Laporan LPJ LMK B')])
      Card(child:ListTile(
        leading:const Icon(Icons.description_outlined,color:Color(0xff226fda)),
        title:Text('LPJ LMK '+mod.$1),
        subtitle:const Text('Isi keuangan, kirim, periksa status dan cetak LPJ'),
        trailing:const Icon(Icons.chevron_right),
        onTap:()=>onOpen(mod.$2),
      )),
  ]);
}

class _Expense {
 final activity=TextEditingController(),amount=TextEditingController(),notes=TextEditingController();
 void dispose(){activity.dispose();amount.dispose();notes.dispose();}
}

class LpjPage extends StatefulWidget {
 final CikokoApi api;
 final String kind;
 const LpjPage({super.key,required this.api,required this.kind});
 @override State<LpjPage> createState()=>_LpjPageState();
}
class _LpjPageState extends State<LpjPage> {
 Map<String,dynamic>? scope;
 List<Map<String,dynamic>> records=[];
 String? error;
 bool loading=true,creating=false,sending=false;
 final period=TextEditingController(),opening=TextEditingController(text:'0'),income=TextEditingController(text:'0');
 final expenses=<_Expense>[];
 @override void initState(){super.initState();final now=DateTime.now();period.text=now.year.toString()+'-'+now.month.toString().padLeft(2,'0');reload();}
 @override void dispose(){period.dispose();opening.dispose();income.dispose();for(final e in expenses){e.dispose();}super.dispose();}
 Future<void> reload()async{
  if(mounted)setState((){loading=true;error=null;});
  try{
   final catalog=await widget.api.call('civic_catalog');
   final listing=await widget.api.call('civic_list');
   final rawScope=catalog['scope'];
   final raw=List<dynamic>.from(listing['items']??[]);
   if(mounted)setState((){
    scope=rawScope is Map?Map<String,dynamic>.from(rawScope):null;
    records=raw.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).where((x)=>x['kind']==widget.kind).toList();
   });
  }catch(e){if(mounted)setState(()=>error=e.toString());}
  finally{if(mounted)setState(()=>loading=false);}
 }
 bool get canCreate=>scope?['duty']==lpjDuties[widget.kind];
 String get region {
  if(scope==null)return 'Jabatan wilayah belum terdaftar';
  final rw=(scope?['rw']??'-').toString();
  final rt=(scope?['rt']??'').toString();
  return (rt.isEmpty?'RW '+rw:'RT '+rt+' / RW '+rw);
 }
 void addExpense(){if(expenses.length>=60)return;setState(()=>expenses.add(_Expense()));}
 void removeExpense(int index){setState((){final e=expenses.removeAt(index);e.dispose();});}
 int? amountValue(String s)=>RegExp(r'^[0-9]{1,12}$').hasMatch(s.trim())?int.tryParse(s.trim()):null;
 Future<void> submit()async{
  final p=period.text.trim(),o=amountValue(opening.text),i=amountValue(income.text);
  if(!RegExp(r'^20[0-9]{2}-(0[1-9]|1[0-2])$').hasMatch(p)||o==null||i==null){
   showError('Isi periode YYYY-MM dan angka rupiah bulat tanpa tanda baca.');return;
  }
  final entries=<Map<String,dynamic>>[];
  var spent=0;
  for(final e in expenses){
   final a=amountValue(e.amount.text),label=e.activity.text.trim(),note=e.notes.text.trim();
   if(a==null||label.length<3||note.length>500){showError('Lengkapi nama kegiatan (min. 3 huruf) dan nominal pengeluaran.');return;}
   spent+=a;entries.add({'activity':label,'amount':a,'notes':note});
  }
  if(spent>o+i){showError('Jumlah pengeluaran melebihi saldo awal dan penerimaan.');return;}
  final confirm=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
   title:const Text('Kirim LPJ untuk diperiksa?'),
   content:const Text('Setelah dikirim, LPJ masuk ke alur persetujuan yang berwenang. Tidak otomatis disahkan.'),
   actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Batal')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Kirim LPJ'))],
  ));
  if(confirm!=true||!mounted)return;
  setState(()=>sending=true);
  try{
   await widget.api.call('civic_submit',body:{
    'kind':widget.kind,'period':p,
    'fields':{'opening':o,'income':i,'entries':entries},
   });
   if(!mounted)return;
   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('LPJ berhasil dikirim untuk persetujuan.')));
   setState(()=>creating=false);await reload();
  }catch(e){showError(e.toString());}
  finally{if(mounted)setState(()=>sending=false);}
 }
 void showError(String message){if(!mounted)return;ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(message),backgroundColor:Colors.red.shade700));}
 Widget moneyInput(String label,TextEditingController controller)=>Padding(padding:const EdgeInsets.only(bottom:12),child:TextField(
  controller:controller,keyboardType:TextInputType.number,
  inputFormatters:[FilteringTextInputFormatter.digitsOnly],
  decoration:InputDecoration(labelText:label,prefixText:'Rp ',border:const OutlineInputBorder()),
 ));
 Widget form()=>ListView(padding:const EdgeInsets.all(14),children:[
  Text(lpjLabels[widget.kind]??'LPJ',style:Theme.of(context).textTheme.titleLarge),
  const SizedBox(height:4),Text('Wilayah dari akun: '+region),
  const SizedBox(height:16),
  TextField(controller:period,decoration:const InputDecoration(labelText:'Periode (YYYY-MM)',border:OutlineInputBorder())),
  const SizedBox(height:12),
  moneyInput('Saldo awal bulan',opening),
  moneyInput('Penerimaan bulan ini',income),
  Row(children:[const Expanded(child:Text('Rincian pengeluaran',style:TextStyle(fontSize:16,fontWeight:FontWeight.bold))),
   TextButton.icon(onPressed:expenses.length>=60?null:addExpense,icon:const Icon(Icons.add),label:const Text('Tambah'))]),
  for(var n=0;n<expenses.length;n++)
   Card(key:ObjectKey(expenses[n]),child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[
    Row(children:[Expanded(child:Text('Pengeluaran '+(n+1).toString())),IconButton(onPressed:()=>removeExpense(n),icon:const Icon(Icons.delete_outline),tooltip:'Hapus pengeluaran')]),
    TextField(controller:expenses[n].activity,decoration:const InputDecoration(labelText:'Nama kegiatan / pengeluaran')),
    const SizedBox(height:10),moneyInput('Nominal',expenses[n].amount),
    TextField(controller:expenses[n].notes,maxLines:2,decoration:const InputDecoration(labelText:'Keterangan (opsional)')),
   ]))),
  const SizedBox(height:16),
  FilledButton.icon(onPressed:sending?null:submit,icon:const Icon(Icons.send_outlined),label:Text(sending?'Mengirim...':'Kirim LPJ')),
  const SizedBox(height:6),
  OutlinedButton(onPressed:sending?null:()=>setState(()=>creating=false),child:const Text('Kembali ke daftar')),
  const SizedBox(height:24),
 ]);
 @override Widget build(BuildContext context){
  if(loading)return const Center(child:CircularProgressIndicator());
  if(error!=null)return Center(child:Padding(padding:const EdgeInsets.all(22),child:Column(mainAxisSize:MainAxisSize.min,children:[
   const Icon(Icons.warning_amber_outlined,size:42,color:Colors.orange),
   const SizedBox(height:12),Text('Layanan LPJ belum tersambung:\n'+error!,textAlign:TextAlign.center),
   const SizedBox(height:15),FilledButton(onPressed:reload,child:const Text('Coba lagi')),
  ])));
  if(creating)return form();
  return RefreshIndicator(onRefresh:reload,child:ListView(padding:const EdgeInsets.all(14),children:[
   Text(lpjLabels[widget.kind]??'LPJ',style:Theme.of(context).textTheme.titleLarge),
   const SizedBox(height:8),Text(region),
   const SizedBox(height:12),
   if(canCreate)FilledButton.icon(onPressed:()=>setState(()=>creating=true),icon:const Icon(Icons.add_circle_outline),label:const Text('Buat LPJ baru'))
   else const Card(child:ListTile(leading:Icon(Icons.verified_user_outlined),title:Text('LPJ disusun oleh Bendahara'),subtitle:Text('Ketua RT/RW memeriksa dan menandatangani LPJ yang masuk sesuai wilayah.'))),
   const SizedBox(height:16),const Text('Daftar dan status LPJ',style:TextStyle(fontSize:16,fontWeight:FontWeight.w700)),
   if(records.isEmpty)const Card(child:ListTile(title:Text('Belum ada LPJ'),subtitle:Text('LPJ yang dikirim petugas berwenang akan tampil di sini.'))),
   for(final doc in records)
    Card(child:ListTile(
     leading:const Icon(Icons.receipt_long_outlined),
     title:Text('Periode '+(doc['period']??'-').toString()),
     subtitle:Text('Status: '+(doc['status']??'-').toString().replaceAll('_',' ')+' • '+(doc['owner_name']??'').toString()),
     trailing:const Icon(Icons.chevron_right),
     onTap:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>LpjDetailPage(api:widget.api,docId:int.tryParse(doc['id'].toString())??0,kind:widget.kind))).then((_)=>reload()),
    )),
   const SizedBox(height:32),
  ]));
 }
}

class LpjDetailPage extends StatefulWidget {
 final CikokoApi api;
 final int docId;
 final String kind;
 const LpjDetailPage({super.key,required this.api,required this.docId,required this.kind});
 @override State<LpjDetailPage> createState()=>_LpjDetailPageState();
}
class _LpjDetailPageState extends State<LpjDetailPage>{
 Map<String,dynamic>? doc,scope;
 bool loading=true,busy=false;
 String? error;
 @override void initState(){super.initState();reload();}
 Future<void> reload()async{
  setState(()=>loading=true);
  try{
   final a=await widget.api.call('civic_detail&id='+widget.docId.toString());
   final b=await widget.api.call('civic_catalog');
   if(mounted)setState((){
    doc=Map<String,dynamic>.from(a['item'] as Map);
    scope=b['scope'] is Map?Map<String,dynamic>.from(b['scope'] as Map):null;
    error=null;
   });
  }catch(e){if(mounted)setState(()=>error=e.toString());}
  finally{if(mounted)setState(()=>loading=false);}
 }
 String get expectedSigner=>switch((doc?['status']??'').toString()){
  'menunggu_ketua'=>widget.kind=='lpj_rt'?'rt':'rw',
  'menunggu_bendahara'=>widget.kind=='lpj_rt'?'bendahara_rt':'bendahara_rw',
  'menunggu_lmk'=>'lmk',
  _=>'',
 };
 Future<void> setupPin()async{
  final password=TextEditingController(),pin=TextEditingController(),confirmPin=TextEditingController();
  final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
   title:const Text('Atur PIN persetujuan LPJ'),
   content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
    const Text('PIN 6 angka disimpan sebagai hash di server. Konfirmasi password akun untuk mengaktifkan atau mengganti PIN.'),
    const SizedBox(height:12),
    TextField(controller:password,obscureText:true,decoration:const InputDecoration(labelText:'Password akun')),
    TextField(controller:pin,obscureText:true,keyboardType:TextInputType.number,maxLength:6,inputFormatters:[FilteringTextInputFormatter.digitsOnly],decoration:const InputDecoration(labelText:'PIN baru (6 angka)')),
    TextField(controller:confirmPin,obscureText:true,keyboardType:TextInputType.number,maxLength:6,inputFormatters:[FilteringTextInputFormatter.digitsOnly],decoration:const InputDecoration(labelText:'Ulangi PIN')),
   ])),
   actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Batal')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Simpan PIN'))],
  ));
  final pw=password.text,code=pin.text,confirm=confirmPin.text;
  password.dispose();pin.dispose();confirmPin.dispose();
  if(ok!=true||!mounted)return;
  if(pw.isEmpty||!RegExp(r'^[0-9]{6}$').hasMatch(code)||code!=confirm){showMessage('Password wajib diisi dan PIN 6 angka harus sama.');return;}
  setState(()=>busy=true);
  try{
   await widget.api.call('civic_pin_set',body:{'current_password':pw,'pin':code});
   showMessage('PIN LPJ berhasil disimpan. Gunakan saat persetujuan.');
  }catch(e){showMessage(e.toString());}
  finally{if(mounted)setState(()=>busy=false);}
 }
 Future<void> decide(String decision)async{
  final pin=TextEditingController(),reason=TextEditingController();
  final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
   title:Text(decision=='approve'?'Setujui LPJ':'Kembalikan LPJ'),
   content:Column(mainAxisSize:MainAxisSize.min,children:[
    Text(decision=='approve'?'Masukkan PIN 6 digit untuk menyetujui dokumen.':'Tuliskan alasan perbaikan (minimal 5 karakter).'),
    const SizedBox(height:10),
    if(decision=='approve')TextField(controller:pin,obscureText:true,keyboardType:TextInputType.number,maxLength:6,inputFormatters:[FilteringTextInputFormatter.digitsOnly],decoration:const InputDecoration(labelText:'PIN petugas')),
    if(decision!='approve')TextField(controller:reason,maxLines:3,decoration:const InputDecoration(labelText:'Alasan pengembalian')),
   ]),
   actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Batal')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Konfirmasi'))],
  ));
  if(ok!=true||!mounted){pin.dispose();reason.dispose();return;}
  final submittedPin=pin.text,submittedReason=reason.text.trim();
  pin.dispose();reason.dispose();
  if(decision=='approve'&& !RegExp(r'^[0-9]{6}$').hasMatch(submittedPin)){showMessage('PIN harus 6 digit');return;}
  if(decision=='return'&&submittedReason.length<5){showMessage('Alasan pengembalian minimal 5 karakter');return;}
  setState(()=>busy=true);
  try{
   await widget.api.call('civic_review',body:{'id':widget.docId,'decision':decision,'pin':submittedPin,'notes':submittedReason});
   if(mounted){showMessage('Status LPJ berhasil diperbarui');await reload();}
  }catch(e){showMessage(e.toString());}
  finally{if(mounted)setState(()=>busy=false);}
 }
 void showMessage(String message){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(message)));}
 Future<void> printPdf()async{
  setState(()=>busy=true);
  try{
   final response=await http.get(Uri.parse(CikokoApi.root+'?action=civic_pdf&id='+widget.docId.toString()),headers:widget.api.authHeaders()).timeout(const Duration(seconds:45));
   final data=response.bodyBytes;
   if(response.statusCode!=200||data.length<4||String.fromCharCodes(data.take(4))!='%PDF')throw ApiError('PDF belum tersedia atau belum dapat dicetak.');
   await Printing.layoutPdf(onLayout:(_)=>data,name:'Cikoko-LPJ-'+widget.docId.toString());
  }catch(e){showMessage(e.toString());}
  finally{if(mounted)setState(()=>busy=false);}
 }
 @override Widget build(BuildContext context){
  final payload=doc?['payload'] is Map?Map<String,dynamic>.from(doc!['payload'] as Map):<String,dynamic>{};
  final approvals=doc?['approvals'] is List?List<dynamic>.from(doc!['approvals'] as List):<dynamic>[];
  final canReview=expectedSigner.isNotEmpty&&scope?['duty']==expectedSigner;
  return Scaffold(appBar:AppBar(title:const Text('Detail LPJ')),body:loading?const Center(child:CircularProgressIndicator()):error!=null?Center(child:Text(error!)):ListView(padding:const EdgeInsets.all(16),children:[
   Text(lpjLabels[widget.kind]??'LPJ',style:Theme.of(context).textTheme.titleLarge),
   const SizedBox(height:8),
   Text('Periode: '+(doc?['period']??'-').toString()),
   Text('Wilayah: RT '+(doc?['rt']??'-').toString()+' / RW '+(doc?['rw']??'-').toString()),
   Text('Status: '+(doc?['status']??'-').toString().replaceAll('_',' ')),
   const Divider(height:28),
   Text('Saldo awal: Rp '+(payload['opening']??0).toString()),
   Text('Penerimaan: Rp '+(payload['income']??0).toString()),
   Text('Total pengeluaran: Rp '+(payload['total_expenses']??0).toString()),
   Text('Saldo akhir: Rp '+(payload['closing']??0).toString(),style:const TextStyle(fontWeight:FontWeight.bold)),
   const SizedBox(height:15),const Text('Rincian pengeluaran',style:TextStyle(fontWeight:FontWeight.bold)),
   for(final row in (payload['entries'] is List?(payload['entries'] as List):<dynamic>[]))
    if(row is Map)ListTile(title:Text((row['activity']??'').toString()),subtitle:Text((row['notes']??'').toString()),trailing:Text('Rp '+(row['amount']??0).toString())),
   const Divider(),
   const Text('Riwayat persetujuan',style:TextStyle(fontWeight:FontWeight.bold)),
   for(final a in approvals)if(a is Map)ListTile(leading:const Icon(Icons.verified_outlined),title:Text((a['duty']??'').toString()+' • '+(a['action']??'').toString()),subtitle:Text((a['created_at']??'').toString())),
   const SizedBox(height:14),
   if(canReview)OutlinedButton.icon(onPressed:busy?null:setupPin,icon:const Icon(Icons.lock_outline),label:const Text('Atur / Ganti PIN Persetujuan')),
   if(canReview)Row(children:[
    Expanded(child:FilledButton(onPressed:busy?null:()=>decide('approve'),child:const Text('Setujui dengan PIN'))),
    const SizedBox(width:8),Expanded(child:OutlinedButton(onPressed:busy?null:()=>decide('return'),child:const Text('Kembalikan'))),
   ]),
   const SizedBox(height:9),
   OutlinedButton.icon(onPressed:busy?null:printPdf,icon:const Icon(Icons.print_outlined),label:const Text('Lihat / Cetak PDF')),
   const SizedBox(height:26),
  ]));
 }
}
