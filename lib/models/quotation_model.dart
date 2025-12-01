// lib/models/quotation_model.dart

class Quotation {
  final String id;
  final String clientId;
  final String clientName;
  final DateTime date;
  final DateTime validUntil; // Fecha de validez (RF05.1)
  final List<QuotationItem> items;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final QuotationStatus status;
  final String? notes;
  final String? terms; // Términos y condiciones
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;
  final String? convertedToSaleId; // ID de venta si fue convertida

  Quotation({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.date,
    required this.validUntil,
    required this.items,
    required this.subtotal,
    this.tax = 0.0,
    this.discount = 0.0,
    required this.total,
    this.status = QuotationStatus.pending,
    this.notes,
    this.terms,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
    this.convertedToSaleId,
  });

  // Crear cotización con cálculos automáticos
  factory Quotation.create({
    required String id,
    required String clientId,
    required String clientName,
    required DateTime date,
    int validDays = 15, // Válida por 15 días por defecto
    required List<QuotationItem> items,
    double taxRate = 0.16,
    double discount = 0.0,
    String? notes,
    String? terms,
  }) {
    final validUntil = date.add(Duration(days: validDays));
    final subtotal = items.fold(0.0, (sum, item) => sum + item.total);
    final tax = subtotal * taxRate;
    final total = subtotal + tax - discount;

    return Quotation(
      id: id,
      clientId: clientId,
      clientName: clientName,
      date: date,
      validUntil: validUntil,
      items: items,
      subtotal: subtotal,
      tax: tax,
      discount: discount,
      total: total,
      status: QuotationStatus.pending,
      notes: notes,
      terms: terms ?? _defaultTerms,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      synced: false,
    );
  }

  // Términos y condiciones por defecto
  static const String _defaultTerms = '''
TÉRMINOS Y CONDICIONES:
1. Esta cotización es válida hasta la fecha indicada
2. Los precios están sujetos a cambios sin previo aviso
3. El tiempo de entrega será coordinado con el cliente
4. Los pagos deben realizarse según lo acordado
5. Las devoluciones se aceptan dentro de los 7 días posteriores a la compra
''';

  // Verificar si está vencida
  bool get isExpired => DateTime.now().isAfter(validUntil);

  // Verificar si puede ser convertida a venta
  bool get canConvert =>
      status == QuotationStatus.pending &&
          !isExpired &&
          convertedToSaleId == null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'date': date.toIso8601String(),
      'validUntil': validUntil.toIso8601String(),
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'status': status.toString(),
      'notes': notes,
      'terms': terms,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'synced': synced,
      'convertedToSaleId': convertedToSaleId,
    };
  }

  factory Quotation.fromMap(Map<String, dynamic> map) {
    return Quotation(
      id: map['id'],
      clientId: map['clientId'],
      clientName: map['clientName'],
      date: DateTime.parse(map['date']),
      validUntil: DateTime.parse(map['validUntil']),
      items: (map['items'] as List)
          .map((item) => QuotationItem.fromMap(item))
          .toList(),
      subtotal: map['subtotal'].toDouble(),
      tax: map['tax'].toDouble(),
      discount: map['discount']?.toDouble() ?? 0.0,
      total: map['total'].toDouble(),
      status: QuotationStatus.values.firstWhere(
            (e) => e.toString() == map['status'],
        orElse: () => QuotationStatus.pending,
      ),
      notes: map['notes'],
      terms: map['terms'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      synced: map['synced'] ?? false,
      convertedToSaleId: map['convertedToSaleId'],
    );
  }

  Quotation copyWith({
    String? id,
    String? clientId,
    String? clientName,
    DateTime? date,
    DateTime? validUntil,
    List<QuotationItem>? items,
    double? subtotal,
    double? tax,
    double? discount,
    double? total,
    QuotationStatus? status,
    String? notes,
    String? terms,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
    String? convertedToSaleId,
  }) {
    return Quotation(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      date: date ?? this.date,
      validUntil: validUntil ?? this.validUntil,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
      convertedToSaleId: convertedToSaleId ?? this.convertedToSaleId,
    );
  }
}

// Item de cotización (similar a SaleItem)
class QuotationItem {
  final String productId;
  final String productName;
  final String sku;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double total;

  QuotationItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.total,
  });

  factory QuotationItem.create({
    required String productId,
    required String productName,
    required String sku,
    required double quantity,
    required String unit,
    required double unitPrice,
  }) {
    return QuotationItem(
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

  factory QuotationItem.fromMap(Map<String, dynamic> map) {
    return QuotationItem(
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

// Estados de cotización
enum QuotationStatus {
  pending, // Pendiente de respuesta
  approved, // Aprobada por el cliente
  rejected, // Rechazada
  expired, // Vencida
  converted, // Convertida a venta
}

extension QuotationStatusExtension on QuotationStatus {
  String get displayName {
    switch (this) {
      case QuotationStatus.pending:
        return 'Pendiente';
      case QuotationStatus.approved:
        return 'Aprobada';
      case QuotationStatus.rejected:
        return 'Rechazada';
      case QuotationStatus.expired:
        return 'Vencida';
      case QuotationStatus.converted:
        return 'Convertida';
    }
  }

  String get icon {
    switch (this) {
      case QuotationStatus.pending:
        return '⏳';
      case QuotationStatus.approved:
        return '✅';
      case QuotationStatus.rejected:
        return '❌';
      case QuotationStatus.expired:
        return '⌛';
      case QuotationStatus.converted:
        return '🔄';
    }
  }
}