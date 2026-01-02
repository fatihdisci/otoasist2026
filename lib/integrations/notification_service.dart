import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Firebase Cloud Messaging ve Local Notifications yönetimi
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Servisi başlatır (main.dart'ta çağrılmalı)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. İzin iste
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('Kullanıcı bildirim izni verdi');
      } else {
        debugPrint('Kullanıcı bildirim izni vermedi');
        return;
      }

      // 2. Local Notifications ayarla
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // 3. FCM Token al
      final token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');

      // 4. Token değişikliklerini dinle
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('Yeni FCM Token: $newToken');
        // Burada token'ı backend'e gönderebilirsiniz
      });

      // 5. Foreground mesajlarını dinle
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 6. Background mesaj handler'ı (main.dart'ta tanımlanmalı)
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      _isInitialized = true;
      debugPrint('NotificationService başarıyla başlatıldı');
    } catch (e) {
      debugPrint('NotificationService başlatma hatası: $e');
    }
  }

  /// Foreground'da gelen mesajları göster
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground mesaj alındı: ${message.notification?.title}');

    // Local notification göster
    _showLocalNotification(
      title: message.notification?.title ?? 'Bildirim',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  /// Local notification göster
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'oto_asist_channel',
      'Oto Asist Bildirimleri',
      channelDescription: 'Araç bakım ve onarım bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Bildirime tıklandığında
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Bildirime tıklandı: ${response.payload}');
    // Burada navigation yapılabilir
  }

  /// Bakım hatırlatması gönder
  Future<void> scheduleMaintenanceReminder({
    required String vehicleName,
    required int daysUntilMaintenance,
    required int kmUntilMaintenance,
  }) async {
    final title = 'Bakım Hatırlatması';
    final body = daysUntilMaintenance > 0
        ? '$vehicleName için $daysUntilMaintenance gün sonra bakım zamanı!'
        : '$vehicleName için $kmUntilMaintenance km sonra bakım zamanı!';

    await _showLocalNotification(
      title: title,
      body: body,
      payload: 'maintenance_reminder',
    );
  }

  /// Kritik bakım uyarısı gönder
  Future<void> sendCriticalMaintenanceAlert({
    required String vehicleName,
    required String message,
  }) async {
    await _showLocalNotification(
      title: '⚠️ Kritik Bakım Uyarısı',
      body: '$vehicleName: $message',
      payload: 'critical_maintenance',
    );
  }

  /// FCM Token'ı al (Backend'e göndermek için)
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}

/// Background mesaj handler (top-level function olmalı)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background mesaj alındı: ${message.messageId}');
  // Background'da işlem yapılabilir
}

