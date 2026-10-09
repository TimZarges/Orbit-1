import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'dummy-api-key',
      appId: '1:1234567890:web:abcdef',
      messagingSenderId: 'dummy-sender-id',
      projectId: 'orbit-dev',
      storageBucket: 'orbit-dev.appspot.com',
    );
  }
}
