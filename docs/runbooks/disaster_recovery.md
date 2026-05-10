# Disaster Recovery (DR) Plan

## 1. Objectives
- **RPO (Recovery Point Objective):** 15 minutes (Max data loss).
- **RTO (Recovery Time Objective):** 1 hour (Max downtime).

## 2. Backup Strategy
- **MongoDB Atlas:** Continuous cloud backups with PITR (Point-in-Time Recovery) enabled.
- **S3:** Cross-region replication (CRR) from Mumbai (`ap-south-1`) to Singapore (`ap-southeast-1`) for all non-KYC data.
- **KYC Data:** Daily encrypted snapshots moved to local Nepal-domiciled cold storage (as per Data Localization Opinion).

## 3. Recovery Procedures

### Level 1: Database Corruption/Loss
1. Navigate to MongoDB Atlas Console.
2. Select "Restore from Backup".
3. Choose the closest PITR snapshot before the incident.
4. Update `MONGO_URI` in AWS Secrets Manager if the cluster endpoint changes.
5. Restart API services.

### Level 2: Region Failure (AWS Mumbai Down)
1. Initialize Terraform in `infra/terraform/singapore`.
2. Deploy core API and Worker services to `ap-southeast-1`.
3. Point CloudFront/DNS to the new region.
4. *Note:* KYC data retrieval will depend on the availability of the local Nepal-domiciled mirror.

## 4. Annual Drill
A full DR drill must be performed annually. The next scheduled drill is **2026-06-15**.
