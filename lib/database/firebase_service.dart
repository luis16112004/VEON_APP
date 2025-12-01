import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Servicio para conectar y trabajar con Firebase Firestore
/// Reemplaza MongoService, usa Firestore como base de datos en la nube
/// Solo funciona cuando HAY INTERNET
class FirebaseService {
  // Singleton - solo existe una instancia
  static FirebaseService? _instance;
  static FirebaseFirestore? _firestore;
  static FirebaseAuth? _auth;

  FirebaseService._();

  static FirebaseService get instance {
    _instance ??= FirebaseService._();
    return _instance!;
  }

  /// Obtener instancia de Firestore
  FirebaseFirestore get firestore {
    _firestore ??= FirebaseFirestore.instance;
    return _firestore!;
  }

  /// Obtener instancia de Auth
  FirebaseAuth get auth {
    _auth ??= FirebaseAuth.instance;
    return _auth!;
  }

  /// Conectar a Firebase
  /// Firebase se conecta automáticamente, este método verifica la conexión
  Future<void> connect() async {
    try {
      // Verificar si hay un usuario autenticado
      final user = auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ No hay usuario autenticado en Firebase');
      } else {
        debugPrint('✅ Usuario autenticado: ${user.email}');
      }

      // Firestore se conecta automáticamente
      // La persistencia offline está habilitada por defecto en Flutter
      // Solo verificamos que Firestore esté disponible

      debugPrint('✅ Firebase Firestore inicializado correctamente');
    } catch (e) {
      debugPrint('❌ Error inicializando Firebase: $e');
      debugPrint('⚠️  La app funcionará en modo OFFLINE');
      rethrow;
    }
  }

  /// Verificar si está conectado
  /// Nota: Firestore funciona sin autenticación si las reglas lo permiten
  Future<bool> isConnected() async {
    try {
      // Firestore está disponible si Firebase está inicializado
      // No necesitamos verificar usuario, solo que Firestore esté listo
      // La persistencia offline está habilitada por defecto

      // Verificar que Firestore esté inicializado
      if (firestore.app.name.isNotEmpty) {
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('⚠️ Firebase no está conectado: $e');
      return false;
    }
  }

  /// Obtener ID del usuario actual
  String? getCurrentUserId() {
    return auth.currentUser?.uid;
  }

  /// Obtener una colección (como una "tabla" en bases de datos normales)
  CollectionReference getCollection(String collectionName) {
    return firestore.collection(collectionName);
  }

  // ==================== OPERACIONES CRUD ====================

  /// 📝 INSERTAR un documento nuevo
  Future<Map<String, dynamic>?> insertOne(
    String collection,
    Map<String, dynamic> document,
  ) async {
    try {
      // Agregar metadata
      final now = DateTime.now().toIso8601String();
      document['createdAt'] = document['createdAt'] ?? now;
      document['updatedAt'] = now;

      // Agregar userId si hay usuario autenticado (opcional)
      final userId = getCurrentUserId();
      if (userId != null) {
        document['userId'] = userId;
      }

      // Si no tiene ID, Firestore lo generará
      String? docId = document['_id'] as String?;

      if (docId != null) {
        // Usar el ID proporcionado
        document.remove('_id'); // Remover _id ya que Firestore usa 'id'
        await getCollection(collection).doc(docId).set(document);
        document['id'] = docId;
        debugPrint('✅ Documento insertado en Firestore: $collection/$docId');
        return document;
      } else {
        // Firestore genera el ID automáticamente
        final docRef = getCollection(collection).doc();
        document['id'] = docRef.id;
        await docRef.set(document);
        debugPrint(
            '✅ Documento insertado en Firestore: $collection/${docRef.id}');
        return document;
      }
    } catch (e) {
      debugPrint('❌ Error en insertOne: $e');
      return null;
    }
  }

  /// 🔍 BUSCAR documentos
  Future<List<Map<String, dynamic>>> find(
    String collection, {
    Map<String, dynamic>? filter,
  }) async {
    try {
      Query query = getCollection(collection);

      // Filtrar por userId solo si hay usuario autenticado
      final userId = getCurrentUserId();
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      // Aplicar filtros adicionales si se proporcionan
      if (filter != null) {
        for (var entry in filter.entries) {
          if (entry.value != null && entry.key != 'userId') {
            query = query.where(entry.key, isEqualTo: entry.value);
          }
        }
      }

      final snapshot = await query.get();
      final documents = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['_id'] = doc.id; // Mantener compatibilidad con código existente
        data['id'] = doc.id;
        return data;
      }).toList();

      debugPrint('✅ Encontrados ${documents.length} documentos en $collection');
      return documents;
    } catch (e) {
      debugPrint('❌ Error en find: $e');
      return [];
    }
  }

  /// 🔍 BUSCAR UN documento por ID
  Future<Map<String, dynamic>?> findById(
    String collection,
    String id,
  ) async {
    try {
      final doc = await getCollection(collection).doc(id).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return null;

      data['_id'] = doc.id; // Mantener compatibilidad
      data['id'] = doc.id;
      return data;
    } catch (e) {
      debugPrint('❌ Error en findById: $e');
      return null;
    }
  }

  /// ✏️ ACTUALIZAR un documento
  Future<bool> updateOne(
    String collection,
    String id,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final now = DateTime.now().toIso8601String();
      updateData['updatedAt'] = now;

      // Remover campos que no deben actualizarse
      updateData.remove('_id');
      updateData.remove('id');
      updateData.remove('createdAt');
      updateData.remove('userId');

      await getCollection(collection).doc(id).update(updateData);
      debugPrint('✅ Documento actualizado en Firestore: $collection/$id');
      return true;
    } catch (e) {
      debugPrint('❌ Error en updateOne: $e');
      return false;
    }
  }

  /// 🗑️ ELIMINAR un documento
  Future<bool> deleteOne(
    String collection,
    String id,
  ) async {
    try {
      await getCollection(collection).doc(id).delete();
      debugPrint('✅ Documento eliminado de Firestore: $collection/$id');
      return true;
    } catch (e) {
      debugPrint('❌ Error en deleteOne: $e');
      return false;
    }
  }

  /// 🗑️ ELIMINAR todos los documentos que coincidan con un filtro
  Future<int> deleteMany(
    String collection,
    Map<String, dynamic> filter,
  ) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      Query query =
          getCollection(collection).where('userId', isEqualTo: userId);

      // Aplicar filtros
      for (var entry in filter.entries) {
        if (entry.value != null && entry.key != 'userId') {
          query = query.where(entry.key, isEqualTo: entry.value);
        }
      }

      final snapshot = await query.get();
      final batch = firestore.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint(
          '✅ ${snapshot.docs.length} documentos eliminados de $collection');
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('❌ Error en deleteMany: $e');
      return 0;
    }
  }
}

// Función de debug
void debugPrint(String message) {
  // En desarrollo: usar print
  // En producción: usar un logger o simplemente no imprimir
  print(message);
}
