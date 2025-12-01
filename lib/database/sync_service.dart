import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import 'firebase_service.dart'; // ✅ Cambiado de mongo_service a firebase_service
import 'local_storage.dart';

/// Servicio principal que coordina todo
/// Decide si guardar en Firebase Firestore, localmente, o ambos
class SyncService {
  static SyncService? _instance;
  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _syncTimer;

  bool _isSyncing = false;
  bool _isOnline = false;

  SyncService._();

  static SyncService get instance {
    _instance ??= SyncService._();
    return _instance!;
  }

  /// ¿Hay internet ahora?
  bool get isOnline => _isOnline;

  /// Inicializar el servicio (llamar en main.dart)
  Future<void> init() async {
    // ✅ Reemplazar print por debugPrint o logger
    debugPrint('🚀 Inicializando servicio de sincronización...');

    // Verificar conexión inicial
    final result = await _connectivity.checkConnectivity();
    _isOnline = !result.contains(ConnectivityResult.none);
    debugPrint(_isOnline ? '🌐 HAY internet' : '📵 SIN internet');

    // Escuchar cambios en la conexión
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((results) async {
      final wasOffline = !_isOnline;
      _isOnline = !results.contains(ConnectivityResult.none);

      if (_isOnline) {
        debugPrint('🌐 ¡Conectado a internet!');
        // Si acabamos de conectarnos, sincronizar automáticamente
        if (wasOffline) {
          debugPrint('🔄 Iniciando sincronización automática...');
          await Future.delayed(Duration(seconds: 2)); // Esperar un poco
          await syncPendingOperations();
        }
      } else {
        debugPrint('📵 Sin conexión a internet');
      }
    });

    // Sincronización automática cada 10 minutos (si hay internet)
    _syncTimer = Timer.periodic(Duration(minutes: 10), (_) {
      if (_isOnline && !_isSyncing) {
        debugPrint('⏰ Sincronización automática programada');
        syncPendingOperations();
      }
    });

    debugPrint('✅ Servicio de sincronización listo');
  }

  /// Limpiar recursos
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
  }

  // ==================== GUARDAR DATOS ====================

  /// 📝 GUARDAR un documento nuevo
  /// Funciona CON o SIN internet
  Future<bool> saveDocument(
    String collection,
    Map<String, dynamic> data, {
    String? id,
  }) async {
    try {
      // 1. Generar ID único si no existe
      final docId = id ?? const Uuid().v4();
      data['_id'] = docId;
      data['createdAt'] = DateTime.now().toIso8601String();
      data['updatedAt'] = DateTime.now().toIso8601String();

      debugPrint('💾 Guardando documento en $collection...');

      // 2. SIEMPRE guardar localmente primero (funciona sin internet)
      await LocalStorage.instance.saveLocal(collection, docId, data);
      debugPrint('✅ Guardado localmente');

      // 3. Intentar guardar en Firebase si hay internet
      if (_isOnline) {
        try {
          // Intentar guardar directamente (Firestore maneja la conexión)
          final result =
              await FirebaseService.instance.insertOne(collection, data);
          if (result != null) {
            debugPrint('✅ Guardado en Firebase exitosamente');
            return true;
          }
        } catch (e) {
          debugPrint('⚠️ Error guardando en Firebase: $e');
          debugPrint(
              '💡 El documento se guardará localmente y se sincronizará después');
        }
      }

      // 4. Si no se pudo guardar en Firebase, agregar a cola de sincronización
      await LocalStorage.instance.addPendingSync(
        operation: 'insert',
        collection: collection,
        data: data,
        documentId: docId,
      );

      debugPrint(
          '💾 Documento guardado localmente. Se sincronizará cuando haya internet.');
      return true;
    } catch (e) {
      debugPrint('❌ Error guardando documento: $e');
      return false;
    }
  }

  // ==================== ACTUALIZAR DATOS ====================

  /// ✏️ ACTUALIZAR un documento existente
  Future<bool> updateDocument(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      data['_id'] = id;
      data['updatedAt'] = DateTime.now().toIso8601String();

      debugPrint('✏️ Actualizando documento $id en $collection...');

      // 1. Actualizar localmente
      await LocalStorage.instance.saveLocal(collection, id, data);
      debugPrint('✅ Actualizado localmente');

      // 2. Intentar actualizar en Firebase si hay internet
      if (_isOnline) {
        try {
          final success =
              await FirebaseService.instance.updateOne(collection, id, data);
          if (success) {
            debugPrint('✅ Actualizado en Firebase exitosamente');
            return true;
          }
        } catch (e) {
          debugPrint('⚠️ Error actualizando en Firebase: $e');
          debugPrint(
              '💡 El documento se guardará localmente y se sincronizará después');
        }
      }

      // 3. Agregar a cola de sincronización
      await LocalStorage.instance.addPendingSync(
        operation: 'update',
        collection: collection,
        data: data,
        documentId: id,
      );

      debugPrint(
          '💾 Documento actualizado localmente. Se sincronizará cuando haya internet.');
      return true;
    } catch (e) {
      debugPrint('❌ Error actualizando documento: $e');
      return false;
    }
  }

  // ==================== ELIMINAR DATOS ====================

  /// 🗑️ ELIMINAR un documento
  Future<bool> deleteDocument(String collection, String id) async {
    try {
      debugPrint('🗑️ Eliminando documento $id de $collection...');

      // 1. Eliminar localmente
      await LocalStorage.instance.deleteLocal(collection, id);
      debugPrint('✅ Eliminado localmente');

      // 2. Intentar eliminar en Firebase si hay internet
      if (_isOnline) {
        try {
          final success =
              await FirebaseService.instance.deleteOne(collection, id);
          if (success) {
            debugPrint('✅ Eliminado de Firebase exitosamente');
            return true;
          }
        } catch (e) {
          debugPrint('⚠️ Error eliminando en Firebase: $e');
          debugPrint(
              '💡 El documento se guardará localmente y se sincronizará después');
        }
      }

      // 3. Agregar a cola de sincronización
      await LocalStorage.instance.addPendingSync(
        operation: 'delete',
        collection: collection,
        data: {'_id': id},
        documentId: id,
      );

      debugPrint(
          '💾 Documento eliminado localmente. Se sincronizará cuando haya internet.');
      return true;
    } catch (e) {
      debugPrint('❌ Error eliminando documento: $e');
      return false;
    }
  }

  // ==================== LEER DATOS ====================

  /// 🔍 OBTENER todos los documentos de una colección
  /// Primero intenta desde Firebase, si no hay internet usa datos locales
  Future<List<Map<String, dynamic>>> getDocuments(String collection) async {
    debugPrint('🔍 Obteniendo documentos de $collection...');

    // Si hay internet, intentar obtener de Firebase
    if (_isOnline) {
      try {
        final firebaseConnected = await FirebaseService.instance.isConnected();
        if (firebaseConnected) {
          final firebaseData = await FirebaseService.instance.find(collection);

          if (firebaseData.isNotEmpty) {
            // Actualizar datos locales con los de Firebase
            for (var doc in firebaseData) {
              final docId = doc['_id']?.toString() ?? doc['id']?.toString();
              if (docId != null) {
                await LocalStorage.instance.saveLocal(
                  collection,
                  docId,
                  doc,
                );
              }
            }
            debugPrint(
                '✅ Obtenidos ${firebaseData.length} documentos desde Firebase');
            return firebaseData;
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error obteniendo desde Firebase: $e');
      }
    }

    // Usar datos locales
    final localData = LocalStorage.instance.getAllLocal(collection);
    debugPrint(
        '📱 Obtenidos ${localData.length} documentos desde almacenamiento local');
    return localData;
  }

  /// 🔍 OBTENER UN documento por ID
  Future<Map<String, dynamic>?> getDocument(
      String collection, String id) async {
    // Si hay internet, intentar obtener de Firebase
    if (_isOnline) {
      try {
        final firebaseConnected = await FirebaseService.instance.isConnected();
        if (firebaseConnected) {
          final doc = await FirebaseService.instance.findById(collection, id);
          if (doc != null) {
            // Actualizar localmente
            final docId = doc['_id']?.toString() ?? doc['id']?.toString() ?? id;
            await LocalStorage.instance.saveLocal(collection, docId, doc);
            return doc;
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error obteniendo desde Firebase: $e');
      }
    }

    // Usar datos locales
    return LocalStorage.instance.getLocal(collection, id);
  }

  // ==================== SINCRONIZACIÓN ====================

  /// 🔄 SINCRONIZAR operaciones pendientes con Firebase
  /// Se ejecuta automáticamente cuando vuelve el internet
  Future<void> syncPendingOperations() async {
    if (_isSyncing) {
      debugPrint('⏳ Ya hay una sincronización en curso...');
      return;
    }

    if (!_isOnline) {
      debugPrint('📵 Sin internet, no se puede sincronizar');
      return;
    }

    _isSyncing = true;
    debugPrint('🔄 Iniciando sincronización de operaciones pendientes...');

    try {
      // Verificar conexión a Firebase
      final firebaseConnected = await FirebaseService.instance.isConnected();
      if (!firebaseConnected) {
        debugPrint('⚠️ Firebase no está conectado, cancelando sincronización');
        _isSyncing = false;
        return;
      }

      final pendingOps = LocalStorage.instance.getPendingOperations();

      if (pendingOps.isEmpty) {
        debugPrint('✅ No hay operaciones pendientes de sincronizar');
        _isSyncing = false;
        return;
      }

      debugPrint('📤 Sincronizando ${pendingOps.length} operaciones...');

      int successCount = 0;
      int errorCount = 0;

      for (var op in pendingOps) {
        try {
          final operation = op['operation'] as String;
          final collection = op['collection'] as String;
          final data = op['data'] as Map<String, dynamic>;
          final docId = op['documentId'] as String?;
          final key = op['key'];

          bool success = false;

          switch (operation) {
            case 'insert':
              final result =
                  await FirebaseService.instance.insertOne(collection, data);
              success = result != null;
              break;

            case 'update':
              if (docId != null) {
                success = await FirebaseService.instance
                    .updateOne(collection, docId, data);
              }
              break;

            case 'delete':
              if (docId != null) {
                success =
                    await FirebaseService.instance.deleteOne(collection, docId);
              }
              break;
          }

          if (success) {
            await LocalStorage.instance.removeSyncedOperation(key);
            successCount++;
            debugPrint('✅ Sincronizada: $operation en $collection');
          } else {
            errorCount++;
            debugPrint('❌ Error sincronizando: $operation en $collection');
          }
        } catch (e) {
          errorCount++;
          debugPrint('❌ Error sincronizando operación: $e');
        }
      }

      debugPrint('🎉 Sincronización completada:');
      debugPrint(' ✅ Exitosas: $successCount');
      debugPrint(' ❌ Errores: $errorCount');

      // Limpiar operaciones antiguas
      await LocalStorage.instance.cleanOldSyncedOperations();
    } catch (e) {
      debugPrint('❌ Error general en sincronización: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// 📊 Obtener estadísticas de sincronización
  Map<String, dynamic> getStats() {
    final storageStats = LocalStorage.instance.getStats();
    return {
      ...storageStats,
      'isOnline': _isOnline,
      'isSyncing': _isSyncing,
    };
  }
}

// Agregar esta función al inicio del archivo (fuera de la clase)
void debugPrint(String message) {
  // En desarrollo: usar print
  // En producción: usar un logger o simplemente no imprimir
  print(message);
}
