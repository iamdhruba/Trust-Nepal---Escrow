import { getAgenda } from '../config/agenda.js';
import { VaultService } from '../modules/vault/vault.service.js';
import pino from 'pino';

const logger = pino({ name: 'vault-timeout-worker' });
const vaultService = new VaultService();

export const defineVaultTimeoutJobs = () => {
  const agenda = getAgenda();

  agenda.define('vault-timeout', async (job: any) => {
    const { vaultId, action } = job.attrs.data;
    logger.info({ vaultId, action }, 'Processing vault timeout');

    try {
      await vaultService.transition(vaultId, action, 'system', 'SYSTEM', { reason: 'Automated timeout' });
      logger.info({ vaultId, action }, 'Timeout transition complete');
    } catch (err: any) {
      if (err.code === 'INVALID_TRANSITION') {
        logger.info({ vaultId, action }, 'Vault already transitioned — timeout skipped');
        return;
      }
      throw err;
    }
  });
};
