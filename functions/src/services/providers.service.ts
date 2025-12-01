/**
 * Servicio de Proveedores
 * Lógica de negocio para gestión de proveedores
 */

import { BaseRepository } from '../repositories/base.repository';
import { ValidationError } from '../utils/errors.util';
import { validateRequired, validateEmail, validatePhone, sanitizeString } from '../utils/validation.util';

export interface Provider extends BaseEntity {
  name: string;
  contactPerson?: string;
  phoneNumber: string;
  email?: string;
  address?: string;
  website?: string;
  notes?: string;
}

export class ProvidersService {
  private repository: BaseRepository<Provider>;

  constructor() {
    this.repository = new BaseRepository<Provider>('providers');
  }

  /**
   * Crear un nuevo proveedor
   */
  async createProvider(data: Omit<Provider, 'id' | 'createdAt' | 'updatedAt'>, userId?: string): Promise<Provider> {
    // Validaciones
    validateRequired(data.name, 'Provider name');
    validateRequired(data.phoneNumber, 'Phone number');

    if (data.email && !validateEmail(data.email)) {
      throw new ValidationError('Invalid email format');
    }

    if (!validatePhone(data.phoneNumber)) {
      throw new ValidationError('Invalid phone number format');
    }

    // Sanitizar datos
    const providerData = {
      ...data,
      name: sanitizeString(data.name),
      contactPerson: data.contactPerson ? sanitizeString(data.contactPerson) : undefined,
      phoneNumber: sanitizeString(data.phoneNumber),
      email: data.email ? sanitizeString(data.email).toLowerCase() : undefined,
      address: data.address ? sanitizeString(data.address) : undefined,
      userId,
    };

    return await this.repository.create(providerData);
  }

  /**
   * Obtener todos los proveedores
   */
  async getAllProviders(userId?: string): Promise<Provider[]> {
    return await this.repository.findAll(undefined, userId);
  }

  /**
   * Obtener un proveedor por ID
   */
  async getProviderById(id: string): Promise<Provider> {
    const provider = await this.repository.findById(id);
    if (!provider) {
      throw new ValidationError(`Provider with id ${id} not found`);
    }
    return provider;
  }

  /**
   * Actualizar un proveedor
   */
  async updateProvider(id: string, data: Partial<Omit<Provider, 'id' | 'createdAt'>>): Promise<Provider> {
    // Validaciones opcionales
    if (data.email && !validateEmail(data.email)) {
      throw new ValidationError('Invalid email format');
    }

    if (data.phoneNumber && !validatePhone(data.phoneNumber)) {
      throw new ValidationError('Invalid phone number format');
    }

    // Sanitizar datos
    const updateData: any = { ...data };
    if (data.name) updateData.name = sanitizeString(data.name);
    if (data.contactPerson) updateData.contactPerson = sanitizeString(data.contactPerson);
    if (data.phoneNumber) updateData.phoneNumber = sanitizeString(data.phoneNumber);
    if (data.email) updateData.email = sanitizeString(data.email).toLowerCase();
    if (data.address) updateData.address = sanitizeString(data.address);

    return await this.repository.update(id, updateData);
  }

  /**
   * Eliminar un proveedor
   */
  async deleteProvider(id: string): Promise<boolean> {
    return await this.repository.delete(id);
  }
}

