// user_model.dart

class UserModel {
  final String id; // El ID del documento en Firestore
  final String name;
  final String email;
  final String role; // 'admin' or 'vendedor'
  final String? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'vendedor', // Default role
    this.createdAt,
  });

  // Convertir el modelo a un Map para guardar en Hive/Firestore
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'role': role,
      'createdAt': createdAt,
    };
  }

  // Crear el modelo desde un Map
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'vendedor',
      createdAt: json['createdAt'] as String?,
    );
  }
}
