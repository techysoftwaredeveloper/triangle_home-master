// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAf6sci7jZdtWVplHKHm8qEv6Rnqj3VWUY',
    appId: '1:857102138852:web:4c5ab785d232b737b31bf1',
    messagingSenderId: '857102138852',
    projectId: 'trianglehomes-b7306',
    authDomain: 'trianglehomes-b7306.firebaseapp.com',
    storageBucket: 'trianglehomes-b7306.firebasestorage.app',
    measurementId: 'G-N117SGH1NE',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAXZRKcJvCPWUvn9AaApaRdbvxDryb-uB8',
    appId: '1:857102138852:android:f9b141bcdc77cf62b31bf1',
    messagingSenderId: '857102138852',
    projectId: 'trianglehomes-b7306',
    storageBucket: 'trianglehomes-b7306.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDlTpdpj-S9YyqrCATJ-gaeKiMk56536Ac',
    appId: '1:857102138852:ios:4f88de040ca3d8fab31bf1',
    messagingSenderId: '857102138852',
    projectId: 'trianglehomes-b7306',
    storageBucket: 'trianglehomes-b7306.firebasestorage.app',
    iosBundleId: 'com.example.triangleHome',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDlTpdpj-S9YyqrCATJ-gaeKiMk56536Ac',
    appId: '1:857102138852:ios:4f88de040ca3d8fab31bf1',
    messagingSenderId: '857102138852',
    projectId: 'trianglehomes-b7306',
    storageBucket: 'trianglehomes-b7306.firebasestorage.app',
    iosBundleId: 'com.example.triangleHome',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAf6sci7jZdtWVplHKHm8qEv6Rnqj3VWUY',
    appId: '1:857102138852:web:2591bed3249fea28b31bf1',
    messagingSenderId: '857102138852',
    projectId: 'trianglehomes-b7306',
    authDomain: 'trianglehomes-b7306.firebaseapp.com',
    storageBucket: 'trianglehomes-b7306.firebasestorage.app',
    measurementId: 'G-4HGXMZ8843',
  );
}
