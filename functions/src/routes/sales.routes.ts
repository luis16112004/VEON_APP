/**
 * Rutas API para Ventas
 */

import { Router } from 'express';
import { SalesService } from '../services/sales.service';
import { authenticate } from '../middleware/auth.middleware';
import { errorHandler } from '../utils/errors.util';

const router = Router();
const salesService = new SalesService();

// Todas las rutas requieren autenticación
router.use(authenticate);

/**
 * GET /api/sales
 * Obtener todas las ventas del usuario
 */
router.get('/', async (req, res, next) => {
  try {
    const userId = req.user.uid;
    const filter: any = {};
    
    if (req.query.clientId) filter.clientId = req.query.clientId;
    if (req.query.status) filter.status = req.query.status;

    const sales = await salesService.getAllSales(userId, filter);
    res.json({ success: true, data: sales });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/sales/stats
 * Obtener estadísticas de ventas
 */
router.get('/stats', async (req, res, next) => {
  try {
    const userId = req.user.uid;
    const { startDate, endDate } = req.query;
    const stats = await salesService.getSalesStats(
      userId,
      startDate as string,
      endDate as string
    );
    res.json({ success: true, data: stats });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/sales/:id
 * Obtener una venta por ID
 */
router.get('/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const sale = await salesService.getSaleById(id);
    res.json({ success: true, data: sale });
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/sales
 * Crear una nueva venta
 */
router.post('/', async (req, res, next) => {
  try {
    const userId = req.user.uid;
    const sale = await salesService.createSale(req.body, userId);
    res.status(201).json({ success: true, data: sale });
  } catch (error) {
    next(error);
  }
});

/**
 * PUT /api/sales/:id
 * Actualizar una venta
 */
router.put('/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const sale = await salesService.updateSale(id, req.body);
    res.json({ success: true, data: sale });
  } catch (error) {
    next(error);
  }
});

/**
 * DELETE /api/sales/:id
 * Eliminar/cancelar una venta
 */
router.delete('/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    await salesService.deleteSale(id);
    res.json({ success: true, message: 'Sale deleted successfully' });
  } catch (error) {
    next(error);
  }
});

// Aplicar middleware de manejo de errores
router.use(errorHandler);

export { router as salesRouter };

