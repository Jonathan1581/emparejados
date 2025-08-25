import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBhfG60BzXpMUiYgulKjZCFG1rX5yCU784',
    appId: '1:717476747532:android:95a3c063a4e9f9e0199129',
    messagingSenderId: '717476747532',
    projectId: 'emparejados-eb4ea',
    storageBucket: 'emparejados-eb4ea.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBhfG60BzXpMUiYgulKjZCFG1rX5yCU784',
    appId: '1:717476747532:ios:95a3c063a4e9f9e0199129',
    messagingSenderId: '717476747532',
    projectId: 'emparejados-eb4ea',
    storageBucket: 'emparejados-eb4ea.firebasestorage.app',
    iosBundleId: 'com.example.emparejados',
  );
}
