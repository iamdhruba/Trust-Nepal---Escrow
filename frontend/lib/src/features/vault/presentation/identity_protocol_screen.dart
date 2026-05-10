import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/nt_theme.dart';
import 'profile_screen.dart';

class IdentityProtocolScreen extends ConsumerWidget {
  const IdentityProtocolScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: NTColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: NTColors.primary, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'IDENTITY PROTOCOL',
          style: TextStyle(color: NTColors.primary, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: NTColors.secondary)),
        error: (_, __) => const Center(child: Text('Failed to load identity.')),
        data: (profile) => _buildBody(context, profile),
      ),
    );
  }

  Widget _buildBody(BuildContext context, UserProfile? profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIdentitySummary(profile),
          const SizedBox(height: 40),
          _buildSectionLabel('VERIFIED CREDENTIALS'),
          _buildCredentialItem(
            'Citizenship / NID',
            'Document #27-01-72-•••••',
            true,
            Icons.badge_outlined,
          ),
          _buildDivider(),
          _buildCredentialItem(
            'Phone Authentication',
            profile?.phone != null ? '+977 ${profile!.phone}' : '—',
            true,
            Icons.phone_iphone_rounded,
          ),
          _buildDivider(),
          _buildCredentialItem(
            'Tax Registration (PAN)',
            'Verified Status • Active',
            profile?.kycStatus == 'APPROVED',
            Icons.corporate_fare_rounded,
          ),
          const SizedBox(height: 40),
          _buildSectionLabel('ENTITY PROFILE'),
          _buildInfoField('FULL LEGAL NAME', profile?.name ?? '—'),
          const SizedBox(height: 24),
          _buildInfoField('RESIDENTIAL ADDRESS', 'Baneshwor, Kathmandu, Nepal'),
          const SizedBox(height: 24),
          _buildInfoField('PROTOCOL LEVEL', 'Institutional Tier 1'),
          const SizedBox(height: 60),
          _buildActionBtn(),
        ],
      ),
    );
  }

  Widget _buildIdentitySummary(UserProfile? profile) {
    final verified = profile?.kycStatus == 'APPROVED';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NTRadius.lg),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: NTColors.secondary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(verified ? Icons.verified_rounded : Icons.pending_rounded, color: NTColors.secondary, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('KYC VERIFICATION', style: TextStyle(color: NTColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(verified ? 'AUTHENTICATED' : 'REVIEW PENDING', style: const TextStyle(color: NTColors.primary, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 16),
    child: Text(text, style: const TextStyle(color: NTColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
  );

  Widget _buildCredentialItem(String title, String sub, bool verified, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Icon(icon, color: NTColors.primary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: NTColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(sub, style: TextStyle(color: NTColors.onSurfaceVariant.withOpacity(0.7), fontSize: 12)),
              ],
            ),
          ),
          if (verified)
            const Icon(Icons.check_circle_rounded, color: NTColors.secondary, size: 18),
        ],
      ),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, thickness: 1, color: NTColors.surfaceLow);

  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: NTColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: NTColors.primary, fontSize: 15, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildActionBtn() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          foregroundColor: NTColors.primary,
          side: const BorderSide(color: NTColors.primary, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NTRadius.md)),
        ),
        child: const Text('UPDATE IDENTITY DOCUMENTS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
      ),
    );
  }
}
