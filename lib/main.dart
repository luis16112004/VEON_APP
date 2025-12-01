import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Para usar kDebugMode

import 'core/theme/app_theme.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/home/app_shell.dart';

// Imports para la base de datos
import 'database/local_storage.dart';
import 'database/mongo_service.dart';
import 'database/sync_service.dart';

void main() async {
  // Asegura que los bindings de Flutter estén listos antes de ejecutar código asíncrono.
  WidgetsFlutterBinding.ensureInitialized();

  // --- INICIALIZACIÓN DE SERVICIOS ESENCIALES ---
  // Este bloque se ejecuta una sola vez al iniciar la app.

  // PASO 1: Iniciar almacenamiento local. Es rápido y no debe fallar.
  await LocalStorage.instance.init();

  // PASO 2: Intentar conectar a MongoDB. No bloquea la app si falla.
  try {
    await MongoService.instance.connect();
  } catch (e) {
    // En modo de depuración, es útil saber por qué falló.
    // En producción, la app simplemente seguirá en modo offline.
    if (kDebugMode) {
      print('⚠️ MongoDB no disponible al inicio: $e');
    }
  }

  // PASO 3: Iniciar el servicio de sincronización.
  // Este se encargará de gestionar el estado online/offline y sincronizar datos.
  await SyncService.instance.init();

  if (kDebugMode) {
    print('✅ VEON Business App: Servicios inicializados.');
  }

  // Inicia la aplicación de Flutter.
  runApp(const VeonApp());
}

class VeonApp extends StatelessWidget {
  const VeonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VEON Business',
      // Se recomienda mantener esto en 'false' para la versión final.
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // La pantalla de inicio siempre será WelcomeScreen.
      home: const WelcomeScreen(),

      // Rutas para la navegación dentro de la app.
      routes: {
        AppShell.route: (_) => const AppShell(),
        // Aquí puedes agregar otras rutas principales si las tienes.
      },
    );
  }
}
