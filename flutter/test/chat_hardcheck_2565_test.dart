import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/cikoko_chat_v2548.dart';

void main(){
 test('Messages are chronological even when API sends newest first',(){
  final rows=cikokoOrderedChatMessages([
   {'id':30,'message':'paling baru','sender':'admin'},
   {'id':10,'message':'paling lama','sender':'warga'},
   {'id':20,'message':'tengah','sender':'warga'},
  ]);
  expect(rows.map((m)=>m['id']).toList(),[10,20,30]);
 });

 test('Duplicate responses by message ID do not duplicate chat bubbles',(){
  final rows=cikokoOrderedChatMessages([
   {'id':10,'message':'halo'},
   {'id':10,'message':'halo'},
   {'id':12,'message':'halo'},
  ]);
  expect(rows.length,2);
  expect(rows.map((m)=>m['id']).toList(),[10,12]);
 });

 test('Same message text with a different ID is a real new message',(){
  final before=<Map<String,dynamic>>[
   {'id':1,'message':'iya kak','sender':'admin'}
  ];
  final after=cikokoOrderedChatMessages([
   {'id':2,'message':'iya kak','sender':'admin'},
  ]);
  expect(cikokoChatMessagesChanged(before,after),isTrue);
 });

 test('Read receipts refresh even without a new message',(){
  final before=<Map<String,dynamic>>[
   {'id':7,'message':'halo','delivery_status':'sent'}
  ];
  final after=cikokoOrderedChatMessages([
   {'id':7,'message':'halo','delivery_status':'sent'},
  ],receiptUpdates:{'7':'read'});
  expect(after.single['delivery_status'],'read');
  expect(cikokoChatMessagesChanged(before,after),isTrue);
 });

 test('Photo metadata survives temporary legacy API fallback',(){
  final prior=<Map<String,dynamic>>[
   {'id':44,'message':'📷 Foto','has_photo':true,'photo_id':44},
  ];
  final now=cikokoOrderedChatMessages([
   {'id':44,'message':'📷 Foto'},
  ],previous:prior);
  expect(now.single['has_photo'],true);
  expect(now.single['photo_id'],44);
 });
}
