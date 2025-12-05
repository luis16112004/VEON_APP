/**
 * Rutas API para Productos
 */

import { Router } from 'express';
import { ProductsService } from '../services/products.service';
import { authenticate } from '../middleware/auth.middleware';
import { errorHandler } from '../utils/errors.util';

const router = Router();
const productsService = new ProductsService();

// Todas las rutas requieren autenticación
router.use(authenticate);

/**
 * GET /api/products
 * Obtener todos los productos del usuario
 */
router.get('/', async (req, res, next) => {
  try {
    const userId = req.user.uid;
    const filter = req.query.providerId ? { providerId: req.query.providerId } : undefined;
    const products = await productsService.getAllProducts(userId, filter);
    res.json({ success: true, data: products });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/products/:id
 * Obtener un producto por ID
 */
router.get('/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const product = await productsService.getProductById(id);
    res.json({ success: true, data: product });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/products/sku/:sku
 * Obtener un producto por SKU
 */
router.get('/sku/:sku', async (req, res, next) => {
  try {
    const { sku } = req.params;
    const userId = req.user.uid;
    const product = await productsService.getProductBySku(sku, userId);
    
    if (!product) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }
    
    res.json({ success: true, data: product });
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/products
 * Crear un nuevo producto
 */
router.post('/', async (req, res, next) => {
  try {
    const userId = req.user.uid;
    const product = await productsService.createProduct(req.body, userId);
    res.status(201).json({ success: true, data: product });
  } catch (error) {
    next(error);
  }
});

/**
 * PUT /api/products/:id
 * Actualizar un producto
 */
router.put('/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const product = await productsService.updateProduct(id, req.body);
    res.json({ success: true, data: product });
  } catch (error) {
    next(error);
  }
});

/**
 * PATCH /api/products/:id/stock
 * Actualizar stock de un producto
 */
router.patch('/:id/stock', async (req, res, next) => {
  try {
    const { id } = req.params;
    const { quantity, operation } = req.body;
    
    if (quantity === undefined) {
      return res.status(400).json({ success: false, message: 'Quantity is required' });
    }

    const product = await productsService.updateStock(id, quantity, operation || 'set');
    res.json({ success: true, data: product });
  } catch (error) {
    next(error);
  }
});

/**
 * DELETE /api/products/:id
 * Eliminar un producto
 */
router.delete('/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    await productsService.deleteProduct(id);
    res.json({ success: true, message: 'Product deleted successfully' });
  } catch (error) {
    next(error);
  }
});

// Aplicar middleware de manejo de errores
router.use(errorHandler);

export { router as productsRouter };

