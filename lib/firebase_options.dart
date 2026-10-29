// File generated for project tawsila-91768
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
    apiKey: 'AIzaSyAJ6cduFaUn_2bwHd4wI3HPTL8AGkDq9MY',
    appId: '1:608829457774:web:tawsilaweb',
    messagingSenderId: '608829457774',
    projectId: 'tawsila-91768',
    authDomain: 'tawsila-91768.firebaseapp.com',
    storageBucket: 'tawsila-91768.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAJ6cduFaUn_2bwHd4wI3HPTL8AGkDq9MY',
    appId: '1:608829457774:android:6213152fecc5ad172d6d7f',
    messagingSenderId: '608829457774',
    projectId: 'tawsila-91768',
    storageBucket: 'tawsila-91768.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAJ6cduFaUn_2bwHd4wI3HPTL8AGkDq9MY',
    appId: '1:608829457774:ios:tawsilaios',
    messagingSenderId: '608829457774',
    projectId: 'tawsila-91768',
    storageBucket: 'tawsila-91768.firebasestorage.app',
    iosBundleId: 'tn.tawsila.tawsila',
  );
}
