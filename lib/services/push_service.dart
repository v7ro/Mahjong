import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Инициализация пуш-уведомлений.
/// Расписание уведомлений настраивается в Firebase Console →
/// Cloud Messaging → отправить кампанию.
class PushService {
  static final _msg = FirebaseMessaging.instance;

  static Future<void> init(BuildContext context) async {
    // Запрашиваем разрешение
    await _msg.requestPermission(
      alert: true, badge: true, sound: true);

    // Получаем токен (нужен для отправки через Firebase Console)
    final token = await _msg.getToken();
    debugPrint('FCM Token: $token');

    // Обработка уведомлений когда приложение открыто
    FirebaseMessaging.onMessage.listen((msg) {
      final n = msg.notification;
      if (n != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${n.title}: ${n.body}')));
      }
    });
  }
}
