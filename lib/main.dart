import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/home/app_shell.dart';
void main() {
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