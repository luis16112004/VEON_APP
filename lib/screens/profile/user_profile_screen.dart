import 'package:flutter/material.dart';
import 'package:veon_app/screens/auth/constants/colors.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset(
              'assets/images/iconoblanco.png',
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.all_inclusive,
                  color: AppColors.white,
                  size: 24,
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
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

              const SizedBox(height: 32),

              // Profile Options
              _buildProfileOption(
                icon: Icons.edit_outlined,
                iconColor: AppColors.primaryBlue,
                title: 'Edit username',
                subtitle: 'Update your personal information',
                onTap: () {
                  // Navigate to edit username
                },
              ),

              const SizedBox(height: 16),

              _buildProfileOption(
                icon: Icons.refresh,
                iconColor: AppColors.primaryGreen,
                title: 'Change password',
                subtitle: 'Update your login password',
                onTap: () {
                  // Navigate to change password
                },
              ),

              const SizedBox(height: 16),

              _buildProfileOption(
                icon: Icons.settings_outlined,
                iconColor: AppColors.grey,
                title: 'Account settings',
                subtitle: 'Adjust your preferences',
                onTap: () {
                  // Navigate to account settings
                },
              ),

              const SizedBox(height: 16),

              _buildProfileOption(
                icon: Icons.logout,
                iconColor: AppColors.error,
                title: 'Sign out / Log out',
                subtitle: 'Sign out of your account',
                onTap: () {
                  // Handle sign out
                },
              ),

              const SizedBox(height: 16),

              _buildProfileOption(
                icon: Icons.delete_outline,
                iconColor: AppColors.error,
                title: 'Delete account',
                subtitle: 'Permanently delete your account',
                onTap: () {
                  // Handle delete account
                },
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

