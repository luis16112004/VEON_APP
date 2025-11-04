import 'package:flutter/material.dart';
import 'package:veon_app/screens/auth/constants/colors.dart';

import '../../../widgets/client_list_item.dart';
import '../../../widgets/statistics_card.dart';
import '../../../widgets/top_clients_card.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onNavigateToClients;

  const HomeScreen({
    super.key,
    this.onNavigateToClients,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: AppColors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fulano',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Administrator',
                              style: TextStyle(
                                color: AppColors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.white,
                          size: 22,
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Top Clients Card
                const TopClientsCard(),

                const SizedBox(height: 20),

                // Statistics Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Statistics',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Row(
                        children: [
                          const Text(
                            'See Reports',
                            style: TextStyle(
                              color: AppColors.primaryGreen,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              color: AppColors.white,
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Statistics Cards
                const Row(
                  children: [
                    Expanded(
                      child: StatisticsCard(
                        icon: Icons.inventory_2_outlined,
                        value: '920',
                        label: 'Products',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: StatisticsCard(
                        icon: Icons.shopping_bag_outlined,
                        value: '52',
                        label: 'Sales',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: StatisticsCard(
                        icon: Icons.attach_money,
                        value: '\$9,000',
                        label: 'Total sales',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Manage Clients Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Manage clients',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: onNavigateToClients,
                      child: Row(
                        children: [
                          const Text(
                            'See all',
                            style: TextStyle(
                              color: AppColors.primaryGreen,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              color: AppColors.white,
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Client List
                const ClientListItem(
                  name: 'Carlos Hernandez',
                  company: 'Walmart',
                  icon: Icons.store,
                  iconColor: Color(0xFF0071CE),
                ),
                const SizedBox(height: 8),
                const ClientListItem(
                  name: 'Miguel Castañeda',
                  company: 'Starbucks',
                  icon: Icons.local_cafe,
                  iconColor: Color(0xFF00704A),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}