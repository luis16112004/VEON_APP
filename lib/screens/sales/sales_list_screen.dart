// lib/screens/sales/sales_list_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/sale_model.dart';
import '../../services/sale_service.dart';
import 'add_sale_screen.dart';
import 'sale_detail_screen.dart';

class SalesListScreen extends StatefulWidget {
  const SalesListScreen({super.key});

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  final _saleService = SaleService();
  List<Sale> _sales = [];
  List<Sale> _filteredSales = [];
  bool _isLoading = false;
  String _searchQuery = '';
  SaleStatus? _filterStatus;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    try {
      final sales = await _saleService.getAllSales();
      setState(() {
        _sales = sales;
        _filteredSales = sales;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error cargando ventas: $e');
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredSales = _sales.where((sale) {
        // Filtro por búsqueda
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final matchesClient = sale.clientName.toLowerCase().contains(query);
          final matchesId = sale.id.toLowerCase().contains(query);
          if (!matchesClient && !matchesId) return false;
        }

        // Filtro por estado
        if (_filterStatus != null && sale.status != _filterStatus) {
          return false;
        }

        // Filtro por fecha
        if (_dateRange != null) {
          if (sale.date.isBefore(_dateRange!.start) ||
              sale.date.isAfter(_dateRange!.end)) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSales.isEmpty
                ? _buildEmptyState()
                : _buildSalesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddSaleScreen()),
          );
          _loadSales();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva Venta'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar por cliente o ID...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    if (_filterStatus == null && _dateRange == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        children: [
          if (_filterStatus != null)
            Chip(
              label: Text(_filterStatus!.displayName),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() => _filterStatus = null);
                _applyFilters();
              },
            ),
          if (_dateRange != null)
            Chip(
              label: Text(
                '${DateFormat('dd/MM').format(_dateRange!.start)} - ${DateFormat('dd/MM').format(_dateRange!.end)}',
              ),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() => _dateRange = null);
                _applyFilters();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty && _filterStatus == null && _dateRange == null
                ? 'No hay ventas registradas'
                : 'No se encontraron ventas',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Presiona el botón verde para crear una',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesList() {
    // Agrupar ventas por fecha
    final groupedSales = <String, List<Sale>>{};
    for (var sale in _filteredSales) {
      final dateKey = DateFormat('yyyy-MM-dd').format(sale.date);
      if (!groupedSales.containsKey(dateKey)) {
        groupedSales[dateKey] = [];
      }
      groupedSales[dateKey]!.add(sale);
    }

    final sortedDates = groupedSales.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final sales = groupedSales[dateKey]!;
        final date = DateTime.parse(dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _formatDateHeader(date),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            ...sales.map((sale) => _buildSaleCard(sale)).toList(),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final saleDate = DateTime(date.year, date.month, date.day);

    if (saleDate == today) {
      return 'Hoy';
    } else if (saleDate == yesterday) {
      return 'Ayer';
    } else {
      return DateFormat('EEEE, d MMMM', 'es').format(date);
    }
  }

  Widget _buildSaleCard(Sale sale) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SaleDetailScreen(saleId: sale.id),
            ),
          );
          _loadSales();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.clientName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('HH:mm').format(sale.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${sale.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStatusBadge(sale.status),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    _getPaymentIcon(sale.paymentMethod),
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    sale.paymentMethod.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${sale.items.length} producto${sale.items.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(SaleStatus status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case SaleStatus.completed:
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF166534);
        break;
      case SaleStatus.pending:
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        break;
      case SaleStatus.cancelled:
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        break;
      case SaleStatus.draft:
        bgColor = const Color(0xFFE5E7EB);
        textColor = const Color(0xFF374151);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  IconData _getPaymentIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.transfer:
        return Icons.account_balance;
      case PaymentMethod.check:
        return Icons.receipt;
      case PaymentMethod.credit:
        return Icons.credit_score;
      case PaymentMethod.multiple:
        return Icons.payments;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar Ventas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Estado:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: SaleStatus.values.map((status) {
                return FilterChip(
                  label: Text(status.displayName),
                  selected: _filterStatus == status,
                  onSelected: (selected) {
                    setState(() {
                      _filterStatus = selected ? status : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Rango de fechas:'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: _dateRange,
                );
                if (range != null) {
                  setState(() => _dateRange = range);
                }
              },
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _dateRange == null
                    ? 'Seleccionar fechas'
                    : '${DateFormat('dd/MM/yy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yy').format(_dateRange!.end)}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filterStatus = null;
                _dateRange = null;
              });
              _applyFilters();
              Navigator.pop(context);
            },
            child: const Text('Limpiar'),
          ),
          ElevatedButton(
            onPressed: () {
              _applyFilters();
              Navigator.pop(context);
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}