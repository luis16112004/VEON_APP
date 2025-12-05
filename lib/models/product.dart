class Product {
  final int? id; // Changed from String to int? for FastAPI compatibility
  final String name;
  final String sku;
  final String? shortDescription;
  final String? providerId;
  final String? providerName;
  final String? unit;
  final String? unitOfMeasurement;
  final double cost;
  final double salePrice;
  final int stock;
  final String? imagePath;
  final int? categoryId; // Added for FastAPI
  final String? categoryName; // Added for display purposes

  Product({
    this.id,
    required this.name,
    required this.sku,
    this.shortDescription,
    this.providerId,
    this.providerName,
    this.unit,
    this.unitOfMeasurement,
    required this.cost,
    required this.salePrice,
    this.stock = 0,
    this.imagePath,
    this.categoryId,
    this.categoryName,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'sku': sku,
      if (shortDescription != null) 'short_description': shortDescription,
      if (providerId != null) 'provider_id': providerId,
      if (providerName != null) 'provider_name': providerName,
      if (unit != null) 'unit': unit,
      if (unitOfMeasurement != null) 'unit_of_measurement': unitOfMeasurement,
      'cost': cost,
      'sale_price': salePrice,
      'stock': stock,
      if (imagePath != null) 'image_path': imagePath,
      if (categoryId != null) 'category_id': categoryId,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse doubles
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Helper to safely parse ints
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Product(
      id: json['id'] is int 
          ? json['id'] as int?
          : json['id'] is String 
              ? int.tryParse(json['id'] as String)
              : null,
      name: json['name']?.toString() ?? 'Sin Nombre',
      sku: json['sku']?.toString() ?? '',
      shortDescription: json['short_description']?.toString() ?? json['shortDescription']?.toString(),
      providerId: json['provider_id']?.toString() ?? json['providerId']?.toString(),
      providerName: json['provider_name']?.toString() ?? json['providerName']?.toString(),
      unit: json['unit']?.toString(),
      unitOfMeasurement: json['unit_of_measurement']?.toString() ?? json['unitOfMeasurement']?.toString(),
      cost: parseDouble(json['cost']),
      salePrice: parseDouble(json['sale_price'] ?? json['salePrice']),
      stock: parseInt(json['stock']),
      imagePath: json['image_path']?.toString() ?? json['imagePath']?.toString(),
      categoryId: parseInt(json['category_id'] ?? json['categoryId']),
      categoryName: json['category'] is Map 
          ? json['category']['name']?.toString() 
          : json['categoryName']?.toString(),
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? sku,
    String? shortDescription,
    String? providerId,
    String? providerName,
    String? unit,
    String? unitOfMeasurement,
    double? cost,
    double? salePrice,
    int? stock,
    String? imagePath,
    int? categoryId,
    String? categoryName,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      shortDescription: shortDescription ?? this.shortDescription,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      unit: unit ?? this.unit,
      unitOfMeasurement: unitOfMeasurement ?? this.unitOfMeasurement,
      cost: cost ?? this.cost,
      salePrice: salePrice ?? this.salePrice,
      stock: stock ?? this.stock,
      imagePath: imagePath ?? this.imagePath,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
    );
  }
}
