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
