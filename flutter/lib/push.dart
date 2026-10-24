import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api.dart';

@pragma('vm:entry-point')
Future<void> backgroundMessage(RemoteMessage message) async {await Firebase.initializeApp();}
class PushService {
  final CikokoApi api;
  PushService(this.api);
  final local=FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? refresh;
  StreamSubscription<RemoteMessage>? incoming;
  Future<void> start(void Function() onRefresh) async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(backgroundMessage);
      const channel=AndroidNotificationChannel('cikoko_updates','Kegiatan dan Pelayanan',description:'Pembaruan berita, surat dan laporan Cikoko',importance:Importance.high);
      await local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
      await local.initialize(const InitializationSettings(android:AndroidInitializationSettings('@drawable/ic_launcher')));
      await FirebaseMessaging.instance.requestPermission(alert:true,badge:true,sound:true);
      final t=await FirebaseMessaging.instance.getToken();if(t!=null)await register(t);
      refresh=FirebaseMessaging.instance.onTokenRefresh.listen((t){register(t);});
      incoming=FirebaseMessaging.onMessage.listen((m) async {
        final n=m.notification;
        if(n!=null)await local.show(m.hashCode,n.title,n.body,const NotificationDetails(android:AndroidNotificationDetails('cikoko_updates','Kegiatan dan Pelayanan',importance:Importance.max,priority:Priority.high)));
        onRefresh();
      });
      FirebaseMessaging.onMessageOpenedApp.listen((_){onRefresh();});
    }catch(_){ /* API tetap berjalan bila layanan Google tidak tersedia */ }
  }
  Future<void> register(String token) async {if(api.token!=null){try{await api.call('device',body:{'fcm_token':token});}catch(_){}}}
  void dispose(){refresh?.cancel();incoming?.cancel();}
}
