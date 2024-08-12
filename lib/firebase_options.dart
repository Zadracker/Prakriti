import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyCvwwALopoJ6NGc5HtG6Tt71NIEVdQUKpc',
    appId: '1:326170575776:web:0c55d06ec6230009191ac5',
    messagingSenderId: '326170575776',
    projectId: 'prakriti-firebase-ad13e',
    authDomain: 'prakriti-firebase-ad13e.firebaseapp.com',
    storageBucket: 'prakriti-firebase-ad13e.appspot.com',
    measurementId: 'G-LSK36NCFMH',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBHIha4HpzRxbESRpKhxnO3kx_BVb-JrTs',
    appId: '1:326170575776:android:ad3b0312311d0bec191ac5',
    messagingSenderId: '326170575776',
    projectId: 'prakriti-firebase-ad13e',
    storageBucket: 'prakriti-firebase-ad13e.appspot.com',
  );
}
