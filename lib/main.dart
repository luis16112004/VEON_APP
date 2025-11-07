import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/home/app_shell.dart';

// 🆕 Imports para la base de datos
import 'database/local_storage.dart';
import 'database/mongo_service.dart';
import 'database/sync_service.dart';

void main() async {
  // 🆕 Necesario para código asíncrono antes de runApp
  WidgetsFlutterBinding.ensureInitialized();

  print('');
  print('🚀 ========================================');
  print('🚀 Iniciando VEON Business App...');
  print('🚀 ========================================');
  print('');

  // 🆕 PASO 1: Inicializar almacenamiento local
  print('📦 Inicializando almacenamiento local...');
  try {
    await LocalStorage.instance.init();
    print('✅ Almacenamiento local listo');
  } catch (e) {
    print('❌ Error inicializando almacenamiento local: $e');
    print('⚠️  La app puede tener problemas guardando datos');
  }

  print('');

  // 🆕 PASO 2: Conectar a MongoDB (solo si hay internet)
  print('☁️  Conectando a MongoDB...');
  try {
    await MongoService.instance.connect();
    print('✅ MongoDB conectado correctamente');
  } catch (e) {
    print('⚠️  MongoDB no disponible (sin internet o error de conexión)');
    print('   📱 La app funcionará en modo OFFLINE');
    print('   💾 Los datos se guardarán localmente');
    print('   🔄 Se sincronizarán automáticamente cuando haya internet');
  }

  print('');

  // 🆕 PASO 3: Iniciar servicio de sincronización
  print('🔄 Inicializando servicio de sincronización...');
  try {
    await SyncService.instance.init();
    print('✅ Servicio de sincronización activo');

    // Mostrar estadísticas
    final stats = SyncService.instance.getStats();
    print('   📊 Estadísticas:');
    print('      - Online: ${stats['isOnline'] ? 'Sí' : 'No'}');
    print('      - Datos locales: ${stats['totalDatos']}');
    print('      - Operaciones pendientes: ${stats['operacionesPendientes']}');
  } catch (e) {
    print('❌ Error inicializando sincronización: $e');
  }

  print('');
  print('✅ ========================================');
  print('✅ VEON Business App lista para usar');
  print('✅ ========================================');
  print('');

  runApp(const VeonApp());
}

class VeonApp extends StatelessWidget {
  const VeonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VEON Business',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Para ejecutar una pantalla específica en desarrollo,
      // cambia temporalmente 'home' por esa pantalla.
      // Ejemplo: home: AddClientScreen(),
      home: const WelcomeScreen(),
      routes: {
        AppShell.route: (_) => const AppShell(),
      },
    );
  }
}