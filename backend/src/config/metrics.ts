import promBundle from 'express-prom-bundle';

export const metricsMiddleware = promBundle({
  includeMethod: true,
  includePath: true,
  includeStatusCode: true,
  normalizePath: [
    ['^/api/v1/vaults/.*', '/api/v1/vaults/#id'],
    ['^/api/v1/admin/kyc/.*', '/api/v1/admin/kyc/#userId'],
  ],
  promClient: {
    collectDefaultMetrics: {},
  },
});
