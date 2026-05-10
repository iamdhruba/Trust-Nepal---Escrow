import { getAgenda } from '../config/agenda.js';
import pino from 'pino';

const logger = pino({ name: 'refund-worker' });

export const defineRefundJobs = () => {
  const agenda = getAgenda();

  agenda.define('refund.initiate', async (job) => {
    const { vaultId, amount } = job.attrs.data as any;
    logger.info({ vaultId, amount }, 'Initiating payment refund (stub)');

    try {
      // TODO: Call PSP refund API (eSewa/Khalti)
      logger.info({ vaultId, amount }, 'Refund initiated successfully (stub)');
    } catch (error: any) {
      logger.error({ vaultId, error: error.message }, 'Refund failed');
      throw error;
    }
  });
};
