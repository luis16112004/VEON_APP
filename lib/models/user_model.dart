// user_model.dart

class UserModel {
  final String id; // El _id de MongoDB
  final String name; // Necesitas este campo para el Home
  final String email;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.name, // Asegúrate de agregarlo al formulario de registro
    required this.email,
    this.createdAt,
  });

  // Convertir el modelo a un Map para guardar en Hive/Mongo
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'createdAt': createdAt,
    };
  }

  // Crear el modelo desde un Map
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      createdAt: json['createdAt'] as String?,
    );
  }
}