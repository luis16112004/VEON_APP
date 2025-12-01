/**
 * Rutas API para Autenticación
 * Nota: La autenticación real se maneja con Firebase Auth en el cliente
 * Estas rutas son para operaciones adicionales relacionadas con usuarios
 */

import { Router } from 'express';
import { getAuth } from '../config/firebase.config';
import { authenticate, optionalAuthenticate } from '../middleware/auth.middleware';
import { errorHandler } from '../utils/errors.util';
import { ValidationError } from '../utils/errors.util';

const router = Router();

/**
 * GET /api/auth/me
 * Obtener información del usuario actual
 */
router.get('/me', authenticate, async (req, res, next) => {
  try {
    const auth = getAuth();
    const user = await auth.getUser(req.user.uid);
    
    res.json({
      success: true,
      data: {
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoURL: user.photoURL,
        emailVerified: user.emailVerified,
      },
    });
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/auth/register
 * Registro de usuario (principalmente se hace con Firebase Auth, pero puedes agregar lógica adicional)
 */
router.post('/register', optionalAuthenticate, async (req, res, next) => {
  try {
    // La creación de usuario se hace en el cliente con Firebase Auth
    // Aquí puedes agregar lógica adicional como crear perfil en Firestore
    
    res.json({
      success: true,
      message: 'User registration handled by Firebase Auth on client',
    });
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/auth/verify-token
 * Verificar y obtener información de un token
 */
router.post('/verify-token', async (req, res, next) => {
  try {
    const { token } = req.body;
    
    if (!token) {
      throw new ValidationError('Token is required');
    }

    const auth = getAuth();
    const decodedToken = await auth.verifyIdToken(token);
    
    res.json({
      success: true,
      data: {
        uid: decodedToken.uid,
        email: decodedToken.email,
        emailVerified: decodedToken.email_verified,
      },
    });
  } catch (error) {
    next(error);
  }
});

// Aplicar middleware de manejo de errores
router.use(errorHandler);

export { router as authRouter };

