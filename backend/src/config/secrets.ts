import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';

const logger = {
  info: (message: string, data?: any) => console.log(`[INFO] ${message}`, data || ''),
  error: (message: string, data?: any) => console.error(`[ERROR] ${message}`, data || ''),
};

// Initialize Secrets Manager client
let secretsClient: SecretsManagerClient | null = null;

if (process.env.NODE_ENV === 'production' && process.env.AWS_REGION) {
  secretsClient = new SecretsManagerClient({
    region: process.env.AWS_REGION,
  });
  logger.info('AWS Secrets Manager client initialized');
} else {
  logger.info('Running in development mode - using environment variables for secrets');
}

// Secret cache to avoid repeated API calls
const secretCache = new Map<string, any>();
const CACHE_TTL = 5 * 60 * 1000; // 5 minutes

interface EsewaSecrets {
  secret_key: string;
  product_code: string;
}

interface KhaltiSecrets {
  live_secret_key: string;
  public_key: string;
}

interface ConnectIPSSecrets {
  credential_name: string;
  app_id: string;
  app_name: string;
  username: string;
  password: string;
  private_key: string;
}

interface FirebaseSecrets {
  projectId: string;
  clientEmail: string;
  privateKey: string;
  storageBucket: string;
}

/**
 * Retrieve secret from AWS Secrets Manager with caching
 */
async function getSecret(secretName: string): Promise<any> {
  // Check cache first
  const cached = secretCache.get(secretName);
  if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
    return cached.data;
  }

  // In development, use environment variables
  if (process.env.NODE_ENV !== 'production' || !secretsClient) {
    return getSecretFromEnv(secretName);
  }

  try {
    const command = new GetSecretValueCommand({
      SecretId: secretName,
    });

    const response = await secretsClient.send(command);

    if (!response.SecretString) {
      throw new Error(`Secret ${secretName} has no SecretString`);
    }

    const secretData = JSON.parse(response.SecretString);

    // Cache the secret
    secretCache.set(secretName, {
      data: secretData,
      timestamp: Date.now(),
    });

    logger.info('Secret retrieved from AWS Secrets Manager', { secretName });
    return secretData;
  } catch (error) {
    logger.error('Failed to retrieve secret from AWS Secrets Manager', { secretName, error });
    throw new Error(`Failed to retrieve secret ${secretName}: ${error}`);
  }
}

/**
 * Fallback to environment variables for development
 */
function getSecretFromEnv(secretName: string): any {
  switch (secretName) {
    case 'nepaltrust/esewa/production':
      return {
        secret_key: process.env.ESEWA_SECRET || '8g8t8h8',
        product_code: process.env.ESEWA_PRODUCT_CODE || 'NEPALTRUST_DEV',
      };
    case 'nepaltrust/khalti/production':
      return {
        live_secret_key: process.env.KHALTI_SECRET || 'test_secret_key_...',
        public_key: process.env.KHALTI_PUBLIC_KEY || 'test_public_key',
      };
    case 'nepaltrust/connectips/production':
      return {
        credential_name: process.env.CONNECTIPS_CREDENTIAL_NAME || 'TEST_CRED',
        app_id: process.env.CONNECTIPS_APP_ID || 'TEST_APP_ID',
        app_name: process.env.CONNECTIPS_APP_NAME || 'TEST_APP',
        username: process.env.CONNECTIPS_USERNAME || 'test_user',
        password: process.env.CONNECTIPS_PASSWORD || 'test_pass',
        private_key: process.env.CONNECTIPS_PRIVATE_KEY || 'test_key',
      };
    case 'nepaltrust/firebase/production':
      return {
        projectId: process.env.FIREBASE_PROJECT_ID || 'test-project',
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL || 'test@test.com',
        privateKey: (process.env.FIREBASE_PRIVATE_KEY || '').replace(/\\n/g, '\n'),
        storageBucket: process.env.FIREBASE_STORAGE_BUCKET || 'test-bucket.appspot.com',
      };
    case 'nepaltrust/api/audit-log-signing':
      return {
        key: process.env.AUDIT_SECRET || 'dev-secret-key-123',
      };
    default:
      throw new Error(`Unknown secret name: ${secretName}`);
  }
}

/**
 * Get eSewa production credentials
 */
export async function getEsewaSecrets(): Promise<EsewaSecrets> {
  return await getSecret('nepaltrust/esewa/production');
}

/**
 * Get Khalti production credentials
 */
export async function getKhaltiSecrets(): Promise<KhaltiSecrets> {
  return await getSecret('nepaltrust/khalti/production');
}

/**
 * Get connectIPS production credentials
 */
export async function getConnectIPSSecrets(): Promise<ConnectIPSSecrets> {
  return await getSecret('nepaltrust/connectips/production');
}

/**
 * Get Firebase Admin credentials
 */
export async function getFirebaseSecrets(): Promise<FirebaseSecrets> {
  return await getSecret('nepaltrust/firebase/production');
}

/**
 * Get the secret used for signing audit logs (SHA-256 hash-chain)
 */
export async function getAuditSecret(): Promise<string> {
  const secret = await getSecret('nepaltrust/api/audit-log-signing');
  return secret.key || process.env.AUDIT_SECRET || 'dev-secret';
}

/**
 * Clear secret cache (useful for testing or forced refresh)
 */
export function clearSecretCache(): void {
  secretCache.clear();
  logger.info('Secret cache cleared');
}

/**
 * Health check for secrets manager
 */
export async function secretsHealthCheck(): Promise<boolean> {
  if (process.env.NODE_ENV !== 'production') {
    return true; // Always healthy in dev mode
  }

  try {
    // Try to fetch one secret to verify connectivity
    await getSecret('nepaltrust/esewa/production');
    return true;
  } catch (error) {
    logger.error('Secrets Manager health check failed', { error });
    return false;
  }
}
