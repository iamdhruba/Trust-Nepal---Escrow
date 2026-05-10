import admin from 'firebase-admin';
import { getFirebaseSecrets } from './secrets.js';

let firebaseApp: admin.app.App | null = null;

export async function initializeFirebase() {
  if (firebaseApp) return firebaseApp;

  try {
    const secrets = await getFirebaseSecrets();
    
    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert({
        projectId: secrets.projectId,
        clientEmail: secrets.clientEmail,
        privateKey: secrets.privateKey,
      }),
      storageBucket: secrets.storageBucket,
    });

    console.log('[INFO] Firebase Admin SDK initialized');
    return firebaseApp;
  } catch (error) {
    console.error('[ERROR] Failed to initialize Firebase Admin SDK:', error);
    // Don't throw here to allow app to start even if Firebase fails
    // but log it clearly
    return null;
  }
}

export const getFirebaseAdmin = () => admin;
