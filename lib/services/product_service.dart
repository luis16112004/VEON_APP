import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:veon_app/models/product.dart';
import 'package:veon_app/database/sync_service.dart';
import 'package:veon_app/config/fastapi_config.dart';
import 'package:veon_app/services/fastapi_auth_service.dart';

class ProductService {
  static const String _collectionName = 'products';
  final _syncService = SyncService.instance;
  final FastApiAuthService _authService = FastApiAuthService.instance;

  /// Obtener todos los productos
  Future<List<Product>> getProducts() async {
    if (FastApiConfig.isFastApiEnabled) {
      return _getProductsFromFastApi();
    } else {
      return _getProductsFromFirebase();
    }
  }

  Future<List<Product>> _getProductsFromFastApi() async {
    try {
      // Asegurar que hay autenticación antes de hacer la petición
      final isAuth = await _authService.ensureAuthenticated();
      if (!isAuth) {
        throw Exception('No se pudo autenticar con FastAPI');
      }

      print(
          '📦 Obteniendo productos de FastAPI: ${FastApiConfig.baseUrl}/products');
      final headers = _authService.getHeaders();
      print('🔑 Headers: ${headers.keys}');

      final response = await http.get(
        Uri.parse('${FastApiConfig.baseUrl}/products'),
        headers: headers,
      );

      print('📡 Respuesta productos: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ Productos obtenidos: ${data.length}');
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        String errorMessage = 'Error obteniendo productos';
        try {
          final errorBody = jsonDecode(response.body);
          errorMessage =
              errorBody['detail'] ?? errorBody['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = 'Error ${response.statusCode}: ${response.body}';
        }
        print('❌ Error obteniendo productos: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Error obteniendo productos desde FastAPI: $e');
      rethrow;
    }
  }

  Future<List<Product>> _getProductsFromFirebase() async {
    try {
      final docs = await _syncService.getDocuments(_collectionName);
      return docs.map((doc) => Product.fromJson(doc)).toList();
    } catch (e) {
      print('❌ Error obteniendo productos desde Firebase: $e');
      return [];
    }
  }

  /// Busca y devuelve un solo producto por su ID.
  Future<Product?> getProductById(dynamic id) async {
    if (FastApiConfig.isFastApiEnabled) {
      return _getProductByIdFromFastApi(id);
    } else {
      return _getProductByIdFromFirebase(id.toString());
    }
  }

  Future<Product?> _getProductByIdFromFastApi(dynamic id) async {
    try {
      final isAuth = await _authService.ensureAuthenticated();
      if (!isAuth) {
        throw Exception('No se pudo autenticar con FastAPI');
      }

      final int productId = id is int ? id : int.parse(id.toString());
      final response = await http.get(
        Uri.parse('${FastApiConfig.baseUrl}/products/$productId'),
        headers: _authService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Product.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['detail'] ?? 'Error obteniendo producto';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Error obteniendo producto desde FastAPI: $e');
      return null;
    }
  }

  Future<Product?> _getProductByIdFromFirebase(String id) async {
    try {
      final doc = await _syncService.getDocument(_collectionName, id);
      return doc != null ? Product.fromJson(doc) : null;
    } catch (e) {
      print('ℹ️ Producto con ID $id no encontrado: $e');
      return null;
    }
  }

  /// Buscar productos por nombre, SKU o categoría
  Future<List<Product>> searchProducts(String query) async {
    if (FastApiConfig.isFastApiEnabled) {
      try {
        final isAuth = await _authService.ensureAuthenticated();
        if (!isAuth) {
          throw Exception('No se pudo autenticar con FastAPI');
        }

        // FastAPI puede no tener endpoint de búsqueda, buscar localmente
        final products = await getProducts();
        final queryLower = query.toLowerCase();
        return products.where((product) {
          return product.name.toLowerCase().contains(queryLower) ||
              product.sku.toLowerCase().contains(queryLower) ||
              (product.categoryName?.toLowerCase().contains(queryLower) ??
                  false);
        }).toList();
      } catch (e) {
        print('❌ Error buscando productos: $e');
        return [];
      }
    } else {
      // Fallback a búsqueda local
      final products = await getProducts();
      final queryLower = query.toLowerCase();
      return products.where((product) {
        return product.name.toLowerCase().contains(queryLower) ||
            product.sku.toLowerCase().contains(queryLower) ||
            (product.categoryName?.toLowerCase().contains(queryLower) ?? false);
      }).toList();
    }
  }

  /// Validar que el SKU sea único
  Future<bool> isSkuUnique(String sku, {int? excludeProductId}) async {
    if (FastApiConfig.isFastApiEnabled) {
      try {
        final products = await getProducts();
        return !products.any((p) =>
            p.sku.toLowerCase() == sku.toLowerCase() &&
            (excludeProductId == null || p.id != excludeProductId));
      } catch (e) {
        print('❌ Error validando SKU único: $e');
        return false;
      }
    } else {
      try {
        final products = await getProducts();
        return !products.any((p) =>
            p.sku.toLowerCase() == sku.toLowerCase() &&
            (excludeProductId == null ||
                p.id.toString() != excludeProductId.toString()));
      } catch (e) {
        return false;
      }
    }
  }

  Future<bool> saveProduct(Product product) async {
    if (FastApiConfig.isFastApiEnabled) {
      return _saveProductToFastApi(product);
    } else {
      return _saveProductToFirebase(product);
    }
  }

  Future<bool> _saveProductToFastApi(Product product) async {
    try {
      final isAuth = await _authService.ensureAuthenticated();
      if (!isAuth) {
        throw Exception('No se pudo autenticar con FastAPI');
      }

      final response = await http.post(
        Uri.parse('${FastApiConfig.baseUrl}/products'),
        headers: _authService.getHeaders(),
        body: jsonEncode(product.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Producto guardado en FastAPI: ${product.name}');
        return true;
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['detail'] ?? 'Error guardando producto';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Error guardando producto en FastAPI: $e');
      rethrow;
    }
  }

  Future<bool> _saveProductToFirebase(Product product) async {
    try {
      await _syncService.saveDocument(_collectionName, product.toJson(),
          id: product.id?.toString());
      print('✅ Producto guardado en Firebase: ${product.name}');
      return true;
    } catch (e) {
      print('❌ Error guardando producto en Firebase: $e');
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    if (FastApiConfig.isFastApiEnabled) {
      return _updateProductInFastApi(product);
    } else {
      return _updateProductInFirebase(product);
    }
  }

  Future<bool> _updateProductInFastApi(Product product) async {
    if (product.id == null) {
      throw Exception('El producto debe tener un ID para actualizar');
    }

    try {
      final isAuth = await _authService.ensureAuthenticated();
      if (!isAuth) {
        throw Exception('No se pudo autenticar con FastAPI');
      }

      final response = await http.put(
        Uri.parse('${FastApiConfig.baseUrl}/products/${product.id}'),
        headers: _authService.getHeaders(),
        body: jsonEncode(product.toJson()),
      );

      if (response.statusCode == 200) {
        print('✅ Producto actualizado en FastAPI: ${product.name}');
        return true;
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage =
            errorBody['detail'] ?? 'Error actualizando producto';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Error actualizando producto en FastAPI: $e');
      rethrow;
    }
  }

  Future<bool> _updateProductInFirebase(Product product) async {
    try {
      await _syncService.updateDocument(
          _collectionName, product.id?.toString() ?? '', product.toJson());
      print('✅ Producto actualizado en Firebase: ${product.name}');
      return true;
    } catch (e) {
      print('❌ Error actualizando producto en Firebase: $e');
      return false;
    }
  }

  /// Actualizar stock directamente
  Future<bool> updateStock(int productId, int newStock) async {
    if (FastApiConfig.isFastApiEnabled) {
      try {
        final isAuth = await _authService.ensureAuthenticated();
        if (!isAuth) {
          throw Exception('No se pudo autenticar con FastAPI');
        }

        final response = await http.patch(
          Uri.parse('${FastApiConfig.baseUrl}/products/$productId/stock'),
          headers: _authService.getHeaders(),
          body: jsonEncode({'stock': newStock}),
        );

        if (response.statusCode == 200) {
          print('✅ Stock actualizado');
          return true;
        } else {
          final errorBody = jsonDecode(response.body);
          final errorMessage =
              errorBody['detail'] ?? 'Error actualizando stock';
          throw Exception(errorMessage);
        }
      } catch (e) {
        print('❌ Error actualizando stock: $e');
        return false;
      }
    } else {
      // Fallback: obtener producto, actualizar y guardar
      final product = await getProductById(productId);
      if (product != null) {
        final updatedProduct = product.copyWith(stock: newStock);
        return await updateProduct(updatedProduct);
      }
      return false;
    }
  }

  /// Disminuir stock (decrease-stock)
  Future<bool> decreaseStock(int productId, int quantity) async {
    if (FastApiConfig.isFastApiEnabled) {
      try {
        final isAuth = await _authService.ensureAuthenticated();
        if (!isAuth) {
          throw Exception('No se pudo autenticar con FastAPI');
        }

        final response = await http.post(
          Uri.parse(
              '${FastApiConfig.baseUrl}/products/$productId/decrease-stock'),
          headers: _authService.getHeaders(),
          body: jsonEncode({'quantity': quantity}),
        );

        if (response.statusCode == 200) {
          print('✅ Stock disminuido exitosamente');
          return true;
        } else {
          final errorBody = jsonDecode(response.body);
          final errorMessage =
              errorBody['detail'] ?? 'Error disminuyendo stock';
          throw Exception(errorMessage);
        }
      } catch (e) {
        print('❌ Error disminuyendo stock: $e');
        return false;
      }
    } else {
      // Fallback: obtener producto, actualizar y guardar
      final product = await getProductById(productId);
      if (product != null) {
        final newStock =
            (product.stock - quantity).clamp(0, double.infinity).toInt();
        final updatedProduct = product.copyWith(stock: newStock);
        return await updateProduct(updatedProduct);
      }
      return false;
    }
  }

  Future<bool> deleteProduct(dynamic productId) async {
    if (FastApiConfig.isFastApiEnabled) {
      return _deleteProductFromFastApi(productId);
    } else {
      return _deleteProductFromFirebase(productId.toString());
    }
  }

  Future<bool> _deleteProductFromFastApi(dynamic productId) async {
    try {
      final isAuth = await _authService.ensureAuthenticated();
      if (!isAuth) {
        throw Exception('No se pudo autenticar con FastAPI');
      }

      final int id =
          productId is int ? productId : int.parse(productId.toString());
      final response = await http.delete(
        Uri.parse('${FastApiConfig.baseUrl}/products/$id'),
        headers: _authService.getHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Producto eliminado de FastAPI');
        return true;
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['detail'] ?? 'Error eliminando producto';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Error eliminando producto de FastAPI: $e');
      return false;
    }
  }

  Future<bool> _deleteProductFromFirebase(String productId) async {
    try {
      await _syncService.deleteDocument(_collectionName, productId);
      print('✅ Producto eliminado de Firebase');
      return true;
    } catch (e) {
      print('❌ Error eliminando producto de Firebase: $e');
      return false;
    }
  }
}
