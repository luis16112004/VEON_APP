/// Configuración de la API FastAPI (veon-pos.onrender.com)
/// Permite cambiar entre Firebase y FastAPI
class FastApiConfig {
  // URL base de FastAPI
  static const String fastApiBaseUrl = 'https://veon-pos.onrender.com';

  // Toggle para activar/desactivar FastAPI
  // true = usar FastAPI para productos y categorías
  // false = usar Firebase (comportamiento actual)
  static const bool useFastApi = true;

  // Toggle para requerir autenticación en FastAPI
  // true = requiere login (token JWT)
  // false = API pública (sin token)
  static const bool requiresAuth = false;

  // Obtener la URL base según la configuración
  static String get baseUrl => fastApiBaseUrl;

  // Verificar si FastAPI está activo
  static bool get isFastApiEnabled => useFastApi;

  // Configuración JWT
  static const String secretKey = 'meshico';
  static const int accessTokenExpireMinutes = 240;
  static const String algorithm = 'HS256';

  // Credenciales por defecto para FastAPI (pueden cambiarse según necesidad)
  static const String defaultUsername = 'admin';
  static const String defaultPassword = 'admin123';
}
