/**
 * Utilidades de validación
 */

export function validateRequired(value: any, fieldName: string): void {
  if (value === null || value === undefined || value === '') {
    throw new Error(`${fieldName} is required`);
  }
}

export function validateEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

export function validatePhone(phone: string): boolean {
  const phoneRegex = /^\+?[\d\s-()]+$/;
  return phoneRegex.test(phone);
}

export function validatePositiveNumber(value: number, fieldName: string): void {
  if (typeof value !== 'number' || value < 0) {
    throw new Error(`${fieldName} must be a positive number`);
  }
}

export function sanitizeString(value: string): string {
  return value.trim();
}

