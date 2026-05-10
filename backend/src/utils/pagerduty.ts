import axios from 'axios';
import pino from 'pino';

const logger = pino({ name: 'pagerduty-client' });

/**
 * NepalTrust PagerDuty Integration
 * Requirement: hhh.md line 480
 */

export enum AlertSeverity {
  CRITICAL = 'critical',
  ERROR = 'error',
  WARNING = 'warning',
  INFO = 'info',
}

export async function triggerAlert(
  summary: string,
  source: string,
  severity: AlertSeverity,
  customDetails: any = {}
) {
  const integrationKey = process.env.PAGERDUTY_INTEGRATION_KEY;
  
  if (!integrationKey) {
    logger.warn({ summary, severity }, 'PagerDuty integration key not found. Alert logged only.');
    return;
  }

  try {
    await axios.post('https://events.pagerduty.com/v2/enqueue', {
      payload: {
        summary,
        timestamp: new Date().toISOString(),
        source,
        severity,
        component: 'api-server',
        group: 'production',
        class: 'incident',
        custom_details: customDetails,
      },
      routing_key: integrationKey,
      event_action: 'trigger',
    });
    
    logger.info({ summary }, 'PagerDuty alert triggered successfully');
  } catch (error) {
    logger.error({ summary, error }, 'Failed to trigger PagerDuty alert');
  }
}
