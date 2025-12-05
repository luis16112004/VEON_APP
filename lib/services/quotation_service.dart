// lib/services/quotation_service.dart

import '../models/quotation_model.dart';
import '../models/sale_model.dart';
import '../database/sync_service.dart';
import 'sale_service.dart';

class QuotationService {
  static final QuotationService _instance = QuotationService._internal();
  factory QuotationService() => _instance;
  QuotationService._internal();

  final _syncService = SyncService.instance;
  final _saleService = SaleService();

  static const String _collectionName = 'quotations';

  // ==================== CREATE ====================

  /// Crear nueva cotización (RF05.1)
  Future<Quotation> createQuotation(Quotation quotation) async {
    print('📝 Creando cotización: ${quotation.id}');

    try {
      // Guardar usando SyncService (maneja Firebase automáticamente)
      await _syncService.saveDocument(_collectionName, quotation.toMap(),
          id: quotation.id);
      print('✅ Cotización guardada y sincronizada');

      // Marcar como sincronizada si está online
      if (_syncService.isOnline) {
        return quotation.copyWith(synced: true);
      } else {
        print('📦 Cotización en cola de sincronización');
        return quotation;
      }
    } catch (e) {
      print('❌ Error creando cotización: $e');
      rethrow;
    }
  }

  // ==================== READ ====================

  /// Obtener todas las cotizaciones
  Future<List<Quotation>> getAllQuotations() async {
    try {
      final docs = await _syncService.getDocuments(_collectionName);
      return docs.map((doc) => Quotation.fromMap(doc)).toList();
    } catch (e) {
      print('❌ Error obteniendo cotizaciones: $e');
      return [];
    }
  }

  /// Obtener cotización por ID
  Future<Quotation?> getQuotationById(String id) async {
    try {
      final doc = await _syncService.getDocument(_collectionName, id);
      return doc != null ? Quotation.fromMap(doc) : null;
    } catch (e) {
      print('❌ Error obteniendo cotización: $e');
      return null;
    }
  }

  // ... (El resto de los métodos READ no necesitan cambios)

  /// Obtener cotizaciones por cliente (RF03.3)
  Future<List<Quotation>> getQuotationsByClient(String clientId) async {
    try {
      final allQuotations = await getAllQuotations();
      return allQuotations
          .where((quotation) => quotation.clientId == clientId)
          .toList();
    } catch (e) {
      print('❌ Error obteniendo cotizaciones del cliente: $e');
      return [];
    }
  }

  /// Obtener cotizaciones activas (pendientes y no vencidas)
  Future<List<Quotation>> getActiveQuotations() async {
    try {
      final allQuotations = await getAllQuotations();
      return allQuotations.where((q) {
        return q.status == QuotationStatus.pending && !q.isExpired;
      }).toList();
    } catch (e) {
      print('❌ Error obteniendo cotizaciones activas: $e');
      return [];
    }
  }

  /// Obtener cotizaciones vencidas
  Future<List<Quotation>> getExpiredQuotations() async {
    try {
      final allQuotations = await getAllQuotations();
      return allQuotations.where((q) => q.isExpired).toList();
    } catch (e) {
      print('❌ Error obteniendo cotizaciones vencidas: $e');
      return [];
    }
  }

  // ==================== UPDATE ====================

  /// Actualizar cotización
  Future<void> updateQuotation(Quotation quotation) async {
    try {
      final updatedQuotation = quotation.copyWith(
        updatedAt: DateTime.now(),
        synced: false,
      );

      // Actualizar usando SyncService (maneja Firebase automáticamente)
      await _syncService.updateDocument(
        _collectionName,
        quotation.id,
        updatedQuotation.toMap(),
      );

      print('✅ Cotización actualizada');
    } catch (e) {
      print('❌ Error actualizando cotización: $e');
      rethrow;
    }
  }

  // ... (El resto de los métodos UPDATE no necesitan cambios)
  /// Aprobar cotización
  Future<void> approveQuotation(String quotationId) async {
    try {
      final quotation = await getQuotationById(quotationId);
      if (quotation == null) throw Exception('Cotización no encontrada');

      if (quotation.isExpired) {
        throw Exception('No se puede aprobar una cotización vencida');
      }

      final approvedQuotation = quotation.copyWith(
        status: QuotationStatus.approved,
      );
      await updateQuotation(approvedQuotation);

      print('✅ Cotización aprobada');
    } catch (e) {
      print('❌ Error aprobando cotización: $e');
      rethrow;
    }
  }

  /// Rechazar cotización
  Future<void> rejectQuotation(String quotationId) async {
    try {
      final quotation = await getQuotationById(quotationId);
      if (quotation == null) throw Exception('Cotización no encontrada');

      final rejectedQuotation = quotation.copyWith(
        status: QuotationStatus.rejected,
      );
      await updateQuotation(rejectedQuotation);

      print('✅ Cotización rechazada');
    } catch (e) {
      print('❌ Error rechazando cotización: $e');
      rethrow;
    }
  }

  /// Convertir cotización a venta (RF05.2)
  Future<Sale> convertQuotationToSale({
    required String quotationId,
    required PaymentMethod paymentMethod,
    String? additionalNotes,
  }) async {
    print('🔄 Convirtiendo cotización a venta: $quotationId');

    try {
      final quotation = await getQuotationById(quotationId);
      if (quotation == null) {
        throw Exception('Cotización no encontrada');
      }

      if (!quotation.canConvert) {
        throw Exception(
          'La cotización no puede ser convertida. '
          'Estado: ${quotation.status.displayName}, '
          'Vencida: ${quotation.isExpired}',
        );
      }

      // Crear items de venta desde items de cotización
      final saleItems = quotation.items.map((item) {
        return SaleItem(
          productId: item.productId,
          productName: item.productName,
          sku: item.sku,
          quantity: item.quantity,
          unit: item.unit,
          unitPrice: item.unitPrice,
          total: item.total,
        );
      }).toList();

      // Crear venta
      final sale = Sale(
        id: 'sale_${DateTime.now().millisecondsSinceEpoch}',
        clientId: quotation.clientId,
        clientName: quotation.clientName,
        date: DateTime.now(),
        items: saleItems,
        subtotal: quotation.subtotal,
        tax: quotation.tax,
        discount: quotation.discount,
        total: quotation.total,
        paymentMethod: paymentMethod,
        status: SaleStatus.completed,
        notes: additionalNotes != null
            ? '${quotation.notes ?? ''}\n$additionalNotes'
            : quotation.notes,
        quotationId: quotation.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        synced: false,
      );

      // Guardar venta (esto automáticamente actualizará el inventario)
      final createdSale = await _saleService.createSale(sale);

      // Marcar cotización como convertida
      final convertedQuotation = quotation.copyWith(
        status: QuotationStatus.converted,
        convertedToSaleId: createdSale.id,
      );
      await updateQuotation(convertedQuotation);

      print('✅ Cotización convertida exitosamente');
      return createdSale;
    } catch (e) {
      print('❌ Error convirtiendo cotización: $e');
      rethrow;
    }
  }

  // ==================== DELETE ====================

  /// Eliminar cotización
  Future<void> deleteQuotation(String id) async {
    try {
      await _syncService.deleteDocument(_collectionName, id);
      print('✅ Cotización eliminada');
    } catch (e) {
      print('❌ Error eliminando cotización: $e');
      rethrow;
    }
  }

  // ... (El resto del código de MAINTENANCE y STATS no necesita cambios)
  /// Actualizar estado de cotizaciones vencidas automáticamente
  Future<void> updateExpiredQuotations() async {
    try {
      final allQuotations = await getAllQuotations();

      for (var quotation in allQuotations) {
        if (quotation.status == QuotationStatus.pending &&
            quotation.isExpired) {
          final expiredQuotation = quotation.copyWith(
            status: QuotationStatus.expired,
          );
          await updateQuotation(expiredQuotation);
          print('⌛ Cotización ${quotation.id} marcada como vencida');
        }
      }
    } catch (e) {
      print('❌ Error actualizando cotizaciones vencidas: $e');
    }
  }

  /// Obtener tasa de conversión de cotizaciones a ventas
  Future<Map<String, dynamic>> getConversionStats() async {
    try {
      final allQuotations = await getAllQuotations();

      final total = allQuotations.length;
      final converted = allQuotations
          .where((q) => q.status == QuotationStatus.converted)
          .length;
      final pending = allQuotations
          .where((q) => q.status == QuotationStatus.pending)
          .length;
      final approved = allQuotations
          .where((q) => q.status == QuotationStatus.approved)
          .length;
      final rejected = allQuotations
          .where((q) => q.status == QuotationStatus.rejected)
          .length;
      final expired = allQuotations
          .where((q) => q.status == QuotationStatus.expired)
          .length;

      final conversionRate = total > 0 ? (converted / total * 100) : 0.0;

      return {
        'total': total,
        'converted': converted,
        'pending': pending,
        'approved': approved,
        'rejected': rejected,
        'expired': expired,
        'conversionRate': conversionRate,
      };
    } catch (e) {
      print('❌ Error obteniendo estadísticas de conversión: $e');
      return {
        'total': 0,
        'converted': 0,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'expired': 0,
        'conversionRate': 0.0,
      };
    }
  }
}
