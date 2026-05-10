/**
 * Trust Nepal Business Rules & Configuration
 * 
 * This file contains business logic constants that are not necessarily secrets
 * but need to be centralized for compliance and easy updates.
 */

export const BUSINESS_RULES = {
  /**
   * Platform fee as a percentage of the vault amount.
   * Currently set to 1% for the pilot phase.
   * Requirement: BL-002
   */
  PLATFORM_FEE_PERCENTAGE: 0.01,

  /**
   * Default vault expiration in days if not shipment occurs.
   * Requirement: E-commerce Guidelines 2026 Cl.8.3
   */
  DEFAULT_VAULT_EXPIRY_DAYS: 7,

  /**
   * Time window in hours for buyer to confirm delivery before auto-release.
   * Requirement: Vault State Machine TC-006
   */
  AUTO_CONFIRM_WINDOW_HOURS: 48,

  /**
   * Maximum OTP attempts per hour per phone number.
   * Requirement: Security Matrix - Rate Limiting
   */
  MAX_OTP_ATTEMPTS_PER_HOUR: 5,

  /**
   * Minimum transaction amount in NPR.
   */
  MIN_TRANSACTION_AMOUNT: 10,

  /**
   * Maximum transaction amount in NPR for non-KYC or tier-1 users.
   */
  MAX_TRANSACTION_AMOUNT_TIER_1: 50000,
};
