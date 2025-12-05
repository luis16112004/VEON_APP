// lib/screens/sales/sale_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/sale_model.dart';
import '../../services/sale_service.dart';
import '../../services/auth_service.dart';
import '../../services/permission_service.dart';

class SaleDetailScreen extends StatefulWidget {
  final String saleId;

  const SaleDetailScreen({
    super.key,
    required this.saleId,
  });

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  final _saleService = SaleService();
  final _authService = AuthService.instance;
  final _permissionService = PermissionService.instance;
  Sale? _sale;
  bool _isLoading = false;
  bool _canEditSale = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadSale();
  }

  Future<void> _checkPermissions() async {
    final user = await _authService.getCurrentUser();
    setState(() {
      _canEditSale = _permissionService.canEditSale(user);
    });
  }

  Future<void> _loadSale() async {
    setState(() => _isLoading = true);
    try {
      final sale = await _saleService.getSaleById(widget.saleId);
      setState(() {
        _sale = sale;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error cargando venta: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Venta'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        actions: [
          if (_sale != null && _sale!.status != SaleStatus.cancelled && _canEditSale)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'cancel') {
                  _confirmCancelSale();
                } else if (value == 'invoice') {
                  _generateInvoice();
                } else if (value == 'share') {
                  _shareSale();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'invoice',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf),
                      SizedBox(width: 8),
                      Text('Generar Factura PDF'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share),
                      SizedBox(width: 8),
                      Text('Compartir'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Cancelar Venta', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sale == null
          ? _buildErrorState()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildClientInfo(),
            const SizedBox(height: 16),
            _buildSaleInfo(),
            const SizedBox(height: 16),
            _buildProductsList(),
            const SizedBox(height: 16),
            _buildTotalsSummary(),
            if (_sale!.notes != null) ...[
              const SizedBox(height: 16),
              _buildNotesCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Venta no encontrada',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Volver'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    Color bgColor;
    Color borderColor;
    IconData icon;
    String message;

    switch (_sale!.status) {
      case SaleStatus.completed:
        bgColor = const Color(0xFFDCFCE7);
        borderColor = const Color(0xFF10B981);
        icon = Icons.check_circle;
        message = 'Venta completada exitosamente';
        break;
      case SaleStatus.pending:
        bgColor = const Color(0xFFFEF3C7);
        borderColor = const Color(0xFFF59E0B);
        icon = Icons.pending;
        message = 'Venta pendiente de pago';
        break;
      case SaleStatus.cancelled:
        bgColor = const Color(0xFFFEE2E2);
        borderColor = const Color(0xFFEF4444);
        icon = Icons.cancel;
        message = 'Venta cancelada';
        break;
      case SaleStatus.draft:
        bgColor = const Color(0xFFF3F4F6);
        borderColor = const Color(0xFF6B7280);
        icon = Icons.edit;
        message = 'Borrador de venta';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: borderColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: borderColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                const Text(
                  'Cliente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              _sale!.clientName,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                const Text(
                  'Información de Venta',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              'ID de Venta:',
              _sale!.id,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Fecha:',
              DateFormat('dd/MM/yyyy HH:mm').format(_sale!.date),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Método de Pago:',
              '${_sale!.paymentMethod.icon} ${_sale!.paymentMethod.displayName}',
            ),
            if (_sale!.quotationId != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                'Desde Cotización:',
                _sale!.quotationId!,
              ),
            ],
            const SizedBox(height: 12),
            _buildInfoRow(
              'Estado:',
              '${_sale!.status.icon} ${_sale!.status.displayName}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildProductsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_bag, color: Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                const Text(
                  'Productos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ..._sale!.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  if (index > 0) const Divider(height: 24),
                  _buildProductItem(item),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(SaleItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'SKU: ${item.sku}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${item.quantity} ${item.unit} × \$${item.unitPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        Text(
          '\$${item.total.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsSummary() {
    return Card(
      color: const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTotalRow('Subtotal:', _sale!.subtotal),
            const SizedBox(height: 12),
            _buildTotalRow('IVA:', _sale!.tax),
            if (_sale!.discount > 0) ...[
              const SizedBox(height: 12),
              _buildTotalRow(
                'Descuento:',
                -_sale!.discount,
                color: Colors.red,
              ),
            ],
            const Divider(height: 32),
            _buildTotalRow(
              'TOTAL:',
              _sale!.total,
              isBold: true,
              fontSize: 24,
              color: const Color(0xFF10B981),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(
      String label,
      double amount, {
        bool isBold = false,
        double fontSize = 16,
        Color? color,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note, color: Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                const Text(
                  'Notas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              _sale!.notes!,
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancelSale() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Venta'),
        content: const Text(
          '¿Estás seguro de que deseas cancelar esta venta?\n\n'
              'Los productos regresarán al inventario.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelSale();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelSale() async {
    try {
      await _saleService.cancelSale(widget.saleId);
      await _loadSale();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Venta cancelada y stock devuelto'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      _showError('Error cancelando venta: $e');
    }
  }

  void _generateInvoice() {
    // TODO: Implementar generación de PDF
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔨 Función en desarrollo: Generar PDF'),
        backgroundColor: Color(0xFF3B82F6),
      ),
    );
  }

  void _shareSale() {
    // TODO: Implementar compartir
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔨 Función en desarrollo: Compartir venta'),
        backgroundColor: Color(0xFF3B82F6),
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