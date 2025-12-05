# Firebase Cloud Functions - VEON App Backend

Este directorio contiene el backend de la aplicación VEON usando Firebase Cloud Functions.

## 📁 Estructura del Proyecto

```
functions/
├── src/
│   ├── config/          # Configuración de Firebase
│   ├── middleware/      # Middlewares (autenticación, etc.)
│   ├── repositories/    # Capa de acceso a datos (Repository Pattern)
│   ├── routes/          # Rutas API (Express routers)
│   ├── services/        # Lógica de negocio (Service Layer)
│   ├── utils/           # Utilidades (validación, errores)
│   └── index.ts         # Punto de entrada principal
├── package.json         # Dependencias Node.js
├── tsconfig.json        # Configuración TypeScript
└── README.md            # Este archivo
```

## 🏗️ Arquitectura

El backend sigue principios SOLID y patrones de diseño:

- **Repository Pattern**: Separación de la lógica de acceso a datos
- **Service Layer**: Lógica de negocio centralizada
- **Middleware Pattern**: Autenticación y manejo de errores
- **RESTful API**: Endpoints organizados por recursos

## 🚀 Configuración Inicial

### 1. Instalar Firebase CLI

```bash
npm install -g firebase-tools
```

### 2. Iniciar sesión en Firebase

```bash
firebase login
```

### 3. Inicializar Firebase Functions (si no está inicializado)

```bash
firebase init functions
```

### 4. Instalar dependencias

```bash
cd functions
npm install
```

### 5. Configurar Firebase

Las credenciales de Firebase se configuran automáticamente cuando despliegas. Para desarrollo local:

- Usa el emulador de Firebase
- O configura variables de entorno con las credenciales

## 📝 Variables de Entorno

Para desarrollo local, puedes crear un archivo `.env`:

```env
# Opcional: Para desarrollo local con credenciales propias
GOOGLE_APPLICATION_CREDENTIALS=path/to/serviceAccountKey.json
```

## 🛠️ Scripts Disponibles

```bash
# Compilar TypeScript
npm run build

# Ejecutar localmente con emulador
npm run serve

# Desplegar a Firebase
npm run deploy

# Ver logs
npm run logs
```

## 📡 Endpoints API

Todos los endpoints están bajo `/api`:

### Autenticación
- `GET /api/auth/me` - Obtener usuario actual
- `POST /api/auth/verify-token` - Verificar token

### Clientes
- `GET /api/clients` - Listar clientes
- `GET /api/clients/:id` - Obtener cliente
- `POST /api/clients` - Crear cliente
- `PUT /api/clients/:id` - Actualizar cliente
- `DELETE /api/clients/:id` - Eliminar cliente

### Productos
- `GET /api/products` - Listar productos
- `GET /api/products/:id` - Obtener producto
- `GET /api/products/sku/:sku` - Obtener por SKU
- `POST /api/products` - Crear producto
- `PUT /api/products/:id` - Actualizar producto
- `PATCH /api/products/:id/stock` - Actualizar stock
- `DELETE /api/products/:id` - Eliminar producto

### Proveedores
- `GET /api/providers` - Listar proveedores
- `GET /api/providers/:id` - Obtener proveedor
- `POST /api/providers` - Crear proveedor
- `PUT /api/providers/:id` - Actualizar proveedor
- `DELETE /api/providers/:id` - Eliminar proveedor

### Ventas
- `GET /api/sales` - Listar ventas
- `GET /api/sales/:id` - Obtener venta
- `GET /api/sales/stats` - Estadísticas de ventas
- `POST /api/sales` - Crear venta
- `PUT /api/sales/:id` - Actualizar venta
- `DELETE /api/sales/:id` - Eliminar/cancelar venta

### Cotizaciones
- `GET /api/quotations` - Listar cotizaciones
- `GET /api/quotations/:id` - Obtener cotización
- `POST /api/quotations` - Crear cotización
- `PUT /api/quotations/:id` - Actualizar cotización
- `PATCH /api/quotations/:id/status` - Actualizar estado
- `PATCH /api/quotations/:id/convert` - Convertir a venta
- `DELETE /api/quotations/:id` - Eliminar cotización

## 🔐 Autenticación

Todas las rutas (excepto `/api/health`) requieren autenticación mediante token Bearer:

```
Authorization: Bearer <firebase-id-token>
```

El token se obtiene del cliente después de autenticarse con Firebase Auth.

## 🗄️ Base de Datos

Se usa Firestore como base de datos. Las colecciones principales son:

- `clients` - Clientes
- `products` - Productos
- `providers` - Proveedores
- `sales` - Ventas
- `quotations` - Cotizaciones

Todos los documentos incluyen:
- `id` - ID único del documento
- `userId` - ID del usuario propietario (multi-tenant)
- `createdAt` - Fecha de creación (ISO 8601)
- `updatedAt` - Fecha de última actualización (ISO 8601)

## 🧪 Desarrollo Local

Para desarrollar localmente con el emulador:

```bash
# Iniciar emulador de Firebase
firebase emulators:start

# En otra terminal, compilar y ejecutar
npm run build
npm run serve
```

El emulador estará disponible en `http://localhost:5001`

## 📦 Despliegue

```bash
# Compilar TypeScript
npm run build

# Desplegar funciones
firebase deploy --only functions

# O usar el script
npm run deploy
```

## 🔍 Debugging

Para ver logs en tiempo real:

```bash
npm run logs
```

## 📚 Recursos

- [Firebase Functions Documentation](https://firebase.google.com/docs/functions)
- [Firestore Documentation](https://firebase.google.com/docs/firestore)
- [Express.js Documentation](https://expressjs.com/)

## ⚠️ Notas Importantes

1. **Configuración de Firebase**: La configuración de Firebase se debe hacer en Firebase Console. Este código asume que Firebase ya está inicializado.

2. **Seguridad**: Asegúrate de configurar las reglas de seguridad de Firestore en Firebase Console.

3. **CORS**: El middleware CORS está configurado para permitir todos los orígenes en desarrollo. En producción, restringe esto.

4. **Multi-tenant**: Todos los datos están aislados por `userId` para soportar múltiples usuarios.

