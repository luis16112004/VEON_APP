import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/fastapi_config.dart';

/// Servicio de autenticación para FastAPI
/// Maneja login y almacenamiento de token JWT
class FastApiAuthService {
  static FastApiAuthService? _instance;
  String? _authToken;

  FastApiAuthService._();

  static FastApiAuthService get instance {
    _instance ??= FastApiAuthService._();
    return _instance!;
  }

  /// Obtener token de autenticación
  String? get token => _authToken;

  /// Verificar si hay un token válido
  bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;

  /// Login con username y password
  /// Usuarios de prueba según la documentación:
  /// - Admin: username='admin', password='admin123'
  /// - Usuario: username='user', password='user123'
  Future<bool> login(String username, String password) async {
    try {
      print('🔐 Intentando autenticar en FastAPI: ${FastApiConfig.baseUrl}/auth/login');
      
      // Intentar primero con JSON
      var response = await http.post(
        Uri.parse('${FastApiConfig.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      // Si falla con JSON, intentar con form-data
      if (response.statusCode != 200) {
        print('⚠️ Login con JSON falló, intentando con form-data...');
        response = await http.post(
          Uri.parse('${FastApiConfig.baseUrl}/auth/login'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: 'username=${Uri.encodeComponent(username)}&password=${Uri.encodeComponent(password)}',
        );
      }

      print('📡 Respuesta FastAPI: ${response.statusCode}');
      print('📄 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // FastAPI puede devolver 'access_token' o 'token'
        _authToken = data['access_token'] as String? ?? 
                     data['token'] as String? ?? 
                     data['accessToken'] as String?;
        
        if (_authToken != null && _authToken!.isNotEmpty) {
          print('✅ Login exitoso en FastAPI - Token obtenido');
          return true;
        } else {
          print('⚠️ Login exitoso pero no se obtuvo token. Respuesta: $data');
          return false;
        }
      } else {
        String errorMessage = 'Error en login';
        try {
          final errorBody = jsonDecode(response.body);
          errorMessage = errorBody['detail'] ?? errorBody['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = 'Error ${response.statusCode}: ${response.body}';
        }
        print('❌ Error en login: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Error en login FastAPI: $e');
      rethrow;
    }
  }

  /// Obtener headers con autenticación
  Map<String, String> getHeaders() {
    final headers = {'Content-Type': 'application/json'};
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  /// Limpiar token (para logout)
  void clearToken() {
    _authToken = null;
  }

  /// Inicializar con credenciales por defecto (admin)
  /// Esto se puede llamar al iniciar la app para tener autenticación automática
  Future<bool> initializeWithDefaultCredentials() async {
    try {
      return await login(FastApiConfig.defaultUsername, FastApiConfig.defaultPassword);
    } catch (e) {
      print('⚠️ No se pudo autenticar con credenciales por defecto: $e');
      return false;
    }
  }
  
  /// Verificar y renovar token si es necesario
  Future<bool> ensureAuthenticated() async {
    // Si la configuración dice que no se requiere autenticación, retornar true
    if (!FastApiConfig.requiresAuth) {
      return true;
    }

    if (!isAuthenticated) {
      return await initializeWithDefaultCredentials();
    }
    return true;
  }
}

