// Generated Firebase options – web only (Plan Spark / free tier)
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'config/app_config.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError(
      'DefaultFirebaseOptions are only configured for Flutter Web.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: AppConfig.firebaseApiKey,
    authDomain: AppConfig.firebaseAuthDomain,
    projectId: AppConfig.firebaseProjectId,
    storageBucket: AppConfig.firebaseStorageBucket,
    messagingSenderId: AppConfig.firebaseMessagingSenderId,
    appId: AppConfig.firebaseAppId,
  );
}
