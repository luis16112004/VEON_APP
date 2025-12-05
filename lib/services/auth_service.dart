import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'package:firebase_core/firebase_core.dart';

/// Servicio de autenticación usando Firebase Auth o Laravel API
/// Maneja login, registro, y autenticación con Google
class AuthService {
  static AuthService? _instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService._();

  static AuthService get instance {
    _instance ??= AuthService._();
    return _instance!;
  }

  /// Obtener usuario actual de Firebase Auth
  User? get currentFirebaseUser => _auth.currentUser;

  /// Stream de cambios de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ==================== REGISTRO ====================

  /// Registrar nuevo usuario con email y contraseña
  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
    String role = 'vendedor', // Default role
  }) async {
    try {
      // Usar Firebase directamente
      // Crear usuario en Firebase Auth (las contraseñas ya están cifradas por Firebase)
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('No se pudo crear el usuario');
      }

      // Actualizar el perfil del usuario con el nombre
      await user.updateDisplayName(name);
      await user.reload();

      // Crear documento del usuario en Firestore
      final userModel = UserModel(
        id: user.uid,
        name: name,
        email: email.trim().toLowerCase(),
        createdAt: DateTime.now().toIso8601String(),
      );

      await _firestore.collection('users').doc(user.uid).set({
        'id': user.uid,
        'name': name,
        'email': email.trim().toLowerCase(),
        'role': role,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('✅ Usuario registrado exitosamente: ${user.email}');
      return userModel;
    } on FirebaseAuthException catch (e) {
      print('❌ Error en registro: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Error inesperado en registro: $e');
      throw Exception('Error al registrar usuario: $e');
    }
  }

  // ==================== LOGIN ====================

  /// Iniciar sesión con email y contraseña
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      // Usar Firebase directamente
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('No se pudo iniciar sesión');
      }

      // Obtener datos del usuario desde Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final userModel = UserModel(
          id: user.uid,
          name: userData['name'] ?? user.displayName ?? 'Usuario',
          email: user.email ?? email,
          role: userData['role'] ?? 'vendedor',
          createdAt: _parseDate(userData['createdAt']),
        );

        print('✅ Login exitoso: ${user.email} (${userModel.role})');
        return userModel;
      } else {
        // Si no existe en Firestore, crear el documento
        final userModel = UserModel(
          id: user.uid,
          name: user.displayName ?? 'Usuario',
          email: user.email ?? email,
          createdAt: DateTime.now().toIso8601String(),
        );

        await _firestore.collection('users').doc(user.uid).set({
          'id': user.uid,
          'name': user.displayName ?? 'Usuario',
          'email': user.email ?? email,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        return userModel;
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Error en login: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Error inesperado en login: $e');
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  // ==================== GOOGLE SIGN IN ====================

  /// Iniciar sesión con Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Iniciar el flujo de autenticación de Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // El usuario canceló el inicio de sesión
        return null;
      }

      // Obtener los detalles de autenticación del usuario
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Crear una nueva credencial
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Iniciar sesión con Firebase usando la credencial de Google
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw Exception('No se pudo iniciar sesión con Google');
      }

      // Verificar si el usuario ya existe en Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      UserModel userModel;

      if (userDoc.exists) {
        // Usuario existente
        final userData = userDoc.data()!;
        userModel = UserModel(
          id: user.uid,
          name: userData['name'] ?? user.displayName ?? 'Usuario',
          email: user.email ?? '',
          role: userData['role'] ?? 'vendedor',
          createdAt: _parseDate(userData['createdAt']),
        );
      } else {
        // Nuevo usuario, crear documento en Firestore
        userModel = UserModel(
          id: user.uid,
          name: user.displayName ?? 'Usuario',
          email: user.email ?? '',
          createdAt: DateTime.now().toIso8601String(),
        );

        await _firestore.collection('users').doc(user.uid).set({
          'id': user.uid,
          'name': user.displayName ?? 'Usuario',
          'email': user.email ?? '',
          'photoURL': user.photoURL,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      print('✅ Login con Google exitoso: ${user.email}');
      return userModel;
    } catch (e) {
      print('❌ Error en login con Google: $e');
      throw Exception('Error al iniciar sesión con Google: $e');
    }
  }

  // ==================== OBTENER USUARIO ACTUAL ====================

  /// Obtener el usuario actual logueado
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      // Obtener datos del usuario desde Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        return UserModel(
          id: user.uid,
          name: userData['name'] ?? user.displayName ?? 'Usuario',
          email: user.email ?? '',
          role: userData['role'] ?? 'vendedor',
          createdAt: _parseDate(userData['createdAt']),
        );
      } else {
        // Si no existe en Firestore, crear documento básico
        final userModel = UserModel(
          id: user.uid,
          name: user.displayName ?? 'Usuario',
          email: user.email ?? '',
          createdAt: DateTime.now().toIso8601String(),
        );

        await _firestore.collection('users').doc(user.uid).set({
          'id': user.uid,
          'name': user.displayName ?? 'Usuario',
          'email': user.email ?? '',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        return userModel;
      }
    } catch (e) {
      print('❌ Error obteniendo usuario actual: $e');
      return null;
    }
  }

  // ==================== CERRAR SESIÓN ====================

  /// Cerrar sesión
  Future<void> logout() async {
    try {
      await _auth.signOut();

      try {
        await _googleSignIn.signOut();
      } catch (e) {
        print('⚠️ Error silencioso al cerrar sesión de Google: $e');
      }

      print('✅ Sesión cerrada exitosamente');
    } catch (e) {
      print('❌ Error al cerrar sesión: $e');
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  // ==================== GESTIÓN DE PERFIL ====================

  /// Actualizar perfil (nombre y email)
  Future<void> updateProfile({required String name, String? email}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No hay usuario autenticado');

      // Actualizar Firebase Auth
      if (name != user.displayName) {
        await user.updateDisplayName(name);
        await user.reload();
      }

      if (email != null && email != user.email) {
        await user.verifyBeforeUpdateEmail(email);
      }

      // Actualizar Firestore
      final updateData = <String, dynamic>{
        'name': name,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (email != null) {
        updateData['email'] = email;
      }

      await _firestore.collection('users').doc(user.uid).update(updateData);

      print('✅ Perfil actualizado exitosamente');
    } catch (e) {
      print('❌ Error actualizando perfil: $e');
      throw Exception('Error al actualizar perfil: $e');
    }
  }

  /// Actualizar solo el nombre del usuario
  Future<void> updateName(String name) async {
    await updateProfile(name: name);
  }

  /// Cambiar contraseña
  Future<void> changePassword(
      {required String currentPassword, required String newPassword}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No hay usuario autenticado');

      // Reautenticar para operaciones sensibles
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);

      await user.updatePassword(newPassword);

      print('✅ Contraseña actualizada exitosamente');
    } on FirebaseAuthException catch (e) {
      print('❌ Error cambiando contraseña: ${e.code}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Error cambiando contraseña: $e');
      throw Exception('Error al cambiar contraseña: $e');
    }
  }

  /// Eliminar cuenta
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No hay usuario autenticado');

      // Eliminar datos de Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Eliminar usuario de Auth
      await user.delete();

      print('✅ Cuenta eliminada exitosamente');
    } catch (e) {
      print('❌ Error eliminando cuenta: $e');
      throw Exception('Error al eliminar cuenta: $e');
    }
  }



  /// Crear nuevo usuario (solo admin)
  /// Usa una instancia secundaria de Firebase para no cerrar la sesión del admin
  Future<UserModel?> createUser({
    required String name,
    required String email,
    required String password,
    String role = 'vendedor',
  }) async {
    FirebaseApp? tempApp;
    try {
      // Inicializar app secundaria para no afectar la sesión actual
      try {
        tempApp = await Firebase.initializeApp(
          name: 'tempRegister',
          options: Firebase.app().options,
        );
      } catch (e) {
        print('⚠️ Error inicializando app secundaria: $e');
        // Si falla, usamos la instancia principal (cerrará sesión del admin)
      }

      final authInstance = tempApp != null 
          ? FirebaseAuth.instanceFor(app: tempApp) 
          : _auth;

      // Crear usuario en Firebase Auth
      final userCredential = await authInstance.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('No se pudo crear el usuario');
      }

      // Actualizar el perfil del usuario con el nombre
      await user.updateDisplayName(name);
      
      // Crear documento del usuario en Firestore (usando la instancia principal)
      final userModel = UserModel(
        id: user.uid,
        name: name,
        email: email.trim().toLowerCase(),
        role: role,
        createdAt: DateTime.now().toIso8601String(),
      );

      await _firestore.collection('users').doc(user.uid).set({
        'id': user.uid,
        'name': name,
        'email': email.trim().toLowerCase(),
        'role': role,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('✅ Usuario creado exitosamente: ${user.email} (${role})');
      
      // Limpiar app secundaria
      if (tempApp != null) {
        await authInstance.signOut();
        await tempApp.delete();
        tempApp = null;
      }

      return userModel;
    } on FirebaseAuthException catch (e) {
      print('❌ Error creando usuario: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Error inesperado creando usuario: $e');
      throw Exception('Error al crear usuario: $e');
    } finally {
      if (tempApp != null) {
        try {
          await tempApp.delete();
        } catch (_) {}
      }
    }
  }

  // ==================== RECUPERAR CONTRASEÑA ====================

  /// Enviar email para recuperar contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
      print('✅ Email de recuperación enviado');
    } on FirebaseAuthException catch (e) {
      print('❌ Error enviando email de recuperación: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Error inesperado: $e');
      throw Exception('Error al enviar email de recuperación: $e');
    }
  }

  // ==================== MANEJO DE ERRORES ====================

  // ==================== GESTIÓN DE USUARIOS (ORGANIZACIÓN) ====================

  Future<List<UserModel>> getUsers() async {
    try {
      print('📋 Obteniendo usuarios de Firestore...');
      // Firebase: Obtener todos los documentos de 'users'
      final snapshot = await _firestore.collection('users').get();
      print('📋 Usuarios encontrados: ${snapshot.docs.length}');
      
      final users = snapshot.docs.map((doc) {
        final data = doc.data();
        final user = UserModel(
          id: doc.id,
          name: data['name'] ?? 'Usuario',
          email: data['email'] ?? '',
          role: data['role'] ?? 'vendedor',
          createdAt: _parseDate(data['createdAt']),
        );
        print('👤 Usuario: ${user.name} (${user.email}) - Rol: ${user.role}');
        return user;
      }).toList();
      
      print('✅ Total de usuarios obtenidos: ${users.length}');
      return users;
    } catch (e) {
      print('❌ Error obteniendo usuarios: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// Actualizar el rol de un usuario (solo admin)
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      print('✅ Rol actualizado exitosamente para usuario $userId');
    } catch (e) {
      print('❌ Error actualizando rol: $e');
      throw Exception('Error al actualizar rol: $e');
    }
  }

  /// Eliminar un usuario (solo admin)
  Future<void> deleteUser(String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == userId) {
        throw Exception('No puedes eliminar tu propia cuenta desde aquí');
      }

      // Eliminar de Firestore
      await _firestore.collection('users').doc(userId).delete();

      // Intentar eliminar de Firebase Auth (requiere privilegios de admin)
      // Nota: Esto puede fallar si no tienes permisos de administrador en Firebase
      try {
        // En producción, esto requeriría usar Firebase Admin SDK
        // Por ahora, solo eliminamos de Firestore
        print(
            '⚠️ Usuario eliminado de Firestore. Eliminación de Auth requiere Admin SDK');
      } catch (e) {
        print('⚠️ No se pudo eliminar de Auth (requiere Admin SDK): $e');
      }

      print('✅ Usuario eliminado exitosamente');
    } catch (e) {
      print('❌ Error eliminando usuario: $e');
      throw Exception('Error al eliminar usuario: $e');
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'email-already-in-use':
        return 'Este email ya está registrado';
      case 'invalid-email':
        return 'Email inválido';
      case 'user-not-found':
        return 'Usuario no encontrado';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'user-disabled':
        return 'Usuario deshabilitado';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      case 'operation-not-allowed':
        return 'Operación no permitida';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }

  String? _parseDate(dynamic date) {
    if (date is Timestamp) return date.toDate().toIso8601String();
    if (date is String) return date;
    return null;
  }
}
