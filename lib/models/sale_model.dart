// lib/models/sale_model.dart

class Sale {
  final String id;
  final String clientId; // Referencia al cliente
  final String clientName; // Nombre del cliente (desnormalizado para reportes)
  final DateTime date;
  final List<SaleItem> items; // Productos vendidos
  final double subtotal;
  final double tax; // IVA u otros impuestos
  final double discount; // Descuento aplicado
  final double total;
  final PaymentMethod paymentMethod;
  final SaleStatus status;
  final String? notes; // Notas adicionales
  final String? quotationId; // Si viene de una cotización
  final String? userId; // ID del vendedor
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced; // Para sincronización con Firebase

  Sale({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.date,
    required this.items,
    required this.subtotal,
    this.tax = 0.0,
    this.discount = 0.0,
    required this.total,
    required this.paymentMethod,
    this.status = SaleStatus.completed,
    this.notes,
    this.quotationId,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
  });

  // Calcular totales automáticamente
  factory Sale.create({
    required String id,
    required String clientId,
    required String clientName,
    required DateTime date,
    required List<SaleItem> items,
    double taxRate = 0.16, // 16% IVA por defecto
    double discount = 0.0,
    required PaymentMethod paymentMethod,
    SaleStatus status = SaleStatus.completed,
    String? notes,
    String? quotationId,
    String? userId,
  }) {
    final subtotal = items.fold(0.0, (sum, item) => sum + item.total);
    final tax = subtotal * taxRate;
    final total = subtotal + tax - discount;

    return Sale(
      id: id,
      clientId: clientId,
      clientName: clientName,
      date: date,
      items: items,
      subtotal: subtotal,
      tax: tax,
      discount: discount,
      total: total,
      paymentMethod: paymentMethod,
      status: status,
      notes: notes,
      quotationId: quotationId,
      userId: userId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      synced: false,
    );
  }

  // Convertir a Map para guardar en DB
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'date': date.toIso8601String(),
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'paymentMethod': paymentMethod.toString(),
      'status': status.toString(),
      'notes': notes,
      'quotationId': quotationId,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'synced': synced,
    };
  }

  // Crear desde Map (desde DB)
  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      clientId: map['clientId'],
      clientName: map['clientName'],
      date: DateTime.parse(map['date']),
      items:
          (map['items'] as List).map((item) => SaleItem.fromMap(item)).toList(),
      subtotal: map['subtotal'].toDouble(),
      tax: map['tax'].toDouble(),
      discount: map['discount']?.toDouble() ?? 0.0,
      total: map['total'].toDouble(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString() == map['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      status: SaleStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => SaleStatus.completed,
      ),
      notes: map['notes'],
      quotationId: map['quotationId'],
      userId: map['userId'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      synced: map['synced'] ?? false,
    );
  }

  // Copiar con cambios
  Sale copyWith({
    String? id,
    String? clientId,
    String? clientName,
    DateTime? date,
    List<SaleItem>? items,
    double? subtotal,
    double? tax,
    double? discount,
    double? total,
    PaymentMethod? paymentMethod,
    SaleStatus? status,
    String? notes,
    String? quotationId,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return Sale(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      date: date ?? this.date,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      quotationId: quotationId ?? this.quotationId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }
}

// Item individual de una venta
class SaleItem {
  final String productId;
  final String productName; // Desnormalizado
  final String sku;
  final double quantity;
  final String unit; // kg, pza, caja, etc.
  final double unitPrice;
  final double total; // quantity * unitPrice

  SaleItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.total,
  });

  factory SaleItem.create({
    required String productId,
    required String productName,
    required String sku,
    required double quantity,
    required String unit,
    required double unitPrice,
  }) {
    return SaleItem(
      productId: productId,
      productName: productName,
      sku: sku,
      quantity: quantity,
      unit: unit,
      unitPrice: unitPrice,
      total: quantity * unitPrice,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
      'total': total,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      productId: map['productId'],
      productName: map['productName'],
      sku: map['sku'],
      quantity: map['quantity'].toDouble(),
      unit: map['unit'],
      unitPrice: map['unitPrice'].toDouble(),
      total: map['total'].toDouble(),
    );
  }
}

// Métodos de pago
enum PaymentMethod {
  cash,
  card,
  transfer,
  check,
  credit,
  multiple, // Pago mixto
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.card:
        return 'Tarjeta';
      case PaymentMethod.transfer:
        return 'Transferencia';
      case PaymentMethod.check:
        return 'Cheque';
      case PaymentMethod.credit:
        return 'Crédito';
      case PaymentMethod.multiple:
        return 'Múltiple';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.cash:
        return '💵';
      case PaymentMethod.card:
        return '💳';
      case PaymentMethod.transfer:
        return '🏦';
      case PaymentMethod.check:
        return '📝';
      case PaymentMethod.credit:
        return '📋';
      case PaymentMethod.multiple:
        return '💰';
    }
  }
}

// Estados de venta
enum SaleStatus {
  draft, // Borrador (no confirmada)
  completed, // Completada
  cancelled, // Cancelada
  pending, // Pendiente de pago
}

extension SaleStatusExtension on SaleStatus {
  String get displayName {
    switch (this) {
      case SaleStatus.draft:
        return 'Borrador';
      case SaleStatus.completed:
        return 'Completada';
      case SaleStatus.cancelled:
        return 'Cancelada';
      case SaleStatus.pending:
        return 'Pendiente';
    }
  }

  String get icon {
    switch (this) {
      case SaleStatus.draft:
        return '📝';
      case SaleStatus.completed:
        return '✅';
      case SaleStatus.cancelled:
        return '❌';
      case SaleStatus.pending:
        return '⏳';
    }
  }
}
