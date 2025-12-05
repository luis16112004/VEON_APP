/// Configuración de Firebase
/// Las credenciales se obtienen automáticamente de firebase_options.dart
/// generado con flutterfire configure
///
/// IMPORTANTE: Este archivo es solo para referencia.
/// La configuración real se hace en firebase_options.dart después de ejecutar:
/// flutterfire configure

class FirebaseConfig {
  // La configuración de Firebase se obtiene automáticamente
  // cuando se ejecuta: flutterfire configure
  //
  // Esto generará el archivo: lib/firebase_options.dart
  //
  // NO necesitas configurar nada aquí manualmente.
  // Todo se maneja a través de firebase_options.dart

  static const String instructions = '''
Para configurar Firebase:

1. Instala FlutterFire CLI:
   dart pub global activate flutterfire_cli

2. Configura tu proyecto:
   flutterfire configure

3. Esto generará automáticamente:
   - lib/firebase_options.dart
   - Configuración en android/app/google-services.json
   - Configuración en ios/Runner/GoogleService-Info.plist

4. La inicialización se hace en main.dart con:
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
  ''';
}
