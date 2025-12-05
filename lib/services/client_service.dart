import 'package:veon_app/models/client.dart';
import 'package:veon_app/database/sync_service.dart';

class ClientService {
  static const String _collectionName = 'clients';
  final _syncService = SyncService.instance;

  Future<List<Client>> getClients() async {
    try {
      final docs = await _syncService.getDocuments(_collectionName);
      return docs.map((doc) => Client.fromJson(doc)).toList();
    } catch (e) {
      print('❌ Error obteniendo clientes: $e');
      return [];
    }
  }

  /// Verificar si un correo ya existe
  Future<bool> isEmailUnique(String email, {String? excludeId}) async {
    try {
      final clients = await getClients();
      return !clients.any((c) => 
        c.email.toLowerCase() == email.toLowerCase() && 
        (excludeId == null || c.id != excludeId)
      );
    } catch (e) {
      print('❌ Error verificando correo único: $e');
      return false;
    }
  }

  Future<bool> saveClient(Client client) async {
    try {
      // Validar correo único
      final isUnique = await isEmailUnique(client.email);
      if (!isUnique) {
        throw Exception('El correo ${client.email} ya está registrado');
      }

      await _syncService.saveDocument(_collectionName, client.toJson(),
          id: client.id);
      print('✅ Cliente guardado: ${client.fullName}');
      return true;
    } catch (e) {
      print('❌ Error guardando cliente: $e');
      rethrow;
    }
  }

  Future<bool> updateClient(Client client) async {
    try {
      // Validar correo único (excluyendo el cliente actual)
      final isUnique = await isEmailUnique(client.email, excludeId: client.id);
      if (!isUnique) {
        throw Exception('El correo ${client.email} ya está registrado');
      }

      await _syncService.updateDocument(
          _collectionName, client.id, client.toJson());
      print('✅ Cliente actualizado: ${client.fullName}');
      return true;
    } catch (e) {
      print('❌ Error actualizando cliente: $e');
      rethrow;
    }
  }

  Future<bool> deleteClient(String clientId) async {
    try {
      await _syncService.deleteDocument(_collectionName, clientId);
      print('✅ Cliente eliminado: $clientId');
      return true;
    } catch (e) {
      print('❌ Error eliminando cliente: $e');
      return false;
    }
  }
}
