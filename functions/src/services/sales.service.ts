/**
 * Servicio de Ventas
 * Lógica de negocio para gestión de ventas
 */

import { BaseRepository } from '../repositories/base.repository';
import { ValidationError } from '../utils/errors.util';
import { validateRequired, validatePositiveNumber } from '../utils/validation.util';
import { getFirestore } from '../config/firebase.config';
import { ProductsService } from './products.service';

export interface SaleItem {
  productId: string;
  productName: string;
  sku: string;
  quantity: number;
  unit: string;
  unitPrice: number;
  total: number;
}

export interface Sale extends BaseEntity {
  clientId: string;
  clientName: string;
  date: string;
  items: SaleItem[];
  subtotal: number;
  tax: number;
  discount: number;
  total: number;
  paymentMethod: string;
  status: string;
  notes?: string;
  quotationId?: string;
}

export class SalesService {
  private repository: BaseRepository<Sale>;
  private productsService: ProductsService;

  constructor() {
    this.repository = new BaseRepository<Sale>('sales');
    this.productsService = new ProductsService();
  }

  /**
   * Crear una nueva venta
   */
  async createSale(data: Omit<Sale, 'id' | 'createdAt' | 'updatedAt'>, userId?: string): Promise<Sale> {
    // Validaciones
    validateRequired(data.clientId, 'Client ID');
    validateRequired(data.clientName, 'Client name');
    validateRequired(data.items, 'Items');
    validateRequired(data.paymentMethod, 'Payment method');

    if (!data.items || data.items.length === 0) {
      throw new ValidationError('Sale must have at least one item');
    }

    // Validar y actualizar stock de productos
    const db = getFirestore();
    const batch = db.batch();

    for (const item of data.items) {
      validatePositiveNumber(item.quantity, 'Item quantity');
      validatePositiveNumber(item.unitPrice, 'Item unit price');

      // Verificar stock disponible
      const product = await this.productsService.getProductById(item.productId);
      if (product.stock < item.quantity) {
        throw new ValidationError(`Insufficient stock for product ${product.name}. Available: ${product.stock}, Requested: ${item.quantity}`);
      }

      // Actualizar stock (se hará en batch después)
      const productRef = db.collection('products').doc(item.productId);
      batch.update(productRef, {
        stock: product.stock - item.quantity,
        updatedAt: new Date().toISOString(),
      });
    }

    // Calcular totales
    const subtotal = data.subtotal || data.items.reduce((sum, item) => sum + item.total, 0);
    const tax = data.tax || 0;
    const discount = data.discount || 0;
    const total = subtotal + tax - discount;

    // Crear venta
    const saleData: Sale = {
      ...data,
      subtotal,
      tax,
      discount,
      total,
      status: data.status || 'completed',
      userId,
    } as Sale;

    const sale = await this.repository.create(saleData);

    // Aplicar actualizaciones de stock
    await batch.commit();

    // Incrementar contador de ventas del cliente
    try {
      const clientsService = (await import('./clients.service')).ClientsService;
      const clientService = new clientsService();
      await clientService.incrementSalesCount(data.clientId);
    } catch (error) {
      console.error('Error incrementing client sales count:', error);
      // No fallar la venta por esto
    }

    return sale;
  }

  /**
   * Obtener todas las ventas
   */
  async getAllSales(userId?: string, filter?: { clientId?: string; status?: string }): Promise<Sale[]> {
    return await this.repository.findAll(filter as any, userId);
  }

  /**
   * Obtener una venta por ID
   */
  async getSaleById(id: string): Promise<Sale> {
    const sale = await this.repository.findById(id);
    if (!sale) {
      throw new ValidationError(`Sale with id ${id} not found`);
    }
    return sale;
  }

  /**
   * Actualizar una venta
   */
  async updateSale(id: string, data: Partial<Omit<Sale, 'id' | 'createdAt'>>): Promise<Sale> {
    return await this.repository.update(id, data);
  }

  /**
   * Eliminar una venta (cancelar)
   */
  async deleteSale(id: string): Promise<boolean> {
    // Cuando se elimina una venta, se debe restaurar el stock
    const sale = await this.getSaleById(id);

    const db = getFirestore();
    const batch = db.batch();

    // Restaurar stock de productos
    for (const item of sale.items) {
      const product = await this.productsService.getProductById(item.productId);
      const productRef = db.collection('products').doc(item.productId);
      batch.update(productRef, {
        stock: product.stock + item.quantity,
        updatedAt: new Date().toISOString(),
      });
    }

    await batch.commit();
    return await this.repository.delete(id);
  }

  /**
   * Obtener estadísticas de ventas
   */
  async getSalesStats(userId?: string, startDate?: string, endDate?: string): Promise<any> {
    let sales = await this.getAllSales(userId);

    // Filtrar por fechas si se proporcionan
    if (startDate) {
      sales = sales.filter((s) => s.date >= startDate);
    }
    if (endDate) {
      sales = sales.filter((s) => s.date <= endDate);
    }

    const totalSales = sales.length;
    const totalRevenue = sales.reduce((sum, s) => sum + s.total, 0);
    const averageSale = totalSales > 0 ? totalRevenue / totalSales : 0;

    return {
      totalSales,
      totalRevenue,
      averageSale,
    };
  }
}

