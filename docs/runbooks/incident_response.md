# Incident Response Runbook

## 1. Classification & Escalation
- **P1 (Critical):** Payment failure rate > 2%, database downtime, connectIPS payout failure.
  - *Response:* Immediate page to On-Call Engineer + CTO. Slack: #incidents-war-room.
- **P2 (High):** Vault stuck in state > 1hr, API latency > 500ms, S3 upload failures.
  - *Response:* Slack alert. Resolution required within 4 hours.

## 2. Common Scenarios

### Scenario A: connectIPS Payout Failure
1. **Detection:** PagerDuty alert "Reconciliation Mismatch" or `payout-worker` DLQ entry.
2. **Action:**
   - Check `transactions` collection for status `FAILED`.
   - Verify bank pool account balance via Admin Dashboard (/admin/reconciliation).
   - If funds are present, trigger manual retry from Admin Dashboard.
   - If bank API is down, notify [Bank Contact Person] immediately.

### Scenario B: Payment Webhook Latency
1. **Detection:** Users reporting "Payment completed but vault not funded".
2. **Action:**
   - Check `webhooks_received` collection for unprocessed items.
   - Check Redis queue depth for `notificationQueue`.
   - Restart BullMQ workers if stuck: `docker-compose restart workers`.

## 3. Post-Mortem Requirement
Every P1/P2 incident requires a root cause analysis (RCA) document within 24 hours of resolution.
