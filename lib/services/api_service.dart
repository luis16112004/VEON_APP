import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  // URL base - se obtiene de la configuración
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }
   ApiService._internal();
  // ----------------------------------------------------

  String get baseUrl => ApiConfig.baseUrl;

  // Token de autenticación (se guarda después del login)
  String? _authToken;

  // --- AUTENTICACIÓN ---

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('Intentando login en: $baseUrl/login');
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('Login Status: ${response.statusCode}');
      print('Login Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          // Guardar el token si viene en la respuesta
          if (data['token'] != null || data['access_token'] != null) {
            _authToken = data['token'] ?? data['access_token'];
          }
          return data; // Retorna el token y datos
        } catch (e) {
          throw Exception('Error al procesar respuesta JSON: $e');
        }
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage =
              errorBody['message'] ?? errorBody['error'] ?? 'Falló el login';
          throw Exception(errorMessage);
        } catch (_) {
          throw Exception(
              'Error del servidor (${response.statusCode}): ${response.body}');
        }
      }
    } catch (e) {
      print('Excepción en login: $e');
      rethrow;
    }

  }

  // Actualizar perfil (nombre)
  Future<Map<String, dynamic>> updateUser(String id, String name, String email) async {
    try {
      // Nota: El backend actual solo actualiza el nombre en /update-profile
      final response = await http.post(
        Uri.parse('$baseUrl/update-profile'),
        headers: _getHeaders(),
        body: jsonEncode({'name': name}),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return data;
        } catch (e) {
          throw Exception('Error al procesar respuesta JSON: $e');
        }
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['message'] ??
              errorBody['error'] ??
              'Error actualizando perfil';
          throw Exception(errorMessage);
        } catch (_) {
          throw Exception(
              'Error del servidor (${response.statusCode}): ${response.body}');
        }
      }
    } catch (e) {
      print('Excepción en updateUser: $e');
      rethrow;
    }
  }

  // Cambiar contraseña
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/change-password'),
        headers: _getHeaders(),
        body: jsonEncode({
          'password': newPassword, // El backend espera 'password'
        }),
      );

      if (response.statusCode != 200) {
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['message'] ??
              errorBody['error'] ??
              'Error cambiando contraseña';
          throw Exception(errorMessage);
        } catch (_) {
          throw Exception(
              'Error del servidor (${response.statusCode}): ${response.body}');
        }
      }
    } catch (e) {
      print('Excepción en changePassword: $e');
      rethrow;
    }
  }

  // Eliminar usuario
  Future<void> deleteUser(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/delete-account'),
        headers: _getHeaders(),
        body: jsonEncode({'confirmation': 'eliminarcuenta'}),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['message'] ??
              errorBody['error'] ??
              'Error eliminando usuario';
          throw Exception(errorMessage);
        } catch (_) {
          throw Exception(
              'Error del servidor (${response.statusCode}): ${response.body}');
        }
      }
    } catch (e) {
      print('Excepción en deleteUser: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register(
      String name, String email, String password, {String role = 'vendedor'}) async {
    try {
      print('Intentando registro en: $baseUrl/register');
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password, 'role': role}),
      );

      print('Register Status: ${response.statusCode}');
      print('Register Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          // Guardar el token si viene en la respuesta
          if (data['token'] != null || data['access_token'] != null) {
            _authToken = data['token'] ?? data['access_token'];
          }
          return data;
        } catch (e) {
          throw Exception('Error al procesar respuesta JSON: $e');
        }
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage =
              errorBody['message'] ?? errorBody['error'] ?? 'Falló el registro';
          throw Exception(errorMessage);
        } catch (_) {
          throw Exception(
              'Error del servidor (${response.statusCode}): ${response.body}');
        }
      }
    } catch (e) {
      print('Excepción en registro: $e');
      rethrow;
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

  // --- USUARIOS ---

  Future<List<dynamic>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'), // Asegúrate de tener esta ruta en Laravel
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data is List) return data;
          if (data['data'] != null) return data['data'];
          return [];
        } catch (e) {
          throw Exception('Error al procesar usuarios: $e');
        }
      } else {
        throw Exception('Error cargando usuarios: ${response.statusCode}');
      }
    } catch (e) {
      print('Excepción en getUsers: $e');
      rethrow;
    }
  }

  // --- CRUD PROVEEDORES ---

  // 1. GET (Index)
  Future<List<dynamic>> getProviders() async {
    try {
      print('Obteniendo proveedores de: $baseUrl/providers');
      final response = await http.get(
        Uri.parse('$baseUrl/providers'),
        headers: _getHeaders(),
      );

      print('GetProviders Status: ${response.statusCode}');
      print('GetProviders Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          // Laravel puede devolver los datos directamente o dentro de 'data'
          if (data is List) {
            return data;
          } else if (data['data'] != null) {
            return data['data'] as List;
          }
          return [data];
        } catch (e) {
          throw Exception('Error al procesar respuesta JSON de proveedores: $e');
        }
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['message'] ??
              errorBody['error'] ??
              'Error cargando proveedores';
          throw Exception(errorMessage);
        } catch (_) {
          throw Exception(
              'Error del servidor (${response.statusCode}): ${response.body}');
        }
      }
    } catch (e) {
      print('Excepción en getProviders: $e');
      rethrow;
    }
  }

  // 2. GET (Show) - Obtener un proveedor por ID
  Future<Map<String, dynamic>> getProvider(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/providers/$id'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return data['data'] ?? data;
        } catch (e) {
          throw Exception('Error al procesar respuesta JSON: $e');
        }
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['message'] ??
              errorBody['error'] ??
              'Error obteniendo proveedor';
          throw Exception(errorMessage);
        } catch (_) {
          throw Exception(
              'Error del servidor (${response.statusCode}): ${response.body}');
        }
      }
    } catch (e) {
      print('Excepción en getProvider: $e');
      rethrow;
    }
  }

  // 3. POST (Store)
  Future<Map<String, dynamic>> createProvider(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/providers'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          return responseData['data'] ?? responseData;
        } catch (e) {
          throw Exception('Error al procesar respuesta JSON: $e');
        }
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['message'] ??
              errorBody['error'] ??
              'Error creando proveedor';
          throw Exception(errorMessage);
        } catch (_) {
          throw Exception(
              'Error del servidor (${response.statusCode}): ${response.body}');
        }
      }
    } catch (e) {
      print('Excepción en createProvider: $e');
      rethrow;
    }
  }

  // 4. PUT (Update)
  Future<Map<String, dynamic>> updateProvider(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/providers/$id'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          return responseData['data'] ?? responseData;
        } catch (e) {
          throw Exception('Error al procesar respuesta JSON: $e');
        }
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['message'] ??
              errorBody['error'] ??
              'Error actualizando proveedor';
          throw Exception(errorMessage);
        } catch (_) {
          throw Exception(
              'Error del servidor (${response.statusCode}): ${response.body}');
        }
      }
    } catch (e) {
      print('Excepción en updateProvider: $e');
      rethrow;
    }
  }

  // 5. DELETE (Destroy)
  Future<void> deleteProvider(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/providers/$id'),
        headers: _getHeaders(),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['message'] ??
              errorBody['error'] ??
              'Error eliminando proveedor';
          throw Exception(errorMessage);
        } catch (_) {
          throw Exception(
              'Error del servidor (${response.statusCode}): ${response.body}');
        }
      }
    } catch (e) {
      print('Excepción en deleteProvider: $e');
      rethrow;
    }
  }

  // Limpiar token (para logout)
  void clearToken() {
    _authToken = null;
  }
}
