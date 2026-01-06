import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FCMTokenService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate & save token
  Future<void> saveToken(String userId) async {
    final token = await _messaging.getToken();
    if (token == null) return;

    log("📱 FCM TOKEN: $token");

    await _firestore.collection('users').doc(userId).set({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Refresh token
  void listenTokenRefresh(String userId) {
    _messaging.onTokenRefresh.listen((newToken) async {
      log("♻️ FCM TOKEN REFRESHED");

      await _firestore.collection('users').doc(userId).update({
        'fcmToken': newToken,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
