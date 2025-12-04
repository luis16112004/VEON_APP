class Provider {
  final String id;
  final String companyName;
  final String contactName;
  final String phoneNumber;
  final String email;
  final String address;
  final String postalCode;
  final String country;
  final String state;
  final String city;

  Provider({
    required this.id,
    required this.companyName,
    required this.contactName,
    required this.phoneNumber,
    required this.email,
    required this.address,
    required this.postalCode,
    required this.country,
    required this.state,
    required this.city,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyName': companyName,
      'contactName': contactName,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'postalCode': postalCode,
      'country': country,
      'state': state,
      'city': city,
    };
  }

  factory Provider.fromJson(Map<String, dynamic> json) {
    // Soporta tanto camelCase como snake_case (Laravel)
    return Provider(
      id: json['id']?.toString() ?? '',
      companyName: json['company_name'] ?? json['companyName'] ?? '',
      contactName: json['contact_name'] ?? json['contactName'] ?? '',
      phoneNumber: json['phone_number'] ?? json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      postalCode: json['postal_code'] ?? json['postalCode'] ?? '',
      country: json['country'] ?? '',
      state: json['state'] ?? '',
      city: json['city'] ?? '',
    );
  }

  Provider copyWith({
    String? id,
    String? companyName,
    String? contactName,
    String? phoneNumber,
    String? email,
    String? address,
    String? postalCode,
    String? country,
    String? state,
    String? city,
  }) {
    return Provider(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      contactName: contactName ?? this.contactName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
    );
  }
}
