/**
 * Configuración de Firebase
 * NOTA: Esta configuración se debe agregar en Firebase Console
 * o mediante variables de entorno
 */

import * as admin from 'firebase-admin';

/**
 * Inicializar Firebase Admin SDK
 * La configuración se obtiene automáticamente cuando se despliega en Firebase
 * Para desarrollo local, usar archivo de credenciales o emulador
 */
export function initializeFirebase() {
  if (!admin.apps.length) {
    // En producción, Firebase usa las credenciales automáticamente
    // Para desarrollo local, puedes usar:
    // const serviceAccount = require('path/to/serviceAccountKey.json');
    // admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    
    admin.initializeApp();
  }
  return admin;
}

/**
 * Obtener instancia de Firestore
 */
export function getFirestore() {
  return admin.firestore();
}

/**
 * Obtener instancia de Firebase Auth
 */
export function getAuth() {
  return admin.auth();
}

