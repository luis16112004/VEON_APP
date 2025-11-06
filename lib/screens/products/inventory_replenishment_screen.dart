import 'package:flutter/material.dart';
import 'package:veon_app/models/product.dart';
import 'package:veon_app/screens/auth/constants/colors.dart';
import 'package:veon_app/services/product_service.dart';

class InventoryReplenishmentScreen extends StatefulWidget {
  final Product product;
  const InventoryReplenishmentScreen({super.key, required this.product});

  @override
  State<InventoryReplenishmentScreen> createState() => _InventoryReplenishmentScreenState();
}

class _InventoryReplenishmentScreenState extends State<InventoryReplenishmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final ProductService _productService = ProductService();
  
  String? _selectedReason;
  
  final List<String> _inventoryReasons = [
    'Reception of goods',
    'Stock adjustment',
    'Return from customer',
    'Return to supplier',
    'Damaged goods',
    'Expired products',
    'Theft/Loss',
    'Inventory count correction',
    'Transfer from another location',
    'Production/Manufacturing',
    'Other',
  ];

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  String? _validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Quantity is required';
    }
    final quantity = int.tryParse(value);
    if (quantity == null || quantity < 0) {
      return 'Quantity must be 0 or greater';
    }
    return null;
  }

  Future<void> _handleConfirm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedReason == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a reason'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      try {
        final quantity = int.parse(_quantityController.text.trim());
        final newStock = widget.product.stock + quantity;
        
        final updated = widget.product.copyWith(stock: newStock);
        final success = await _productService.updateProduct(updated);

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Inventory updated successfully'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.of(context).pop(true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error updating inventory'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
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
          icon: const Icon(Icons.close, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Product',
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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product Name
                TextFormField(
                  initialValue: widget.product.name,
                  enabled: false,
                  decoration: _inputDecoration('Product Name', Icons.inventory_2_outlined),
                ),

                const SizedBox(height: 20),

                // Product SKU
                TextFormField(
                  initialValue: widget.product.sku,
                  enabled: false,
                  decoration: _inputDecoration('SKU', Icons.qr_code_outlined),
                ),

                const SizedBox(height: 20),

                // Inventory Reason Dropdown
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightGrey),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedReason,
                    decoration: InputDecoration(
                      hintText: 'Reception of goods',
                      prefixIcon: const Icon(Icons.list_alt_outlined, color: AppColors.grey),
                      suffixIcon: const Icon(Icons.arrow_drop_down, color: AppColors.grey),
                      filled: true,
                      fillColor: AppColors.white,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    items: _inventoryReasons.map((reason) {
                      return DropdownMenuItem<String>(
                        value: reason,
                        child: Text(reason),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedReason = value;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Quantity
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Quantity', Icons.numbers_outlined),
                  validator: _validateQuantity,
                  textInputAction: TextInputAction.done,
                ),

                const SizedBox(height: 32),

                // Confirm Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.grey),
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
      ),
    );
  }
}

