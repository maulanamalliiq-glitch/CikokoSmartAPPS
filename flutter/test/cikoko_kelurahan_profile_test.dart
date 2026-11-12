import 'package:cikoko/api.dart';
import 'package:cikoko/cikoko_kelurahan_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class StubProfileApi extends CikokoApi {
 String? lastAction;
 @override Future<Map<String,dynamic>> call(String action,
   {Map<String,dynamic>? body,bool authorized=false}) async{
    lastAction=action;
    return {'ok':true,'title':'Kelurahan Cikoko',
      'description':'Kelurahan Cikoko berada di Kecamatan Pancoran, Jakarta Selatan.',
      'map_image':'https://datawebs.my.id/mobile-api/civic-assets/profile/peta-wilayah-cikoko.jpg',
      'organization_image':'https://datawebs.my.id/mobile-api/civic-assets/profile/struktur-organisasi-cikoko.jpg'};
 }
}
void main(){
 testWidgets('Peta wilayah appears above kelurahan description',(tester)async{
  final api=StubProfileApi();
  await tester.pumpWidget(MaterialApp(home:Scaffold(body:
    CikokoKelurahanProfilePage(api:api,title:'Tentang Kami',navigate:(_){ }))));
  await tester.pump();
  expect(api.lastAction,'profile_kelurahan_public');
  expect(find.text('Peta Wilayah Cikoko'),findsOneWidget);
  expect(find.byKey(const Key('cikoko_profile_map_image')),findsOneWidget);
  expect(find.text('Tentang Kelurahan Cikoko'),findsOneWidget);
  expect(tester.getTopLeft(find.text('Peta Wilayah Cikoko')).dy,
    lessThan(tester.getTopLeft(find.text('Tentang Kelurahan Cikoko')).dy));
 });
}
