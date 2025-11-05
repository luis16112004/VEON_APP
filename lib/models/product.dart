class Product {
  final String id;
  final String name;
  final String sku;
  final String? shortDescription;
  final String? providerId;
  final String? providerName;
  final String? unit;
  final String? unitOfMeasurement;
  final double cost;
  final double salePrice;
  final String? imagePath;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    this.shortDescription,
    this.providerId,
    this.providerName,
    this.unit,
    this.unitOfMeasurement,
    required this.cost,
    required this.salePrice,
    this.imagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'shortDescription': shortDescription,
      'providerId': providerId,
      'providerName': providerName,
      'unit': unit,
      'unitOfMeasurement': unitOfMeasurement,
      'cost': cost,
      'salePrice': salePrice,
      'imagePath': imagePath,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String,
      shortDescription: json['shortDescription'] as String?,
      providerId: json['providerId'] as String?,
      providerName: json['providerName'] as String?,
      unit: json['unit'] as String?,
      unitOfMeasurement: json['unitOfMeasurement'] as String?,
      cost: (json['cost'] as num).toDouble(),
      salePrice: (json['salePrice'] as num).toDouble(),
      imagePath: json['imagePath'] as String?,
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? sku,
    String? shortDescription,
    String? providerId,
    String? providerName,
    String? unit,
    String? unitOfMeasurement,
    double? cost,
    double? salePrice,
    String? imagePath,
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
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
