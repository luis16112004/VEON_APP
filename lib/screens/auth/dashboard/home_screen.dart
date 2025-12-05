import 'package:flutter/material.dart';
import 'package:veon_app/screens/auth/constants/colors.dart';
import 'package:veon_app/services/auth_service.dart';
import 'package:veon_app/services/client_service.dart';
import 'package:veon_app/services/product_service.dart';
import 'package:veon_app/services/sale_service.dart';
import 'package:veon_app/services/quotation_service.dart';
import 'package:veon_app/models/user_model.dart';
import 'package:veon_app/models/client.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../widgets/client_list_item.dart';
import '../../../widgets/statistics_card.dart';
import '../../../widgets/top_clients_card.dart';
import '../../reports/reports_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToClients;

  const HomeScreen({
    super.key,
    this.onNavigateToClients,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService.instance;
  final _clientService = ClientService();
  final _productService = ProductService();
  final _saleService = SaleService();
  final _quotationService = QuotationService();

  UserModel? _currentUser;
  int _totalProducts = 0;
  int _totalSales = 0;
  double _totalRevenue = 0.0;
  int _totalClients = 0;
  int _totalQuotations = 0;
  List<Client> _topClients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // Cargar usuario actual
      _currentUser = await _authService.getCurrentUser();

      // Cargar estadísticas
      final products = await _productService.getProducts();
      final sales = await _saleService.getAllSales();
      final clients = await _clientService.getClients();
      final quotations = await _quotationService.getAllQuotations();

      // Calcular estadísticas
      _totalProducts = products.length;
      _totalSales = sales.length;
      _totalRevenue = sales.fold(0.0, (sum, sale) => sum + sale.total);
      _totalClients = clients.length;
      _totalQuotations = quotations.length;

      // Top clientes (ordenar por número de ventas)
      _topClients = List.from(clients);
      _topClients.sort((a, b) => b.salesCount.compareTo(a.salesCount));
      _topClients = _topClients.take(5).toList();
    } catch (e) {
      print('❌ Error cargando datos del dashboard: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryGreen,
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                color: AppColors.primaryGreen,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header con nombre del usuario
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentUser?.name ?? 'Usuario',
                                      style: const TextStyle(
                                        color: AppColors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
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

                        // Top Clients Card con datos reales
                        if (_topClients.isNotEmpty)
                          TopClientsCard(clients: _topClients)
                        else
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
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ReportsScreen(),
                                  ),
                                );
                              },
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

                        // Statistics Cards con datos reales
                        Row(
                          children: [
                            Expanded(
                              child: StatisticsCard(
                                icon: Icons.inventory_2_outlined,
                                value: _totalProducts.toString(),
                                label: 'Products',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatisticsCard(
                                icon: Icons.shopping_bag_outlined,
                                value: _totalSales.toString(),
                                label: 'Sales',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatisticsCard(
                                icon: Icons.attach_money,
                                value: _formatCurrency(_totalRevenue),
                                label: 'Total sales',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Additional Statistics
                        Row(
                          children: [
                            Expanded(
                              child: StatisticsCard(
                                icon: Icons.group_outlined,
                                value: _totalClients.toString(),
                                label: 'Clients',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatisticsCard(
                                icon: Icons.description_outlined,
                                value: _totalQuotations.toString(),
                                label: 'Quotations',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Sales Chart
                        _buildSalesChart(),

                        const SizedBox(height: 20),

                        // Manage Clients Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Clients',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: widget.onNavigateToClients,
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

                        // Recent Clients List
                        ...(_topClients.take(2).map((client) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ClientListItem(
                                name: client.fullName,
                                company: client.companyName ?? 'No company',
                                icon: Icons.store,
                                iconColor: AppColors.primaryGreen,
                              ),
                            ))),
                        if (_topClients.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No clients yet',
                              style: TextStyle(
                                color: AppColors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSalesChart() {
    return FutureBuilder<List>(
      future: _getSalesDataForChart(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'No sales data yet',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }

        final chartData = snapshot.data!;
        return Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: chartData.map((data) {
                    return FlSpot(data['day'].toDouble(), data['amount']);
                  }).toList(),
                  isCurved: true,
                  color: AppColors.primaryGreen,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primaryGreen.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getSalesDataForChart() async {
    try {
      final sales = await _saleService.getAllSales();
      
      if (sales.isEmpty) {
        return [];
      }

      // Agrupar ventas por día de la última semana
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      
      final Map<int, double> dailySales = {};
      for (var i = 0; i < 7; i++) {
        dailySales[i] = 0.0;
      }

      for (var sale in sales) {
        final saleDate = sale.date;
        if (saleDate.isAfter(weekAgo) || saleDate.isAtSameMomentAs(weekAgo)) {
          final daysDiff = now.difference(saleDate).inDays;
          if (daysDiff >= 0 && daysDiff < 7) {
            final dayIndex = 6 - daysDiff;
            if (dayIndex >= 0 && dayIndex < 7) {
              dailySales[dayIndex] = (dailySales[dayIndex] ?? 0.0) + sale.total;
            }
          }
        }
      }

      // Normalizar los valores para que la gráfica se vea bien
      final maxValue = dailySales.values.reduce((a, b) => a > b ? a : b);
      
      return dailySales.entries.map((entry) {
        return {
          'day': entry.key,
          'amount': maxValue > 0 ? (entry.value / maxValue * 100) : entry.value,
        };
      }).toList();
    } catch (e) {
      print('Error obteniendo datos para gráfica: $e');
      return [];
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return formatter.format(amount);
  }
}
