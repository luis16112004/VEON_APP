import 'package:flutter/material.dart';
import 'package:veon_app/screens/auth/constants/colors.dart';

class ProvidersListScreen extends StatelessWidget {
  const ProvidersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: const SafeArea(
        child: Center(
          child: Text(
            'Providers (próximamente)',
            style: TextStyle(color: AppColors.white, fontSize: 18),
          ),
        ),
      ),
    );
  }
}

