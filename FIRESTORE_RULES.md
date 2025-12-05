# 🔥 Reglas de Seguridad de Firestore

## Configuración Importante

Para que los datos se guarden correctamente en Firebase, necesitas configurar las reglas de seguridad de Firestore.

### Reglas Básicas (Desarrollo)

En Firebase Console → Firestore Database → Reglas, configura:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // PERMITIR TODO EN DESARROLLO (⚠️ NO USAR EN PRODUCCIÓN)
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

### Reglas de Producción (Recomendado)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Reglas para colecciones de la app
    match /{collection}/{document} {
      // Permitir lectura y escritura si el documento tiene userId del usuario autenticado
      allow read, write: if request.auth != null 
        && (resource == null || resource.data.userId == request.auth.uid);
      
      // Permitir creación si el userId es del usuario autenticado
      allow create: if request.auth != null 
        && request.resource.data.userId == request.auth.uid;
    }
  }
}
```

### Reglas sin Autenticación (Desarrollo/Temporal)

Si quieres que funcione sin autenticación temporalmente:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permitir todo (solo para desarrollo)
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

## ⚠️ IMPORTANTE

1. **Desarrollo**: Puedes usar reglas abiertas (`allow read, write: if true;`)
2. **Producción**: Debes usar reglas seguras con autenticación
3. **Cambios**: Las reglas toman efecto inmediatamente

## Cómo Configurar

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto
3. Ve a **Firestore Database** → **Reglas**
4. Pega las reglas que necesites
5. Haz clic en **Publicar**

## Verificación

Después de configurar las reglas, los datos deberían guardarse correctamente en Firestore.

Puedes verificar en Firebase Console → Firestore Database → Datos

