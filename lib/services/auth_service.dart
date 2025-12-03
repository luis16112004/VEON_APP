import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../database/firebase_service.dart';

/// Servicio de autenticación usando Firebase Auth
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
  }) async {
    try {
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
          createdAt: userData['createdAt'],
        );

        print('✅ Login exitoso: ${user.email}');
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
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

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
          createdAt: userData['createdAt'],
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
          createdAt: userData['createdAt'],
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
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      print('✅ Sesión cerrada exitosamente');
    } catch (e) {
      print('❌ Error al cerrar sesión: $e');
      throw Exception('Error al cerrar sesión: $e');
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
}
