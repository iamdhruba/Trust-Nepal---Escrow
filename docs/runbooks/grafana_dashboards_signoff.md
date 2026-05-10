# Grafana Dashboards — On-Call Signoff

**Date:** 2026-05-01
**Reviewers:**
- Pramod (DevOps)
- Sandesh (Backend)
- Kiran (SysAdmin)

## Approved Dashboards
The on-call team has reviewed and approved the following PromQL and Loki queries present on the main Grafana Production Dashboard:

1. **Vault State Transitions (Gauge):** `nepaltrust_vault_state_total`
2. **Payment Success Rate (Gauge):** `nepaltrust_payment_success_rate`
3. **P95 Latency (Histogram):** `nepaltrust_api_request_duration_ms`
4. **BullMQ Queue Depths:** Real-time metrics for invoices, notifications, refunds, and payouts.
5. **Exception Tracking:** Loki query tracking 500 status codes mapped to traces.

## Signoff
*The on-call team confirms that the dashboard panels effectively surface the information needed to diagnose P1 and P2 incidents within the SLA.*
