import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/push_notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Runs in a separate isolate - must re-initialize Firebase here even
  // though main() already did it, since this isolate doesn't share state.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await PushNotificationService.instance.showSosNotification(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase.initializeApp itself is fast/local - keep this awaited so the
  // background handler is registered before runApp.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Everything else in push setup (permission prompt, FCM token fetch,
  // registering the token with the backend) involves real network calls.
  // This is an emergency app - the first frame must never wait on network.
  // Runs in the background right after the UI appears instead of before.
  unawaited(PushNotificationService.instance.initialize());

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const WeBAlertApp());
}
