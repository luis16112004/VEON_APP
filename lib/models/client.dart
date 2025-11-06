class Client {
  final String id;
  final String fullName;
  final String? companyName;
  final String phoneNumber;
  final String email;
  final String address;
  final String? imagePath;
  final int salesCount;

  Client({
    required this.id,
    required this.fullName,
    this.companyName,
    required this.phoneNumber,
    required this.email,
    required this.address,
    this.imagePath,
    this.salesCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'companyName': companyName,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'imagePath': imagePath,
      'salesCount': salesCount,
    };
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      companyName: json['companyName'] as String?,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String,
      address: json['address'] as String,
      imagePath: json['imagePath'] as String?,
      salesCount: json['salesCount'] as int? ?? 0,
    );
  }

  Client copyWith({
    String? id,
    String? fullName,
    String? companyName,
    String? phoneNumber,
    String? email,
    String? address,
    String? imagePath,
    int? salesCount,
  }) {
    return Client(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      companyName: companyName ?? this.companyName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      imagePath: imagePath ?? this.imagePath,
      salesCount: salesCount ?? this.salesCount,
    );
  }
}






