import 'package:mongo_dart/mongo_dart.dart';

/// Servicio para conectar y trabajar con MongoDB (base de datos en la nube)
/// Solo funciona cuando HAY INTERNET
class MongoService {
  // Singleton - solo existe una instancia
  static MongoService? _instance;
  static Db? _db;

  MongoService._();

  static MongoService get instance {
    _instance ??= MongoService._();
    return _instance!;
  }

  // 🔧 IMPORTANTE: Reemplaza esto con tu URI de MongoDB Atlas
  // Para obtenerla:
  // 1. Ve a https://www.mongodb.com/cloud/atlas
  // 2. Crea una cuenta gratuita
  // 3. Crea un cluster
  // 4. Dale click en "Connect" y copia la URI
  static const String _connectionString =
      'mongodb+srv://veon_admin:veon123@cluster0.mywn7fo.mongodb.net/veon_business?appName=Cluster0&retryWrites=true&w=majority';

  /// Conectar a MongoDB
  Future<void> connect() async {
    try {
      // Si ya está conectado, no hacer nada
      if (_db != null && _db!.state == State.OPEN) {
        print('✅ Ya conectado a MongoDB');
        return;
      }

      _db = await Db.create(_connectionString);
      await _db!.open();
      print('✅ Conectado a MongoDB exitosamente');
    } catch (e) {
      print('❌ Error conectando a MongoDB: $e');
      print('⚠️  La app funcionará en modo OFFLINE');
      rethrow;
    }
  }

  /// Desconectar de MongoDB
  Future<void> disconnect() async {
    if (_db != null && _db!.state == State.OPEN) {
      await _db!.close();
      print('🔌 Desconectado de MongoDB');
    }
  }

  /// Obtener una colección (como una "tabla" en bases de datos normales)
  DbCollection getCollection(String collectionName) {
    if (_db == null || _db!.state != State.OPEN) {
      throw Exception('MongoDB no está conectado');
    }
    return _db!.collection(collectionName);
  }

  /// Verificar si está conectado
  Future<bool> isConnected() async {
    try {
      if (_db == null || _db!.state != State.OPEN) {
        return false;
      }
      // Hacer un ping para verificar
      await _db!.serverStatus();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==================== OPERACIONES CRUD ====================

  /// 📝 INSERTAR un documento nuevo
  Future<Map<String, dynamic>?> insertOne(
      String collection,
      Map<String, dynamic> document
      ) async {
    try {
      final coll = getCollection(collection);
      final result = await coll.insertOne(document);

      if (result.isSuccess) {
        print('✅ Documento insertado en MongoDB: $collection');
        return result.document;
      } else {
        print('❌ Error insertando documento');
        return null;
      }
    } catch (e) {
      print('❌ Error en insertOne: $e');
      return null;
    }
  }

  /// 🔍 BUSCAR documentos
  Future<List<Map<String, dynamic>>> find(
      String collection,
      {Map<String, dynamic>? filter}
      ) async {
    try {
      final coll = getCollection(collection);
      final cursor = coll.find(filter ?? {});
      final documents = await cursor.toList();
      print('✅ Encontrados ${documents.length} documentos en $collection');
      return documents;
    } catch (e) {
      print('❌ Error en find: $e');
      return [];
    }
  }

  /// 🔍 BUSCAR UN documento por ID
  Future<Map<String, dynamic>?> findById(
      String collection,
      String id
      ) async {
    try {
      final coll = getCollection(collection);
      final doc = await coll.findOne(where.eq('_id', id));
      return doc;
    } catch (e) {
      print('❌ Error en findById: $e');
      return null;
    }
  }

  /// ✏️ ACTUALIZAR un documento
  Future<bool> updateOne(
      String collection,
      String id,
      Map<String, dynamic> updateData
      ) async {
    try {
      final coll = getCollection(collection);

      // Agregar fecha de actualización
      updateData['updatedAt'] = DateTime.now().toIso8601String();

      final result = await coll.updateOne(
        where.eq('_id', id),
        modify.set('updatedAt', updateData['updatedAt']),
      );

      // Actualizar todos los campos
      for (var entry in updateData.entries) {
        await coll.updateOne(
          where.eq('_id', id),
          modify.set(entry.key, entry.value),
        );
      }

      print('✅ Documento actualizado en MongoDB: $collection');
      return true;
    } catch (e) {
      print('❌ Error en updateOne: $e');
      return false;
    }
  }

  /// 🗑️ ELIMINAR un documento
  Future<bool> deleteOne(
      String collection,
      String id
      ) async {
    try {
      final coll = getCollection(collection);
      final result = await coll.deleteOne(where.eq('_id', id));

      if (result.isSuccess) {
        print('✅ Documento eliminado de MongoDB: $collection');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error en deleteOne: $e');
      return false;
    }
  }

  /// 🗑️ ELIMINAR todos los documentos que coincidan con un filtro
  Future<int> deleteMany(
      String collection,
      Map<String, dynamic> filter
      ) async {
    try {
      final coll = getCollection(collection);
      final result = await coll.deleteMany(filter);
      print('✅ ${result.nRemoved} documentos eliminados de $collection');
      return result.nRemoved ?? 0;
    } catch (e) {
      print('❌ Error en deleteMany: $e');
      return 0;
    }
  }
}