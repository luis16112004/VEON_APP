// lib/services/sale_service.dart

import '../models/sale_model.dart';
import '../models/product.dart'; // Importante tener el modelo de Product
import '../database/local_storage.dart';
import '../database/mongo_service.dart';
import '../database/sync_service.dart';
import 'product_service.dart';

class SaleService {
  static final SaleService _instance = SaleService._internal();
  factory SaleService() => _instance;
  SaleService._internal();

  final _localStorage = LocalStorage.instance;
  final _mongoService = MongoService.instance;
  final _syncService = SyncService.instance;
  final _productService = ProductService();

  static const String _collectionName = 'sales';

  // ==================== CREATE ====================

  Future<Sale> createSale(Sale sale) async {
    print('📝 Creando venta: ${sale.id}');

    try {
      // PASO 1: Validar stock
      for (var item in sale.items) {
        final product = await _productService.getProductById(item.productId);
        if (product == null) {
          throw Exception('Producto no encontrado: ${item.productName}');
        }
        // ... Lógica de stock (asumiendo que ya funciona)
      }

      // PASO 2: Guardar localmente
      await LocalStorage.instance.saveLocal(_collectionName, sale.id, sale.toMap());
      print('✅ Venta guardada localmente');

      // PASO 3: Actualizar inventario
      await _updateInventoryForSale(sale);
      print('✅ Inventario actualizado');

      // PASO 4: Sincronizar
      if (_syncService.isOnline) {
        await _mongoService.insertOne(_collectionName, sale.toMap());
        print('✅ Venta sincronizada con MongoDB');
        return sale.copyWith(synced: true);
      } else {
        await LocalStorage.instance.addPendingSync(
          operation: 'insert',
          collection: _collectionName,
          data: sale.toMap(),
          documentId: sale.id,
        );
        print('📦 Venta en cola de sincronización');
      }

      return sale;
    } catch (e) {
      print('❌ Error creando venta: $e');
      rethrow;
    }
  }

  // ==================== READ ====================

  Future<List<Sale>> getAllSales() async {
    final docs = await _syncService.getDocuments(_collectionName);
    return docs.map((doc) => Sale.fromMap(doc)).toList();
  }

  Future<Sale?> getSaleById(String id) async {
    final doc = await _syncService.getDocument(_collectionName, id);
    return doc != null ? Sale.fromMap(doc) : null;
  }

  // ==================== UPDATE ====================

  Future<void> updateSale(Sale sale) async {
    final updatedSale = sale.copyWith(updatedAt: DateTime.now());
    await _syncService.updateDocument(
        _collectionName, updatedSale.id, updatedSale.toMap());
    print('✅ Venta actualizada');
  }

  Future<void> cancelSale(String saleId) async {
    try {
      final sale = await getSaleById(saleId);
      if (sale == null) throw Exception('Venta no encontrada');

      for (var item in sale.items) {
        final product = await _productService.getProductById(item.productId);
        if (product != null) {

          // ========= 👇 CORRECCIÓN 1 AQUÍ 👇 =========
          // Si product.unit es nulo, usamos 'item.unit' como respaldo seguro.
          final quantityInBaseUnit = _convertToBaseUnit(
              item.quantity, item.unit, product.unit ?? item.unit);

          final newStock = (product.stock + quantityInBaseUnit).round();

          final updatedProduct = product.copyWith(
            stock: newStock,
          );
          await _productService.updateProduct(updatedProduct);
        }
      }
      final cancelledSale = sale.copyWith(status: SaleStatus.cancelled);
      await updateSale(cancelledSale);
      print('✅ Venta cancelada y stock devuelto');
    } catch (e) {
      print('❌ Error cancelando venta: $e');
      rethrow;
    }
  }

  // ==================== DELETE ====================

  Future<void> deleteSale(String id) async {
    await _syncService.deleteDocument(_collectionName, id);
    print('✅ Venta eliminada');
  }

  // ==================== HELPER FUNCTIONS ====================

  Future<void> _updateInventoryForSale(Sale sale) async {
    for (var item in sale.items) {
      try {
        final product = await _productService.getProductById(item.productId);
        if (product == null) continue;

        // ========= 👇 CORRECCIÓN 2 AQUÍ 👇 =========
        // Si product.unit es nulo, usamos 'item.unit' como respaldo seguro.
        final quantityInBaseUnit = _convertToBaseUnit(
            item.quantity, item.unit, product.unit ?? item.unit);

        final newStock = (product.stock - quantityInBaseUnit).round();

        final updatedProduct = product.copyWith(stock: newStock);

        await _productService.updateProduct(updatedProduct);

        // Usamos '??' para los prints por seguridad, aunque el error principal ya está corregido.
        print('   📦 Stock actualizado: ${product.name} -> $newStock ${product.unit ?? 'unidades'}');
      } catch (e) {
        print('   ⚠️ Error actualizando stock de ${item.productName}: $e');
      }
    }
  }

  double _convertToBaseUnit(double quantity, String fromUnit, String baseUnit) {
    if (fromUnit.toLowerCase() == baseUnit.toLowerCase()) {
      return quantity;
    }
    final conversions = {
      'kg_g': 1000.0,
      'l_ml': 1000.0,
      'caja_pza': 12.0,
      'm_cm': 100.0,
    };
    final key = '${baseUnit.toLowerCase()}_${fromUnit.toLowerCase()}';
    if (conversions.containsKey(key)) {
      return quantity * conversions[key]!;
    }
    final reverseKey = '${fromUnit.toLowerCase()}_${baseUnit.toLowerCase()}';
    if (conversions.containsKey(reverseKey)) {
      return quantity / conversions[reverseKey]!;
    }
    return quantity;
  }
}
