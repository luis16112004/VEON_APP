/**
 * Servicio de Clientes
 * Lógica de negocio para gestión de clientes
 */

import { BaseRepository } from '../repositories/base.repository';
import { ValidationError } from '../utils/errors.util';
import { validateRequired, validateEmail, validatePhone, sanitizeString } from '../utils/validation.util';

export interface Client extends BaseEntity {
  fullName: string;
  companyName?: string;
  phoneNumber: string;
  email: string;
  address: string;
  imagePath?: string;
  salesCount: number;
}

export class ClientsService {
  private repository: BaseRepository<Client>;

  constructor() {
    this.repository = new BaseRepository<Client>('clients');
  }

  /**
   * Crear un nuevo cliente
   */
  async createClient(data: Omit<Client, 'id' | 'createdAt' | 'updatedAt' | 'salesCount'>, userId?: string): Promise<Client> {
    // Validaciones
    validateRequired(data.fullName, 'Full name');
    validateRequired(data.email, 'Email');
    validateRequired(data.phoneNumber, 'Phone number');
    validateRequired(data.address, 'Address');

    if (!validateEmail(data.email)) {
      throw new ValidationError('Invalid email format');
    }

    if (!validatePhone(data.phoneNumber)) {
      throw new ValidationError('Invalid phone number format');
    }

    // Sanitizar datos
    const clientData = {
      ...data,
      fullName: sanitizeString(data.fullName),
      email: sanitizeString(data.email).toLowerCase(),
      phoneNumber: sanitizeString(data.phoneNumber),
      address: sanitizeString(data.address),
      companyName: data.companyName ? sanitizeString(data.companyName) : undefined,
      salesCount: 0,
      userId,
    };

    return await this.repository.create(clientData);
  }

  /**
   * Obtener todos los clientes
   */
  async getAllClients(userId?: string): Promise<Client[]> {
    return await this.repository.findAll(undefined, userId);
  }

  /**
   * Obtener un cliente por ID
   */
  async getClientById(id: string): Promise<Client> {
    const client = await this.repository.findById(id);
    if (!client) {
      throw new ValidationError(`Client with id ${id} not found`);
    }
    return client;
  }

  /**
   * Actualizar un cliente
   */
  async updateClient(id: string, data: Partial<Omit<Client, 'id' | 'createdAt' | 'updatedAt'>>): Promise<Client> {
    // Validaciones opcionales si se proporcionan
    if (data.email && !validateEmail(data.email)) {
      throw new ValidationError('Invalid email format');
    }

    if (data.phoneNumber && !validatePhone(data.phoneNumber)) {
      throw new ValidationError('Invalid phone number format');
    }

    // Sanitizar datos si se proporcionan
    const updateData: any = { ...data };
    if (data.fullName) updateData.fullName = sanitizeString(data.fullName);
    if (data.email) updateData.email = sanitizeString(data.email).toLowerCase();
    if (data.phoneNumber) updateData.phoneNumber = sanitizeString(data.phoneNumber);
    if (data.address) updateData.address = sanitizeString(data.address);
    if (data.companyName) updateData.companyName = sanitizeString(data.companyName);

    return await this.repository.update(id, updateData);
  }

  /**
   * Eliminar un cliente
   */
  async deleteClient(id: string): Promise<boolean> {
    return await this.repository.delete(id);
  }

  /**
   * Incrementar contador de ventas de un cliente
   */
  async incrementSalesCount(clientId: string): Promise<void> {
    const client = await this.getClientById(clientId);
    await this.repository.update(clientId, {
      salesCount: (client.salesCount || 0) + 1,
    });
  }
}

