/**
 * Rutas API para Proveedores
 */

import { Router } from 'express';
import { ProvidersService } from '../services/providers.service';
import { authenticate } from '../middleware/auth.middleware';
import { errorHandler } from '../utils/errors.util';

const router = Router();
const providersService = new ProvidersService();

// Todas las rutas requieren autenticación
router.use(authenticate);

/**
 * GET /api/providers
 * Obtener todos los proveedores del usuario
 */
router.get('/', async (req, res, next) => {
  try {
    const userId = req.user.uid;
    const providers = await providersService.getAllProviders(userId);
    res.json({ success: true, data: providers });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/providers/:id
 * Obtener un proveedor por ID
 */
router.get('/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const provider = await providersService.getProviderById(id);
    res.json({ success: true, data: provider });
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/providers
 * Crear un nuevo proveedor
 */
router.post('/', async (req, res, next) => {
  try {
    const userId = req.user.uid;
    const provider = await providersService.createProvider(req.body, userId);
    res.status(201).json({ success: true, data: provider });
  } catch (error) {
    next(error);
  }
});

/**
 * PUT /api/providers/:id
 * Actualizar un proveedor
 */
router.put('/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const provider = await providersService.updateProvider(id, req.body);
    res.json({ success: true, data: provider });
  } catch (error) {
    next(error);
  }
});

/**
 * DELETE /api/providers/:id
 * Eliminar un proveedor
 */
router.delete('/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    await providersService.deleteProvider(id);
    res.json({ success: true, message: 'Provider deleted successfully' });
  } catch (error) {
    next(error);
  }
});

// Aplicar middleware de manejo de errores
router.use(errorHandler);

export { router as providersRouter };

