import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  // Replace the placeholder values with your Firebase project configuration.
  static FirebaseOptions get firebaseOptions {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyD8kN6gli9PAMWWz4JNoprBeOLAb40IrM8',
        authDomain: 'zamzam-laundry.firebaseapp.com',
        projectId: 'zamzam-laundry',
        storageBucket: 'zamzam-laundry.firebasestorage.app',
        messagingSenderId: '844100582161',
        appId: '1:844100582161:web:5cfa69fa047e34184b2ab0',
        measurementId: 'G-QS97DEC6RE',
      );
    }

    return const FirebaseOptions(
      apiKey: 'AIzaSyBYQZRBJ6mcJ8Rv9rLFAKA9GJ2enOnYP60',
      projectId: 'zamzam-laundry',
      storageBucket: 'zamzam-laundry.firebasestorage.app',
      messagingSenderId: '844100582161',
      appId: '1:844100582161:android:39097a49efae46594b2ab0',
    );
  }
}
