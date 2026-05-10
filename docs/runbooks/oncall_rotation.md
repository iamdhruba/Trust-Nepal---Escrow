# Incident Management & On-Call Rotation

## 1. PagerDuty Schedules (Beta Launch Phase)
- **Primary Schedule:** Weekly rotation (Monday 09:00 NPT to next Monday 09:00 NPT).
- **Secondary (Escalation) Schedule:** Always CTO / Lead Architect.

### Initial Rotation (May 2026)
- **Week 1:** DevOps Engineer (Pramod)
- **Week 2:** Backend Lead (Sandesh)
- **Week 3:** System Administrator (Kiran)
- **Week 4:** DevOps Engineer (Pramod)

## 2. Slack Integration (#incidents)
- All PagerDuty alerts automatically trigger a message in the `#incidents` Slack channel.
- **P1 Incidents:** Will trigger an `@channel` mention.
- **P2 Incidents:** Will trigger an `@here` mention.

## 3. Acknowledgement SLAs
- **P1 (Critical):** 5 minutes.
- **P2 (High):** 15 minutes.
If the Primary on-call does not acknowledge the incident in PagerDuty within the SLA, the incident automatically escalates to the Secondary schedule.

## 4. Runbooks
Always refer to the [Incident Response Runbook](incident_response.md) before attempting to modify the production database or manual payouts.
