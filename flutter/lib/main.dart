import 'profile_editor.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';
import 'push.dart';
import 'role_catalog.dart';
import 'structured_drawer.dart';
import 'integrated_services.dart';
import 'waris_requirements.dart';
import 'admin_accounts.dart';
import 'mobile_editor.dart';
import 'permission_editor.dart';
import 'document_detail.dart';
import 'surat_identifier.dart';
import 'home_widgets.dart';
import 'public_letters.dart';
import 'v211_features.dart';
import 'rt_rw_letters.dart';
import 'rt_rw_signer_page.dart';
import 'lpj_pages.dart';

const navy=Color(0xff10375f), blue=Color(0xff226fda), pale=Color(0xfff3f7fc);
const sky=Color(0xffdceeff), ink=Color(0xff18334f);
final api=CikokoApi();
void main(){WidgetsFlutterBinding.ensureInitialized();runApp(const CikokoApp());}
class CikokoApp extends StatelessWidget {
 const CikokoApp({super.key});
 @override Widget build(BuildContext c)=>MaterialApp(title:'Cikoko',debugShowCheckedModeBanner:false,
 builder:(ctx,child)=>Stack(children:[
   if(child!=null)child,
   ValueListenableBuilder<double?>(valueListenable:CikokoRequestProgress.value,
     builder:(context,value,_)=>value==null?const SizedBox.shrink():Align(
       alignment:Alignment.topCenter,
       child:Padding(
         padding:EdgeInsets.fromLTRB(18,MediaQuery.paddingOf(context).top+6,18,0),
         child:Material(elevation:5,borderRadius:BorderRadius.circular(12),
         color:Colors.white,child:Padding(padding:const EdgeInsets.symmetric(horizontal:13,vertical:10),
           child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
             Row(children:[
               Icon(value==1?Icons.check_circle:Icons.sync,
                 color:value==1?Colors.green:blue,size:17),
               const SizedBox(width:8),
               Expanded(child:Text(value==1?'Proses berhasil diselesaikan':value>0?'Sedang mengirim data':'Permintaan sedang diproses',
                 style:const TextStyle(fontSize:12,fontWeight:FontWeight.w600))),
               if(value>0)Text('${(100*value).round()}%',style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700)),
             ]),
             const SizedBox(height:7),
             LinearProgressIndicator(value:value>0?value:null,minHeight:4,
                 borderRadius:BorderRadius.circular(5)),
           ]))))),
     ),
 ]),theme:ThemeData(useMaterial3:true,scaffoldBackgroundColor:pale,colorScheme:ColorScheme.fromSeed(seedColor:blue),appBarTheme:const AppBarTheme(backgroundColor:Colors.white,foregroundColor:navy),inputDecorationTheme:InputDecorationTheme(isDense:true,filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(12))),cardTheme:CardThemeData(color:Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))),textTheme:const TextTheme(titleLarge:TextStyle(fontSize:20,fontWeight:FontWeight.w700,color:navy),titleMedium:TextStyle(fontSize:15,fontWeight:FontWeight.w700,color:navy),bodyMedium:TextStyle(fontSize:13.5)) ),home:const Entry());
}
class Entry extends StatefulWidget{const Entry({super.key});@override State<Entry> createState()=>_EntryState();}
class _EntryState extends State<Entry>{bool loading=true;@override void initState(){super.initState();api.restore().whenComplete((){if(mounted)setState(()=>loading=false);});}
 @override Widget build(BuildContext c)=>loading?const Scaffold(body:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Logo(size:110),SizedBox(height:18),Text('Kelurahan Cikoko',style:TextStyle(fontSize:19,color:navy,fontWeight:FontWeight.w800)),SizedBox(height:20),CircularProgressIndicator()]))):HomePage(key:ValueKey(api.token??'guest'),onAuthenticated:()=>setState((){}),onLogout:()=>setState((){}));}
class Logo extends StatelessWidget{final double size;const Logo({super.key,this.size=58});@override Widget build(BuildContext c)=>ClipOval(child:Image.asset('assets/logo.png',width:size,height:size,fit:BoxFit.cover));}
class LoginPage extends StatefulWidget{final VoidCallback onLogin;const LoginPage({super.key,required this.onLogin});@override State<LoginPage> createState()=>_LoginState();}
class _LoginState extends State<LoginPage>{final user=TextEditingController(),pass=TextEditingController();bool busy=false,signup=false;final fields=<String,TextEditingController>{};
 @override void dispose(){user.dispose();pass.dispose();for(final c in fields.values){c.dispose();}super.dispose();}
 TextEditingController ctrl(String key)=>fields.putIfAbsent(key,()=>TextEditingController());
 Future<void> submit() async{setState(()=>busy=true);try{if(signup){if(ctrl('password').text!=ctrl('confirm').text)throw ApiError('Konfirmasi password tidak sama');await api.register({for(final k in ['name','username','password','confirm','address','rt','rw','phone','email']) k:ctrl(k).text.trim()});if(mounted){setState(()=>signup=false);notify(context,'Akun warga aktif. Silakan login.');}}else{await api.login(user.text.trim(),pass.text);widget.onLogin();}}catch(e){if(mounted)notify(context,'$e',error:true);}finally{if(mounted)setState(()=>busy=false);}}
 @override
 Widget build(BuildContext context) {
   final title = signup ? 'Daftar Akun Warga' : 'Login Cikoko';
   return Scaffold(
     appBar: AppBar(title: const Text('Masuk ke Cikoko'), backgroundColor: pale),
     body: Center(
       child: SingleChildScrollView(
         padding: const EdgeInsets.all(18),
         child: ConstrainedBox(
           constraints: const BoxConstraints(maxWidth: 430),
           child: Card(
             elevation: 0,
             child: Padding(
               padding: const EdgeInsets.all(24),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   Center(child:Container(width:90,height:90,decoration:BoxDecoration(color:const Color(0xffe6f1ff),borderRadius:BorderRadius.circular(30)),alignment:Alignment.center,child:const Logo(size:64))),
                   const SizedBox(height: 16),
                   Text(title, style: Theme.of(context).textTheme.titleLarge),
                   const SizedBox(height: 6),
                   const Text('Layanan Digital Kelurahan Cikoko • Pancoran', style: TextStyle(color: Colors.blueGrey)),
                   const SizedBox(height: 22),
                   if (signup)
                     for (final entry in <String, String>{
                       'name': 'Nama lengkap',
                       'username': 'Username',
                       'password': 'Password',
                       'confirm': 'Ulangi password',
                       'address': 'Alamat lengkap',
                       'rt': 'RT (contoh: 02)',
                       'rw': 'RW (contoh: 05)',
                       'phone': 'Nomor telepon',
                       'email': 'Email',
                     }.entries)
                       Padding(
                         padding: const EdgeInsets.only(bottom: 12),
                         child: TextField(
                           controller: ctrl(entry.key),
                           obscureText: entry.key == 'password' || entry.key == 'confirm',
                           keyboardType: entry.key == 'email' ? TextInputType.emailAddress : (entry.key == 'phone' || entry.key == 'rt' || entry.key == 'rw') ? TextInputType.number : TextInputType.text,
                           decoration: InputDecoration(labelText: entry.value),
                         ),
                       )
                   else ...[
                     TextField(controller: user, decoration: const InputDecoration(labelText: 'Username'), textInputAction: TextInputAction.next),
                     const SizedBox(height: 12),
                     TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                   ],
                   const SizedBox(height: 22),
                   SizedBox(
                     width: double.infinity,
                     child: FilledButton(
                       onPressed: busy ? null : submit,
                       child: Padding(
                         padding: const EdgeInsets.all(12),
                         child: busy ? const SizedBox(height: 17, width: 17, child: CircularProgressIndicator(strokeWidth: 2)) : Text(signup ? 'Daftar Sekarang' : 'Masuk ke Akun'),
                       ),
                     ),
                   ),
                   const SizedBox(height: 14),
                   TextButton(onPressed: busy ? null : () => setState(() => signup = !signup), child: Text(signup ? 'Sudah punya akun? Login' : 'Daftar Akun Warga →')),
                   const Divider(),
                   const Text('Data pribadi diproses untuk pelayanan Kelurahan Cikoko.', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                 ],
               ),
             ),
           ),
         ),
       ),
     ),
   );
 }

}
void notify(BuildContext c,String text,{bool error=false}){ScaffoldMessenger.of(c).hideCurrentSnackBar();ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(error?cikokoFormalMessage(text):text),backgroundColor:error?Colors.red.shade700:navy));}
class HomePage extends StatefulWidget{final VoidCallback onLogout,onAuthenticated;const HomePage({super.key,required this.onLogout,required this.onAuthenticated});@override State<HomePage> createState()=>_HomeState();}
class _HomeState extends State<HomePage> {
  String section='Dashboard';
  int nav=2;
  List<dynamic> items=[],events=[];
  List<Map<String,dynamic>> activeServices=cikokoDefaultIntegratedServices();
  int get unreadCount=>events.where((e)=>e['is_read']!=true && '${e['is_read']??0}'!='1').length;
  Map<String,int>? letterCounts;
  Map<String,bool> capabilities={};
  bool loading=true,permissionsOk=false;
  Timer? timer;
  PushService? push;
  String get role => api.token==null?'guest':'${api.profile?['role']??'warga'}';
  String get roleLabel=>role=='guest'?'Portal Publik':(roleNames[role]??role.toUpperCase());
  bool get isStaff=>role!='warga'&&role!='guest';
  bool get isAdmin=>capabilities['reports:view']==true;
  List<RoleFeature> get modules=>role=='guest'?[roleFeatures['services']!,roleFeatures['waris']!,roleFeatures['waris_requirements']!,roleFeatures['jumantik']!,roleFeatures['news']!,roleFeatures['announcements']!,roleFeatures['gallery']!]:modulesForRole(role,capabilities);
  @override void initState(){super.initState();load();if(api.token!=null){push=PushService(api);push!.start(refresh,onOpen:(message){
      WidgetsBinding.instance.addPostFrameCallback((_){
        if(!mounted)return;
        final pushId=int.tryParse('${message.data['event_id']??''}')??0;
        if(pushId>0)api.call('event_read',body:{'id':pushId}).then((_)=>refresh()).catchError((_){});
        switchTo(destinationForPushCategory('${message.data['category']??''}',isStaff:isStaff));
      });
    });timer=Timer.periodic(const Duration(seconds:15),(_)=>refresh());}}
  @override void dispose(){timer?.cancel();push?.dispose();super.dispose();}
  Future<void> refresh() async {
    try {if(api.token==null)return;final v=await api.call('events');final incoming=List<dynamic>.from(v['events']??[]);await push?.onEvents(incoming);if(mounted)setState(()=>events=incoming);}
    catch(_) {}
  }
  Future<void> load() async {
    if(mounted)setState(()=>loading=true);
    try {
      if(api.token==null){if(mounted)setState(()=>permissionsOk=true);}else{
      final permissionResult=await api.call('permissions');
      final raw=Map<String,dynamic>.from(permissionResult['capabilities'] as Map);
      if(mounted)setState((){capabilities=raw.map((key,value)=>MapEntry(key,value==true));permissionsOk=true;});}
    } catch(e){if(mounted){setState(()=>permissionsOk=false);notify(context,'Hak akses belum tersambung: $e',error:true);}}
    try {
      await refresh();
      final result=await api.call('content');
      if(mounted)setState(()=>items=List<dynamic>.from(result['items']??[]));
      if(role=='warga'){
        try{
          final data=await api.call('integrated_services');
          final all=List<dynamic>.from(data['items']??[]);
          if(mounted)setState(()=>activeServices=all.map((e)=>Map<String,dynamic>.from(e as Map)).toList());
        }catch(_){/* Katalog bawaan tetap tersedia saat koneksi terputus. */}
      }
      // This is public letter service-wide data, not the user's private history.
      try {
        final summary=await api.call('public_letter_status');
        final raw=Map<String,dynamic>.from(summary['counts'] as Map);
        if(mounted)setState(()=>letterCounts={
          for(final key in ['masuk','proses','selesai'])
            key:(raw[key] as num?)?.toInt()??0,
        });
      }catch(_){if(mounted)setState(()=>letterCounts=null);}
    }catch(e){if(mounted)notify(context,'$e',error:true);}
    finally {if(mounted)setState(()=>loading=false);}
  }
  bool get guest=>api.token==null;
  bool _needsLogin(String route)=>route=='Surat Ahli Waris'||route=='Surat Pengantar RT/RW'||route.startsWith('Laporan ')||route=='Jumantik Warga'||route=='Riwayat'||route=='Verifikasi Laporan'||route=='Verifikasi Ahli Waris'||route=='Laporan Kegiatan Admin'||route=='Hubungi Kami';
  Future<void> openLogin() async {
    if(!mounted)return;
    final loggedIn=await Navigator.of(context).push<bool>(MaterialPageRoute<bool>(
      builder:(pageContext)=>LoginPage(onLogin:()=>Navigator.of(pageContext).pop(true)),
    ));
    if(loggedIn==true&&mounted){widget.onAuthenticated();}
  }
  void switchTo(String s) {
    if(s=='Persyaratan Ahli Waris'){
      showCikokoWarisRequirements(context,
        onApply:(){if(mounted)switchTo('Surat Ahli Waris');});
      return;
    }
    if(guest&&_needsLogin(s)){openLogin();return;}
    setState(() {
      section=s;
      if(s=='Dashboard'){nav=2;}
      else if(s=='Berita & Kegiatan'){nav=1;}
      else if(s=='Inovasi'){nav=3;}
      else if(s=='Profil'){nav=4;}
      else if(s=='Riwayat'||s=='Verifikasi Laporan'||s=='Verifikasi Ahli Waris'||s=='Laporan Kegiatan Admin'){nav=1;}
      else if(s=='Notifikasi'){nav=2;}
      else {nav=0;}
    });
  }
  void selectNav(int value){
    if(value==0){switchTo('Menu Cikoko');return;}
    if(value==1){switchTo('Berita & Kegiatan');return;}
    if(value==2){switchTo('Dashboard');return;}
    if(value==3){switchTo('Inovasi');return;}
    switchTo('Profil');
  }
  IconData iconFor(String s)=>switch(s){
    'Dashboard'=>Icons.home_outlined,'Menu Cikoko'=>Icons.grid_view_rounded,
    'Berita & Kegiatan'=>Icons.newspaper_outlined,'Pengumuman'=>Icons.campaign_outlined,
    'Layanan Online'=>Icons.widgets_outlined,'Galeri'=>Icons.photo_library_outlined,
    'Surat Ahli Waris'=>Icons.description_outlined,'Persyaratan Ahli Waris'=>Icons.fact_check_outlined,'Surat Pengantar RT/RW'=>Icons.markunread_mailbox_outlined,
    'Surat Wilayah'=>Icons.fact_check_outlined,'Wilayah Ketua RT/RW'=>Icons.location_city_outlined,'Laporan Jumantik'=>Icons.bug_report_outlined,
    'Jumantik Warga'=>Icons.bug_report_outlined,'Laporan Kegiatan'=>Icons.assignment_outlined,'Laporan Kegiatan Admin'=>Icons.assignment_turned_in_outlined,'Verifikasi Ahli Waris'=>Icons.verified_user_outlined,
    'Laporan LPJ RT'=>Icons.receipt_long_outlined,'Laporan LPJ RW'=>Icons.receipt_long_outlined,'Laporan LPJ LMK'=>Icons.receipt_long_outlined,
    'Laporan FKDM'=>Icons.shield_outlined,'Laporan LMK'=>Icons.groups_outlined,
    'Laporan Posyandu'=>Icons.medical_services_outlined,'Laporan Dasawisma'=>Icons.family_restroom_outlined,
    'Laporan PPSU'=>Icons.cleaning_services_outlined,'Laporan Kerja Bakti'=>Icons.volunteer_activism_outlined,
    'Tambah Berita'=>Icons.post_add_outlined,'Tambah Pengumuman'=>Icons.add_alert_outlined,
    'Tambah Arsip Ahli Waris'=>Icons.create_new_folder_outlined,'Arsip Ahli Waris'=>Icons.folder_copy_outlined,
    'Hak Akses Role'=>Icons.admin_panel_settings_outlined,'Kelola Akun Petugas'=>Icons.manage_accounts_outlined,'Manajemen Bendahara RT/RW'=>Icons.account_balance_wallet_outlined,'Riwayat'=>Icons.history,
    'Pesan Masuk'=>Icons.forum_outlined,'Hubungi Kami'=>Icons.chat_bubble_outline,
    'Notifikasi'=>Icons.notifications_none,'Inovasi'=>Icons.auto_awesome_outlined,'Profil'=>Icons.person_outline,
    _=>Icons.category_outlined};
  Future<void> confirmExit() async {
    final leave=await showDialog<bool>(context:context,builder:(dialog)=>AlertDialog(
      title:const Text('Konfirmasi Keluar'),
      content:const Text('Apakah Anda ingin keluar dari aplikasi Cikoko?'),
      actions:[TextButton(onPressed:()=>Navigator.pop(dialog,false),child:const Text('Tidak')),
        FilledButton(onPressed:()=>Navigator.pop(dialog,true),child:const Text('Ya'))],
    ));
    if(leave==true&&mounted){SystemNavigator.pop();}
  }
  @override Widget build(BuildContext c)=>PopScope(canPop:false,onPopInvokedWithResult:(didPop,result){if(!didPop)confirmExit();},child:Scaffold(
    appBar:AppBar(
      title:Row(children:[const Logo(size:31),const SizedBox(width:9),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Kelurahan Cikoko',maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:16.5,fontWeight:FontWeight.w800,color:navy)),Text(roleLabel,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10.5,color:Colors.blueGrey))]))]),
      actions:[IconButton(tooltip:'Notifikasi',onPressed:()=>switchTo('Notifikasi'),icon:Badge(isLabelVisible:unreadCount>0,label:Text('$unreadCount'),child:const Icon(Icons.notifications_none))),IconButton(tooltip:'Muat ulang',onPressed:load,icon:const Icon(Icons.refresh))],
    ),
    drawer:Drawer(child:CikokoStructuredDrawer(
      avatar:const Logo(size:52),
      accountName:'${api.profile?['name']??'Warga Cikoko'}',
      roleLabel:roleLabel,
      guest:guest,
      allowedFeatures:modules,
      currentRoute:section,
      iconFor:iconFor,
      onClose:()=>Navigator.pop(context),
      onNavigate:(route){Navigator.pop(context);switchTo(route);},
      onLogin:(){Navigator.pop(context);openLogin();},
      onLogout:()async{
        Navigator.pop(context);
        await api.logout();
        widget.onLogout();
      },
    )),
    body:loading?const Center(child:CircularProgressIndicator()):_page(),
    bottomNavigationBar:NavigationBar(height:67,selectedIndex:nav,labelBehavior:NavigationDestinationLabelBehavior.alwaysShow,onDestinationSelected:selectNav,destinations:[
      const NavigationDestination(icon:Icon(Icons.grid_view_outlined),selectedIcon:Icon(Icons.grid_view_rounded),label:'Menu'),
      const NavigationDestination(icon:Icon(Icons.newspaper_outlined),selectedIcon:Icon(Icons.newspaper),label:'Berita'),
      const NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'Beranda'),
      const NavigationDestination(icon:Icon(Icons.auto_awesome_outlined),selectedIcon:Icon(Icons.auto_awesome),label:'Inovasi'),
      const NavigationDestination(icon:Icon(Icons.person_outline),selectedIcon:Icon(Icons.person),label:'Profil'),
    ]),
    floatingActionButton:section=='Hubungi Kami'?null:FloatingActionButton.small(tooltip:'Hubungi Admin',onPressed:()=>switchTo('Hubungi Kami'),backgroundColor:blue,foregroundColor:Colors.white,child:const Icon(Icons.chat_bubble_outline)),
  ));
  Widget _page(){switch(section){
    case 'Dashboard':return home();
    case 'Menu Cikoko':return menuPage();
    case 'Berita & Kegiatan':return feed('berita');
    case 'Pengumuman':return feed('pengumuman');
    case 'Layanan Online':return guest ? feed('layanan') : CikokoIntegratedServices(api:api);
     case 'Kelola Layanan Terpadu':return role=='admin' ? CikokoIntegratedServices(api:api,admin:true) : const Center(child:Text('Menu ini hanya tersedia untuk Admin Utama.'));
    case 'Galeri':return feed('galeri');
    case 'Surat Ahli Waris':return const WarisForm();
    case 'Surat Pengantar RT/RW':return RtRwLettersPage(api:api);
    case 'Surat Wilayah':return RtRwLettersPage(api:api);
    case 'TTD & Stempel':return RtRwSignerPage(api:api);
    case 'Wilayah Ketua RT/RW':return RtRwOfficerManager(api:api);
    case 'Laporan Jumantik':return const ReportForm(kind:'jumantik');
    case 'Laporan Kegiatan':return const ReportForm(kind:'kegiatan');
    case 'Laporan LPJ RT':return LpjPage(api:api,kind:'lpj_rt');
    case 'Laporan LPJ RW':return LpjPage(api:api,kind:'lpj_rw');
    case 'Laporan LPJ LMK':return LpjLmkMenu(onOpen:switchTo);
    case 'Laporan LPJ LMK A':return LpjPage(api:api,kind:'lpj_lmk_a');
    case 'Laporan LPJ LMK B':return LpjPage(api:api,kind:'lpj_lmk_b');
    case 'Laporan FKDM':return const ReportForm(kind:'fkdm');
    case 'Laporan LMK':return const ReportForm(kind:'lmk');
    case 'Laporan Posyandu':return const ReportForm(kind:'posyandu');
    case 'Laporan Dasawisma':return const ReportForm(kind:'pkk');
    case 'Laporan Kerja Bakti':return const ReportForm(kind:'kerja_bakti');
    case 'Laporan PPSU':return PpsuReportPage(api:api);
    case 'Riwayat':return const HistoryPage();
    case 'Hubungi Kami':return const ChatPage();
    case 'Pesan Masuk':return const AdminChatPage();
    case 'Notifikasi':return eventList();
    case 'Inovasi':return InnovationPage(api:api);
    case 'Profil':return guest?profilePage():CivicProfilePage(api:api);
    case 'Verifikasi Laporan':return const AdminReports();
    case 'Verifikasi Ahli Waris':return role=='admin' ? const AdminReports(onlyKind:'waris',allowWarisDate:true) : const Center(child:Text('Khusus Admin Utama.'));
    case 'Laporan Kegiatan Admin':return role=='admin' ? const AdminReports(onlyKind:'report') : const Center(child:Text('Khusus Admin Utama.'));
    case 'Tambah Berita':return MobileEditor(api:api,mode:'berita');
    case 'Tambah Pengumuman':return MobileEditor(api:api,mode:'pengumuman');
    case 'Tambah Arsip Ahli Waris':return ArchiveEditorPage(api:api);
    case 'Arsip Ahli Waris':return ArchiveList(api:api);
    case 'Hak Akses Role':return RolePermissionPage(api:api);
    case 'Kelola Akun Petugas':return AdminAccountsPage(api:api);
    case 'Manajemen Bendahara RT/RW':
      // UI tidak membuka menu sensitif untuk role lain; server tetap
      // mewajibkan autentikasi Admin Utama di setiap request.
      return role == 'admin' && capabilities['role:manage'] == true
          ? AdminAccountsPage(api:api, bendaharaOnly:true)
          : const Center(child:Text('Hanya Admin Utama yang dapat mengelola Bendahara.'));
    default: return featureUnavailable(section);
  }}
  Widget featureUnavailable(String name) => Center(child:Padding(padding:const EdgeInsets.all(22),child:Card(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.construction_outlined,size:44,color:blue),const SizedBox(height:16),Text(name,style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:10),const Text('Halaman ini tercantum dalam rancangan role, tetapi modul data dan API belum tersedia. Tidak ada perubahan data yang dilakukan.',textAlign:TextAlign.center),const SizedBox(height:18),FilledButton(onPressed:()=>switchTo('Dashboard'),child:const Text('Kembali ke Beranda'))])))));
  Widget menuPage()=>ListView(padding:const EdgeInsets.all(14),children:[
    Text('Menu $roleLabel',style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:6),
    const Text('Pilih layanan sesuai kewenangan akun.',style:TextStyle(color:Colors.blueGrey)),
    if(!permissionsOk)const Card(child:ListTile(leading:Icon(Icons.warning_amber_rounded,color:Colors.orange),title:Text('Izin server belum berhasil dimuat'),subtitle:Text('Menu khusus disembunyikan sampai koneksi pulih.'))),
    const SizedBox(height:12),for(final f in modules)Card(child:ListTile(onTap:()=>switchTo(f.route),leading:CircleAvatar(backgroundColor:sky,child:Icon(iconFor(f.route),color:blue)),title:Text(f.title,style:const TextStyle(fontWeight:FontWeight.w600,fontSize:13.5)),subtitle:Text(f.connected?f.description:'${f.description} • Modul belum terintegrasi',style:const TextStyle(fontSize:11.5)),trailing:const Icon(Icons.chevron_right))),
  ]);
  Future<void> showOfficeProfile() async {
    await showModalBottomSheet<void>(context:context,isScrollControlled:true,
      showDragHandle:true,builder:(sheetContext)=>SafeArea(child:Padding(
        padding:const EdgeInsets.fromLTRB(20,0,20,24),child:Column(mainAxisSize:MainAxisSize.min,
          crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('Profil Kelurahan Cikoko',style:TextStyle(fontSize:19,color:navy,fontWeight:FontWeight.w800)),
            const SizedBox(height:8),
            const Text('Kecamatan Pancoran, Kota Administrasi Jakarta Selatan. Pelayanan publik, informasi, dan pengajuan surat tersedia melalui Cikoko.'),
            const SizedBox(height:14),
            FilledButton.icon(onPressed:(){Navigator.pop(sheetContext);switchTo('Layanan Online');},
              icon:const Icon(Icons.widgets_outlined),label:const Text('Lihat Layanan')),
          ]))));
  }
  List<RoleFeature> get homeShortcuts {
    if(role=='warga'||guest){
      final wanted=['Layanan Online','Surat Pengantar RT/RW','Surat Ahli Waris','Laporan Jumantik','Riwayat','Berita & Kegiatan','Pengumuman'];
      return wanted.map((route)=>roleFeatures.values.firstWhere((f)=>f.route==route)).toList();
    }
    return modules.take(6).toList();
  }
  Widget home()=>ListView(padding:const EdgeInsets.fromLTRB(12,10,12,20),children:[
    CikokoOfficeHero(onService:()=>switchTo('Layanan Online'),onProfile:showOfficeProfile),
    if(guest)Padding(padding:const EdgeInsets.only(top:8),child:Material(
      color:const Color(0xffe9f1fa),borderRadius:BorderRadius.circular(11),
      child:ListTile(dense:true,contentPadding:const EdgeInsets.symmetric(horizontal:10),
        leading:const Icon(Icons.lock_open_outlined,color:blue,size:20),
        title:const Text('Silakan login untuk menikmati lebih banyak layanan.',style:TextStyle(fontSize:11.5,fontWeight:FontWeight.w700)),
        trailing:TextButton(onPressed:openLogin,child:const Text('Masuk',style:TextStyle(fontSize:11))),
      ),
    )),
    if(guest||role=='warga'||role=='admin')Padding(padding:const EdgeInsets.only(top:8),child:CikokoLetterCounters(
      counts:letterCounts,onStatusTap:(category)=>
          role=='admin' && category=='all'
            ? showPublicLetterPie(context,api)
            : showPublicLetterStatus(context,api,category:category))),
    Padding(padding:const EdgeInsets.only(top:12,bottom:7),child:Row(
      mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
        Text(role=='warga'||guest?'Layanan Masyarakat':'Menu Cepat',style:const TextStyle(color:navy,fontSize:14,fontWeight:FontWeight.w800)),
        TextButton(onPressed:()=>switchTo(role=='warga'?'Layanan Online':'Menu Cikoko'),child:const Text('Lihat Semua →',style:TextStyle(fontSize:11))),
      ])),
    if(role=='warga')
      LayoutBuilder(builder:(ctx,c)=>GridView.count(
        crossAxisCount:c.maxWidth>700?3:2,
        crossAxisSpacing:8,mainAxisSpacing:8,
        childAspectRatio:1.94,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
        children:[
          for(final item in activeServices)
            CikokoServiceTile(title:'${item['title']}',description:'${item['description']}',icon:Icons.account_balance_outlined,
              accent:const Color(0xff2868c9),onTap:()=>switchTo('Layanan Online')),
        ],
      ))
    else if(guest)
      LayoutBuilder(builder:(ctx,c)=>GridView.count(
        crossAxisCount:c.maxWidth>700?3:2,
        crossAxisSpacing:8,mainAxisSpacing:8,
        childAspectRatio:1.94,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
        children:[
          CikokoServiceTile(title:'Administrasi Kependudukan',description:'Informasi KTP dan KK',icon:Icons.badge_outlined,accent:const Color(0xff2868c9),onTap:()=>switchTo('Layanan Online')),
          CikokoServiceTile(title:'Surat Pengantar RT/RW',description:'Dikirim sesuai alamat warga',icon:Icons.description_outlined,accent:const Color(0xff15966d),onTap:()=>switchTo('Surat Pengantar RT/RW')),
          CikokoServiceTile(title:'Informasi Publik',description:'Berita dan kegiatan',icon:Icons.newspaper_outlined,accent:const Color(0xff6554cb),onTap:()=>switchTo('Berita & Kegiatan')),
          CikokoServiceTile(title:'Layanan Lainnya',description:'Jelajahi semua layanan',icon:Icons.apps_outlined,accent:const Color(0xff54738d),onTap:()=>switchTo('Menu Cikoko')),
        ],
      ))
        else LayoutBuilder(builder:(ctx,c)=>GridView.builder(
      shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
      gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:c.maxWidth>680?3:2,mainAxisSpacing:8,crossAxisSpacing:8,
        mainAxisExtent:80),
      itemCount:homeShortcuts.length,
      itemBuilder:(ctx,i){final feature=homeShortcuts[i];return CikokoQuickMenu(
        title:feature.title,icon:iconFor(feature.route),onTap:()=>switchTo(feature.route));},
    )),
    if(role=='warga'||guest)Padding(padding:const EdgeInsets.only(top:9),child:Wrap(spacing:7,runSpacing:2,children:[
      ActionChip(avatar:const Icon(Icons.description_outlined,size:16,color:blue),label:const Text('Ahli Waris',style:TextStyle(fontSize:11)),onPressed:()=>switchTo('Surat Ahli Waris')),
      ActionChip(avatar:const Icon(Icons.bug_report_outlined,size:16,color:blue),label:const Text('Jumantik',style:TextStyle(fontSize:11)),onPressed:()=>switchTo('Laporan Jumantik')),
      ActionChip(avatar:const Icon(Icons.history,size:16,color:blue),label:const Text('Riwayat',style:TextStyle(fontSize:11)),onPressed:()=>switchTo('Riwayat')),
    ])),
    Padding(padding:const EdgeInsets.only(top:17,bottom:8),child:Row(children:[
      const Expanded(child:Text('Berita & Informasi',style:TextStyle(color:navy,fontSize:14,fontWeight:FontWeight.w800))),
      TextButton(onPressed:()=>switchTo('Berita & Kegiatan'),child:const Text('Lihat Semua →',style:TextStyle(fontSize:11)))
    ])),
    for(final x in items.where((x)=>x['type']=='berita'||x['type']=='pengumuman').take(3))contentCard(Map<String,dynamic>.from(x)),
    if(items.isEmpty)const Card(child:ListTile(dense:true,title:Text('Belum ada berita atau pengumuman.'))),
    if(!guest&&events.isNotEmpty)...[
      const Padding(padding:EdgeInsets.only(top:12,bottom:7),child:Text('Aktivitas Terbaru',style:TextStyle(color:navy,fontSize:14,fontWeight:FontWeight.w800))),
      for(final e in events.take(2))Card(child:ListTile(dense:true,leading:const Icon(Icons.notifications_outlined,color:blue),
        title:Text('${e['title']??''}',maxLines:1),subtitle:Text('${e['created_at']??''}',style:const TextStyle(fontSize:10)))),
    ],
    if(!guest && (role=='ppsu'||isAdmin||role=='admin_kelurahan'))PpsuHighlights(api:api),
    const SizedBox(height:74),
  ]);
 Widget feed(String type)=>ListView(padding:const EdgeInsets.all(14),children:[for(final v in items.where((e)=>e['type']==type))contentCard(Map<String,dynamic>.from(v)),if(!items.any((e)=>e['type']==type))const Padding(padding:EdgeInsets.all(18),child:Text('Belum ada konten pada kategori ini.'))]);
 Widget contentCard(Map<String, dynamic> item) {
   final image = api.media('${item['image']??''}');
   final title = '${item['title']??''}';
   final description = '${item['body']??''}';
   Widget photo() => image.isEmpty ? const SizedBox.shrink() : Image.network(
     image, height: 150, width: double.infinity, fit: BoxFit.cover,
     errorBuilder: (c, e, stack) => const SizedBox.shrink(),
   );
   Future<void> detail() async {
     if(item['type']=='berita'){
       await Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>CivicNewsDetail(api:api,preview:item)));
     }else{
       await showModalBottomSheet<void>(context:context,isScrollControlled:true,showDragHandle:true,
         builder:(sheet)=>SafeArea(child:Padding(padding:const EdgeInsets.all(18),child:SingleChildScrollView(
         child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
           Text(title,style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:12),photo(),const SizedBox(height:12),Text(description)
         ])))));
     }
   }
   return Card(
     margin: const EdgeInsets.only(bottom:9),
     elevation:0,
     clipBehavior:Clip.antiAlias,
     shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(13),side:const BorderSide(color:Color(0xffe0e8f1))),
     child:InkWell(onTap:detail,child:Padding(
       padding:const EdgeInsets.all(9),
       child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
         ClipRRect(borderRadius:BorderRadius.circular(9),
           child:image.isEmpty?Container(width:104,height:91,color:const Color(0xffeaf2fc),child:const Icon(Icons.newspaper_outlined,color:blue,size:27)):
             Image.network(image,width:104,height:91,fit:BoxFit.cover,
               errorBuilder:(_,__,___)=>Container(width:104,height:91,color:const Color(0xffeaf2fc),child:const Icon(Icons.image_not_supported_outlined,color:blue)))),
         const SizedBox(width:11),
         Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
           Text('${item['type']??''}'.toUpperCase(),style:const TextStyle(fontSize:9.5,letterSpacing:.65,color:blue,fontWeight:FontWeight.w700)),
           const SizedBox(height:4),
           Text(title,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:13.5,height:1.23,fontWeight:FontWeight.w800,color:navy)),
           const SizedBox(height:5),
           Text(description,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10.8,height:1.22,color:Color(0xff647992))),
           const SizedBox(height:7),
           const Text('Baca selengkapnya →',style:TextStyle(fontSize:10.4,fontWeight:FontWeight.w700,color:blue)),
         ])),
       ]),
     )),
   );
 }

 Future<void> share(String link) async {final u=Uri.parse(link);await launchUrl(u,mode:LaunchMode.externalApplication);}
 Future<void> openNotification(Map<String,dynamic> event)async{
     final eventId=int.tryParse('${event['id']??''}')??0;
     if(eventId>0 && event['is_read']!=true && '${event['is_read']??0}'!='1'){
       try{
         await api.call('event_read',body:{'id':eventId});
         if(mounted)setState((){
           events=events.map((e)=>'${e['id']??''}'=='$eventId'?{...Map<String,dynamic>.from(e as Map),'is_read':1}:e).toList();
         });
       }catch(_){if(mounted)notify(context,'Belum berhasil menandai notifikasi sebagai dibaca.',error:true);}
     }
    final objectType='${event['object_type']??''}';
    final id=int.tryParse('${event['object_id']??''}')??0;
    if(id>0&&(objectType=='waris'||objectType=='report')){
      await showCikokoDocument(context,api,id:id,kind:objectType,onChanged:refresh);
      if(mounted)await refresh();return;
    }
    if(!mounted)return;
    final category='${event['category']??''}';
    if(category=='chat'){switchTo(isStaff?'Pesan Masuk':'Hubungi Kami');return;}
    if(category=='rt_rw_surat'||category=='rt_rw_status'){switchTo(isStaff?'Surat Wilayah':'Surat Pengantar RT/RW');return;}
    if(category=='surat'||category=='progres_surat'||category=='laporan_masuk'){
      switchTo(isStaff?'Verifikasi Laporan':'Riwayat');return;
    }
    await showDialog<void>(context:context,builder:(c)=>AlertDialog(
      title:Text('${event['title']??'Notifikasi'}'),content:Text('${event['message']??''}'),
      actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Tutup'))],
    ));
  }
  Widget eventList()=>guest?Center(child:Card(child:Padding(padding:const EdgeInsets.all(22),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.notifications_outlined,size:40,color:blue),const Text('Notifikasi surat dan laporan memerlukan login.'),const SizedBox(height:12),FilledButton(onPressed:openLogin,child:const Text('Login'))])))):ListView(padding:const EdgeInsets.all(12),children:[
    for(final e in events)Card(child:ListTile(
      leading:CircleAvatar(backgroundColor:const Color(0xffeaf3ff),child:Icon('${e['is_read']??0}'=='1'?Icons.notifications_none:Icons.notifications_active_outlined,color:blue)),
      title:Text('${e['title']??''}',style:TextStyle(fontWeight:'${e['is_read']??0}'=='1'?FontWeight.w400:FontWeight.w700,fontSize:13)),
      subtitle:Text('${e['message']??''}\n${e['created_at']??''}',maxLines:3,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11)),
      trailing:const Icon(Icons.chevron_right),onTap:()=>openNotification(Map<String,dynamic>.from(e)),
    )),if(events.isEmpty)const ListTile(title:Text('Belum ada notifikasi.'))]);
 Widget profilePage()=>guest?Center(child:Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.person_outline,size:42,color:blue),const Text('Silakan masuk untuk mengelola profil.'),FilledButton(onPressed:openLogin,child:const Text('Masuk'))])))):CikokoProfileEditor(api:api);
}
class Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final int lines;
  final TextInputType keyboard;
  final bool date;
  const Field(this.label,this.ctrl,{super.key,this.lines=1,
    this.keyboard=TextInputType.text,this.date=false});

  Future<void> chooseDate(BuildContext context) async {
    final today=DateTime.now();
    final parsed=DateTime.tryParse(ctrl.text);
    final initial=parsed!=null && !parsed.isAfter(today) && parsed.year>=1850
      ? parsed : DateTime(today.year-25);
    final picked=await showDatePicker(context:context,initialDate:initial,
      firstDate:DateTime(1850),lastDate:today,helpText:label);
    if(picked!=null)ctrl.text=picked.year.toString().padLeft(4,'0')+'-'
      +picked.month.toString().padLeft(2,'0')+'-'
      +picked.day.toString().padLeft(2,'0');
  }

  @override Widget build(BuildContext c)=>Padding(
    padding:const EdgeInsets.only(bottom:12),
    child:TextField(
      controller:ctrl,maxLines:lines,
      keyboardType:date?TextInputType.datetime:keyboard,
      readOnly:date,
      onTap:date?()=>chooseDate(c):null,
      inputFormatters:!date && keyboard==TextInputType.number
        ?[FilteringTextInputFormatter.digitsOnly]:null,
      decoration:InputDecoration(
        labelText:label,alignLabelWithHint:lines>1,
        suffixIcon:date?IconButton(
          icon:const Icon(Icons.calendar_month_outlined),
          tooltip:'Pilih tanggal',
          onPressed:()=>chooseDate(c),
        ):null,
      ),
    ),
  );
}
class PhotoInput extends StatefulWidget {
  final String label;
  final void Function(String path) onChanged;
  final String? currentPath;
  const PhotoInput({super.key,required this.label,required this.onChanged,this.currentPath});
  @override State<PhotoInput> createState()=>_PhotoState();
}
class _PhotoState extends State<PhotoInput> {
  String? selectedPath, selectedName;
  bool selecting=false;
  @override void initState(){
    super.initState();
    selectedPath=widget.currentPath;
  }
  @override void didUpdateWidget(PhotoInput oldWidget){
    super.didUpdateWidget(oldWidget);
    if(oldWidget.currentPath!=widget.currentPath){
      selectedPath=widget.currentPath;
    }
  }
  Future<void> pick(ImageSource source) async {
    if(selecting)return;
    setState(()=>selecting=true);
    try{
      final file=await ImagePicker().pickImage(source:source,
        maxWidth:1900,maxHeight:2400,imageQuality:82,requestFullMetadata:false);
      if(file==null)return;

      // Picker paths can be recycled or deleted after subsequent camera picks.
      // Always make a unique app-owned copy BEFORE returning to the form.
      final root=await getTemporaryDirectory();
      final folder=Directory(root.path+'/cikoko_waris_photos');
      if(!await folder.exists())await folder.create(recursive:true);
      final unique=DateTime.now().microsecondsSinceEpoch.toString()+'_'
        +Random.secure().nextInt(0x7fffffff).toRadixString(16);
      final lower=file.name.toLowerCase();
      var bytes=await File(file.path).readAsBytes();
      // Convert unsupported camera formats and large files to JPEG.
      if(bytes.length>1550000 ||
          !(lower.endsWith('.png')||lower.endsWith('.webp')||
            lower.endsWith('.jpg')||lower.endsWith('.jpeg'))){
        for(final quality in [80,68,55]){
          final compressed=await FlutterImageCompress.compressWithFile(
            file.path,quality:quality,format:CompressFormat.jpeg,keepExif:false);
          if(compressed==null)break;
          bytes=compressed;
          if(bytes.length<=1550000)break;
        }
      }
      final isJpeg=bytes.length>=3&&bytes[0]==0xff&&bytes[1]==0xd8;
      final isPng=bytes.length>=4&&bytes[0]==0x89&&bytes[1]==0x50;
      final isWebp=bytes.length>=12 &&
        String.fromCharCodes(bytes.sublist(8,12))=='WEBP';
      if(!isJpeg&&!isPng&&!isWebp)throw const FormatException(
        'Foto harus JPG, PNG atau WebP.');
      final savedExt=isJpeg?'.jpg':isPng?'.png':'.webp';
      final out=File(folder.path+'/'+unique+savedExt);
      await out.writeAsBytes(bytes,flush:true);
      if(!await out.exists()||await out.length()<100){
        throw const FileSystemException('Foto belum berhasil disimpan.');
      }
      if(!mounted)return;
      final previous=selectedPath;
      setState((){
        selectedPath=out.path;
        selectedName=source==ImageSource.camera
          ?'Foto Kamera - '+DateTime.now().day.toString()+'-'
            +DateTime.now().month.toString()+'-'+DateTime.now().year.toString()+savedExt
          :file.name;
      });
      widget.onChanged(out.path);
      // Do not remove other documents; only replace this field's old copy.
      if(previous!=null&&previous!=out.path) {
        final f=File(previous);
        if(await f.exists())await f.delete();
      }
    }catch(e){
      if(mounted)notify(context,'Foto '+widget.label+' tidak dapat disimpan: '+e.toString(),
        error:true);
    }finally{
      if(mounted)setState(()=>selecting=false);
    }
  }
  @override Widget build(BuildContext c)=>Card(
    child:Padding(padding:const EdgeInsets.all(10),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(widget.label,style:const TextStyle(fontWeight:FontWeight.w700,fontSize:12)),
      const SizedBox(height:8),
      Row(crossAxisAlignment:CrossAxisAlignment.center,children:[
        if(selectedPath!=null)...[
          ClipRRect(borderRadius:BorderRadius.circular(10),child:Image.file(File(selectedPath!),width:57,height:62,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const SizedBox(width:57,height:62,child:Icon(Icons.broken_image_outlined)))),
          const SizedBox(width:10),
        ],
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Wrap(spacing:6,runSpacing:5,children:[
            OutlinedButton.icon(onPressed:selecting?null:()=>pick(ImageSource.camera),icon:const Icon(Icons.camera_alt_outlined,size:16),label:const Text('Kamera',style:TextStyle(fontSize:12))),
            OutlinedButton.icon(onPressed:selecting?null:()=>pick(ImageSource.gallery),icon:const Icon(Icons.photo_library_outlined,size:16),label:const Text('Galeri',style:TextStyle(fontSize:12))),
          ]),
          Text(selectedName??(selectedPath==null?'Belum ada foto':'Foto sudah dipilih'),maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11,color:Colors.blueGrey)),
        ]))
      ]),
    ])));
}
class WarisForm extends StatefulWidget{const WarisForm({super.key});@override State<WarisForm> createState()=>_WarisState();}
class _WarisState extends State<WarisForm>{final inputs=<String,TextEditingController>{};final files=<String,List<String>>{};int children=0;bool sending=false;double progress=0;bool agree=false;String? savedReference;bool completed=false;
 TextEditingController v(String id)=>inputs.putIfAbsent(id,()=>TextEditingController());
 String? photoFor(String id)=>files[id]?.isNotEmpty==true?files[id]!.first:null;
 @override void dispose(){for(final x in inputs.values){x.dispose();}super.dispose();}
 static const names=<String,String>{'name':'Nama pemohon','nik':'NIK pemohon (16 digit)','phone':'Nomor HP','address':'Alamat lengkap','relation':'Hubungan dengan pewaris','deceased_name':'Nama almarhum / almarhumah','birthplace':'Tempat lahir pewaris','birthdate':'Tanggal lahir (YYYY-MM-DD)','marriage_date':'Tanggal menikah (YYYY-MM-DD)','deathdate':'Tanggal meninggal (YYYY-MM-DD)','marital_status':'Status perkawinan','heirs':'Daftar ahli waris'};
 static const requiredPhotos=<String,String>{'r1':'Surat pengantar RT/RW','r2':'Surat permohonan','r3':'Surat pernyataan keabsahan','r4_ktp':'KTP Ahli Waris','r4_kk':'KK Ahli Waris','r4_akta':'Akta Lahir Ahli Waris','r5':'Surat kematian','r6':'Surat nikah'};
 static const witnessPhotos=<String,String>{'saksi_1':'KTP Saksi Pertama','saksi_2':'KTP Saksi Kedua'};
 static const optionalPhotos=<String,String>{'r7':'Akta cerai (jika bercerai)','r8':'Surat kematian ahli waris (jika ada)'};
 static const childPhotos=<String,String>{'ktp':'KTP','kk':'KK','akta':'Akta Lahir'};
 Future<void> showIncomplete(List<String> problems)async{
   if(!mounted)return;
   await showDialog<void>(context:context,builder:(dialog)=>AlertDialog(
     title:const Text('Pengajuan Ahli Waris Belum Lengkap'),
     content:ConstrainedBox(constraints:const BoxConstraints(maxHeight:370),
       child:SingleChildScrollView(child:Column(
         mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,
         children:[
           const Text('Mohon lengkapi atau perbaiki bagian berikut sebelum mengirim:'),
           const SizedBox(height:12),
           for(var i=0;i<problems.length;i++)Padding(
             padding:const EdgeInsets.only(bottom:8),
             child:Text((i+1).toString()+'. '+problems[i],
               style:const TextStyle(fontSize:13))),
         ],
       ))),
     actions:[FilledButton(onPressed:()=>Navigator.pop(dialog),
       child:const Text('Perbaiki Isian'))],
   ));
 }
 bool validDate(String value){
   if(!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value))return false;
   final parts=value.split('-').map(int.tryParse).toList();
   if(parts.any((part)=>part==null))return false;
   final date=DateTime(parts[0]!,parts[1]!,parts[2]!);
   return date.year==parts[0]&&date.month==parts[1]&&date.day==parts[2] &&
     !date.isAfter(DateTime.now())&&date.year>=1850;
 }
 Future<void> uploadWitnessDocuments(String reference)async{
    final witnessFiles=<String,List<String>>{};
    for(final e in witnessPhotos.entries){
      final path=photoFor(e.key);
      if(path!=null)witnessFiles[e.key]=[path];
    }
    if(witnessFiles.length!=witnessPhotos.length)throw ApiError('Mohon lengkapi kedua foto KTP saksi.');
    await api.upload('waris_add_witnesses',{'reference':reference},witnessFiles,
      progress:(p){if(mounted)setState(()=>progress=p);});
  }
  Future<void> send()async{
    if(sending||completed)return;
    if(savedReference!=null){
      setState((){sending=true;progress=0;});
      try{
        await uploadWitnessDocuments(savedReference!);
        if(mounted){setState(()=>completed=true);notify(context,'KTP kedua saksi berhasil melengkapi pengajuan '+savedReference!);}
      }catch(_){
        await showIncomplete(['Pengajuan '+savedReference!+' sudah tersimpan. KTP saksi belum dapat ditambahkan. Coba lagi, atau lengkapi melalui Riwayat Pengajuan.']);
      }finally{if(mounted)setState(()=>sending=false);}
      return;
    }
   final missing=<String>[];
   for(final key in const ['name','nik','phone','address','relation',
       'deceased_name','heirs']){
     if(v(key).text.trim().isEmpty)missing.add('Isian '+(names[key]??key)+' masih kosong.');
   }
   final nik=v('nik').text.trim();
   if(nik.isNotEmpty&&!RegExp(r'^\d{16}$').hasMatch(nik)){
     missing.add('NIK pemohon harus tepat 16 digit angka.');
   }
   final phone=v('phone').text.trim();
   if(phone.isNotEmpty&&!RegExp(r'^\+?[0-9]{8,16}$').hasMatch(phone)){
     missing.add('Nomor HP harus 8–16 digit angka, boleh diawali tanda +.');
   }
   for(final key in const ['birthdate','marriage_date','deathdate']){
     final date=v(key).text.trim();
     if(date.isNotEmpty&&!validDate(date)){
       missing.add((names[key]??key)+' harus dipilih dari kalender dan tidak boleh melewati hari ini.');
     }
   }
   for(final entry in {...requiredPhotos,...witnessPhotos}.entries){
      final path=photoFor(entry.key);
     if(path==null)missing.add('Foto '+entry.value+' belum dipilih (Kamera atau Galeri).');
     else if(!await File(path).exists())missing.add('Foto '+entry.value+' tidak ditemukan; pilih ulang fotonya.');
   }
   for(var i=1;i<=children;i++){
     if(v('child_name_'+i.toString()).text.trim().isEmpty){
       missing.add('Nama anak ke-'+i.toString()+' belum diisi.');
     }
     for(final entry in childPhotos.entries){
       final key='child_'+i.toString()+'_'+entry.key;
       final path=photoFor(key);
       if(path==null)missing.add('Foto '+entry.value+' anak ke-'+i.toString()+' belum dipilih.');
       else if(!await File(path).exists())missing.add('Foto '+entry.value+' anak ke-'+i.toString()+' hilang; pilih ulang.');
     }
   }
   for(final entry in optionalPhotos.entries){
     final path=photoFor(entry.key);
     if(path!=null&&!await File(path).exists()){
       missing.add('Foto '+entry.value+' tidak ditemukan; pilih ulang atau kosongkan.');
     }
   }
   if(!agree)missing.add('Centang pernyataan kebenaran data dan foto dokumen.');
   if(missing.isNotEmpty){await showIncomplete(missing);return;}

   setState((){sending=true;progress=0;});
   try{
     // Reject an outdated cPanel before sending potentially sensitive documents.
     final capability=await api.call('waris_format');
     if(capability['upload_format']!='split_v1'){
        throw ApiError('Layanan Ahli Waris perlu diperbarui sebelum pengajuan dikirim.');
      }
      final witnessCapability=await api.call('waris_witness_capabilities');
      if(witnessCapability['supported']!=true)throw ApiError('Fitur dua KTP saksi belum tersedia. Hubungi pengelola layanan.');
     final count=requiredPhotos.length+children*childPhotos.length+
       optionalPhotos.keys.where((key)=>photoFor(key)!=null).length;
     final maxFiles=(capability['max_file_uploads'] as num?)?.toInt()??0;
     final staged=capability['staged_uploads']==true;
     final mainPhotos=<String,List<String>>{
        for(final e in files.entries)
          if(!witnessPhotos.containsKey(e.key))e.key:e.value,
      };
      final data=<String,String>{for(final e in inputs.entries)e.key:e.value.text.trim(),
       'declaration':'1','child_count':children.toString(),
       'document_format':'split_v1'};
     late final Map<String,dynamic> response;
     if(staged){
       // Shared hosting may limit each POST to 20 files. Send 8 per request.
       final random=Random.secure();
       final draftKey=List.generate(16,
         (_)=>random.nextInt(256).toRadixString(16).padLeft(2,'0')).join();
       final photos=<MapEntry<String,String>>[
         for(final entry in mainPhotos.entries)
            for(final path in entry.value)MapEntry(entry.key,path),
       ];
       const batchSize=8;
       final steps=(photos.length+batchSize-1)~/batchSize;
       for(var i=0;i<photos.length;i+=batchSize){
         final chunk=photos.skip(i).take(batchSize);
         final subset=<String,List<String>>{
           for(final photo in chunk)photo.key:[photo.value],
         };
         final batch=i~/batchSize;
         await api.upload('waris_stage',{'draft_key':draftKey},subset,
           progress:(value){
             if(mounted)setState(()=>progress=(batch+value)/steps*0.95);
           });
       }
       data['draft_key']=draftKey;
       response=await api.upload('waris',data,{},progress:(value){
         if(mounted)setState(()=>progress=0.95+0.05*value);
       });
     }else{
       if(maxFiles>0&&count>maxFiles){
         throw ApiError('Server hanya menerima '+maxFiles.toString()+
           ' foto per permintaan. Perbarui API cPanel agar mendukung unggah bertahap tanpa perubahan hosting.');
       }
       response=await api.upload('waris',data,mainPhotos,
         progress:(value){if(mounted)setState(()=>progress=value);});
     }
           savedReference='${response['reference']??''}'.trim();
      if(savedReference!.isEmpty)throw ApiError('Nomor pengajuan belum tersedia. Periksa Riwayat Pengajuan.');
      await uploadWitnessDocuments(savedReference!);
      if(mounted){setState(()=>completed=true);notify(context,'Permohonan dan KTP saksi berhasil disimpan. Nomor: '+savedReference!);}
   }catch(e){
     final raw=e.toString();
     final text=raw.contains('Endpoint tidak tersedia')||
        raw.contains('Persyaratan foto belum lengkap: r4')
       ?'Server cPanel masih menggunakan format dokumen Ahli Waris lama (r4). '
        'Formulir HP sudah terpisah, tetapi server perlu Patch Ahli Waris terbaru. '
        'Foto yang sudah dipilih tetap berada dalam formulir.'
       :raw;
     await showIncomplete([savedReference!=null
        ?'Pengajuan '+savedReference!+' sudah tersimpan. KTP saksi belum berhasil ditambahkan. Jangan mengirim pengajuan baru. Gunakan Coba Lengkapi KTP Saksi atau buka Riwayat.'
        :text]);
   }finally{if(mounted)setState(()=>sending=false);}
 }
 @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(12),children:[const Card(child:Padding(padding:EdgeInsets.all(16),child:Text('Permohonan Pencatatan Ahli Waris\nSemua data dan foto dokumen akan diperiksa petugas. Pastikan foto terbaca.',style:TextStyle(color:navy,fontWeight:FontWeight.w600)))),Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Identitas Pemohon dan Pewaris',style:Theme.of(c).textTheme.titleMedium),const SizedBox(height:14),for(final e in names.entries)Field(e.value,v(e.key),lines:e.key=='heirs'||e.key=='address'?3:1,date:const ['birthdate','marriage_date','deathdate'].contains(e.key),keyboard:e.key=='nik'?TextInputType.number:e.key=='phone'?TextInputType.phone:TextInputType.text)]))),const SizedBox(height:12),Text('Foto Persyaratan Wajib',style:Theme.of(c).textTheme.titleMedium),for(final e in requiredPhotos.entries)PhotoInput(key:ValueKey(e.key),label:e.value,currentPath:photoFor(e.key),onChanged:(f)=>setState(()=>files[e.key]=[f])),
const SizedBox(height:12),
Text('Dua Orang Saksi',style:Theme.of(c).textTheme.titleMedium),
for(final e in witnessPhotos.entries)PhotoInput(key:ValueKey(e.key),label:e.value,currentPath:photoFor(e.key),onChanged:(f)=>setState(()=>files[e.key]=[f])),
const SizedBox(height:12),Text('Dokumen Kondisional',style:Theme.of(c).textTheme.titleMedium),for(final e in optionalPhotos.entries)PhotoInput(key:ValueKey(e.key),label:e.value,currentPath:photoFor(e.key),onChanged:(f)=>setState(()=>files[e.key]=[f])),const SizedBox(height:14),Row(children:[Expanded(child:Text('Data Anak (maksimal 10)',style:Theme.of(c).textTheme.titleMedium)),OutlinedButton(onPressed:children>=10?null:()=>setState(()=>children++),child:const Text('+ Tambah Anak'))]),for(var i=1;i<=children;i++)Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[Field('Nama anak ke-$i',v('child_name_$i')),for(final e in childPhotos.entries)PhotoInput(key:ValueKey('child_${i}_${e.key}'),label:'${e.value} anak ke-$i',currentPath:photoFor('child_${i}_${e.key}'),onChanged:(f)=>setState(()=>files['child_${i}_${e.key}']=[f]))]))),CheckboxListTile(value:agree,onChanged:(v)=>setState(()=>agree=v??false),title:const Text('Saya menyatakan seluruh data dan foto dokumen sesuai keadaan sebenarnya.',style:TextStyle(fontSize:12))),if(sending)...[LinearProgressIndicator(value:progress),Padding(padding:const EdgeInsets.all(8),child:Text('Mengirim ${(progress*100).toStringAsFixed(0)}%'))],FilledButton.icon(onPressed:sending||completed?null:send,
 icon:Icon(completed?Icons.check_circle:savedReference!=null?Icons.cloud_upload_outlined:Icons.send),
 label:Padding(padding:const EdgeInsets.all(12),child:Text(completed?'Pengajuan dan KTP Saksi Tersimpan':savedReference!=null?'Coba Lengkapi KTP Saksi':'Kirim Permohonan Ahli Waris'))),const SizedBox(height:24)]);
}
class ReportForm extends StatefulWidget{final String kind;const ReportForm({super.key,required this.kind});@override State<ReportForm> createState()=>_ReportState();}
class _ReportState extends State<ReportForm>{final address=TextEditingController(),phone=TextEditingController(),notes=TextEditingController();String? photo;bool sending=false;double progress=0;
 @override void dispose(){address.dispose();phone.dispose();notes.dispose();super.dispose();}
 Future<void> send()async{if(address.text.trim().isEmpty||notes.text.trim().isEmpty||photo==null){notify(context,'Lengkapi alamat, keterangan dan foto',error:true);return;}setState(()=>sending=true);try{await api.upload('report',{'kind':widget.kind,'address':address.text,'phone':phone.text,'notes':notes.text},{'photo':[photo!]},progress:(p){if(mounted)setState(()=>progress=p);});if(mounted)notify(context,'Laporan berhasil dikirim');}catch(e){if(mounted)notify(context,'$e',error:true);}finally{if(mounted)setState(()=>sending=false);}}
 @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(14),children:[Field('Alamat / Lokasi',address),Field('Nomor telepon',phone),Field('Keterangan kegiatan / hasil pemantauan',notes,lines:5),PhotoInput(label:'Foto bukti kegiatan',onChanged:(f)=>photo=f),if(sending)...[LinearProgressIndicator(value:progress),Text('${(progress*100).round()}%')],FilledButton(onPressed:sending?null:send,child:const Text('Kirim Laporan'))]);
}
class HistoryPage extends StatefulWidget{const HistoryPage({super.key});@override State<HistoryPage> createState()=>_HistoryState();}
class _HistoryState extends State<HistoryPage>{Future<Map<String,dynamic>>? future;
 @override void initState(){super.initState();reload();}
 void reload(){setState((){future=api.call('history');});}
 @override Widget build(BuildContext c)=>FutureBuilder<Map<String,dynamic>>(future:future,builder:(c,s){
 if(s.hasError)return const Center(child:Padding(padding:EdgeInsets.all(18),child:Text('Riwayat pengajuan belum dapat ditampilkan. Silakan coba kembali.',textAlign:TextAlign.center)));
 if(!s.hasData)return const Center(child:CircularProgressIndicator());
 final rows=List<dynamic>.from(s.data!['items']??[]);
 return RefreshIndicator(onRefresh:()async{reload();try{await future;}catch(_){/* Ditampilkan oleh FutureBuilder. */}},child:ListView(padding:const EdgeInsets.all(12),children:[
  for(final r in rows)Card(child:ListTile(
    leading:const CircleAvatar(child:Icon(Icons.description_outlined)),
    title:Text('${r['title']??r['reference']??'Pengajuan'}',style:const TextStyle(fontSize:13,fontWeight:FontWeight.w700)),
    subtitle:Text('${r['reference']??''} • ${r['status']??''}\n${r['created_at']??''}',style:const TextStyle(fontSize:11)),
    trailing:const Icon(Icons.chevron_right),
    onTap:(){
      final row=Map<String,dynamic>.from(r);
      final id=cikokoPositiveId(row);
      final ref=cikokoWarisReference(row);
      if(id==null && ref==null){notify(context,'Nomor pengajuan tidak diterima dari server. Pastikan API V2525 aktif.',error:true);reload();return;}
      showCikokoDocument(context,api,id:id??0,reference:ref??'',
        kind:cikokoDocumentKind(row),onChanged:reload);
    },
  )),if(rows.isEmpty)const ListTile(title:Text('Belum ada riwayat pengajuan.'))]));});
}
class ChatPage extends StatefulWidget{const ChatPage({super.key});@override State<ChatPage> createState()=>_ChatState();}
class _ChatState extends State<ChatPage>{final ctrl=TextEditingController();List<dynamic> messages=[];bool busy=false;Timer?timer;@override void initState(){super.initState();refresh();timer=Timer.periodic(const Duration(seconds:15),(_)=>refresh());} @override void dispose(){timer?.cancel();ctrl.dispose();super.dispose();}
 Future<void> refresh()async{try{final d=await api.call('chat');if(mounted)setState(()=>messages=List<dynamic>.from(d['messages']??[]));}catch(_){}}
 Future<void> send()async{if(ctrl.text.trim().isEmpty)return;setState(()=>busy=true);try{await api.call('chat_send',body:{'message':ctrl.text.trim()});ctrl.clear();await refresh();}catch(e){if(mounted)notify(context,'$e',error:true);}finally{if(mounted)setState(()=>busy=false);}}
 @override Widget build(BuildContext c)=>Column(children:[Container(width:double.infinity,padding:const EdgeInsets.all(12),color:Colors.white,child:const Text('Hubungi Admin • Pesan dijawab pada jam kerja Sen–Kam 07.30–16.00, Jum 07.30–16.30 WIB.',style:TextStyle(fontSize:12))),Expanded(child:ListView(padding:const EdgeInsets.all(12),children:[for(final m in messages)Align(alignment:m['sender']=='admin'?Alignment.centerLeft:Alignment.centerRight,child:Card(color:m['sender']=='admin'?Colors.white:const Color(0xffdef0ff),child:Padding(padding:const EdgeInsets.all(12),child:Text('${m['message']}'))))])),SafeArea(child:Padding(padding:const EdgeInsets.all(10),child:Row(children:[Expanded(child:TextField(controller:ctrl,maxLines:3,minLines:1,decoration:const InputDecoration(hintText:'Tulis pesan ke admin...'))),IconButton(onPressed:busy?null:send,icon:const Icon(Icons.send,color:blue))])))]);
}
class AdminChatPage extends StatefulWidget{const AdminChatPage({super.key});@override State<AdminChatPage> createState()=>_AdminChatState();}
class _AdminChatState extends State<AdminChatPage>{List<dynamic> threads=[];@override void initState(){super.initState();load();}
 Future<void> load()async{try{final d=await api.call('chat_threads');if(mounted)setState(()=>threads=List<dynamic>.from(d['threads']??[]));}catch(e){if(mounted)notify(context,'$e',error:true);}}
 Future<void> reply(Map<String,dynamic> thread)async{
   final sent=await showModalBottomSheet<bool>(context:context,isScrollControlled:true,useSafeArea:true,
     builder:(_)=>AdminReplySheet(thread:thread));
   if(sent==true&&mounted)await load();
 }
 @override Widget build(BuildContext c)=>ListView(children:[for(final t in threads)ListTile(leading:const CircleAvatar(child:Icon(Icons.person_outline)),title:Text('${t['name']}'),subtitle:Text('${t['message']}',maxLines:2,overflow:TextOverflow.ellipsis),trailing:const Icon(Icons.reply),onTap:()=>reply(Map<String,dynamic>.from(t))),if(threads.isEmpty)const ListTile(title:Text('Belum ada pesan masuk.'))]);
}
class AdminReplySheet extends StatefulWidget{
 final Map<String,dynamic> thread;
 const AdminReplySheet({super.key,required this.thread});
 @override State<AdminReplySheet> createState()=>_AdminReplySheetState();
}
class _AdminReplySheetState extends State<AdminReplySheet>{
 final TextEditingController message=TextEditingController();bool sending=false;
 @override void dispose(){message.dispose();super.dispose();}
 Future<void> submit()async{
   final text=message.text.trim();if(text.isEmpty||sending)return;
   setState(()=>sending=true);
   try{
     await api.call('chat_reply',body:{'user_id':'${widget.thread['user_id']}','message':text});
     if(mounted)Navigator.of(context).pop(true);
   }catch(e){if(mounted)notify(context,'Balasan gagal: $e',error:true);}
   finally{if(mounted)setState(()=>sending=false);}
 }
 @override Widget build(BuildContext context)=>Padding(
   padding:EdgeInsets.only(left:18,right:18,top:20,bottom:MediaQuery.viewInsetsOf(context).bottom+18),
   child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
     Text('Balas pesan ${widget.thread['name']}',style:Theme.of(context).textTheme.titleMedium),
     const SizedBox(height:12),
     TextField(controller:message,minLines:2,maxLines:5,autofocus:true,decoration:const InputDecoration(hintText:'Tulis balasan untuk warga...')),
     const SizedBox(height:12),
     SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:sending?null:submit,icon:const Icon(Icons.send),label:Text(sending?'Mengirim...':'Kirim Balasan'))),
   ]));
}
class AdminReports extends StatefulWidget{
 final String? onlyKind;
 final bool allowWarisDate;
 const AdminReports({super.key,this.onlyKind,this.allowWarisDate=false});
 @override State<AdminReports> createState()=>_AdminReportsState();
}
class _AdminReportsState extends State<AdminReports>{List<dynamic> rows=[];bool busy=false;
 @override void initState(){super.initState();load();}
 Future<void> load()async{try{
 final d=await api.call('admin_reports');
 final list=List<dynamic>.from(d['items']??[]);
 if(mounted)setState(()=>rows=list.where((item)=>widget.onlyKind==null||
  cikokoDocumentKind(Map<String,dynamic>.from(item as Map))==widget.onlyKind).toList());
 }catch(e){if(mounted)notify(context,'$e',error:true);}}
 Future<void> update(Map<String,dynamic> r,String status)async{
  final kind=cikokoDocumentKind(r);
  final id=cikokoPositiveId(r);
  final ref=cikokoWarisReference(r);
  if(id==null && ref==null){
    if(mounted)notify(context,'Server belum mengirim ID pengajuan. Pastikan API V2525 aktif lalu muat ulang.',error:true);
    await load();return;
  }
  try{
    await api.call('status',body:{
      'kind':kind,'id':id??ref,'status':status,
      if(ref!=null)'reference_no':ref,
    });
    await load();
  }catch(e){if(mounted)notify(context,'$e',error:true);}
 }

 Future<void> editWarisDate(Map<String,dynamic> row)async{
  if(!widget.allowWarisDate||api.profile?['role']!='admin'||cikokoDocumentKind(row)!='waris')return;
  final id=cikokoPositiveId(row);
  if(id==null){notify(context,'ID Ahli Waris tidak tersedia.',error:true);return;}
  final raw=(row['created_at']??'').toString();
  final oldDate=raw.length>=10?raw.substring(0,10):'';
  final today=DateTime.now();
  final old=DateTime.tryParse(oldDate)??today;
  final selected=await showDatePicker(
   context:context,firstDate:DateTime(2000),
   lastDate:DateTime(today.year,today.month,today.day),
   initialDate:old.year<2000?DateTime(2000):old.isAfter(today)?today:old,
   helpText:'Tanggal Pengajuan Ahli Waris');
  if(selected==null||!mounted)return;
  final date=selected.year.toString().padLeft(4,'0')+'-'+
   selected.month.toString().padLeft(2,'0')+'-'+selected.day.toString().padLeft(2,'0');
  if(date==oldDate){notify(context,'Tanggal tidak berubah.');return;}
  final yes=await showDialog<bool>(context:context,builder:(dialog)=>AlertDialog(
   title:const Text('Ubah Tanggal Pengajuan'),
   content:Text('Nomor: '+(row['reference']??'-').toString()+
    '\nTanggal sebelumnya: '+oldDate+'\nTanggal baru: '+date+
    '\n\nPerubahan hanya untuk tanggal pengajuan surat ini. Tanggal foto/lampiran dan status tidak diubah. Riwayat akan dicatat.'),
   actions:[
    TextButton(onPressed:()=>Navigator.pop(dialog,false),child:const Text('Batal')),
    FilledButton(onPressed:()=>Navigator.pop(dialog,true),child:const Text('Simpan')),
   ],
  ));
  if(yes!=true||!mounted)return;
  setState(()=>busy=true);
  try{
   final result=await api.call('admin_waris_date',body:{'id':id,'date':date});
   await load();
   if(mounted)notify(context,(result['message']??'Tanggal diperbarui').toString());
  }catch(e){if(mounted)notify(context,'Gagal mengubah tanggal: $e',error:true);}
  finally{if(mounted)setState(()=>busy=false);}
 }
 @override Widget build(BuildContext c)=>RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(12),children:[
  Padding(padding:const EdgeInsets.all(8),child:Text(
   widget.onlyKind=='waris'?'Verifikasi Ahli Waris':
   widget.onlyKind=='report'?'Laporan Kegiatan':'Verifikasi Laporan',
   style:const TextStyle(fontSize:20,color:navy,fontWeight:FontWeight.bold))),
  if(widget.onlyKind=='waris')const Padding(
   padding:EdgeInsets.symmetric(horizontal:8,vertical:4),
   child:Text('Khusus Ahli Waris. Admin Utama dapat mengatur progres dan tanggal pengajuan.')),
  if(widget.onlyKind=='report')const Padding(
   padding:EdgeInsets.symmetric(horizontal:8,vertical:4),
   child:Text('Laporan kegiatan selain Ahli Waris.')),
  const Padding(padding:EdgeInsets.all(8),child:Text('Ketuk surat untuk membuka data, progres, dan meminta kelengkapan dokumen.',style:TextStyle(fontSize:12,color:Colors.blueGrey))),
  for(final r in rows)Card(child:ListTile(
    leading:const Icon(Icons.fact_check_outlined,color:blue),
    title:Text('${r['title']??r['reference']??'Pengajuan'}',style:const TextStyle(fontWeight:FontWeight.w700,fontSize:13)),
    subtitle:Text('${r['status']} • ${r['name']??''}'+'\nTanggal: '+(r['created_at']??'-').toString(),style:const TextStyle(fontSize:11)),
    onTap:(){
      final row=Map<String,dynamic>.from(r);
      final id=cikokoPositiveId(row);
      final ref=cikokoWarisReference(row);
      if(id==null && ref==null){notify(context,'Server belum mengirim ID surat. Pastikan API V2525 aktif.',error:true);load();return;}
      showCikokoDocument(context,api,id:id??0,reference:ref??'',kind:cikokoDocumentKind(row),onChanged:load);
    },
    trailing:PopupMenuButton<String>(tooltip:'Tindakan Admin',enabled:!busy,
      onSelected:(value)=>value=='edit_date'
       ? editWarisDate(Map<String,dynamic>.from(r))
       : update(Map<String,dynamic>.from(r),value),
      itemBuilder:(_)=>[
       if(widget.allowWarisDate&&api.profile?['role']=='admin'&&cikokoDocumentKind(Map<String,dynamic>.from(r))=='waris')
        const PopupMenuItem<String>(value:'edit_date',child:Text('Ubah Tanggal Pengajuan')),
       for(final status in ['masuk','proses','revisi','selesai','ditolak'])
        PopupMenuItem<String>(value:status,child:Text('Status: '+status)),
      ]),
  )),if(rows.isEmpty)const ListTile(title:Text('Belum ada permohonan.'))]));
}
