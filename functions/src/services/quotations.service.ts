/**
 * Servicio de Cotizaciones
 * Lógica de negocio para gestión de cotizaciones
 */

import { BaseRepository } from '../repositories/base.repository';
import { ValidationError } from '../utils/errors.util';
import { validateRequired, validatePositiveNumber } from '../utils/validation.util';

export interface QuotationItem {
  productId: string;
  productName: string;
  sku: string;
  quantity: number;
  unit: string;
  unitPrice: number;
  total: number;
}

export interface Quotation extends BaseEntity {
  clientId: string;
  clientName: string;
  date: string;
  validUntil: string;
  items: QuotationItem[];
  subtotal: number;
  tax: number;
  discount: number;
  total: number;
  status: string;
  notes?: string;
  terms?: string;
  convertedToSaleId?: string;
}

export class QuotationsService {
  private repository: BaseRepository<Quotation>;

  constructor() {
    this.repository = new BaseRepository<Quotation>('quotations');
  }

  /**
   * Crear una nueva cotización
   */
  async createQuotation(data: Omit<Quotation, 'id' | 'createdAt' | 'updatedAt' | 'status' | 'convertedToSaleId'>, userId?: string): Promise<Quotation> {
    // Validaciones
    validateRequired(data.clientId, 'Client ID');
    validateRequired(data.clientName, 'Client name');
    validateRequired(data.date, 'Date');
    validateRequired(data.validUntil, 'Valid until');
    validateRequired(data.items, 'Items');

    if (!data.items || data.items.length === 0) {
      throw new ValidationError('Quotation must have at least one item');
    }

    // Validar items
    for (const item of data.items) {
      validatePositiveNumber(item.quantity, 'Item quantity');
      validatePositiveNumber(item.unitPrice, 'Item unit price');
    }

    // Calcular totales
    const subtotal = data.subtotal || data.items.reduce((sum, item) => sum + item.total, 0);
    const tax = data.tax || 0;
    const discount = data.discount || 0;
    const total = subtotal + tax - discount;

    // Crear cotización
    const quotationData: Quotation = {
      ...data,
      subtotal,
      tax,
      discount,
      total,
      status: 'pending',
      userId,
    } as Quotation;

    return await this.repository.create(quotationData);
  }

  /**
   * Obtener todas las cotizaciones
   */
  async getAllQuotations(userId?: string, filter?: { clientId?: string; status?: string }): Promise<Quotation[]> {
    return await this.repository.findAll(filter as any, userId);
  }

  /**
   * Obtener una cotización por ID
   */
  async getQuotationById(id: string): Promise<Quotation> {
    const quotation = await this.repository.findById(id);
    if (!quotation) {
      throw new ValidationError(`Quotation with id ${id} not found`);
    }
    return quotation;
  }

  /**
   * Actualizar una cotización
   */
  async updateQuotation(id: string, data: Partial<Omit<Quotation, 'id' | 'createdAt'>>): Promise<Quotation> {
    return await this.repository.update(id, data);
  }

  /**
   * Marcar cotización como convertida a venta
   */
  async markAsConverted(id: string, saleId: string): Promise<Quotation> {
    return await this.repository.update(id, {
      status: 'converted',
      convertedToSaleId: saleId,
    });
  }

  /**
   * Actualizar estado de una cotización
   */
  async updateStatus(id: string, status: string): Promise<Quotation> {
    const validStatuses = ['pending', 'approved', 'rejected', 'expired', 'converted'];
    if (!validStatuses.includes(status)) {
      throw new ValidationError(`Invalid status: ${status}`);
    }

    return await this.repository.update(id, { status });
  }

  /**
   * Eliminar una cotización
   */
  async deleteQuotation(id: string): Promise<boolean> {
    return await this.repository.delete(id);
  }
}

