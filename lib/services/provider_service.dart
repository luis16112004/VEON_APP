import 'package:veon_app/models/provider.dart';
import 'package:veon_app/database/sync_service.dart';

class ProviderService {
  static const String _collectionName = 'providers';
  final _syncService = SyncService.instance;

  Future<List<Provider>> getProviders() async {
    try {
      final docs = await _syncService.getDocuments(_collectionName);
      return docs.map((doc) => Provider.fromJson(doc)).toList();
    } catch (e) {
      print('❌ Error obteniendo proveedores: $e');
      return [];
    }
  }

  Future<bool> saveProvider(Provider provider) async {
    try {
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
      await _syncService.deleteDocument(_collectionName, providerId);
      print('✅ Proveedor eliminado: $providerId');
      return true;
    } catch (e) {
      print('❌ Error eliminando proveedor: $e');
      return false;
    }
  }
}
