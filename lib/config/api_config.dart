/// Configuración de la API
/// Permite cambiar entre Firebase y Laravel API
class ApiConfig {
  // URL base de Laravel API
  static const String laravelBaseUrl = 'https://api-production-aa3d.up.railway.app/api';

  // Toggle para activar/desactivar Laravel API
  // true = usar Laravel API para login, register y providers
  // false = usar Firebase (comportamiento actual)
  static const bool useLaravelApi = true;

  // Obtener la URL base según la configuración
  static String get baseUrl => laravelBaseUrl;

  // Verificar si Laravel está activo
  static bool get isLaravelEnabled => useLaravelApi;
}
