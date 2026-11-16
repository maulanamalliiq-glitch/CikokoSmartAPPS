import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/cikoko_chat_v2548.dart';

void main(){
 test('Inbox uses one thread per account, not one per message', (){
  final items=cikokoDistinctChatThreads([
   {'user_id':'resident-A','id':1,'name':'Warga A','message':'Pesan pertama'},
   {'user_id':'resident-A','id':3,'name':'Warga A','message':'Pesan baru'},
   {'user_id':'resident-B','id':2,'name':'Warga B','message':'Pesan lain'},
  ]);
  expect(items.length,2);
  expect(items.first['user_id'],'resident-A');
  expect(items.first['message'],'Pesan baru');
 });
 test('Two accounts with identical names remain private separate threads', (){
  final items=cikokoDistinctChatThreads([
   {'user_id':'account-1','last_id':10,'name':'Nama Sama'},
   {'user_id':'account-2','last_id':11,'name':'Nama Sama'},
  ]);
  expect(items.length,2);
  expect(items[0]['user_id'],'account-2');
  expect(items[1]['user_id'],'account-1');
 });
 test('Unread count is parsed as nonnegative and never shown as negative', (){
  expect(cikokoChatUnreadCount({'unread_count':'4'}),4);
  expect(cikokoChatUnreadCount({'unread_count':-2}),0);
  expect(cikokoChatUnreadCount({'unread_count':'unknown'}),0);
 });
 test('Rows without a canonical account id are excluded', (){
  final items=cikokoDistinctChatThreads([
   {'user_id':'', 'id':4},
   {'id':5},
   {'user_id':'account-3','id':6},
  ]);
  expect(items.length,1);
  expect(items.single['user_id'],'account-3');
 });
}
