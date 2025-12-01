import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veon_app/models/product.dart';

class ProductService {
  static const String _productsKey = 'products';

  Future<List<Product>> getProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final productsJson = prefs.getString(_productsKey);

      if (productsJson == null) {
        return [];
      }

      final List<dynamic> productsList = json.decode(productsJson);
      return productsList.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // =================================================================
  // ===           👇 MÉTODO NUEVO Y CORREGIDO AÑADIDO AQUÍ 👇         ===
  // =================================================================

  /// Busca y devuelve un solo producto por su ID.
  Future<Product?> getProductById(String id) async {
    try {
      // 1. Obtiene la lista completa de productos.
      final products = await getProducts();

      // 2. Busca en la lista el primer producto que coincida con el ID.
      // Usa 'firstWhere' dentro de un try-catch para manejar el caso de que no se encuentre.
      return products.firstWhere((product) => product.id == id);
    } catch (e) {
      // Si 'firstWhere' no encuentra ningún elemento, lanza un error.
      // Capturamos ese error y devolvemos null, indicando que no se encontró el producto.
      print('ℹ️ Producto con ID $id no encontrado.');
      return null;
    }
  }

  Future<bool> saveProduct(Product product) async {
    try {
      final products = await getProducts();
      products.add(product);

      final prefs = await SharedPreferences.getInstance();
      final productsJson = json.encode(
        products.map((p) => p.toJson()).toList(),
      );

      return await prefs.setString(_productsKey, productsJson);
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    try {
      final products = await getProducts();
      final index = products.indexWhere((p) => p.id == product.id);

      if (index == -1) {
        // Si el producto no existe, podrías optar por guardarlo como nuevo
        // o simplemente devolver false.
        print('⚠️ Producto con ID ${product.id} no encontrado para actualizar.');
        return false;
      }

      products[index] = product;

      final prefs = await SharedPreferences.getInstance();
      final productsJson = json.encode(
        products.map((p) => p.toJson()).toList(),
      );

      return await prefs.setString(_productsKey, productsJson);
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      final products = await getProducts();
      products.removeWhere((p) => p.id == productId);

      final prefs = await SharedPreferences.getInstance();
      final productsJson = json.encode(
        products.map((p) => p.toJson()).toList(),
      );

      return await prefs.setString(_productsKey, productsJson);
    } catch (e) {
      return false;
    }
  }
}
