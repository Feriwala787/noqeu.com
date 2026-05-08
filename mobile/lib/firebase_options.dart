import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web not configured.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS not configured yet.');
      default:
        throw UnsupportedError('Unsupported platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCiyQoW4vGDgegzJkwgx_kSTmEnX63Gmh4',
    appId: '1:856980079213:android:24f91f8e11b4698a757564',
    messagingSenderId: '856980079213',
    projectId: 'noqeu-640a4',
    storageBucket: 'noqeu-640a4.firebasestorage.app',
  );
}
