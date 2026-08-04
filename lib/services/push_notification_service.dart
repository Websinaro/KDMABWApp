import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api_service.dart';
import 'dnd_service.dart';

/// Handles FCM setup, the custom high-priority SOS notification channel,
/// and routing a tapped notification to the live SOS map screen.
///
/// `onSosNotificationTapped` is set by the app's navigation layer (main.dart
/// or wherever the navigatorKey lives) so this service stays UI-agnostic.
class PushNotificationService {
  PushNotificationService._internal();
  static final PushNotificationService instance = PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  void Function(int sosId, String senderName, double lat, double lon)? onSosNotificationTapped;

  /// Public so the top-level background handler in main.dart can reuse the
  /// exact same notification logic as the foreground listener.
  Future<void> showSosNotification(RemoteMessage message) => _showSosNotification(message);
  
  Future<void> initialize() async {
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);

    // Re-create the channel every launch - cheap, and picks up DND-bypass
    // status immediately once the user grants Notification Policy Access
    // (they might grant it after first install, on a later app open).
    await DndService.instance.createSosChannel();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) => _handlePayload(response.payload),
    );

    // Foreground: FCM doesn't auto-show a system notification while the app
    // is open, so we display it ourselves via flutter_local_notifications
    // using the same high-priority channel.
    FirebaseMessaging.onMessage.listen(_showSosNotification);

    // Tapped from background (app was minimized).
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleDataPayload(message.data);
    });

    // App was fully terminated and opened via the notification tap.
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleDataPayload(initialMessage.data);
    }

    // Register/refresh this device's token with the backend so protectors
    // can actually be reached.
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _registerToken(token);
    }
    FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);
  }

  Future<void> _registerToken(String token) async {
    try {
      await ApiService.instance.registerDeviceToken(token: token, platform: 'android');
    } catch (_) {
      // Non-fatal - will retry on next app open / token refresh.
    }
  }

  Future<void> _showSosNotification(RemoteMessage message) async {
    if (message.data['type'] != 'sos_alert') return;

    final senderName = message.data['sender_name'] ?? 'Someone';
    final payload = jsonEncode(message.data);

    const androidDetails = AndroidNotificationDetails(
      'sos_alerts',
      'SOS Emergency Alerts',
      channelDescription: 'Emergency alerts from your Safety Circle',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.call,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('sos_alarm'),
      visibility: NotificationVisibility.public,
    );

    await _local.show(
      message.data['sos_id']?.hashCode ?? 0,
      'EMERGENCY: $senderName needs help',
      'Tap to see their live location',
      const NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  void _handlePayload(String? payload) {
    if (payload == null) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _handleDataPayload(data);
    } catch (_) {}
  }

  void _handleDataPayload(Map<String, dynamic> data) {
    if (data['type'] != 'sos_alert') return;
    final sosId = int.tryParse('${data['sos_id']}');
    final lat = double.tryParse('${data['latitude']}');
    final lon = double.tryParse('${data['longitude']}');
    if (sosId == null || lat == null || lon == null) return;

    onSosNotificationTapped?.call(sosId, data['sender_name']?.toString() ?? 'Someone', lat, lon);
  }
}
