/**
 * Repositorio base con operaciones CRUD comunes
 * Patrón Repository para separar la lógica de acceso a datos
 */

import { getFirestore } from '../config/firebase.config';
import { NotFoundError, ValidationError } from '../utils/errors.util';
import * as admin from 'firebase-admin';

export interface BaseEntity {
  id: string;
  createdAt: string;
  updatedAt: string;
  userId?: string; // Para multi-tenant
}

export class BaseRepository<T extends BaseEntity> {
  constructor(protected collectionName: string) {}

  protected getCollection() {
    return getFirestore().collection(this.collectionName);
  }

  /**
   * Crear un nuevo documento
   */
  async create(data: Omit<T, 'id' | 'createdAt' | 'updatedAt'>): Promise<T> {
    const now = new Date().toISOString();
    const docRef = this.getCollection().doc();

    const newData = {
      ...data,
      id: docRef.id,
      createdAt: now,
      updatedAt: now,
    } as T;

    await docRef.set(newData);
    return newData;
  }

  /**
   * Obtener un documento por ID
   */
  async findById(id: string): Promise<T | null> {
    const doc = await this.getCollection().doc(id).get();

    if (!doc.exists) {
      return null;
    }

    return { id: doc.id, ...doc.data() } as T;
  }

  /**
   * Obtener todos los documentos (con filtros opcionales)
   */
  async findAll(filter?: Partial<T>, userId?: string): Promise<T[]> {
    let query: admin.firestore.Query = this.getCollection();

    // Filtro por usuario si se proporciona
    if (userId) {
      query = query.where('userId', '==', userId);
    }

    // Aplicar otros filtros
    if (filter) {
      Object.entries(filter).forEach(([key, value]) => {
        if (value !== undefined && key !== 'userId') {
          query = query.where(key, '==', value);
        }
      });
    }

    const snapshot = await query.get();
    return snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    })) as T[];
  }

  /**
   * Actualizar un documento
   */
  async update(id: string, data: Partial<Omit<T, 'id' | 'createdAt'>>): Promise<T> {
    const docRef = this.getCollection().doc(id);
    const existingDoc = await docRef.get();

    if (!existingDoc.exists) {
      throw new NotFoundError(this.collectionName, id);
    }

    const updateData = {
      ...data,
      updatedAt: new Date().toISOString(),
    };

    await docRef.update(updateData);
    const updatedDoc = await docRef.get();

    return { id: updatedDoc.id, ...updatedDoc.data() } as T;
  }

  /**
   * Eliminar un documento
   */
  async delete(id: string): Promise<boolean> {
    const docRef = this.getCollection().doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
      throw new NotFoundError(this.collectionName, id);
    }

    await docRef.delete();
    return true;
  }

  /**
   * Verificar si un documento existe
   */
  async exists(id: string): Promise<boolean> {
    const doc = await this.getCollection().doc(id).get();
    return doc.exists;
  }

  /**
   * Contar documentos
   */
  async count(filter?: Partial<T>, userId?: string): Promise<number> {
    let query: admin.firestore.Query = this.getCollection();

    if (userId) {
      query = query.where('userId', '==', userId);
    }

    if (filter) {
      Object.entries(filter).forEach(([key, value]) => {
        if (value !== undefined && key !== 'userId') {
          query = query.where(key, '==', value);
        }
      });
    }

    const snapshot = await query.count().get();
    return snapshot.data().count;
  }
}

