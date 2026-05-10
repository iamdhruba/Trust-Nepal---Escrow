# Escrow Bank Partnership Agreement (Template)
**Parties:** 
1. **NepalTrust Escrow Platform** (The "Provider")
2. **Nabil Bank Limited** (The "Escrow Bank"), a Class-A Commercial Bank licensed by NRB.

## 1. Objective
To establish a dedicated non-interest bearing Escrow Pool Account for holding buyer funds until transaction fulfillment.

## 2. API Integration
The Escrow Bank shall provide API access to NepalTrust for:
- Real-time balance inquiry of the pool account.
- Automated payout triggers via connectIPS/NCHL.
- Statement reconciliation on an hourly basis.

## 3. Funds Security
- Funds in the Escrow Pool Account are the property of the transacting users and shall not be used for bank lending or collateral.
- Payouts can ONLY be triggered by signed instructions from the NepalTrust `VaultService` via the `payout-worker` using the platform's RSA private key.

## 4. Compliance
Both parties agree to comply with the **Anti-Money Laundering (AML) and Counter-Terrorism Financing (CFT)** requirements. NepalTrust will provide the bank with full KYC data of all transacting parties upon request.

## 5. Liability
The Escrow Bank is responsible for the finality of payments once triggered. NepalTrust is responsible for the validity of the state transition (e.g., ensuring "DELIVERED" state was reached).
