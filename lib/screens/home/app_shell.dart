import 'package:flutter/material.dart';
import 'package:veon_app/screens/auth/constants/colors.dart';
import 'package:veon_app/screens/auth/dashboard/home_screen.dart';
import 'package:veon_app/screens/clients/clients_list_screen.dart';
import 'package:veon_app/screens/products/products_list_screen.dart';
import 'package:veon_app/screens/providers/providers_list_screen.dart';
import 'package:veon_app/screens/categories/categories_list_screen.dart';
import 'package:veon_app/screens/sales/sales_list_screen.dart';
import 'package:veon_app/screens/quotations/quotations_list_screen.dart';
import 'package:veon_app/screens/profile/user_profile_screen.dart';
import 'package:veon_app/screens/reports/reports_screen.dart';
import 'package:veon_app/services/auth_service.dart';
import 'package:veon_app/models/user_model.dart';

class AppShell extends StatefulWidget {
  static const String route = '/app';
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  bool _isLoading = true;
  UserModel? _currentUser;
  
  // List of all available pages
  List<_PageDef> _allPages = [];
  // List of pages accessible to current user
  List<_PageDef> _availablePages = [];

  @override
  void initState() {
    super.initState();
    _loadUserAndSetupPages();
  }

  Future<void> _loadUserAndSetupPages() async {
    _currentUser = await AuthService.instance.getCurrentUser();
    
    // Define all pages with RBAC
    _allPages = [
      _PageDef(
        page: HomeScreen(onNavigateToClients: () => _navigateToPage('Clients')),
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Dashboard',
        allowedRoles: ['admin', 'gerente', 'vendedor'],
      ),
      _PageDef(
        page: const ClientsListScreen(),
        icon: Icons.group_outlined,
        activeIcon: Icons.group,
        label: 'Clients',
        allowedRoles: ['admin', 'gerente'], // Vendedor no ve clientes
      ),
      _PageDef(
        page: const ProductsListScreen(),
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2,
        label: 'Products',
        allowedRoles: ['admin', 'gerente'], // Vendedor no gestiona productos
      ),
      _PageDef(
        page: const CategoriesListScreen(),
        icon: Icons.category_outlined,
        activeIcon: Icons.category,
        label: 'Categories',
        allowedRoles: ['admin', 'gerente'], // Vendedor no gestiona categorías
      ),
      _PageDef(
        page: const SalesListScreen(),
        icon: Icons.shopping_bag_outlined,
        activeIcon: Icons.shopping_bag,
        label: 'Sales',
        allowedRoles: ['admin', 'gerente', 'vendedor'],
      ),
      _PageDef(
        page: const QuotationsListScreen(),
        icon: Icons.description_outlined,
        activeIcon: Icons.description,
        label: 'Quotations',
        allowedRoles: ['admin', 'gerente', 'vendedor'],
      ),
      _PageDef(
        page: const ProvidersListScreen(),
        icon: Icons.local_shipping_outlined,
        activeIcon: Icons.local_shipping,
        label: 'Providers',
        allowedRoles: ['admin', 'gerente'], // Vendedor no gestiona proveedores
      ),
      _PageDef(
        page: const ReportsScreen(),
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart,
        label: 'Reports',
        allowedRoles: ['admin', 'gerente', 'vendedor'],
      ),
      _PageDef(
        page: const UserProfileScreen(),
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profile',
        isProfile: true,
        allowedRoles: ['admin', 'gerente', 'vendedor'],
      ),
    ];

    // Filter pages based on role
    final userRole = _currentUser?.role.toLowerCase() ?? 'vendedor';
    
    setState(() {
      _availablePages = _allPages.where((page) {
        return page.allowedRoles.contains(userRole);
      }).toList();
      _isLoading = false;
    });
  }

  void _navigateToPage(String label) {
    final index = _availablePages.indexWhere((p) => p.label == label);
    if (index != -1) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.black,
      body: IndexedStack(
        index: _currentIndex,
        children: _availablePages.map((p) => p.page).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.black,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (i) {
            final page = _availablePages[i];
            if (page.isProfile) {
              // Profile item - navigate to separate screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserProfileScreen(),
                ),
              );
            } else {
              setState(() => _currentIndex = i);
            }
          },
          backgroundColor: AppColors.black,
          selectedItemColor: AppColors.primaryGreen,
          unselectedItemColor: AppColors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: _availablePages.map((p) => BottomNavigationBarItem(
            icon: Icon(p.icon),
            activeIcon: Icon(p.activeIcon),
            label: p.label,
          )).toList(),
        ),
      ),
    );
  }
}

class _PageDef {
  final Widget page;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final List<String> allowedRoles;
  final bool isProfile;

  _PageDef({
    required this.page,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.allowedRoles,
    this.isProfile = false,
  });
}
