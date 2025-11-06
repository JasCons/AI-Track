import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ======= WEB (minimal) =======
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaEXAMPLE_web_api_key_1234567890',
    appId: "1:370121170127:web:abcdef123456",
    messagingSenderId: "370121170127",
    projectId: "ai-track-42cce",
    authDomain: "ai-track-42cce.firebaseapp.com",
    storageBucket: "ai-track-42cce.firebasestorage.app",
  );

  // ======= ANDROID =======
  // Note: Android also requires the google-services.json file to be present in android/app/
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyDe5AvPQLcse9NwdR1td5PJbjWEAyp9mag",
    appId: "1:370121170127:android:7c6e0a4fe0d6630df9abba",
    messagingSenderId: "370121170127",
    projectId: "ai-track-42cce",
    storageBucket: "ai-track-42cce.firebasestorage.app",
  );

  // ======= iOS / macOS =======
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaEXAMPLE_ios_api_key_1122334455',
    appId: '1:1234567890:ios:abcdef123456',
    messagingSenderId: "370121170127",
    projectId: "ai-track-42cce",
    storageBucket: "ai-track-42cce.firebasestorage.app",
    iosBundleId: "com.example.helloworld",
  );
}
