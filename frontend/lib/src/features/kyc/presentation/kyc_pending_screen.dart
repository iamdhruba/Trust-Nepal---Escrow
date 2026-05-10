import 'package:flutter/material.dart';
import '../../../core/theme/nt_theme.dart';

class KycPendingScreen extends StatelessWidget {
  const KycPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NTColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(NTSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: NTColors.primary.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: NTColors.primary.withOpacity(0.1)),
                ),
                child: const Icon(Icons.shield_rounded, color: NTColors.primary, size: 48),
              ),
              const SizedBox(height: 40),
              const Text(
                'COMPLIANCE REVIEW',
                style: TextStyle(color: NTColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Verification in Progress',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: NTColors.primary,
                      letterSpacing: -0.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Our institutional compliance desk is currently auditing your identity assets. This typically takes 2-4 business hours.',
                style: TextStyle(color: NTColors.onSurfaceVariant.withOpacity(0.8), fontSize: 14, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(NTRadius.md),
                  border: Border.all(color: NTColors.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AUDIT PROGRESSION',
                      style: TextStyle(
                        color: NTColors.onSurfaceVariant,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildStep('Document Integrity Hash', true),
                    _buildStep('Biometric Liveness Match', true),
                    _buildStep('AML / Sanction Screening', false),
                    _buildStep('Final Risk Assessment', false),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.logout_rounded, size: 18, color: NTColors.error),
                  label: const Text('TERMINATE SECURE SESSION', style: TextStyle(color: NTColors.error, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                  style: TextButton.styleFrom(
                    backgroundColor: NTColors.error.withOpacity(0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NTRadius.md)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String label, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            done ? Icons.verified_rounded : Icons.pending_outlined,
            color: done ? NTColors.secondary : NTColors.outlineVariant,
            size: 20,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: done ? NTColors.primary : NTColors.onSurfaceVariant.withOpacity(0.5),
                fontSize: 13,
                fontWeight: done ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          if (done) const Icon(Icons.check, color: NTColors.secondary, size: 12),
        ],
      ),
    );
  }
}
