# Legal Opinion: Data Localization Compliance
**To:** Board of Directors, NepalTrust
**From:** Compliance Counsel
**Date:** 2026-05-01
**Subject:** Compliance with Data Localization Amendment 2026 (Art. 2)

## 1. Statutory Requirement
The **Data Localization Amendment 2026 (Art. 2)** requires that all Know Your Customer (KYC) data and primary financial ledgers for payment service providers (PSPs) be domiciled on servers physically located within the sovereign territory of Nepal.

## 2. Current Infrastructure Analysis
NepalTrust currently utilizes **AWS Mumbai (ap-south-1)** for its core application logic and database (MongoDB Atlas). 

- **KYC Data:** Includes National Identity (NID), Citizenship cards, and selfie liveness videos.
- **Financial Ledger:** The immutable SHA-256 audit log stored in MongoDB.

## 3. Compliance Risk
Using AWS Mumbai for sensitive data constitutes a high compliance risk. While AWS provides superior reliability, it does not satisfy the physical residency requirement of the 2026 Amendment.

## 4. Proposed Mitigation (Hybrid Strategy)
To ensure 100% compliance before the NRB final audit, we recommend:
1. **Primary Database Mirroring:** Maintain a real-time replica of the `users` (KYC) and `transactions` collections on a local server (e.g., CloudHimalaya or NTC GDC).
2. **Object Storage Redirection:** Store all raw ID images and unboxing videos on a local S3-compatible storage provider (e.g., local MinIO instance).
3. **Application Orchestration:** The API and frontend can remain on AWS Mumbai for performance, provided no PII is cached permanently on foreign disks.

## 5. Conclusion
Proceeding with AWS Mumbai for non-sensitive data is acceptable for the Beta phase, but **local data residency must be operational before the full commercial license issuance**.

**Status:** [Pending Board Approval]
