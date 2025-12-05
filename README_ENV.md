# 🔐 Configuración de Variables de Entorno

## Archivo .env

Se ha creado un archivo `.env.example` como plantilla para las credenciales de Firebase.

### Pasos para configurar:

1. **Copia el archivo de ejemplo:**
   ```bash
   cp .env.example .env
   ```

2. **Edita el archivo `.env`** y completa con tus credenciales:
   - Puedes obtener estas credenciales desde Firebase Console
   - Ve a: Firebase Console > Project Settings > General

3. **Agrega `.env` a `.gitignore`:**
   ```gitignore
   .env
   ```

## Importante

**Las credenciales de Firebase se configuran principalmente a través de:**

### Flutter (App móvil)
- Ejecuta: `flutterfire configure`
- Esto generará automáticamente:
  - `lib/firebase_options.dart`
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`

### Firebase Functions (Backend)
- Las credenciales se obtienen automáticamente cuando despliegas
- Para desarrollo local, puedes usar el emulador de Firebase

## Variables de Entorno en el Código

El archivo `.env` es útil para:
- Configuraciones de desarrollo
- URLs de APIs personalizadas
- Claves de servicios adicionales
- Configuraciones específicas del entorno

**Nota**: Firebase normalmente no requiere un archivo `.env` porque las credenciales se gestionan automáticamente a través de los archivos de configuración generados.

## Uso en Flutter

Si necesitas usar variables de entorno en Flutter, puedes usar el paquete `flutter_dotenv`:

```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

Luego en tu código:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Cargar .env
await dotenv.load(fileName: ".env");

// Usar variables
String apiKey = dotenv.env['FIREBASE_API_KEY'] ?? '';
```

## Seguridad

⚠️ **NUNCA** commitees archivos `.env` con credenciales reales a git.

Siempre usa `.env.example` como plantilla sin valores sensibles.

