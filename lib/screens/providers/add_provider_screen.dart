import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:veon_app/models/provider.dart';
import 'package:veon_app/screens/auth/constants/colors.dart';
import 'package:veon_app/services/provider_service.dart';

class AddProviderScreen extends StatefulWidget {
  const AddProviderScreen({super.key});

  @override
  State<AddProviderScreen> createState() => _AddProviderScreenState();
}

class _AddProviderScreenState extends State<AddProviderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _postalCodeController = TextEditingController();

  String? _selectedCountry;
  String? _selectedState;
  String? _selectedCity;

  final ProviderService _providerService = ProviderService();

  final List<String> _countries = ['Mexico', 'United States', 'Canada', 'Spain', 'Colombia'];
  final Map<String, List<String>> _statesByCountry = {
    'Mexico': ['CDMX', 'Jalisco', 'Nuevo León', 'Puebla', 'Yucatán'],
    'United States': ['California', 'Texas', 'New York', 'Florida', 'Illinois'],
    'Canada': ['Ontario', 'Quebec', 'British Columbia', 'Alberta'],
    'Spain': ['Madrid', 'Catalonia', 'Andalusia', 'Valencia'],
    'Colombia': ['Bogotá', 'Antioquia', 'Valle del Cauca', 'Atlántico'],
  };
  final Map<String, List<String>> _citiesByState = {
    'CDMX': ['Cuauhtemoc', 'Benito Juárez', 'Miguel Hidalgo', 'Coyoacán'],
    'Jalisco': ['Guadalajara', 'Zapopan', 'Tlaquepaque'],
    'Nuevo León': ['Monterrey', 'San Pedro Garza García'],
    'Puebla': ['Puebla', 'Cholula'],
    'Yucatán': ['Mérida', 'Valladolid'],
    'California': ['Los Angeles', 'San Francisco', 'San Diego'],
    'Texas': ['Houston', 'Dallas', 'Austin'],
    'New York': ['New York City', 'Buffalo', 'Rochester'],
    'Florida': ['Miami', 'Tampa', 'Orlando'],
    'Illinois': ['Chicago', 'Aurora', 'Naperville'],
    'Ontario': ['Toronto', 'Ottawa', 'Mississauga'],
    'Quebec': ['Montreal', 'Quebec City'],
    'British Columbia': ['Vancouver', 'Victoria'],
    'Alberta': ['Calgary', 'Edmonton'],
    'Madrid': ['Madrid', 'Alcalá de Henares'],
    'Catalonia': ['Barcelona', 'Girona'],
    'Andalusia': ['Seville', 'Málaga'],
    'Valencia': ['Valencia', 'Alicante'],
    'Bogotá': ['Bogotá', 'Chía'],
    'Antioquia': ['Medellín', 'Bello'],
    'Valle del Cauca': ['Cali', 'Palmira'],
    'Atlántico': ['Barranquilla', 'Soledad'],
  };

  @override
  void dispose() {
    _companyNameController.dispose();
    _contactNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  String? _validateCompanyName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Company name is required';
    }
    if (value.trim().length <= 2) {
      return 'Name must be greater than 2 characters';
    }
    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Please enter a valid name';
    }
    return null;
  }

  String? _validateContactName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Contact name is required';
    }
    if (value.trim().length <= 2) {
      return 'Name must be greater than 2 characters';
    }
    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Please enter a valid name';
    }
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length != 10) {
      return 'Phone number must be exactly 10 digits';
    }
    return null;
  }

  bool _isValidatingEmail = false;
  String? _emailErrorMessage;

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      setState(() {
        _emailErrorMessage = 'Email is required';
      });
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      setState(() {
        _emailErrorMessage = 'Please enter a valid email';
      });
      return 'Please enter a valid email';
    }
    
    // Si hay un mensaje de error de unicidad, mantenerlo
    if (_emailErrorMessage == 'Este correo ya está registrado') {
      return _emailErrorMessage;
    }
    
    setState(() {
      _emailErrorMessage = null;
    });
    return null;
  }

  Future<void> _validateEmailUniqueness(String email) async {
    if (email.trim().isEmpty) return;
    
    setState(() => _isValidatingEmail = true);
    try {
      final isUnique = await _providerService.isEmailUnique(email.trim());
      setState(() {
        _isValidatingEmail = false;
        if (!isUnique) {
          _emailErrorMessage = 'Este correo ya está registrado';
        } else {
          _emailErrorMessage = null;
        }
      });
    } catch (e) {
      setState(() {
        _isValidatingEmail = false;
      });
    }
  }

  String? _validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }
    if (value.trim().length < 5) {
      return 'Address must have at least 5 characters';
    }
    return null;
  }

  String? _validatePostalCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Postal code is required';
    }
    return null;
  }

  Future<void> _handleContinue() async {
    // Validar unicidad del correo antes de guardar
    await _validateEmailUniqueness(_emailController.text);
    
    if (_formKey.currentState!.validate() && _emailErrorMessage == null) {
      try {
        final provider = Provider(
          id: const Uuid().v4(),
          companyName: _companyNameController.text.trim(),
          contactName: _contactNameController.text.trim(),
          phoneNumber: _phoneNumberController.text.trim(),
          email: _emailController.text.trim(),
          address: _addressController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
          country: _selectedCountry ?? '',
          state: _selectedState ?? '',
          city: _selectedCity ?? '',
        );

        final success = await _providerService.saveProvider(provider);

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Provider added successfully'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.of(context).pop(true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error saving provider'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          final errorMessage = e.toString().replaceFirst('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
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
          'Add New Provider',
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
                // Company Name
                TextFormField(
                  controller: _companyNameController,
                  decoration: _inputDecoration('Company Name', Icons.business_outlined),
                  validator: _validateCompanyName,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 20),

                // Contact Name
                TextFormField(
                  controller: _contactNameController,
                  decoration: _inputDecoration('Contact Name', Icons.person_outline),
                  validator: _validateContactName,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 20),

                // Phone Number
                TextFormField(
                  controller: _phoneNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration('Phone Number', Icons.phone_outlined),
                  validator: _validatePhoneNumber,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 20),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    'Email',
                    Icons.email_outlined,
                    suffixIcon: _isValidatingEmail
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ).copyWith(
                    errorText: _emailErrorMessage,
                  ),
                  validator: _validateEmail,
                  textInputAction: TextInputAction.next,
                  onChanged: (value) {
                    _validateEmail(value);
                    // Validar unicidad después de un breve delay
                    if (value.trim().isNotEmpty) {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (_emailController.text == value) {
                          _validateEmailUniqueness(value);
                        }
                      });
                    }
                  },
                ),

                const SizedBox(height: 20),

                // Address
                TextFormField(
                  controller: _addressController,
                  decoration: _inputDecoration('Address', Icons.location_on_outlined),
                  validator: _validateAddress,
                  textInputAction: TextInputAction.next,
                  maxLines: 2,
                ),

                const SizedBox(height: 20),

                // Postal Code
                TextFormField(
                  controller: _postalCodeController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Postal Code', Icons.pin_outlined),
                  validator: _validatePostalCode,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 20),

                // Country Dropdown
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightGrey),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedCountry,
                    decoration: InputDecoration(
                      hintText: 'Country',
                      prefixIcon: const Icon(Icons.public_outlined, color: AppColors.grey),
                      suffixIcon: const Icon(Icons.arrow_drop_down, color: AppColors.grey),
                      filled: true,
                      fillColor: AppColors.white,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    items: _countries.map((country) {
                      return DropdownMenuItem<String>(
                        value: country,
                        child: Text(country),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCountry = value;
                        _selectedState = null;
                        _selectedCity = null;
                      });
                    },
                    validator: (value) => value == null ? 'Country is required' : null,
                  ),
                ),

                const SizedBox(height: 20),

                // State Dropdown
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightGrey),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedState,
                    decoration: InputDecoration(
                      hintText: 'State',
                      prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.grey),
                      suffixIcon: const Icon(Icons.arrow_drop_down, color: AppColors.grey),
                      filled: true,
                      fillColor: AppColors.white,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    items: _selectedCountry != null && _statesByCountry.containsKey(_selectedCountry)
                        ? _statesByCountry[_selectedCountry]!.map((state) {
                            return DropdownMenuItem<String>(
                              value: state,
                              child: Text(state),
                            );
                          }).toList()
                        : [],
                    onChanged: (value) {
                      setState(() {
                        _selectedState = value;
                        _selectedCity = null;
                      });
                    },
                    validator: (value) => value == null ? 'State is required' : null,
                  ),
                ),

                const SizedBox(height: 20),

                // City Dropdown
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightGrey),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedCity,
                    decoration: InputDecoration(
                      hintText: 'City',
                      prefixIcon: const Icon(Icons.location_city_outlined, color: AppColors.grey),
                      suffixIcon: const Icon(Icons.arrow_drop_down, color: AppColors.grey),
                      filled: true,
                      fillColor: AppColors.white,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    items: _selectedState != null && _citiesByState.containsKey(_selectedState)
                        ? _citiesByState[_selectedState]!.map((city) {
                            return DropdownMenuItem<String>(
                              value: city,
                              child: Text(city),
                            );
                          }).toList()
                        : [],
                    onChanged: (value) {
                      setState(() {
                        _selectedCity = value;
                      });
                    },
                    validator: (value) => value == null ? 'City is required' : null,
                  ),
                ),

                const SizedBox(height: 32),

                // Continue Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Continue',
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

  InputDecoration _inputDecoration(String hint, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.grey),
      suffixIcon: suffixIcon,
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
