import 'package:uuid/uuid.dart';
import 'package:veon_app/database/sync_service.dart';
import 'package:veon_app/database/local_storage.dart';
import '../models/user_model.dart'; // Asume que creaste el modelo aquí

class AuthService {
  static AuthService? _instance;
  AuthService._();
  static AuthService get instance {
    _instance ??= AuthService._();
    return _instance!;
  }

  static const String _userCollection =
      'users'; // Nombre de la colección en Firestore

  // Llave para guardar el ID del usuario logueado localmente
  static const String _loggedInUserIdKey = 'current_user_id';

  // ==================== 1. REGISTRO ====================

  /// Registra un nuevo usuario, guarda localmente y en la cola de sincronización
  Future<UserModel?> register({
    required String name,
    required String email,
    required String
        password, // Opcional: podrías hashear la contraseña antes de guardar
  }) async {
    // Aquí puedes añadir validaciones adicionales (ej. si el email ya existe)

    final newUser = UserModel(
      // Generar un ID temporal hasta que Firebase lo confirme (SyncService se encarga de esto)
      id: const Uuid().v4(),
      name: name,
      email: email,
    );

    final userData = newUser.toJson();
    userData['password'] =
        password; // Se guarda el password (sin hashear por simplicidad)

    // Usar el SyncService para guardar
    final success = await SyncService.instance.saveDocument(
      _userCollection,
      userData,
      id: newUser.id,
    );

    if (success) {
      // 2. Guardar el usuario logueado localmente para acceso rápido
      await LocalStorage.instance.saveLocal('app_settings', _loggedInUserIdKey,
          {'id': newUser.id, 'name': newUser.name});

      // 3. Puedes devolver el modelo para usarlo inmediatamente
      return newUser;
    }

    return null;
  }

  // ==================== 2. OBTENER USUARIO ====================

  /// Obtiene el usuario actualmente logueado (desde la base de datos local)
  UserModel? getCurrentUser() {
    // 1. Intentar obtener el ID del usuario logueado de los settings
    final settings =
        LocalStorage.instance.getLocal('app_settings', _loggedInUserIdKey);
    final userId = settings?['id'];

    if (userId == null) return null;

    // 2. Usar el ID para obtener los datos completos del usuario
    final userData = LocalStorage.instance.getLocal(_userCollection, userId);

    if (userData != null) {
      return UserModel.fromJson(userData);
    }
    return null;
  }

  // ==================== 3. CERRAR SESIÓN ====================

  Future<void> logout() async {
    // Simplemente elimina la referencia al ID del usuario logueado
    await LocalStorage.instance.deleteLocal('app_settings', _loggedInUserIdKey);
  }
}
