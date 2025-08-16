// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/foundation.dart'
//     show defaultTargetPlatform, kIsWeb, TargetPlatform;

// class DefaultFirebaseOptions {
//   static FirebaseOptions get currentPlatform {
//     if (kIsWeb) {
//       return web;
//     }
//     switch (defaultTargetPlatform) {
//       case TargetPlatform.android:
//         return android;
//       case TargetPlatform.iOS:
//         return ios;
//       case TargetPlatform.macOS:
//         throw UnsupportedError(
//           'DefaultFirebaseOptions have not been configured for macos - '
//           'you can reconfigure this by running the FlutterFire CLI again.',
//         );
//       case TargetPlatform.windows:
//         throw UnsupportedError(
//           'DefaultFirebaseOptions have not been configured for windows - '
//           'you can reconfigure this by running the FlutterFire CLI again.',
//         );
//       case TargetPlatform.linux:
//         throw UnsupportedError(
//           'DefaultFirebaseOptions have not been configured for linux - '
//           'you can reconfigure this by running the FlutterFire CLI again.',
//         );
//       default:
//         throw UnsupportedError(
//           'DefaultFirebaseOptions are not supported for this platform.',
//         );
//     }
//   }

// class FirebaseConfig {
//   static const FirebaseOptions web = FirebaseOptions(
//     apiKey: "your-api-key",
//     authDomain: "taskflow-flutter-YOUR-PROJECT-ID.firebaseapp.com",
//     projectId: "taskflow-flutter-YOUR-PROJECT-ID",
//     storageBucket: "taskflow-flutter-YOUR-PROJECT-ID.appspot.com",
//     messagingSenderId: "your-sender-id",
//     appId: "your-app-id",
//     measurementId: "your-measurement-id", // Optional
//   );

//   static const FirebaseOptions android = FirebaseOptions(
//     apiKey: "your-android-api-key",
//     appId: "your-android-app-id",
//     messagingSenderId: "your-sender-id",
//     projectId: "taskflow-flutter-YOUR-PROJECT-ID",
//     storageBucket: "taskflow-flutter-YOUR-PROJECT-ID.appspot.com",
//   );

//   static const FirebaseOptions ios = FirebaseOptions(
//     apiKey: "your-ios-api-key",
//     appId: "your-ios-app-id",
//     messagingSenderId: "your-sender-id",
//     projectId: "taskflow-flutter-YOUR-PROJECT-ID",
//     storageBucket: "taskflow-flutter-YOUR-PROJECT-ID.appspot.com",
//     iosBundleId: 'com.taskflow.taskflow_flutter',
//   );
// }