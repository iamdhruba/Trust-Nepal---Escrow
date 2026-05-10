import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/nt_theme.dart';
import 'vault_viewmodel.dart';

class DisputeScreen extends ConsumerStatefulWidget {
  final String vaultId;
  const DisputeScreen({super.key, required this.vaultId});
  @override
  ConsumerState<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends ConsumerState<DisputeScreen> {
  final _descCtrl = TextEditingController();
  bool _isLoading = false;
  String? _selectedReason;

  final _reasons = [
    'Counterparty Non-Compliance',
    'Asset Discrepancy / Damage',
    'Logistics Verification Failure',
    'Contractual Terms Violation',
    'Other Regulatory Issue'
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NTColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: NTColors.primary, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Trust Nepal', style: TextStyle(color: NTColors.primary, fontWeight: FontWeight.w900, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.gavel_rounded, color: NTColors.error, size: 20),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTrustAnchor(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  const Text('Arbitration Request', 
                      style: TextStyle(color: NTColors.primary, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  const Text('Initiate a formal audit of this transaction protocol.', 
                      style: TextStyle(color: NTColors.onSurfaceVariant, fontSize: 13)),
                  const SizedBox(height: 32),
                  _buildLegalWarning(),
                  const SizedBox(height: 40),
                  const Text('NATURE OF DISPUTE', 
                      style: TextStyle(color: NTColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  ..._reasons.map((r) => _buildReasonOption(r)),
                  const SizedBox(height: 32),
                  const Text('DETAILED EVIDENCE / STATEMENT', 
                      style: TextStyle(color: NTColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  _buildEvidenceField(),
                  const SizedBox(height: 48),
                  _buildSubmitBtn(),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustAnchor() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      color: NTColors.error.withOpacity(0.03),
      child: Row(
        children: [
          const Icon(Icons.security_rounded, color: NTColors.error, size: 14),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('PROTOCOL HALT: ARBITRATION OVERRIDE', 
                style: TextStyle(color: NTColors.error, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalWarning() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NTColors.error,
        borderRadius: BorderRadius.circular(NTRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Initiating arbitration will freeze vault funds immediately. Our legal mediators will perform a full audit of transaction logs and provided evidence.',
              style: TextStyle(color: Colors.white, fontSize: 12, height: 1.5, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonOption(String reason) {
    final active = _selectedReason == reason;
    return GestureDetector(
      onTap: () => setState(() => _selectedReason = reason),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: active ? Colors.white : NTColors.background,
          borderRadius: BorderRadius.circular(NTRadius.md),
          border: Border.all(color: active ? NTColors.error : NTColors.outlineVariant.withOpacity(0.3), width: active ? 2 : 1),
          boxShadow: active ? [BoxShadow(color: NTColors.error.withOpacity(0.1), blurRadius: 10)] : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(reason, 
                  style: TextStyle(color: NTColors.primary, fontWeight: active ? FontWeight.w900 : FontWeight.bold, fontSize: 14)),
            ),
            Icon(active ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded, 
                color: active ? NTColors.error : NTColors.outlineVariant.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NTRadius.md),
        border: Border.all(color: NTColors.outlineVariant.withOpacity(0.5)),
      ),
      child: TextField(
        controller: _descCtrl,
        maxLines: 6,
        style: const TextStyle(color: NTColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Provide a comprehensive statement for our legal team (min. 50 characters)...',
          hintStyle: TextStyle(color: NTColors.onSurfaceVariant.withOpacity(0.4), fontWeight: FontWeight.normal),
          contentPadding: const EdgeInsets.all(20),
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(NTRadius.md), borderSide: const BorderSide(color: NTColors.error, width: 2)),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildSubmitBtn() {
    final bool valid = _selectedReason != null && _descCtrl.text.length >= 50 && !_isLoading;
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: valid ? _submit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: NTColors.error,
          foregroundColor: Colors.white,
          disabledBackgroundColor: NTColors.outlineVariant,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NTRadius.md)),
        ),
        child: _isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('SUBMIT FOR ARBITRATION', 
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final success = await ref
        .read(vaultViewModelProvider.notifier)
        .transitionVault(widget.vaultId, 'dispute', {'reason': _selectedReason, 'description': _descCtrl.text});
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Arbitration request submitted.'), backgroundColor: NTColors.primary),
        );
        context.pop();
      }
    }
  }
}
