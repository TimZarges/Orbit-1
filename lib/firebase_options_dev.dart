import 'package:firebase_core/firebase_core.dart';

/// Standard-Konfiguration für Firebase Web (orbit-app-mvp)
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'AIzaSyAzarr5ItVeQI67QNryfUwGi1OvM657Jpo',
      appId: '1:58590696532:web:51d347f5ba8b35bb9549c1',
      messagingSenderId: '58590696532',
      projectId: 'orbit-app-mvp',
      authDomain: 'orbit-app-mvp.firebaseapp.com',
      storageBucket: 'orbit-app-mvp.firebasestorage.app',
    );
  }
}
