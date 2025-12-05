import '../models/user_model.dart';

/// Servicio para gestionar permisos basados en roles
class PermissionService {
  static PermissionService? _instance;
  
  PermissionService._();
  
  static PermissionService get instance {
    _instance ??= PermissionService._();
    return _instance!;
  }

  /// Verificar si el usuario puede crear ventas
  bool canCreateSale(UserModel? user) {
    if (user == null) return false;
    return ['admin', 'vendedor', 'gerente'].contains(user.role.toLowerCase());
  }

  /// Verificar si el usuario puede ver ventas
  bool canViewSales(UserModel? user) {
    if (user == null) return false;
    return ['admin', 'vendedor', 'gerente'].contains(user.role.toLowerCase());
  }

  /// Verificar si el usuario puede editar/eliminar ventas
  /// Vendedor NO puede editar/eliminar ventas
  bool canEditSale(UserModel? user) {
    if (user == null) return false;
    return ['admin', 'gerente'].contains(user.role.toLowerCase());
  }

  /// Verificar si el usuario puede crear cotizaciones
  bool canCreateQuotation(UserModel? user) {
    if (user == null) return false;
    return ['admin', 'vendedor', 'gerente'].contains(user.role.toLowerCase());
  }

  /// Verificar si el usuario puede ver cotizaciones
  bool canViewQuotations(UserModel? user) {
    if (user == null) return false;
    return ['admin', 'vendedor', 'gerente'].contains(user.role.toLowerCase());
  }

  /// Verificar si el usuario puede editar/eliminar cotizaciones
  /// Vendedor SÍ puede editar/eliminar sus propias cotizaciones
  bool canEditQuotation(UserModel? user) {
    if (user == null) return false;
    return ['admin', 'gerente', 'vendedor'].contains(user.role.toLowerCase());
  }

  /// Verificar si el usuario puede gestionar productos
  bool canManageProducts(UserModel? user) {
    if (user == null) return false;
    return ['admin', 'gerente'].contains(user.role.toLowerCase());
  }

  /// Verificar si el usuario puede gestionar categorías
  bool canManageCategories(UserModel? user) {
    if (user == null) return false;
    return ['admin', 'gerente'].contains(user.role.toLowerCase());
  }

  /// Verificar si el usuario puede gestionar clientes
  bool canManageClients(UserModel? user) {
    if (user == null) return false;
    return ['admin', 'gerente'].contains(user.role.toLowerCase());
  }

  /// Verificar si el usuario puede gestionar proveedores
  bool canManageProviders(UserModel? user) {
    if (user == null) return false;
    return ['admin', 'gerente'].contains(user.role.toLowerCase());
  }

  /// Verificar si el usuario puede gestionar usuarios
  bool canManageUsers(UserModel? user) {
    if (user == null) return false;
    return ['admin', 'gerente'].contains(user.role.toLowerCase());
  }

  /// Verificar si el usuario puede ver reportes
  bool canViewReports(UserModel? user) {
    if (user == null) return false;
    return ['admin', 'gerente', 'vendedor'].contains(user.role.toLowerCase());
  }

  /// Verificar si el usuario es admin
  bool isAdmin(UserModel? user) {
    if (user == null) return false;
    return user.role.toLowerCase() == 'admin';
  }

  /// Verificar si el usuario es gerente
  bool isManager(UserModel? user) {
    if (user == null) return false;
    return user.role.toLowerCase() == 'gerente';
  }

  /// Verificar si el usuario es vendedor
  bool isSeller(UserModel? user) {
    if (user == null) return false;
    return user.role.toLowerCase() == 'vendedor';
  }
}

