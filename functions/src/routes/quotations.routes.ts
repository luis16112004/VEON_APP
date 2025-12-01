/**
 * Rutas API para Cotizaciones
 */

import { Router } from 'express';
import { QuotationsService } from '../services/quotations.service';
import { authenticate } from '../middleware/auth.middleware';
import { errorHandler } from '../utils/errors.util';

const router = Router();
const quotationsService = new QuotationsService();

// Todas las rutas requieren autenticación
router.use(authenticate);

/**
 * GET /api/quotations
 * Obtener todas las cotizaciones del usuario
 */
router.get('/', async (req, res, next) => {
  try {
    const userId = req.user.uid;
    const filter: any = {};
    
    if (req.query.clientId) filter.clientId = req.query.clientId;
    if (req.query.status) filter.status = req.query.status;

    const quotations = await quotationsService.getAllQuotations(userId, filter);
    res.json({ success: true, data: quotations });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/quotations/:id
 * Obtener una cotización por ID
 */
router.get('/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const quotation = await quotationsService.getQuotationById(id);
    res.json({ success: true, data: quotation });
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/quotations
 * Crear una nueva cotización
 */
router.post('/', async (req, res, next) => {
  try {
    const userId = req.user.uid;
    const quotation = await quotationsService.createQuotation(req.body, userId);
    res.status(201).json({ success: true, data: quotation });
  } catch (error) {
    next(error);
  }
});

/**
 * PUT /api/quotations/:id
 * Actualizar una cotización
 */
router.put('/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const quotation = await quotationsService.updateQuotation(id, req.body);
    res.json({ success: true, data: quotation });
  } catch (error) {
    next(error);
  }
});

/**
 * PATCH /api/quotations/:id/status
 * Actualizar estado de una cotización
 */
router.patch('/:id/status', async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    
    if (!status) {
      return res.status(400).json({ success: false, message: 'Status is required' });
    }

    const quotation = await quotationsService.updateStatus(id, status);
    res.json({ success: true, data: quotation });
  } catch (error) {
    next(error);
  }
});

/**
 * PATCH /api/quotations/:id/convert
 * Marcar cotización como convertida a venta
 */
router.patch('/:id/convert', async (req, res, next) => {
  try {
    const { id } = req.params;
    const { saleId } = req.body;
    
    if (!saleId) {
      return res.status(400).json({ success: false, message: 'Sale ID is required' });
    }

    const quotation = await quotationsService.markAsConverted(id, saleId);
    res.json({ success: true, data: quotation });
  } catch (error) {
    next(error);
  }
});

/**
 * DELETE /api/quotations/:id
 * Eliminar una cotización
 */
router.delete('/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    await quotationsService.deleteQuotation(id);
    res.json({ success: true, message: 'Quotation deleted successfully' });
  } catch (error) {
    next(error);
  }
});

// Aplicar middleware de manejo de errores
router.use(errorHandler);

export { router as quotationsRouter };

