import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  // URL base - se obtiene de la configuración
  String get baseUrl => ApiConfig.baseUrl;

  // Token de autenticación (se guarda después del login)
  String? _authToken;

  // --- AUTENTICACIÓN ---

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Guardar el token si viene en la respuesta
      if (data['token'] != null || data['access_token'] != null) {
        _authToken = data['token'] ?? data['access_token'];
      }
      return data; // Retorna el token y datos
    } else {
      final errorBody = jsonDecode(response.body);
      final errorMessage =
          errorBody['message'] ?? errorBody['error'] ?? 'Falló el login';
      throw Exception(errorMessage);
    }
  }

  Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Guardar el token si viene en la respuesta
      if (data['token'] != null || data['access_token'] != null) {
        _authToken = data['token'] ?? data['access_token'];
      }
      return data;
    } else {
      final errorBody = jsonDecode(response.body);
      final errorMessage =
          errorBody['message'] ?? errorBody['error'] ?? 'Falló el registro';
      throw Exception(errorMessage);
    }
  }

  // Obtener headers con autenticación
  Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // --- CRUD PROVEEDORES ---

  // 1. GET (Index)
  Future<List<dynamic>> getProviders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/providers'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Laravel puede devolver los datos directamente o dentro de 'data'
      if (data is List) {
        return data;
      } else if (data['data'] != null) {
        return data['data'] as List;
      }
      return [data];
    } else {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ??
          errorBody['error'] ??
          'Error cargando proveedores';
      throw Exception(errorMessage);
    }
  }

  // 2. GET (Show) - Obtener un proveedor por ID
  Future<Map<String, dynamic>> getProvider(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/providers/$id'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? data;
    } else {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ??
          errorBody['error'] ??
          'Error obteniendo proveedor';
      throw Exception(errorMessage);
    }
  }

  // 3. POST (Store)
  Future<Map<String, dynamic>> createProvider(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/providers'),
      headers: _getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['data'] ?? responseData;
    } else {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ??
          errorBody['error'] ??
          'Error creando proveedor';
      throw Exception(errorMessage);
    }
  }

  // 4. PUT (Update)
  Future<Map<String, dynamic>> updateProvider(
      String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/providers/$id'),
      headers: _getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['data'] ?? responseData;
    } else {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ??
          errorBody['error'] ??
          'Error actualizando proveedor';
      throw Exception(errorMessage);
    }
  }

  // 5. DELETE (Destroy)
  Future<void> deleteProvider(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/providers/$id'),
      headers: _getHeaders(),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ??
          errorBody['error'] ??
          'Error eliminando proveedor';
      throw Exception(errorMessage);
    }
  }

  // Limpiar token (para logout)
  void clearToken() {
    _authToken = null;
  }
}
