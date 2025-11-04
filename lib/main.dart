import 'package:flutter/material.dart';
import 'package:veon_app/screens/auth/constants/colors.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/welcome_screen.dart';
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
      home: const WelcomeScreen(),
    );
  }
}