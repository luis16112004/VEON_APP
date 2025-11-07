import 'package:hive_flutter/hive_flutter.dart';

/// Servicio para guardar datos localmente en el dispositivo
/// Funciona SIEMPRE, incluso sin internet
class LocalStorage {
  // Nombres de las "cajas" donde guardamos datos
  static const String _pendingSyncBoxName = 'pending_sync';  // Operaciones pendientes
  static const String _dataBoxName = 'local_data';           // Datos actuales

  // Singleton
  static LocalStorage? _instance;
  late Box<Map> _pendingBox;
  late Box<Map> _dataBox;

  LocalStorage._();

  static LocalStorage get instance {
    _instance ??= LocalStorage._();
    return _instance!;
  }

  /// Inicializar Hive (llamar esto en main.dart al inicio)
  Future<void> init() async {
    await Hive.initFlutter();
    _pendingBox = await Hive.openBox<Map>(_pendingSyncBoxName);
    _dataBox = await Hive.openBox<Map>(_dataBoxName);
    print('✅ Almacenamiento local inicializado');
    print('📦 Datos guardados: ${_dataBox.length}');
    print('⏳ Operaciones pendientes: ${_pendingBox.length}');
  }

  // ==================== GUARDAR Y LEER DATOS ====================

  /// 📝 Guardar datos localmente
  Future<void> saveLocal(String collection, String id, Map<String, dynamic> data) async {
    final key = '${collection}_$id';
    await _dataBox.put(key, data);
    print('💾 Guardado localmente: $key');
  }

  /// 🔍 Obtener UN dato local por ID
  Map<String, dynamic>? getLocal(String collection, String id) {
    final key = '${collection}_$id';
    final data = _dataBox.get(key);
    if (data != null) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  /// 🔍 Obtener TODOS los datos de una colección
  List<Map<String, dynamic>> getAllLocal(String collection) {
    final results = <Map<String, dynamic>>[];

    // Buscar todas las claves que empiecen con el nombre de la colección
    for (var key in _dataBox.keys) {
      if (key.toString().startsWith('${collection}_')) {
        final data = _dataBox.get(key);
        if (data != null) {
          results.add(Map<String, dynamic>.from(data));
        }
      }
    }

    print('📚 Encontrados ${results.length} registros locales en $collection');
    return results;
  }

  /// 🗑️ Eliminar datos locales
  Future<void> deleteLocal(String collection, String id) async {
    final key = '${collection}_$id';
    await _dataBox.delete(key);
    print('🗑️ Eliminado localmente: $key');
  }

  /// 🧹 Limpiar TODOS los datos de una colección
  Future<void> clearCollection(String collection) async {
    final keysToDelete = <dynamic>[];
    for (var key in _dataBox.keys) {
      if (key.toString().startsWith('${collection}_')) {
        keysToDelete.add(key);
      }
    }
    await _dataBox.deleteAll(keysToDelete);
    print('🧹 Limpiada colección $collection (${keysToDelete.length} registros)');
  }

  // ==================== COLA DE SINCRONIZACIÓN ====================

  /// ➕ Agregar operación a la cola de sincronización
  /// Esto se usa cuando no hay internet y queremos recordar qué hacer después
  Future<void> addPendingSync({
    required String operation,    // 'insert', 'update', 'delete'
    required String collection,   // nombre de la colección
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    final pendingOp = {
      'operation': operation,
      'collection': collection,
      'data': data,
      'documentId': documentId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'synced': false,
    };

    // Crear una clave única con timestamp
    final key = '${DateTime.now().millisecondsSinceEpoch}_$operation';
    await _pendingBox.put(key, pendingOp);

    print('📝 Operación pendiente agregada: $operation en $collection');
    print('⏳ Total pendientes: ${_pendingBox.length}');
  }

  /// 📋 Obtener todas las operaciones pendientes de sincronizar
  List<Map<String, dynamic>> getPendingOperations() {
    final pending = <Map<String, dynamic>>[];

    for (var key in _pendingBox.keys) {
      final op = _pendingBox.get(key);
      if (op != null && op['synced'] == false) {
        pending.add({
          'key': key,
          ...Map<String, dynamic>.from(op),
        });
      }
    }

    // Ordenar por timestamp (más antiguo primero)
    pending.sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));

    return pending;
  }

  /// ✅ Marcar operación como sincronizada
  Future<void> markAsSynced(String key) async {
    final op = _pendingBox.get(key);
    if (op != null) {
      op['synced'] = true;
      await _pendingBox.put(key, op);
      print('✅ Operación marcada como sincronizada: $key');
    }
  }

  /// 🗑️ Eliminar operación ya sincronizada
  Future<void> removeSyncedOperation(String key) async {
    await _pendingBox.delete(key);
    print('🗑️ Operación sincronizada eliminada: $key');
  }

  /// 🧹 Limpiar todas las operaciones sincronizadas (más de 24 horas)
  Future<int> cleanOldSyncedOperations() async {
    final keysToDelete = <dynamic>[];
    final oneDayAgo = DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;

    for (var key in _pendingBox.keys) {
      final op = _pendingBox.get(key);
      if (op != null && op['synced'] == true) {
        final timestamp = op['timestamp'] as int;
        if (timestamp < oneDayAgo) {
          keysToDelete.add(key);
        }
      }
    }

    await _pendingBox.deleteAll(keysToDelete);
    print('🧹 Limpiadas ${keysToDelete.length} operaciones antiguas');
    return keysToDelete.length;
  }

  /// 📊 Obtener estadísticas del almacenamiento
  Map<String, int> getStats() {
    final pending = getPendingOperations();
    return {
      'totalDatos': _dataBox.length,
      'operacionesPendientes': pending.length,
      'operacionesSincronizadas': _pendingBox.length - pending.length,
    };
  }
}