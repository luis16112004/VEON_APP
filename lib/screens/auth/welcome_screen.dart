import 'package:flutter/material.dart';
import 'package:veon_app/screens/auth/constants/colors.dart';
import 'login_screen.dart'; // Para navegar al presionar 'Explore'

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16161E),
      body: Stack(
        children: [
          // Imagen de Fondo
          Image.asset(
            'assets/images/welcome_background.png',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),

          // Contenido Principal
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // --- ESTE ES EL CAMBIO ---
                  // Reemplazamos el Spacer por un SizedBox de altura fija.
                  // Puedes ajustar el 80.0 si lo quieres más arriba (ej. 60.0)
                  // o un poco más abajo (ej. 100.0).
                  const SizedBox(height: 80.0),

                  // Logo
                  Align(
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/images/veon_logo_services.png',
                      height: 80,
                    ),
                  ),

                  // Spacer después del logo para empujar el texto hacia abajo
                  const Spacer(), // Quitamos el flex para que solo ocupe el espacio restante

                  // Título principal
                  const Text(
                    'All-in-one\nSolution\nto optimize',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Botón "Explore"
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF00B383),
                              Color(0xFF00D4A1),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: const Text(
                            'Explore',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16), // Espacio inferior
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}