/**
 * Middleware de autenticación
 */

import { getAuth } from '../config/firebase.config';
import { UnauthorizedError } from '../utils/errors.util';

/**
 * Middleware para verificar autenticación del usuario
 */
export async function authenticate(req: any, res: any, next: any) {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedError('No token provided');
    }

    const token = authHeader.split('Bearer ')[1];
    const auth = getAuth();
    const decodedToken = await auth.verifyIdToken(token);

    // Agregar información del usuario a la request
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
    };

    next();
  } catch (error: any) {
    throw new UnauthorizedError('Invalid or expired token');
  }
}

/**
 * Middleware opcional de autenticación (no lanza error si no hay token)
 */
export async function optionalAuthenticate(req: any, res: any, next: any) {
  try {
    const authHeader = req.headers.authorization;

    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split('Bearer ')[1];
      const auth = getAuth();
      const decodedToken = await auth.verifyIdToken(token);

      req.user = {
        uid: decodedToken.uid,
        email: decodedToken.email,
      };
    }

    next();
  } catch (error) {
    // Si falla, continuar sin usuario autenticado
    next();
  }
}

