import pino from 'pino';
import { defineNotificationJobs } from './notification.worker.js';
import { defineVaultTimeoutJobs } from './vault_timeout.worker.js';
import { defineInvoiceJobs } from './invoice.worker.js';
import { definePayoutJobs } from './payout.worker.js';
import { defineRefundJobs } from './refund.worker.js';

const logger = pino({ name: 'worker-bootstrapper' });

export function startWorkers() {
  logger.info('Registering Agenda background jobs...');
  
  defineNotificationJobs();
  defineVaultTimeoutJobs();
  defineInvoiceJobs();
  definePayoutJobs();
  defineRefundJobs();
  
  logger.info('Background job definitions registered');
}
