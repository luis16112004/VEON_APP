import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:veon_app/models/client.dart';
import 'package:veon_app/screens/auth/constants/colors.dart';
import 'package:veon_app/services/client_service.dart';

class EditClientScreen extends StatefulWidget {
  final Client client;
  const EditClientScreen({super.key, required this.client});

  @override
  State<EditClientScreen> createState() => _EditClientScreenState();
}

class _EditClientScreenState extends State<EditClientScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _companyNameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  final ClientService _clientService = ClientService();
  final ImagePicker _picker = ImagePicker();
  File? _image;

  bool _fullNameError = false;
  bool _phoneNumberError = false;
  bool _addressError = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.client.fullName);
    _companyNameController = TextEditingController(text: widget.client.companyName ?? '');
    _phoneNumberController = TextEditingController(text: widget.client.phoneNumber);
    _emailController = TextEditingController(text: widget.client.email);
    _addressController = TextEditingController(text: widget.client.address);
    if (widget.client.imagePath != null) {
      _image = File(widget.client.imagePath!);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _companyNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _validateFullName(String? v) {
    if (v == null || v.trim().isEmpty) { setState(()=>_fullNameError=true); return 'Full name is required'; }
    if (v.trim().length <= 2) { setState(()=>_fullNameError=true); return 'Name must be greater than 2 characters'; }
    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    if (!nameRegex.hasMatch(v.trim())) { setState(()=>_fullNameError=true); return 'Please enter a valid name'; }
    setState(()=>_fullNameError=false); return null;
  }
  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) { setState(()=>_phoneNumberError=true); return 'Phone number is required'; }
    final digitsOnly = v.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length != 10) { setState(()=>_phoneNumberError=true); return 'Phone number must be exactly 10 digits'; }
    setState(()=>_phoneNumberError=false); return null;
  }
  String? _validateAddress(String? v) {
    if (v == null || v.trim().isEmpty) { setState(()=>_addressError=true); return 'Address is required'; }
    if (v.trim().length < 5) { setState(()=>_addressError=true); return 'Address must have at least 5 characters'; }
    setState(()=>_addressError=false); return null;
  }

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, maxHeight: 800, maxWidth: 800, imageQuality: 85);
    if (x != null) {
      setState(() { _image = File(x.path); });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final updated = widget.client.copyWith(
      fullName: _fullNameController.text.trim(),
      companyName: _companyNameController.text.trim().isEmpty ? null : _companyNameController.text.trim(),
      phoneNumber: _phoneNumberController.text.trim(),
      address: _addressController.text.trim(),
      imagePath: _image?.path,
    );
    final ok = await _clientService.updateClient(updated);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Client updated successfully'), backgroundColor: AppColors.success));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error updating client'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.white), onPressed: ()=>Navigator.pop(context)),
        title: const Text('Edit Client', style: TextStyle(color: AppColors.white)),
        centerTitle: true,
        actions: const [SizedBox(width: 16)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
                    child: _image != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(_image!, fit: BoxFit.cover))
                        : const Icon(Icons.image_outlined, size: 64, color: AppColors.grey),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _fullNameController,
                  decoration: _decor('Full Name', _fullNameError, Icons.person_outline),
                  validator: _validateFullName,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _companyNameController,
                  decoration: _decor('Company Name (optional)', false, Icons.business_outlined),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: _decor('Phone Number', _phoneNumberError, Icons.phone_outlined),
                  validator: _validatePhone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  enabled: false, // campo no editable
                  decoration: _decor('Email (no editable)', false, Icons.email_outlined),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: _decor('Address', _addressError, Icons.location_on_outlined),
                  validator: _validateAddress,
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decor(String hint, bool isError, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.grey),
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isError ? AppColors.error : AppColors.lightGrey, width: isError ? 2 : 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isError ? AppColors.error : AppColors.lightGrey, width: isError ? 2 : 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isError ? AppColors.error : AppColors.primaryGreen, width: 2),
      ),
    );
  }
}



