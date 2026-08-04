import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'FirebaseOptions have not been configured for web.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'FirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC-YnxZVowgoCzULPQQriYQZ6o-gQdt1kc',
    appId: '1:307774380841:android:46b38e90728b546678b538',
    messagingSenderId: '307774380841',
    projectId: 'webalert-705e6',
    storageBucket: 'webalert-705e6.firebasestorage.app',
  );
}