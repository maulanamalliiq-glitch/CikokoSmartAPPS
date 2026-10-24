import 'package:flutter/material.dart';
import 'api.dart';

class RolePermissionPage extends StatefulWidget {final CikokoApi api;const RolePermissionPage({super.key,required this.api});@override State<RolePermissionPage> createState()=>_RolePermissionPageState();}
class _RolePermissionPageState extends State<RolePermissionPage> {
 Map<String,dynamic>? data;
 String role='asn';
 bool busy=false;
 String? error;
 @override void initState(){super.initState();load();}
 Future<void> load() async {try{final result=await widget.api.call('role_permissions');if(mounted)setState((){data=result;error=null;});}catch(e){if(mounted)setState(()=>error='$e');}}
 bool allowed(String key) {
  final overrides=(data?['overrides'] as List<dynamic>? ?? []);
  for(final o in overrides){if(o['role']==role && o['capability']==key) return o['allowed']==true || o['allowed']==1 || o['allowed']=='1';}
  final defaults=Map<String,dynamic>.from(data?['defaults'] as Map? ??{});
  return (defaults[role] as List<dynamic>? ??[]).contains(key);
 }
 Future<void> change(String key,bool enable)async {
  if(busy)return;setState(()=>busy=true);
  try{await widget.api.call('role_permissions',body:{'role':role,'capability':key,'allowed':enable});await load();}
  catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Gagal menyimpan hak akses: $e')));}
  finally{if(mounted)setState(()=>busy=false);}
 }
 @override Widget build(BuildContext c){if(error!=null)return Center(child:Text('Gagal memuat hak akses: $error'));if(data==null)return const Center(child:CircularProgressIndicator());
  final roles=Map<String,dynamic>.from(data!['roles'] as Map);
  final keys=(data!['keys'] as List<dynamic>).cast<String>().where((e)=>e!='role:manage').toList();
  return ListView(padding:const EdgeInsets.all(14),children:[Text('Hak Akses Petugas',style:Theme.of(c).textTheme.titleLarge),const SizedBox(height:6),const Text('Perubahan berlaku pada API server. Admin Utama selalu memiliki akses penuh.',style:TextStyle(color:Colors.blueGrey,fontSize:12)),const SizedBox(height:12),
   DropdownButtonFormField<String>(initialValue:role,decoration:const InputDecoration(labelText:'Pilih role'),items:[for(final e in roles.entries)if(e.key!='admin')DropdownMenuItem(value:e.key,child:Text('${e.value}'))],onChanged:busy?null:(r){if(r!=null)setState(()=>role=r);}),
   const SizedBox(height:8),for(final key in keys)Card(child:SwitchListTile(dense:true,title:Text(key.replaceAll(':',' / ').replaceAll('_',' ')),value:allowed(key),onChanged:busy?null:(v)=>change(key,v))),
   const SizedBox(height:18),
  ]);
 }
}
