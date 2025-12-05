/**
 * VEON App - Firebase Cloud Functions
 * Backend API para la aplicación de gestión empresarial
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Inicializar Firebase Admin (la configuración se hará en Firebase Console)
admin.initializeApp();

// Importar routers de diferentes módulos
import { authRouter } from './routes/auth.routes';
import { clientsRouter } from './routes/clients.routes';
import { productsRouter } from './routes/products.routes';
import { providersRouter } from './routes/providers.routes';
import { salesRouter } from './routes/sales.routes';
import { quotationsRouter } from './routes/quotations.routes';

// Middleware de CORS
const cors = require('cors')({ origin: true });

/**
 * Express app principal
 */
const express = require('express');
const app = express();

app.use(cors);
app.use(express.json());

// Rutas API
app.use('/api/auth', authRouter);
app.use('/api/clients', clientsRouter);
app.use('/api/products', productsRouter);
app.use('/api/providers', providersRouter);
app.use('/api/sales', salesRouter);
app.use('/api/quotations', quotationsRouter);

// Health check endpoint
app.get('/api/health', (req: any, res: any) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Exportar como Cloud Function
export const api = functions.https.onRequest(app);

