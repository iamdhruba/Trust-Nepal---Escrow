import { getAgenda } from './agenda.js';

export const dispatchJob = async (name: string, data: any, options: { delay?: number } = {}) => {
  const agenda = getAgenda();
  if (options.delay) {
    await agenda.schedule(new Date(Date.now() + options.delay), name, data);
  } else {
    await agenda.now(name, data);
  }
};

// Compatibility shims for existing code
export const invoiceQueue = { add: (name: string, data: any) => dispatchJob('invoice.generate', data) };
export const refundQueue = { add: (name: string, data: any) => dispatchJob('refund.initiate', data) };
export const payoutQueue = { add: (name: string, data: any) => dispatchJob('payout.initiate', data) };
export const notificationQueue = { add: (name: string, data: any) => dispatchJob('notification.send', data) };
export const vaultTimeoutQueue = { add: (name: string, data: any, opts: any) => dispatchJob('vault-timeout', data, { delay: opts.delay }) };
