import 'package:flutter/material.dart';
import 'package:veon_app/screens/auth/constants/colors.dart';
import 'package:veon_app/services/auth_service.dart';
import 'package:veon_app/services/permission_service.dart';
import 'package:veon_app/models/user_model.dart';
import 'package:veon_app/screens/profile/organization_screen.dart';
import 'package:veon_app/screens/auth/welcome_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _authService = AuthService.instance;
  UserModel? _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    try {
      setState(() => _isLoading = true);
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesión: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showEditProfileDialog() async {
    if (_currentUser == null) return;

    final nameController = TextEditingController(text: _currentUser!.name);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Editar Perfil', style: TextStyle(color: Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                labelText: 'Nombre',
                labelStyle: TextStyle(color: Colors.black54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryGreen)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Email: ${_currentUser!.email}',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            onPressed: () async {
              try {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                await _authService.updateName(nameController.text);
                await _loadUser();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Perfil actualizado'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // CAMBIO: Fondo blanco para que contraste con la letra negra
        backgroundColor: Colors.white,
        // CAMBIO: Título en negro
        title: const Text('Cambiar Contraseña', style: TextStyle(color: Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPassController,
              obscureText: true,
              // CAMBIO: Letra del input en NEGRO
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                labelText: 'Contraseña Actual',
                // CAMBIO: Label en gris oscuro/negro para que se lea
                labelStyle: TextStyle(color: Colors.black54),
                // Borde gris visible en fondo blanco
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryGreen)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPassController,
              obscureText: true,
              // CAMBIO: Letra del input en NEGRO
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                labelText: 'Nueva Contraseña',
                // CAMBIO: Label en gris oscuro/negro
                labelStyle: TextStyle(color: Colors.black54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryGreen)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            onPressed: () async {
              try {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                await _authService.changePassword(
                  currentPassword: currentPassController.text,
                  newPassword: newPassController.text,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contraseña actualizada'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Eliminar Cuenta', style: TextStyle(color: Colors.red)),
        content: const Text(
          '¿Estás seguro de que quieres eliminar tu cuenta? Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => _isLoading = true);
        await _authService.deleteAccount();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar cuenta: $e'), backgroundColor: Colors.red),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: AppColors.white),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Profile Picture
                    Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryGreen,
                            border: Border.all(
                              color: AppColors.white,
                              width: 4,
                            ),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: AppColors.white,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.black,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Text(
                      _currentUser?.name ?? 'Usuario',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _currentUser?.email ?? '',
                      style: const TextStyle(
                         fontSize: 14,
    color: Colors.grey,
                    ),
                    ),

                    const SizedBox(height: 24),
                    
                    // Editar perfil - disponible para todos
                    _buildProfileOption(
                      icon: Icons.edit_outlined,
                      iconColor: Colors.blue,
                      title: 'Editar Perfil',
                      subtitle: 'Cambiar tu nombre',
                      onTap: _showEditProfileDialog,
                    ),

                    const SizedBox(height: 16),

                    // Organización - solo para admin
                    if (_currentUser != null && PermissionService.instance.isAdmin(_currentUser))
                      _buildProfileOption(
                        icon: Icons.business_outlined,
                        iconColor: Colors.orange,
                        title: 'Organización',
                        subtitle: 'Gestionar usuarios y roles',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OrganizationScreen(),
                            ),
                          ).then((_) => _loadUser());
                        },
                      ),

                    if (_currentUser != null && PermissionService.instance.isAdmin(_currentUser))
                      const SizedBox(height: 16),

                    // Cambiar contraseña - disponible para todos
                    _buildProfileOption(
                      icon: Icons.lock_outline,
                      iconColor: AppColors.primaryGreen,
                      title: 'Cambiar Contraseña',
                      subtitle: 'Actualizar tu contraseña de acceso',
                      onTap: _showChangePasswordDialog,
                    ),

                    const SizedBox(height: 16),

                    // Cerrar sesión - disponible para todos
                    _buildProfileOption(
                      icon: Icons.logout,
                      iconColor: AppColors.error,
                      title: 'Cerrar Sesión',
                      subtitle: 'Salir de tu cuenta',
                      onTap: _handleLogout,
                    ),

                    const SizedBox(height: 16),

                    // Eliminar cuenta - disponible para todos
                    _buildProfileOption(
                      icon: Icons.delete_outline,
                      iconColor: AppColors.error,
                      title: 'Eliminar Cuenta',
                      subtitle: 'Eliminar permanentemente tu cuenta',
                      onTap: _handleDeleteAccount,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

