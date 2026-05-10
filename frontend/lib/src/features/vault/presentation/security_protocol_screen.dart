import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/nt_theme.dart';

class SecurityProtocolScreen extends StatelessWidget {
  const SecurityProtocolScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          'SECURITY PROTOCOL',
          style: TextStyle(color: NTColors.primary, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShieldHeader(),
            const SizedBox(height: 40),
            _buildSectionLabel('AUTHENTICATION LAYERS'),
            _buildSecurityToggle(
              'Biometric Lock',
              'Require fingerprint or face ID to authorize transactions.',
              true,
              Icons.fingerprint_rounded,
            ),
            _buildDivider(),
            _buildSecurityToggle(
              'Two-Factor Auth (2FA)',
              'Secure your account with SMS or Authenticator app codes.',
              true,
              Icons.app_registration_rounded,
            ),
            const SizedBox(height: 40),
            _buildSectionLabel('SECURE SESSION'),
            _buildSecurityToggle(
              'Automatic Logout',
              'Terminate session after 15 minutes of inactivity.',
              true,
              Icons.timer_outlined,
            ),
            _buildDivider(),
            _buildSecurityToggle(
              'Login Notifications',
              'Get alerted via SMS on every account access.',
              false,
              Icons.notifications_active_outlined,
            ),
            const SizedBox(height: 60),
            _buildAuditLogs(),
          ],
        ),
      ),
    );
  }

  Widget _buildShieldHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: NTColors.primary,
        borderRadius: BorderRadius.circular(NTRadius.lg),
        boxShadow: [BoxShadow(color: NTColors.primary.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.shield_rounded, color: NTColors.secondary, size: 40),
          ),
          const SizedBox(height: 20),
          const Text('SECURITY LEVEL 2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
          const SizedBox(height: 8),
          const Text('Institutional grade encryption active.', style: TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 16),
    child: Text(text, style: const TextStyle(color: NTColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
  );

  Widget _buildSecurityToggle(String title, String desc, bool value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: NTColors.surfaceLow, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: NTColors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: NTColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: NTColors.onSurfaceVariant.withOpacity(0.7), fontSize: 11, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: (v) {},
            activeColor: NTColors.secondary,
            activeTrackColor: NTColors.secondary.withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, thickness: 1, color: NTColors.surfaceLow);

  Widget _buildAuditLogs() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NTRadius.md),
        border: Border.all(color: NTColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RECENT ACCESS LOGS', style: TextStyle(color: NTColors.primary, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
          const SizedBox(height: 20),
          _logItem('Web Console Login', 'Chrome on Windows • Kathmandu', 'Oct 24, 11:42 AM'),
          const SizedBox(height: 16),
          _logItem('Mobile App Authorization', 'iPhone 15 Pro • Pokhara', 'Oct 23, 09:15 PM'),
        ],
      ),
    );
  }

  Widget _logItem(String title, String sub, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(title, style: const TextStyle(color: NTColors.primary, fontWeight: FontWeight.bold, fontSize: 12))),
            const SizedBox(width: 8),
            Text(time, style: TextStyle(color: NTColors.onSurfaceVariant.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text(sub, style: TextStyle(color: NTColors.onSurfaceVariant.withOpacity(0.7), fontSize: 11)),
      ],
    );
  }
}
