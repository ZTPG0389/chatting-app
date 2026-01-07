import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance =
  NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin
  _localNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // ================= INIT =================
  Future<void> init() async {
    // Permission
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Local notification init
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings =
    InitializationSettings(android: androidSettings);

    await _localNotificationsPlugin.initialize(initSettings);

    // Foreground
    FirebaseMessaging.onMessage.listen((message) {
      print("🔔 Foreground notification");
      showLocalNotification(message);
    });

    // Notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print("📲 Notification clicked");
    });
  }

  // ================= SHOW LOCAL =================
  static Future<void> showLocalNotification(
      RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_channel',
      'Chat Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details =
    NotificationDetails(android: androidDetails);

    await _localNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title ?? 'New Message',
      message.notification?.body ?? '',
      details,
    );
  }

  // ================= BACKGROUND =================
  static Future<void> backgroundHandler(
      RemoteMessage message) async {
    await Firebase.initializeApp();
    print("🌙 Background notification");
    showLocalNotification(message);
  }
}
