# 🔥 Guía de Migración: MongoDB → Firebase

Esta guía explica los cambios realizados al migrar de MongoDB a Firebase.

## 📋 Cambios Principales

### Backend (Firebase Cloud Functions)

Se ha creado un backend completo usando Firebase Cloud Functions en el directorio `functions/`:

- ✅ **Repository Pattern**: Capa de acceso a datos separada
- ✅ **Service Layer**: Lógica de negocio centralizada
- ✅ **RESTful API**: Endpoints organizados por recursos
- ✅ **Autenticación**: Middleware de autenticación con Firebase Auth
- ✅ **Validación**: Validación de datos centralizada
- ✅ **Manejo de Errores**: Sistema de errores estructurado

### Frontend (Flutter)

#### Cambios en Servicios:

1. **`mongo_service.dart` → `firebase_service.dart`**
   - Reemplazado completamente por `FirebaseService`
   - Usa Firestore en lugar de MongoDB
   - Integrado con Firebase Auth para autenticación

2. **`sync_service.dart`**
   - Actualizado para usar `FirebaseService` en lugar de `MongoService`
   - Mantiene la misma interfaz para compatibilidad

#### Dependencias Actualizadas:

```yaml
# Antes (MongoDB)
mongo_dart: ^0.10.3

# Ahora (Firebase)
firebase_core: ^3.6.0
cloud_firestore: ^5.4.4
firebase_auth: ^5.3.1
```

## 🚀 Configuración Requerida

### 1. Configurar Firebase en Flutter

1. Crear proyecto en [Firebase Console](https://console.firebase.google.com/)
2. Agregar aplicación Flutter al proyecto
3. Descargar `google-services.json` (Android) y `GoogleService-Info.plist` (iOS)
4. Colocar los archivos en las ubicaciones correspondientes

### 2. Inicializar Firebase en `main.dart`

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Se genera automáticamente

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Inicializar Hive
  await LocalStorage.instance.init();
  
  // Inicializar servicio de sincronización
  await SyncService.instance.init();
  
  runApp(MyApp());
}
```

### 3. Generar `firebase_options.dart`

```bash
flutter pub get
flutter pub run flutterfire_cli:flutterfire configure
```

### 4. Configurar Firebase Functions

```bash
cd functions
npm install
firebase init functions
```

## 📝 Cambios en el Código

### Conexión a la Base de Datos

**Antes (MongoDB):**
```dart
await MongoService.instance.connect();
```

**Ahora (Firebase):**
```dart
await FirebaseService.instance.connect();
```

Firebase se conecta automáticamente, pero puedes verificar la conexión con `isConnected()`.

### Autenticación

Firebase Auth maneja la autenticación. Necesitarás integrar el flujo de autenticación:

```dart
// Registro
await FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: email,
  password: password,
);

// Login
await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: email,
  password: password,
);

// Obtener token para las APIs
String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
```

### Colecciones

Las colecciones en Firestore tienen la misma estructura que antes, pero ahora incluyen:

- `userId`: ID del usuario propietario (multi-tenant)
- `createdAt`: Fecha de creación (ISO 8601)
- `updatedAt`: Fecha de actualización (ISO 8601)

## 🔐 Seguridad

### Firestore Security Rules

Configura las reglas de seguridad en Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Usuarios solo pueden acceder a sus propios datos
    match /{collection}/{document} {
      allow read, write: if request.auth != null 
        && resource.data.userId == request.auth.uid;
      
      allow create: if request.auth != null 
        && request.resource.data.userId == request.auth.uid;
    }
  }
}
```

## 📡 APIs Backend

El backend está disponible en `functions/` con las siguientes APIs:

- `/api/auth` - Autenticación
- `/api/clients` - Clientes
- `/api/products` - Productos
- `/api/providers` - Proveedores
- `/api/sales` - Ventas
- `/api/quotations` - Cotizaciones

Ver `functions/README.md` para más detalles.

## 🔄 Migración de Datos

Si tienes datos existentes en MongoDB que quieres migrar:

1. Exportar datos de MongoDB
2. Transformar al formato de Firestore
3. Importar usando el Admin SDK o script de migración

**Nota**: No se incluye un script de migración automática. Debes crear uno según tus necesidades específicas.

## ✅ Checklist de Migración

- [ ] Crear proyecto en Firebase Console
- [ ] Configurar Firebase en Flutter (`google-services.json`, etc.)
- [ ] Generar `firebase_options.dart`
- [ ] Actualizar `main.dart` para inicializar Firebase
- [ ] Reemplazar llamadas a `MongoService` por `FirebaseService`
- [ ] Configurar reglas de seguridad de Firestore
- [ ] Configurar Firebase Functions (backend)
- [ ] Probar autenticación
- [ ] Probar sincronización offline/online
- [ ] Migrar datos existentes (si aplica)
- [ ] Actualizar documentación del proyecto

## 🐛 Solución de Problemas

### Error: "Firebase not initialized"

Asegúrate de llamar `Firebase.initializeApp()` antes de usar cualquier servicio de Firebase.

### Error: "User not authenticated"

Verifica que el usuario esté autenticado antes de hacer operaciones en Firestore.

### Error: "Permission denied"

Revisa las reglas de seguridad de Firestore y asegúrate de que el usuario tenga permisos.

## 📚 Recursos

- [Firebase Flutter Documentation](https://firebase.google.com/docs/flutter/setup)
- [Cloud Firestore Documentation](https://firebase.google.com/docs/firestore)
- [Firebase Auth Documentation](https://firebase.google.com/docs/auth)

## 💡 Notas Importantes

1. **Offline Support**: Firestore tiene soporte offline integrado. El `SyncService` todavía es útil para operaciones más complejas.

2. **Autenticación**: Firebase Auth reemplaza cualquier sistema de autenticación previo. Asegúrate de migrar los usuarios.

3. **Multi-tenant**: Todos los datos están aislados por `userId` para soportar múltiples usuarios.

4. **Backend**: Las Firebase Functions proporcionan la lógica del backend. El cliente puede usar directamente Firestore o las APIs REST.

