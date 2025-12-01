// lib/screens/quotations/quotation_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/quotation_model.dart';
import '../../models/sale_model.dart';
import '../../services/quotation_service.dart';

class QuotationDetailScreen extends StatefulWidget {
  final String quotationId;

  const QuotationDetailScreen({
    super.key,
    required this.quotationId,
  });

  @override
  State<QuotationDetailScreen> createState() => _QuotationDetailScreenState();
}

class _QuotationDetailScreenState extends State<QuotationDetailScreen> {
  final _quotationService = QuotationService();
  Quotation? _quotation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadQuotation();
  }

  Future<void> _loadQuotation() async {
    setState(() => _isLoading = true);
    try {
      final quotation = await _quotationService.getQuotationById(widget.quotationId);
      setState(() {
        _quotation = quotation;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error cargando cotización: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Cotización'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        actions: [
          if (_quotation != null && _quotation!.status != QuotationStatus.converted)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'approve') {
                  _approveQuotation();
                } else if (value == 'reject') {
                  _rejectQuotation();
                } else if (value == 'convert') {
                  _confirmConvertToSale();
                } else if (value == 'pdf') {
                  _generatePDF();
                } else if (value == 'email') {
                  _sendEmail();
                }
              },
              itemBuilder: (context) => [
                if (_quotation!.canConvert)
                  const PopupMenuItem(
                    value: 'convert',
                    child: Row(
                      children: [
                        Icon(Icons.shopping_cart, color: Color(0xFF10B981)),
                        SizedBox(width: 8),
                        Text('Convertir a Venta'),
                      ],
                    ),
                  ),
                if (_quotation!.status == QuotationStatus.pending)
                  const PopupMenuItem(
                    value: 'approve',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF10B981)),
                        SizedBox(width: 8),
                        Text('Aprobar'),
                      ],
                    ),
                  ),
                if (_quotation!.status == QuotationStatus.pending)
                  const PopupMenuItem(
                    value: 'reject',
                    child: Row(
                      children: [
                        Icon(Icons.cancel, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Rechazar'),
                      ],
                    ),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf),
                      SizedBox(width: 8),
                      Text('Generar PDF'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'email',
                  child: Row(
                    children: [
                      Icon(Icons.email),
                      SizedBox(width: 8),
                      Text('Enviar por Email'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quotation == null
          ? _buildErrorState()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildValidityCard(),
            const SizedBox(height: 16),
            _buildClientInfo(),
            const SizedBox(height: 16),
            _buildQuotationInfo(),
            const SizedBox(height: 16),
            _buildProductsList(),
            const SizedBox(height: 16),
            _buildTotalsSummary(),
            if (_quotation!.notes != null) ...[
              const SizedBox(height: 16),
              _buildNotesCard(),
            ],
            if (_quotation!.terms != null) ...[
              const SizedBox(height: 16),
              _buildTermsCard(),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _quotation != null && _quotation!.canConvert
          ? _buildConvertButton()
          : null,
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
            'Cotización no encontrada',
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

    switch (_quotation!.status) {
      case QuotationStatus.pending:
        bgColor = const Color(0xFFDEECFF);
        borderColor = const Color(0xFF3B82F6);
        icon = Icons.pending;
        message = 'Cotización pendiente';
        break;
      case QuotationStatus.approved:
        bgColor = const Color(0xFFDCFCE7);
        borderColor = const Color(0xFF10B981);
        icon = Icons.check_circle;
        message = 'Cotización aprobada';
        break;
      case QuotationStatus.rejected:
        bgColor = const Color(0xFFFEE2E2);
        borderColor = const Color(0xFFEF4444);
        icon = Icons.cancel;
        message = 'Cotización rechazada';
        break;
      case QuotationStatus.expired:
        bgColor = const Color(0xFFFEF3C7);
        borderColor = const Color(0xFFF59E0B);
        icon = Icons.warning;
        message = 'Cotización vencida';
        break;
      case QuotationStatus.converted:
        bgColor = const Color(0xFFD1FAE5);
        borderColor = const Color(0xFF10B981);
        icon = Icons.check_circle_outline;
        message = 'Convertida a venta';
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

  Widget _buildValidityCard() {
    final isExpired = _quotation!.isExpired;
    final daysRemaining = _quotation!.validUntil.difference(DateTime.now()).inDays;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isExpired
            ? const Color(0xFFFEE2E2)
            : daysRemaining <= 3
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isExpired ? Icons.schedule : Icons.timer,
            color: isExpired
                ? Colors.red
                : daysRemaining <= 3
                ? Colors.orange
                : Colors.green,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExpired
                      ? 'Cotización Vencida'
                      : daysRemaining == 0
                      ? 'Vence Hoy'
                      : 'Válida por $daysRemaining día${daysRemaining != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isExpired
                        ? Colors.red
                        : daysRemaining <= 3
                        ? Colors.orange
                        : Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Válida hasta: ${DateFormat('dd/MM/yyyy').format(_quotation!.validUntil)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
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
              _quotation!.clientName,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotationInfo() {
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
                  'Información',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('ID:', _quotation!.id),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Fecha:',
              DateFormat('dd/MM/yyyy').format(_quotation!.date),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Válida hasta:',
              DateFormat('dd/MM/yyyy').format(_quotation!.validUntil),
            ),
            if (_quotation!.convertedToSaleId != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                'ID de Venta:',
                _quotation!.convertedToSaleId!,
              ),
            ],
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
          width: 120,
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
            ..._quotation!.items.asMap().entries.map((entry) {
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

  Widget _buildProductItem(QuotationItem item) {
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
            color: Color(0xFF3B82F6),
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
            _buildTotalRow('Subtotal:', _quotation!.subtotal),
            const SizedBox(height: 12),
            _buildTotalRow('IVA:', _quotation!.tax),
            if (_quotation!.discount > 0) ...[
              const SizedBox(height: 12),
              _buildTotalRow(
                'Descuento:',
                -_quotation!.discount,
                color: Colors.red,
              ),
            ],
            const Divider(height: 32),
            _buildTotalRow(
              'TOTAL:',
              _quotation!.total,
              isBold: true,
              fontSize: 24,
              color: const Color(0xFF3B82F6),
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
              _quotation!.notes!,
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.gavel, color: Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                const Text(
                  'Términos y Condiciones',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              _quotation!.terms!,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConvertButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _confirmConvertToSale,
          icon: const Icon(Icons.shopping_cart),
          label: const Text(
            'Convertir a Venta',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmConvertToSale() {
    PaymentMethod selectedPayment = PaymentMethod.cash;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Convertir a Venta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Confirmar la conversión de esta cotización a una venta?',
              ),
              const SizedBox(height: 16),
              const Text(
                'Método de pago:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PaymentMethod.values.map((method) {
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(method.icon),
                        const SizedBox(width: 4),
                        Text(method.displayName),
                      ],
                    ),
                    selected: selectedPayment == method,
                    onSelected: (selected) {
                      setState(() => selectedPayment = method);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _convertToSale(selectedPayment);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              child: const Text('Convertir'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _convertToSale(PaymentMethod paymentMethod) async {
    setState(() => _isLoading = true);
    try {
      await _quotationService.convertQuotationToSale(
        quotationId: widget.quotationId,
        paymentMethod: paymentMethod,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cotización convertida a venta exitosamente'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context); // Volver a la lista
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error convirtiendo cotización: $e');
    }
  }

  Future<void> _approveQuotation() async {
    try {
      await _quotationService.approveQuotation(widget.quotationId);
      await _loadQuotation();
      _showSuccess('Cotización aprobada');
    } catch (e) {
      _showError('Error aprobando cotización: $e');
    }
  }

  Future<void> _rejectQuotation() async {
    try {
      await _quotationService.rejectQuotation(widget.quotationId);
      await _loadQuotation();
      _showSuccess('Cotización rechazada');
    } catch (e) {
      _showError('Error rechazando cotización: $e');
    }
  }

  void _generatePDF() {
    // TODO: Implementar generación de PDF
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔨 Función en desarrollo: Generar PDF'),
        backgroundColor: Color(0xFF3B82F6),
      ),
    );
  }

  void _sendEmail() {
    // TODO: Implementar envío de email
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔨 Función en desarrollo: Enviar Email'),
        backgroundColor: Color(0xFF3B82F6),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
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