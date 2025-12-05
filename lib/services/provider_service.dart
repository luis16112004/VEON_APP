import 'package:veon_app/models/provider.dart';
import 'package:veon_app/database/sync_service.dart';

class ProviderService {
  static const String _collectionName = 'providers';
  final _syncService = SyncService.instance;

  Future<List<Provider>> getProviders() async {
    try {
      // Usar Firebase directamente
      final docs = await _syncService.getDocuments(_collectionName);
      return docs.map((doc) => Provider.fromJson(doc)).toList();
    } catch (e) {
      print('❌ Error obteniendo proveedores: $e');
      return [];
    }
  }

  /// Verificar si un correo ya existe
  Future<bool> isEmailUnique(String email, {String? excludeId}) async {
    try {
      final providers = await getProviders();
      return !providers.any((p) => 
        p.email.toLowerCase() == email.toLowerCase() && 
        (excludeId == null || p.id != excludeId)
      );
    } catch (e) {
      print('❌ Error verificando correo único: $e');
      return false;
    }
  }

  Future<bool> saveProvider(Provider provider) async {
    try {
      // Validar correo único
      final isUnique = await isEmailUnique(provider.email);
      if (!isUnique) {
        throw Exception('El correo ${provider.email} ya está registrado');
      }

      // Usar Firebase directamente
      await _syncService.saveDocument(_collectionName, provider.toJson(),
          id: provider.id);
      print('✅ Proveedor guardado: ${provider.companyName}');
      return true;
    } catch (e) {
      print('❌ Error guardando proveedor: $e');
      rethrow;
    }
  }

  Future<bool> updateProvider(Provider provider) async {
    try {
      // Validar correo único (excluyendo el proveedor actual)
      final isUnique = await isEmailUnique(provider.email, excludeId: provider.id);
      if (!isUnique) {
        throw Exception('El correo ${provider.email} ya está registrado');
      }

      // Usar Firebase directamente
      await _syncService.updateDocument(
          _collectionName, provider.id, provider.toJson());
      print('✅ Proveedor actualizado: ${provider.companyName}');
      return true;
    } catch (e) {
      print('❌ Error actualizando proveedor: $e');
      rethrow;
    }
  }

  Future<bool> deleteProvider(String providerId) async {
    try {
      // Usar Firebase directamente
      await _syncService.deleteDocument(_collectionName, providerId);
      print('✅ Proveedor eliminado: $providerId');
      return true;
    } catch (e) {
      print('❌ Error eliminando proveedor: $providerId');
      return false;
    }
  }

}
