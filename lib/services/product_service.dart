import 'package:veon_app/models/product.dart';
import 'package:veon_app/database/sync_service.dart';

class ProductService {
  static const String _collectionName = 'products';
  final _syncService = SyncService.instance;

  Future<List<Product>> getProducts() async {
    try {
      final docs = await _syncService.getDocuments(_collectionName);
      return docs.map((doc) => Product.fromJson(doc)).toList();
    } catch (e) {
      print('❌ Error obteniendo productos: $e');
      return [];
    }
  }

  /// Busca y devuelve un solo producto por su ID.
  Future<Product?> getProductById(String id) async {
    try {
      final doc = await _syncService.getDocument(_collectionName, id);
      return doc != null ? Product.fromJson(doc) : null;
    } catch (e) {
      print('ℹ️ Producto con ID $id no encontrado: $e');
      return null;
    }
  }

  Future<bool> saveProduct(Product product) async {
    try {
      await _syncService.saveDocument(_collectionName, product.toJson(),
          id: product.id);
      print('✅ Producto guardado: ${product.name}');
      return true;
    } catch (e) {
      print('❌ Error guardando producto: $e');
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    try {
      await _syncService.updateDocument(
          _collectionName, product.id, product.toJson());
      print('✅ Producto actualizado: ${product.name}');
      return true;
    } catch (e) {
      print('❌ Error actualizando producto: $e');
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await _syncService.deleteDocument(_collectionName, productId);
      print('✅ Producto eliminado: $productId');
      return true;
    } catch (e) {
      print('❌ Error eliminando producto: $e');
      return false;
    }
  }
}
