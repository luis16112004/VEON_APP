import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:veon_app/models/product.dart';
import 'package:veon_app/models/provider.dart';
import 'package:veon_app/screens/auth/constants/colors.dart';
import 'package:veon_app/services/product_service.dart';
import 'package:veon_app/services/provider_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _shortDescriptionController = TextEditingController();
  final _unitController = TextEditingController();
  final _costController = TextEditingController();
  final _salePriceController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;

  String? _selectedProviderId;
  String? _selectedProviderName;
  String? _selectedUnitOfMeasurement;
  List<Provider> _providers = [];

  final ProductService _productService = ProductService();
  final ProviderService _providerService = ProviderService();

  final List<String> _unitsOfMeasurement = [
    'Piece',
    'Kilogram',
    'Gram',
    'Liter',
    'Milliliter',
    'Box',
    'Pack',
    'Unit',
  ];

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    try {
      final providers = await _providerService.getProviders();
      setState(() {
        _providers = providers;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _shortDescriptionController.dispose();
    _unitController.dispose();
    _costController.dispose();
    _salePriceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es requerido';
    }
    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }

  String? _validateSKU(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El SKU es requerido';
    }
    return null;
  }

  String? _validateCost(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El costo es requerido';
    }
    final cost = double.tryParse(value);
    if (cost == null || cost < 0) {
      return 'Ingrese un costo válido';
    }
    return null;
  }

  String? _validateSalePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El precio de venta es requerido';
    }
    final price = double.tryParse(value);
    if (price == null || price < 0) {
      return 'Ingrese un precio válido';
    }
    return null;
  }

  Future<void> _handleConfirm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final product = Product(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          sku: _skuController.text.trim(),
          shortDescription: _shortDescriptionController.text.trim().isEmpty
              ? null
              : _shortDescriptionController.text.trim(),
          providerId: _selectedProviderId,
          providerName: _selectedProviderName,
          unit: _unitController.text.trim().isEmpty ? null : _unitController.text.trim(),
          unitOfMeasurement: _selectedUnitOfMeasurement,
          cost: double.parse(_costController.text.trim()),
          salePrice: double.parse(_salePriceController.text.trim()),
          imagePath: _selectedImage?.path,
        );

        final success = await _productService.saveProduct(product);

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Producto agregado exitosamente'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.of(context).pop(true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error al guardar el producto'),
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
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Add New Product',
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
                // Product Image
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 64,
                                color: AppColors.grey,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add Product Image',
                                style: TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 32),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Name',
                    prefixIcon: const Icon(Icons.inventory_2_outlined, color: AppColors.grey),
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
                  ),
                  validator: _validateName,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 20),

                // SKU
                TextFormField(
                  controller: _skuController,
                  decoration: InputDecoration(
                    hintText: 'SKU',
                    prefixIcon: const Icon(Icons.qr_code_outlined, color: AppColors.grey),
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
                  ),
                  validator: _validateSKU,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 20),

                // Short Description
                TextFormField(
                  controller: _shortDescriptionController,
                  decoration: InputDecoration(
                    hintText: 'Short Description',
                    prefixIcon: const Icon(Icons.description_outlined, color: AppColors.grey),
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
                  ),
                  textInputAction: TextInputAction.next,
                  maxLines: 2,
                ),

                const SizedBox(height: 20),

                // Provider Dropdown
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightGrey),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedProviderId,
                    decoration: InputDecoration(
                      hintText: 'Provider',
                      prefixIcon: const Icon(Icons.grid_view_outlined, color: AppColors.grey),
                      suffixIcon: const Icon(Icons.arrow_drop_down, color: AppColors.grey),
                      filled: true,
                      fillColor: AppColors.white,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Select Provider', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                      ..._providers.map((provider) {
                        return DropdownMenuItem<String>(
                          value: provider.id,
                          child: Text(provider.companyName),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedProviderId = value;
                        if (value != null) {
                          final provider = _providers.firstWhere((p) => p.id == value);
                          _selectedProviderName = provider.companyName;
                        } else {
                          _selectedProviderName = null;
                        }
                      });
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Unit
                TextFormField(
                  controller: _unitController,
                  decoration: InputDecoration(
                    hintText: 'Unit',
                    prefixIcon: const Icon(Icons.inventory_2_outlined, color: AppColors.grey),
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
                  ),
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 20),

                // Unit of Measurement Dropdown
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightGrey),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnitOfMeasurement,
                    decoration: InputDecoration(
                      hintText: 'Unit of Measurement',
                      prefixIcon: const Icon(Icons.straighten_outlined, color: AppColors.grey),
                      suffixIcon: const Icon(Icons.arrow_drop_down, color: AppColors.grey),
                      filled: true,
                      fillColor: AppColors.white,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Select Unit', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                      ..._unitsOfMeasurement.map((unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(unit),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedUnitOfMeasurement = value;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Cost
                TextFormField(
                  controller: _costController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'Cost',
                    prefixIcon: const Icon(Icons.attach_money, color: AppColors.grey),
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
                  ),
                  validator: _validateCost,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 20),

                // Sale Price
                TextFormField(
                  controller: _salePriceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'Sale Price',
                    prefixIcon: const Icon(Icons.attach_money, color: AppColors.grey),
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
                  ),
                  validator: _validateSalePrice,
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
}
