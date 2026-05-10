import { Request, Response, NextFunction } from 'express';
import { AppError } from '../errors/AppError.js';
import pino from 'pino';
import { triggerAlert, AlertSeverity } from '../utils/pagerduty.js';

const logger = pino();

export const errorHandler = (
  err: any,
  req: Request,
  res: Response,
  next: NextFunction
) => {
  const requestId = req.headers['x-request-id'] as string || 'unknown';

  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      success: false,
      error: {
        code: err.code,
        message: err.message,
        details: err.details,
        requestId,
      },
    });
  }

  logger.error({ err, requestId, url: req.url }, 'Unhandled error');

  // Trigger PagerDuty for critical internal errors in production
  if (process.env.NODE_ENV === 'production') {
    triggerAlert(
      `Internal Server Error: ${err.message || 'Unknown'}`,
      'API Server',
      AlertSeverity.CRITICAL,
      { requestId, url: req.url, stack: err.stack }
    ).catch(e => logger.error(e, 'Failed to trigger PagerDuty alert'));
  }

  return res.status(500).json({
    success: false,
    error: {
      code: 'INTERNAL_SERVER_ERROR',
      message: 'An unexpected error occurred',
      requestId,
    },
  });
};
