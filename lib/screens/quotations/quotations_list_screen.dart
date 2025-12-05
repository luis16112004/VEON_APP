// lib/screens/quotations/quotations_list_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/quotation_model.dart';
import '../../services/quotation_service.dart';
import '../../services/auth_service.dart';
import '../../services/permission_service.dart';
import 'add_quotation_screen.dart';
import 'quotation_detail_screen.dart';

class QuotationsListScreen extends StatefulWidget {
  const QuotationsListScreen({super.key});

  @override
  State<QuotationsListScreen> createState() => _QuotationsListScreenState();
}

class _QuotationsListScreenState extends State<QuotationsListScreen> {
  final _quotationService = QuotationService();
  final _authService = AuthService.instance;
  final _permissionService = PermissionService.instance;
  List<Quotation> _quotations = [];
  List<Quotation> _filteredQuotations = [];
  bool _isLoading = false;
  String _searchQuery = '';
  QuotationStatus? _filterStatus;
  bool _canCreateQuotation = false;
  bool _canEditQuotation = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadQuotations();
  }

  Future<void> _checkPermissions() async {
    final user = await _authService.getCurrentUser();
    setState(() {
      _canCreateQuotation = _permissionService.canCreateQuotation(user);
      _canEditQuotation = _permissionService.canEditQuotation(user);
    });
  }

  Future<void> _loadQuotations() async {
    setState(() => _isLoading = true);
    try {
      // Actualizar cotizaciones vencidas primero
      await _quotationService.updateExpiredQuotations();

      final quotations = await _quotationService.getAllQuotations();
      setState(() {
        _quotations = quotations;
        _filteredQuotations = quotations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error cargando cotizaciones: $e');
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredQuotations = _quotations.where((quotation) {
        // Filtro por búsqueda
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final matchesClient = quotation.clientName.toLowerCase().contains(query);
          final matchesId = quotation.id.toLowerCase().contains(query);
          if (!matchesClient && !matchesId) return false;
        }

        // Filtro por estado
        if (_filterStatus != null && quotation.status != _filterStatus) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotizaciones'),
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
          _buildStatsBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredQuotations.isEmpty
                ? _buildEmptyState()
                : _buildQuotationsList(),
          ),
        ],
      ),
      floatingActionButton: _canCreateQuotation
          ? FloatingActionButton.extended(
              heroTag: 'quotations_fab',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddQuotationScreen()),
                );
                _loadQuotations();
              },
              icon: const Icon(Icons.add),
              label: const Text('Nueva Cotización'),
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            )
          : null,
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
    if (_filterStatus == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Chip(
        label: Text(_filterStatus!.displayName),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: () {
          setState(() => _filterStatus = null);
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildStatsBar() {
    final active = _quotations.where((q) =>
    q.status == QuotationStatus.pending && !q.isExpired).length;
    final expired = _quotations.where((q) => q.isExpired).length;
    final converted = _quotations.where((q) =>
    q.status == QuotationStatus.converted).length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Activas', active, const Color(0xFF3B82F6)),
          _buildStatItem('Vencidas', expired, const Color(0xFFF59E0B)),
          _buildStatItem('Convertidas', converted, const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty && _filterStatus == null
                ? 'No hay cotizaciones registradas'
                : 'No se encontraron cotizaciones',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Presiona el botón azul para crear una',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredQuotations.length,
      itemBuilder: (context, index) {
        final quotation = _filteredQuotations[index];
        return _buildQuotationCard(quotation);
      },
    );
  }

  Widget _buildQuotationCard(Quotation quotation) {
    final isExpired = quotation.isExpired;
    final daysUntilExpiry = quotation.validUntil.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuotationDetailScreen(quotationId: quotation.id),
            ),
          );
          _loadQuotations();
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
                          quotation.clientName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cotización: ${quotation.id.substring(0, 13)}...',
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
                        '\$${quotation.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStatusBadge(quotation.status),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Creada: ${DateFormat('dd/MM/yyyy').format(quotation.date)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    isExpired ? Icons.warning : Icons.timer,
                    size: 16,
                    color: isExpired ? Colors.red : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isExpired
                        ? 'Vencida'
                        : daysUntilExpiry == 0
                        ? 'Vence hoy'
                        : 'Vence en $daysUntilExpiry día${daysUntilExpiry != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isExpired
                          ? Colors.red
                          : daysUntilExpiry <= 3
                          ? Colors.orange
                          : Colors.grey[600],
                      fontWeight:
                      isExpired || daysUntilExpiry <= 3 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${quotation.items.length} producto${quotation.items.length != 1 ? 's' : ''}',
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

  Widget _buildStatusBadge(QuotationStatus status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case QuotationStatus.pending:
        bgColor = const Color(0xFFDEECFF);
        textColor = const Color(0xFF1E40AF);
        break;
      case QuotationStatus.approved:
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF166534);
        break;
      case QuotationStatus.rejected:
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        break;
      case QuotationStatus.expired:
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        break;
      case QuotationStatus.converted:
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF065F46);
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar Cotizaciones'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Estado:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: QuotationStatus.values.map((status) {
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _filterStatus = null);
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