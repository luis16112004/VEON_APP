// lib/screens/quotations/add_quotation_screen.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/quotation_model.dart';
import '../../models/client.dart';
import '../../models/product.dart';
import '../../services/quotation_service.dart';
import '../../services/client_service.dart';
import '../../services/product_service.dart';

class AddQuotationScreen extends StatefulWidget {
  const AddQuotationScreen({super.key});

  @override
  State<AddQuotationScreen> createState() => _AddQuotationScreenState();
}

class _AddQuotationScreenState extends State<AddQuotationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quotationService = QuotationService();
  final _clientService = ClientService();
  final _productService = ProductService();

  // Datos de la cotización
  Client? _selectedClient;
  final List<QuotationItem> _items = [];
  int _validDays = 15;
  double _discount = 0.0;
  double _taxRate = 0.16;
  final _notesController = TextEditingController();
  final _termsController = TextEditingController();

  // Estado
  bool _isLoading = false;
  List<Client> _clients = [];
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    // Cargar términos por defecto
    _termsController.text = '''TÉRMINOS Y CONDICIONES:
1. Esta cotización es válida hasta la fecha indicada
2. Los precios están sujetos a cambios sin previo aviso
3. El tiempo de entrega será coordinado con el cliente
4. Los pagos deben realizarse según lo acordado
5. Las devoluciones se aceptan dentro de los 7 días posteriores a la compra''';
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final clients = await _clientService.getClients();
      final products = await _productService.getProducts();

      setState(() {
        _clients = clients;
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error cargando datos: $e');
    }
  }

  double get _subtotal => _items.fold(0.0, (sum, item) => sum + item.total);
  double get _tax => _subtotal * _taxRate;
  double get _total => _subtotal + _tax - _discount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Cotización'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildClientSelector(),
                          const SizedBox(height: 24),
                          _buildValidDaysSelector(),
                          const SizedBox(height: 24),
                          _buildProductsList(),
                          const SizedBox(height: 16),
                          _buildAddProductButton(),
                          const SizedBox(height: 24),
                          _buildDiscountField(),
                          const SizedBox(height: 24),
                          _buildNotesField(),
                          const SizedBox(height: 24),
                          _buildTermsField(),
                          const SizedBox(height: 24),
                          _buildTotalsSummary(),
                        ],
                      ),
                    ),
                  ),
                  _buildSaveButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildClientSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cliente',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<Client>(
            value: _selectedClient,
            isExpanded: true,
            underline: const SizedBox(),
            hint: const Text('Seleccionar cliente'),
            items: _clients.map((client) {
              return DropdownMenuItem(
                value: client,
                child: Text(client.fullName),
              );
            }).toList(),
            onChanged: (client) {
              setState(() => _selectedClient = client);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildValidDaysSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Válida por (días)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _validDays.toDouble(),
                min: 1,
                max: 60,
                divisions: 59,
                label: '$_validDays días',
                onChanged: (value) {
                  setState(() => _validDays = value.toInt());
                },
              ),
            ),
            Container(
              width: 60,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_validDays',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        Text(
          'Vence el: ${_getValidUntilDate()}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _getValidUntilDate() {
    final validUntil = DateTime.now().add(Duration(days: _validDays));
    return '${validUntil.day}/${validUntil.month}/${validUntil.year}';
  }

  Widget _buildProductsList() {
    if (_items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No hay productos agregados\nPresiona el botón de abajo para agregar',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Productos',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _buildProductItem(item, index);
        }).toList(),
      ],
    );
  }

  Widget _buildProductItem(QuotationItem item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SKU: ${item.sku}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${item.quantity} ${item.unit} × \$${item.unitPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${item.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(height: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() => _items.removeAt(index));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddProductButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _showAddProductDialog,
        icon: const Icon(Icons.add),
        label: const Text('Agregar Producto'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          side: const BorderSide(color: Color(0xFF3B82F6)),
          foregroundColor: const Color(0xFF3B82F6),
        ),
      ),
    );
  }

  Widget _buildDiscountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Descuento',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _discount.toString(),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            prefixText: '\$ ',
            border: OutlineInputBorder(),
            hintText: '0.00',
          ),
          onChanged: (value) {
            setState(() {
              _discount = double.tryParse(value) ?? 0.0;
            });
          },
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notas (opcional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          maxLines: 2,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Agregar notas sobre esta cotización...',
          ),
        ),
      ],
    );
  }

  Widget _buildTermsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Términos y Condiciones',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _termsController,
          maxLines: 5,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Términos y condiciones de la cotización...',
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildTotalRow('Subtotal:', _subtotal),
          const SizedBox(height: 8),
          _buildTotalRow(
              'IVA (${(_taxRate * 100).toStringAsFixed(0)}%):', _tax),
          const SizedBox(height: 8),
          _buildTotalRow('Descuento:', -_discount, color: Colors.red),
          const Divider(height: 24),
          _buildTotalRow(
            'TOTAL:',
            _total,
            isBold: true,
            fontSize: 20,
            color: const Color(0xFF3B82F6),
          ),
        ],
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
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
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
        child: ElevatedButton(
          onPressed: _saveQuotation,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Crear Cotización',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _showAddProductDialog() {
    Product? selectedProduct;
    double quantity = 1.0;
    final quantityController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Agregar Producto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Product>(
                  value: selectedProduct,
                  decoration: const InputDecoration(
                    labelText: 'Producto',
                    border: OutlineInputBorder(),
                  ),
                  items: _products.map((product) {
                    return DropdownMenuItem(
                      value: product,
                      child: Text(product.name),
                    );
                  }).toList(),
                  onChanged: (product) {
                    setDialogState(() => selectedProduct = product);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    quantity = double.tryParse(value) ?? 1.0;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedProduct != null && quantity > 0) {
                  final item = QuotationItem.create(
                    productId: selectedProduct!.id?.toString() ?? '',
                    productName: selectedProduct!.name,
                    sku: selectedProduct!.sku,
                    quantity: quantity,
                    unit: selectedProduct!.unitOfMeasurement ??
                        selectedProduct!.unit ??
                        'Unit',
                    unitPrice: selectedProduct!.salePrice,
                  );

                  setState(() => _items.add(item));
                  Navigator.pop(context);
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveQuotation() async {
    if (_selectedClient == null) {
      _showError('Debes seleccionar un cliente');
      return;
    }

    if (_items.isEmpty) {
      _showError('Debes agregar al menos un producto');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final quotation = Quotation.create(
        id: 'quot_${const Uuid().v4()}',
        clientId: _selectedClient!.id,
        clientName: _selectedClient!.fullName,
        date: DateTime.now(),
        validDays: _validDays,
        items: _items,
        taxRate: _taxRate,
        discount: _discount,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        terms: _termsController.text.isEmpty ? null : _termsController.text,
      );

      await _quotationService.createQuotation(quotation);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cotización creada exitosamente'),
            backgroundColor: Color(0xFF3B82F6),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error guardando cotización: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _termsController.dispose();
    super.dispose();
  }
}
