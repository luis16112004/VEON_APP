import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../config/fastapi_config.dart';
import 'fastapi_auth_service.dart';

class CategoryService {
  static CategoryService? _instance;
  final FastApiAuthService _authService = FastApiAuthService.instance;

  CategoryService._();

  static CategoryService get instance {
    _instance ??= CategoryService._();
    return _instance!;
  }

  /// Obtener todas las categorías
  Future<List<Category>> getCategories() async {
    if (!FastApiConfig.isFastApiEnabled) {
      throw Exception('FastAPI no está habilitado');
    }

    try {
      // Asegurar que hay autenticación antes de hacer la petición
      final isAuth = await _authService.ensureAuthenticated();
      if (!isAuth) {
        throw Exception('No se pudo autenticar con FastAPI');
      }
      
      print('📦 Obteniendo categorías de FastAPI: ${FastApiConfig.baseUrl}/categories');
      final response = await http.get(
        Uri.parse('${FastApiConfig.baseUrl}/categories'),
        headers: _authService.getHeaders(),
      );

      print('📡 Respuesta categorías: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ Categorías obtenidas: ${data.length}');
        return data.map((json) => Category.fromJson(json)).toList();
      } else {
        String errorMessage = 'Error obteniendo categorías';
        try {
          final errorBody = jsonDecode(response.body);
          errorMessage = errorBody['detail'] ?? errorBody['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = 'Error ${response.statusCode}: ${response.body}';
        }
        print('❌ Error obteniendo categorías: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Error obteniendo categorías: $e');
      rethrow;
    }
  }

  /// Obtener una categoría por ID
  Future<Category?> getCategoryById(int id) async {
    if (!FastApiConfig.isFastApiEnabled) {
      throw Exception('FastAPI no está habilitado');
    }

    try {
      final isAuth = await _authService.ensureAuthenticated();
      if (!isAuth) {
        throw Exception('No se pudo autenticar con FastAPI');
      }
      
      final response = await http.get(
        Uri.parse('${FastApiConfig.baseUrl}/categories/$id'),
        headers: _authService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Category.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['detail'] ?? 'Error obteniendo categoría';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Error obteniendo categoría: $e');
      rethrow;
    }
  }

  /// Crear una nueva categoría (requiere rol admin)
  Future<Category> createCategory(Category category) async {
    if (!FastApiConfig.isFastApiEnabled) {
      throw Exception('FastAPI no está habilitado');
    }

    try {
      final isAuth = await _authService.ensureAuthenticated();
      if (!isAuth) {
        throw Exception('No se pudo autenticar con FastAPI');
      }
      
      final response = await http.post(
        Uri.parse('${FastApiConfig.baseUrl}/categories'),
        headers: _authService.getHeaders(),
        body: jsonEncode(category.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ Categoría creada exitosamente');
        return Category.fromJson(data);
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['detail'] ?? 'Error creando categoría';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Error creando categoría: $e');
      rethrow;
    }
  }

  /// Actualizar una categoría (requiere rol admin)
  Future<Category> updateCategory(int id, Category category) async {
    if (!FastApiConfig.isFastApiEnabled) {
      throw Exception('FastAPI no está habilitado');
    }

    try {
      final isAuth = await _authService.ensureAuthenticated();
      if (!isAuth) {
        throw Exception('No se pudo autenticar con FastAPI');
      }
      
      final response = await http.put(
        Uri.parse('${FastApiConfig.baseUrl}/categories/$id'),
        headers: _authService.getHeaders(),
        body: jsonEncode(category.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Categoría actualizada exitosamente');
        return Category.fromJson(data);
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['detail'] ?? 'Error actualizando categoría';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Error actualizando categoría: $e');
      rethrow;
    }
  }

  /// Eliminar una categoría (requiere rol admin)
  Future<bool> deleteCategory(int id) async {
    if (!FastApiConfig.isFastApiEnabled) {
      throw Exception('FastAPI no está habilitado');
    }

    try {
      final isAuth = await _authService.ensureAuthenticated();
      if (!isAuth) {
        throw Exception('No se pudo autenticar con FastAPI');
      }
      
      final response = await http.delete(
        Uri.parse('${FastApiConfig.baseUrl}/categories/$id'),
        headers: _authService.getHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Categoría eliminada exitosamente');
        return true;
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['detail'] ?? 'Error eliminando categoría';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Error eliminando categoría: $e');
      rethrow;
    }
  }
}


