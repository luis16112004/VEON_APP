# 🔥 Configuración de Firebase - Guía Rápida

## Paso 1: Crear Proyecto en Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Haz clic en "Agregar proyecto"
3. Completa el nombre del proyecto (ej: "veon-app")
4. Sigue los pasos de configuración

## Paso 2: Agregar Aplicación Flutter

### Android

1. En Firebase Console, haz clic en el ícono de Android
2. Ingresa el package name (ej: `com.example.veon_app`)
3. Descarga `google-services.json`
4. Coloca el archivo en: `android/app/google-services.json`

### iOS

1. En Firebase Console, haz clic en el ícono de iOS
2. Ingresa el bundle ID
3. Descarga `GoogleService-Info.plist`
4. Coloca el archivo en: `ios/Runner/GoogleService-Info.plist`

## Paso 3: Configurar Firebase en Flutter

### Instalar FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### Configurar Firebase en el Proyecto

```bash
flutterfire configure
```

Esto generará automáticamente el archivo `lib/firebase_options.dart`.

## Paso 4: Inicializar Firebase en main.dart

Actualiza `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Generado automáticamente

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Inicializar Hive para almacenamiento local
  await LocalStorage.instance.init();
  
  // Inicializar servicio de sincronización
  await SyncService.instance.init();
  
  // Conectar a Firebase
  await FirebaseService.instance.connect();
  
  runApp(MyApp());
}
```

## Paso 5: Configurar Firebase Functions (Backend)

```bash
cd functions
npm install
firebase init functions
```

Sigue las instrucciones y selecciona:
- TypeScript
- ESLint
- Instalar dependencias ahora

## Paso 6: Configurar Reglas de Seguridad de Firestore

En Firebase Console → Firestore Database → Reglas:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Usuarios autenticados solo pueden acceder a sus propios datos
    match /{collection}/{document} {
      allow read, write: if request.auth != null 
        && resource.data.userId == request.auth.uid;
      
      allow create: if request.auth != null 
        && request.resource.data.userId == request.auth.uid;
    }
  }
}
```

## Paso 7: Desplegar Firebase Functions

```bash
cd functions
npm run build
firebase deploy --only functions
```

## ✅ Verificación

1. **Probar autenticación**: Intenta hacer login en la app
2. **Probar conexión**: Verifica que los datos se guarden en Firestore
3. **Probar offline**: Desactiva internet y verifica que funcione offline

## 🔧 Variables de Entorno (Opcional)

Para desarrollo local con emulador, crea `functions/.env`:

```env
FUNCTIONS_EMULATOR=true
```

## 📝 Notas Importantes

- **No commitees** archivos de configuración (`google-services.json`, `GoogleService-Info.plist`) a git si contienen credenciales sensibles
- Las **Firebase Functions** requieren un plan Blaze (pago) para deploy en producción
- El plan **Spark (gratuito)** funciona para desarrollo y testing

## 🆘 Problemas Comunes

### Error: "Firebase not initialized"
- Asegúrate de llamar `Firebase.initializeApp()` antes de usar Firebase

### Error: "Missing google-services.json"
- Verifica que el archivo esté en `android/app/google-services.json`

### Error: "Permission denied" en Firestore
- Revisa las reglas de seguridad de Firestore

## 📚 Recursos

- [Documentación FlutterFire](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/)

