import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Standard-Konfiguration für Firebase (orbit-app-mvp)
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAzarr5ItVeQI67QNryfUwGi1OvM657Jpo',
    appId: '1:58590696532:web:51d347f5ba8b35bb9549c1',
    messagingSenderId: '58590696532',
    projectId: 'orbit-app-mvp',
    authDomain: 'orbit-app-mvp.firebaseapp.com',
    storageBucket: 'orbit-app-mvp.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA4xYVv6Fx6V25lbsoF2w5MWO19n5z0Fso',
    appId: '1:58590696532:android:94db3229ecbe5ad29549c1',
    messagingSenderId: '58590696532',
    projectId: 'orbit-app-mvp',
    storageBucket: 'orbit-app-mvp.firebasestorage.app',
  );
}
