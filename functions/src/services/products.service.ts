/**
 * Servicio de Productos
 * Lógica de negocio para gestión de productos
 */

import { BaseRepository } from '../repositories/base.repository';
import { ValidationError } from '../utils/errors.util';
import { validateRequired, validatePositiveNumber, sanitizeString } from '../utils/validation.util';

export interface Product extends BaseEntity {
  name: string;
  sku: string;
  shortDescription?: string;
  providerId?: string;
  providerName?: string;
  unit?: string;
  unitOfMeasurement?: string;
  cost: number;
  salePrice: number;
  stock: number;
  imagePath?: string;
}

export class ProductsService {
  private repository: BaseRepository<Product>;

  constructor() {
    this.repository = new BaseRepository<Product>('products');
  }

  /**
   * Crear un nuevo producto
   */
  async createProduct(data: Omit<Product, 'id' | 'createdAt' | 'updatedAt'>, userId?: string): Promise<Product> {
    // Validaciones
    validateRequired(data.name, 'Product name');
    validateRequired(data.sku, 'SKU');
    validatePositiveNumber(data.cost, 'Cost');
    validatePositiveNumber(data.salePrice, 'Sale price');

    if (data.stock !== undefined) {
      validatePositiveNumber(data.stock, 'Stock');
    }

    // Validar que el precio de venta sea mayor o igual al costo
    if (data.salePrice < data.cost) {
      throw new ValidationError('Sale price must be greater than or equal to cost');
    }

    // Sanitizar datos
    const productData = {
      ...data,
      name: sanitizeString(data.name),
      sku: sanitizeString(data.sku).toUpperCase(),
      shortDescription: data.shortDescription ? sanitizeString(data.shortDescription) : undefined,
      stock: data.stock || 0,
      userId,
    };

    return await this.repository.create(productData);
  }

  /**
   * Obtener todos los productos
   */
  async getAllProducts(userId?: string, filter?: { providerId?: string }): Promise<Product[]> {
    return await this.repository.findAll(filter, userId);
  }

  /**
   * Obtener un producto por ID
   */
  async getProductById(id: string): Promise<Product> {
    const product = await this.repository.findById(id);
    if (!product) {
      throw new ValidationError(`Product with id ${id} not found`);
    }
    return product;
  }

  /**
   * Obtener un producto por SKU
   */
  async getProductBySku(sku: string, userId?: string): Promise<Product | null> {
    const products = await this.repository.findAll({ sku: sku.toUpperCase() as any }, userId);
    return products.length > 0 ? products[0] : null;
  }

  /**
   * Actualizar un producto
   */
  async updateProduct(id: string, data: Partial<Omit<Product, 'id' | 'createdAt'>>): Promise<Product> {
    // Validaciones
    if (data.cost !== undefined) {
      validatePositiveNumber(data.cost, 'Cost');
    }

    if (data.salePrice !== undefined) {
      validatePositiveNumber(data.salePrice, 'Sale price');
    }

    if (data.stock !== undefined) {
      validatePositiveNumber(data.stock, 'Stock');
    }

    // Obtener producto actual para validar precio
    const currentProduct = await this.getProductById(id);
    const newCost = data.cost !== undefined ? data.cost : currentProduct.cost;
    const newSalePrice = data.salePrice !== undefined ? data.salePrice : currentProduct.salePrice;

    if (newSalePrice < newCost) {
      throw new ValidationError('Sale price must be greater than or equal to cost');
    }

    // Sanitizar datos
    const updateData: any = { ...data };
    if (data.name) updateData.name = sanitizeString(data.name);
    if (data.sku) updateData.sku = sanitizeString(data.sku).toUpperCase();
    if (data.shortDescription) updateData.shortDescription = sanitizeString(data.shortDescription);

    return await this.repository.update(id, updateData);
  }

  /**
   * Actualizar stock de un producto
   */
  async updateStock(id: string, quantity: number, operation: 'add' | 'subtract' | 'set' = 'set'): Promise<Product> {
    const product = await this.getProductById(id);
    let newStock: number;

    switch (operation) {
      case 'add':
        newStock = (product.stock || 0) + quantity;
        break;
      case 'subtract':
        newStock = Math.max(0, (product.stock || 0) - quantity);
        break;
      case 'set':
        newStock = quantity;
        break;
    }

    validatePositiveNumber(newStock, 'Stock');

    return await this.repository.update(id, { stock: newStock });
  }

  /**
   * Eliminar un producto
   */
  async deleteProduct(id: string): Promise<boolean> {
    return await this.repository.delete(id);
  }
}

