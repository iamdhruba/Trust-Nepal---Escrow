import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/nt_theme.dart';
import '../../auth/presentation/auth_viewmodel.dart';

class UserProfile {
  final String phone;
  final String kycStatus;
  final String name;

  const UserProfile({
    required this.phone,
    required this.kycStatus,
    required this.name,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      phone: json['phone'] ?? '',
      kycStatus: json['kycStatus'] ?? 'NOT_SUBMITTED',
      name: json['name'] ?? '',
    );
  }
}

final profileProvider = FutureProvider<UserProfile?>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.get('/users/me');
    return UserProfile.fromJson(res.data['data']);
  } catch (_) {
    return null;
  }
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: NTColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'ACCOUNT PROTOCOL',
          style: TextStyle(color: NTColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: NTColors.secondary)),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: NTColors.error),
              const SizedBox(height: 16),
              const Text('Failed to load secure profile.', style: TextStyle(color: NTColors.onSurfaceVariant)),
              TextButton(onPressed: () => ref.refresh(profileProvider), child: const Text('RETRY AUTHENTICATION')),
            ],
          ),
        ),
        data: (profile) => _buildBody(context, ref, profile),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, UserProfile? profile) {
    Color statusColor;
    String statusLabel;

    switch (profile?.kycStatus) {
      case 'APPROVED':
        statusColor = NTColors.secondary;
        statusLabel = 'VERIFIED';
        break;
      case 'PENDING':
        statusColor = const Color(0xFFB59410); // Gold
        statusLabel = 'UNDER REVIEW';
        break;
      case 'REJECTED':
        statusColor = NTColors.error;
        statusLabel = 'REJECTED';
        break;
      default:
        statusColor = NTColors.outline;
        statusLabel = 'UNVERIFIED';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(NTSpacing.lg),
      child: Column(children: [
        const SizedBox(height: 12),
        // Institutional Profile Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(NTRadius.lg),
            border: Border.all(color: NTColors.outlineVariant),
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: NTColors.primary.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: NTColors.primary.withOpacity(0.1), width: 1),
                ),
                child: const Icon(Icons.verified_user_rounded, color: NTColors.primary, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                profile?.phone.isNotEmpty == true ? '+977 ${profile!.phone}' : '+977 ••••••••••',
                style: const TextStyle(color: NTColors.primary, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              if (profile?.name.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(profile!.name, style: TextStyle(color: NTColors.onSurfaceVariant.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500)),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_rounded, color: statusColor, size: 12),
                    const SizedBox(width: 8),
                    Text(
                      statusLabel,
                      style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        _buildSectionLabel('SYSTEM PREFERENCES'),
        _buildMenuCard([
          _buildTile(context, Icons.account_circle_outlined, 'Personal Identity', profile?.kycStatus == 'APPROVED' ? 'Verified' : 'Action Required', statusColor, 
              onTap: () => context.push('/profile/identity')),
          _buildDivider(),
          _buildTile(context, Icons.history_rounded, 'Transaction Archive', '', NTColors.primary, 
              onTap: () {}),
          _buildDivider(),
          _buildTile(context, Icons.security_rounded, 'Security Protocol', 'Level 2', NTColors.secondary, 
              onTap: () => context.push('/profile/security')),
        ]),
        const SizedBox(height: 24),
        _buildSectionLabel('SUPPORT & LEGAL'),
        _buildMenuCard([
          _buildTile(context, Icons.help_outline_rounded, 'Institutional Help', '', NTColors.primary, 
              onTap: () {}),
          _buildDivider(),
          _buildTile(context, Icons.description_outlined, 'Terms of Service', '', NTColors.primary, 
              onTap: () {}),
        ]),
        const SizedBox(height: 40),

        // Logout
        SizedBox(
          width: double.infinity,
          height: 60,
          child: TextButton.icon(
            onPressed: () async {
              await ref.read(authViewModelProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded, size: 18, color: NTColors.error),
            label: const Text('TERMINATE SECURE SESSION', style: TextStyle(color: NTColors.error, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
            style: TextButton.styleFrom(
              backgroundColor: NTColors.error.withOpacity(0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NTRadius.md)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text('v1.2.0-verified', style: TextStyle(color: NTColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w500)),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _buildSectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 12),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: const TextStyle(color: NTColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
    ),
  );

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NTRadius.md),
        border: Border.all(color: NTColors.outlineVariant),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, thickness: 1, color: NTColors.surfaceLow, indent: 56);

  Widget _buildTile(BuildContext context, IconData icon, String title, String subtitle, Color color, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: NTColors.surfaceLow, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: NTColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(color: NTColors.primary, fontSize: 14, fontWeight: FontWeight.w600))),
          if (subtitle.isNotEmpty) 
            Text(subtitle, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          const Icon(Icons.arrow_forward_ios_rounded, color: NTColors.outlineVariant, size: 12),
        ]),
      ),
    );
  }
}
