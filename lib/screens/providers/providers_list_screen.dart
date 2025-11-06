import 'package:flutter/material.dart';
import 'package:veon_app/models/provider.dart';
import 'package:veon_app/screens/auth/constants/colors.dart';
import 'package:veon_app/screens/providers/add_provider_screen.dart';
import 'package:veon_app/screens/providers/edit_provider_screen.dart';
import 'package:veon_app/services/provider_service.dart';

class ProvidersListScreen extends StatefulWidget {
  const ProvidersListScreen({super.key});

  @override
  State<ProvidersListScreen> createState() => _ProvidersListScreenState();
}

class _ProvidersListScreenState extends State<ProvidersListScreen> {
  final ProviderService _providerService = ProviderService();
  List<Provider> _providers = [];
  List<Provider> _filteredProviders = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProviders();
    _searchController.addListener(_filterProviders);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProviders() async {
    setState(() => _isLoading = true);
    try {
      final providers = await _providerService.getProviders();
      setState(() {
        _providers = providers;
        _filteredProviders = providers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading providers: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _filterProviders() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProviders = _providers;
      } else {
        _filteredProviders = _providers.where((provider) {
          return provider.companyName.toLowerCase().contains(query) ||
              provider.contactName.toLowerCase().contains(query) ||
              provider.email.toLowerCase().contains(query) ||
              provider.phoneNumber.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _navigateToAddProvider() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProviderScreen(),
      ),
    );

    if (result == true) {
      _loadProviders();
    }
  }

  Future<void> _navigateToEditProvider(Provider provider) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProviderScreen(provider: provider),
      ),
    );
    if (changed == true) {
      _loadProviders();
    }
  }

  Future<void> _deleteProvider(Provider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Provider'),
        content: Text('Are you sure you want to delete ${provider.companyName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _providerService.deleteProvider(provider.id);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Provider deleted successfully'),
                backgroundColor: AppColors.success,
              ),
            );
            _loadProviders();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error deleting provider'),
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
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'All Providers',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Image.asset(
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
                ],
              ),
            ),

            // Search Bar and Add Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search provider...',
                          hintStyle: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.grey,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.add,
                        color: AppColors.white,
                        size: 28,
                      ),
                      onPressed: _navigateToAddProvider,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Providers List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryGreen,
                      ),
                    )
                  : _filteredProviders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_shipping_outlined,
                                size: 64,
                                color: AppColors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _providers.isEmpty
                                    ? 'No providers registered'
                                    : 'No providers found',
                                style: TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadProviders,
                          color: AppColors.primaryGreen,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            itemCount: _filteredProviders.length,
                            itemBuilder: (context, index) {
                              final provider = _filteredProviders[index];
                              return _buildProviderCard(provider);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(Provider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Provider Logo
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                provider.companyName
                    .split(' ')
                    .take(2)
                    .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
                    .join(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Provider Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.companyName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  provider.contactName,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${provider.city}, ${provider.state}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Edit Button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.white,
                    size: 20,
                  ),
                  onPressed: () => _navigateToEditProvider(provider),
                ),
              ),
              const SizedBox(width: 8),
              // Delete Button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.darkBlue,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.white,
                    size: 20,
                  ),
                  onPressed: () => _deleteProvider(provider),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}