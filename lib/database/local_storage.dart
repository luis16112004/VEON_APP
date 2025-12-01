import 'package:hive_flutter/hive_flutter.dart';
// Asumiendo que estos modelos existen en tu proyecto
import '../models/sale_model.dart';
import '../models/quotation_model.dart';

/// Servicio para guardar datos localmente en el dispositivo
/// Funciona SIEMPRE, incluso sin internet
class LocalStorage {
  // Nombres de las "cajas" donde guardamos datos
  static const String _pendingSyncBoxName = 'pending_sync';  // Operaciones pendientes
  static const String _dataBoxName = 'local_data';           // Datos actuales

  // Nombres de cajas dedicadas (agregadas)
  static const String _salesBoxName = 'sales';
  static const String _quotationsBoxName = 'quotations';

  // Singleton
  static LocalStorage? _instance;
  late Box<Map> _pendingBox;
  late Box<Map> _dataBox;

  // Nuevas cajas dedicadas
  late Box<Map> _salesBox;
  late Box<Map> _quotationsBox;

  LocalStorage._();

  static LocalStorage get instance {
    _instance ??= LocalStorage._();
    return _instance!;
  }

  /// Inicializar Hive (llamar esto en main.dart al inicio)
  Future<void> init() async {
    await Hive.initFlutter();

    // Boxes originales
    _pendingBox = await Hive.openBox<Map>(_pendingSyncBoxName);
    _dataBox = await Hive.openBox<Map>(_dataBoxName);

    // Abrir nuevos boxes para ventas y cotizaciones
    _salesBox = await Hive.openBox<Map>(_salesBoxName);
    _quotationsBox = await Hive.openBox<Map>(_quotationsBoxName);

    print('✅ Almacenamiento local inicializado');
    print('📦 Datos guardados: ${_dataBox.length}');
    print('⏳ Operaciones pendientes: ${_pendingBox.length}');
    print('💰 Ventas guardadas: ${_salesBox.length}');
    print('📝 Cotizaciones guardadas: ${_quotationsBox.length}');
  }

  // ==================== GUARDAR Y LEER DATOS GENERALES ====================
  // Métodos para colecciones genéricas (clientes, productos, etc.)

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
      // Importante: Debes obtener una copia modificable si Hive no devuelve una
      final Map<dynamic, dynamic> modifiableOp = Map.from(op);
      modifiableOp['synced'] = true;
      await _pendingBox.put(key, modifiableOp);
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

  // ==================== VENTAS ESPECÍFICAS ====================

  /// Guardar venta
  Future<void> saveSale(Sale sale) async {
    try {
      await _salesBox.put(sale.id, sale.toMap());
      print('💾 Venta guardada localmente: ${sale.id}');
    } catch (e) {
      print('❌ Error guardando venta: $e');
      rethrow;
    }
  }

  /// Obtener venta por ID
  Future<Sale?> getSaleById(String id) async {
    try {
      final data = _salesBox.get(id);
      if (data == null) return null;

      return Sale.fromMap(Map<String, dynamic>.from(data));
    } catch (e) {
      print('❌ Error obteniendo venta: $e');
      return null;
    }
  }

  /// Obtener todas las ventas
  Future<List<Sale>> getAllSales() async {
    try {
      final sales = <Sale>[];

      for (var key in _salesBox.keys) {
        final data = _salesBox.get(key);
        if (data != null) {
          sales.add(Sale.fromMap(Map<String, dynamic>.from(data)));
        }
      }

      // Ordenar por fecha (más reciente primero)
      sales.sort((a, b) => b.date.compareTo(a.date));

      return sales;
    } catch (e) {
      print('❌ Error obteniendo ventas: $e');
      return [];
    }
  }

  /// Eliminar venta
  Future<void> deleteSale(String id) async {
    try {
      await _salesBox.delete(id);
      print('🗑️ Venta eliminada localmente: $id');
    } catch (e) {
      print('❌ Error eliminando venta: $e');
      rethrow;
    }
  }

  /// Obtener ventas no sincronizadas (asume que Sale tiene una propiedad `synced`)
  Future<List<Sale>> getUnsyncedSales() async {
    try {
      final allSales = await getAllSales();
      return allSales.where((sale) => !sale.synced).toList();
    } catch (e) {
      print('❌ Error obteniendo ventas no sincronizadas: $e');
      return [];
    }
  }

  /// Limpiar todas las ventas (usar con precaución)
  Future<void> clearAllSales() async {
    try {
      await _salesBox.clear();
      print('🗑️ Todas las ventas eliminadas');
    } catch (e) {
      print('❌ Error limpiando ventas: $e');
      rethrow;
    }
  }

  // ==================== COTIZACIONES ESPECÍFICAS ====================

  /// Guardar cotización
  Future<void> saveQuotation(Quotation quotation) async {
    try {
      await _quotationsBox.put(quotation.id, quotation.toMap());
      print('💾 Cotización guardada localmente: ${quotation.id}');
    } catch (e) {
      print('❌ Error guardando cotización: $e');
      rethrow;
    }
  }

  /// Obtener cotización por ID
  Future<Quotation?> getQuotationById(String id) async {
    try {
      final data = _quotationsBox.get(id);
      if (data == null) return null;

      return Quotation.fromMap(Map<String, dynamic>.from(data));
    } catch (e) {
      print('❌ Error obteniendo cotización: $e');
      return null;
    }
  }

  /// Obtener todas las cotizaciones
  Future<List<Quotation>> getAllQuotations() async {
    try {
      final quotations = <Quotation>[];

      for (var key in _quotationsBox.keys) {
        final data = _quotationsBox.get(key);
        if (data != null) {
          quotations.add(Quotation.fromMap(Map<String, dynamic>.from(data)));
        }
      }

      // Ordenar por fecha (más reciente primero)
      quotations.sort((a, b) => b.date.compareTo(a.date));

      return quotations;
    } catch (e) {
      print('❌ Error obteniendo cotizaciones: $e');
      return [];
    }
  }

  /// Eliminar cotización
  Future<void> deleteQuotation(String id) async {
    try {
      await _quotationsBox.delete(id);
      print('🗑️ Cotización eliminada localmente: $id');
    } catch (e) {
      print('❌ Error eliminando cotización: $e');
      rethrow;
    }
  }

  /// Obtener cotizaciones no sincronizadas (asume que Quotation tiene una propiedad `synced`)
  Future<List<Quotation>> getUnsyncedQuotations() async {
    try {
      final allQuotations = await getAllQuotations();
      return allQuotations.where((quotation) => !quotation.synced).toList();
    } catch (e) {
      print('❌ Error obteniendo cotizaciones no sincronizadas: $e');
      return [];
    }
  }

  /// Limpiar todas las cotizaciones (usar con precaución)
  Future<void> clearAllQuotations() async {
    try {
      await _quotationsBox.clear();
      print('🗑️ Todas las cotizaciones eliminadas');
    } catch (e) {
      print('❌ Error limpiando cotizaciones: $e');
      rethrow;
    }
  }

  // ==================== ESTADÍSTICAS ====================

  /// 📊 Obtener estadísticas del almacenamiento
  Map<String, int> getStats() {
    final pending = getPendingOperations();
    return {
      'totalDatosGenerales': _dataBox.length,
      'operacionesPendientes': pending.length,
      'operacionesSincronizadas': _pendingBox.length - pending.length,
      'ventasGuardadas': _salesBox.length, // Estadística agregada
      'cotizacionesGuardadas': _quotationsBox.length, // Estadística agregada
    };
  }
}