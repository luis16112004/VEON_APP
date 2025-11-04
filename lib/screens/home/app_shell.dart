import 'package:flutter/material.dart';
import 'package:veon_app/screens/auth/constants/colors.dart';
import 'package:veon_app/screens/clients/clients_list_screen.dart';
import 'package:veon_app/screens/products/products_list_screen.dart';
import 'package:veon_app/screens/providers/providers_list_screen.dart';

class AppShell extends StatefulWidget {
  static const String route = '/app';
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final _pages = const [
    ClientsListScreen(),
    ProductsListScreen(),
    ProvidersListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: AppColors.black),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: AppColors.black,
          selectedItemColor: AppColors.primaryGreen,
          unselectedItemColor: AppColors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              label: 'Clients',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              label: 'Products',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined),
              label: 'Providers',
            ),
          ],
        ),
      ),
    );
  }
}

