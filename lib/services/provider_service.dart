import 'package:veon_app/models/provider.dart';
import 'package:veon_app/database/sync_service.dart';
import 'package:veon_app/config/api_config.dart';
import 'api_service.dart';

class ProviderService {
  static const String _collectionName = 'providers';
  final _syncService = SyncService.instance;
  final _apiService = ApiService();

  Future<List<Provider>> getProviders() async {
    try {
      // Si Laravel API está activo, usar Laravel
      if (ApiConfig.isLaravelEnabled) {
        final providersData = await _apiService.getProviders();
        return providersData.map((doc) => Provider.fromJson(_normalizeLaravelData(doc))).toList();
      }

      // Comportamiento original con Firebase
      final docs = await _syncService.getDocuments(_collectionName);
      return docs.map((doc) => Provider.fromJson(doc)).toList();
    } catch (e) {
      print('❌ Error obteniendo proveedores: $e');
      return [];
    }
  }

  Future<bool> saveProvider(Provider provider) async {
    try {
      // Si Laravel API está activo, usar Laravel
      if (ApiConfig.isLaravelEnabled) {
        // Convertir a formato que Laravel espera (snake_case)
        final data = _convertToLaravelFormat(provider);
        final response = await _apiService.createProvider(data);
        
        // Si Laravel devuelve un ID, actualizar el provider
        if (response['id'] != null) {
          // El ID ya está en el provider, no necesitamos actualizarlo
        }
        
        print('✅ Proveedor guardado en Laravel: ${provider.companyName}');
        return true;
      }

      // Comportamiento original con Firebase
      await _syncService.saveDocument(_collectionName, provider.toJson(),
          id: provider.id);
      print('✅ Proveedor guardado: ${provider.companyName}');
      return true;
    } catch (e) {
      print('❌ Error guardando proveedor: $e');
      return false;
    }
  }

  Future<bool> updateProvider(Provider provider) async {
    try {
      // Si Laravel API está activo, usar Laravel
      if (ApiConfig.isLaravelEnabled) {
        // Convertir a formato que Laravel espera (snake_case)
        final data = _convertToLaravelFormat(provider);
        await _apiService.updateProvider(provider.id, data);
        print('✅ Proveedor actualizado en Laravel: ${provider.companyName}');
        return true;
      }

      // Comportamiento original con Firebase
      await _syncService.updateDocument(
          _collectionName, provider.id, provider.toJson());
      print('✅ Proveedor actualizado: ${provider.companyName}');
      return true;
    } catch (e) {
      print('❌ Error actualizando proveedor: $e');
      return false;
    }
  }

  Future<bool> deleteProvider(String providerId) async {
    try {
      // Si Laravel API está activo, usar Laravel
      if (ApiConfig.isLaravelEnabled) {
        await _apiService.deleteProvider(providerId);
        print('✅ Proveedor eliminado en Laravel: $providerId');
        return true;
      }

      // Comportamiento original con Firebase
      await _syncService.deleteDocument(_collectionName, providerId);
      print('✅ Proveedor eliminado: $providerId');
      return true;
    } catch (e) {
      print('❌ Error eliminando proveedor: $providerId');
      return false;
    }
  }

  // Convertir datos de Laravel (snake_case) a formato de la app (camelCase)
  Map<String, dynamic> _normalizeLaravelData(Map<String, dynamic> data) {
    return {
      'id': data['id']?.toString() ?? data['id'],
      'companyName': data['company_name'] ?? data['companyName'],
      'contactName': data['contact_name'] ?? data['contactName'],
      'phoneNumber': data['phone_number'] ?? data['phoneNumber'],
      'email': data['email'],
      'address': data['address'],
      'postalCode': data['postal_code'] ?? data['postalCode'],
      'country': data['country'],
      'state': data['state'],
      'city': data['city'],
    };
  }

  // Convertir datos de la app (camelCase) a formato Laravel (snake_case)
  Map<String, dynamic> _convertToLaravelFormat(Provider provider) {
    return {
      'company_name': provider.companyName,
      'contact_name': provider.contactName,
      'phone_number': provider.phoneNumber,
      'email': provider.email,
      'address': provider.address,
      'postal_code': provider.postalCode,
      'country': provider.country,
      'state': provider.state,
      'city': provider.city,
    };
  }
}
