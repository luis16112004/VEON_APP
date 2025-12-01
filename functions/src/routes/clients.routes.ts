/**
 * Rutas API para Clientes
 */

import { Router } from 'express';
import { ClientsService } from '../services/clients.service';
import { authenticate } from '../middleware/auth.middleware';
import { errorHandler } from '../utils/errors.util';

const router = Router();
const clientsService = new ClientsService();

// Todas las rutas requieren autenticación
router.use(authenticate);

/**
 * GET /api/clients
 * Obtener todos los clientes del usuario
 */
router.get('/', async (req, res, next) => {
  try {
    const userId = req.user.uid;
    const clients = await clientsService.getAllClients(userId);
    res.json({ success: true, data: clients });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/clients/:id
 * Obtener un cliente por ID
 */
router.get('/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const client = await clientsService.getClientById(id);
    res.json({ success: true, data: client });
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/clients
 * Crear un nuevo cliente
 */
router.post('/', async (req, res, next) => {
  try {
    const userId = req.user.uid;
    const client = await clientsService.createClient(req.body, userId);
    res.status(201).json({ success: true, data: client });
  } catch (error) {
    next(error);
  }
});

/**
 * PUT /api/clients/:id
 * Actualizar un cliente
 */
router.put('/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const client = await clientsService.updateClient(id, req.body);
    res.json({ success: true, data: client });
  } catch (error) {
    next(error);
  }
});

/**
 * DELETE /api/clients/:id
 * Eliminar un cliente
 */
router.delete('/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    await clientsService.deleteClient(id);
    res.json({ success: true, message: 'Client deleted successfully' });
  } catch (error) {
    next(error);
  }
});

// Aplicar middleware de manejo de errores
router.use(errorHandler);

export { router as clientsRouter };

