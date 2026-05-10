import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/nt_theme.dart';
import 'payment_viewmodel.dart';
import 'vault_viewmodel.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String vaultId;
  const PaymentScreen({super.key, required this.vaultId});
  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _selected = 'esewa';
  Map<String, dynamic>? _vault;
  final _currencyFormat = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    _loadVault();
  }

  Future<void> _loadVault() async {
    final v = await ref.read(vaultViewModelProvider.notifier).fetchVaultDetails(widget.vaultId);
    if (mounted) setState(() => _vault = v);
  }

  @override
  Widget build(BuildContext context) {
    final payState = ref.watch(paymentViewModelProvider);
    final amount = (_vault?['amount'] as num?)?.toDouble() ?? 0.0;
    final fee = amount * 0.005; // Standard 0.5%
    final levy = 150.0;
    final total = amount + fee + levy;

    ref.listen(paymentViewModelProvider, (prev, next) {
      if (next.checkoutUrl != null && next.checkoutUrl!.isNotEmpty) {
        final encoded = Uri.encodeComponent(next.checkoutUrl!);
        context.push('/vault/${widget.vaultId}/pay/checkout?url=$encoded');
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: NTColors.error),
        );
      }
    });

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
            icon: const Icon(Icons.help_outline_rounded, color: NTColors.onSurfaceVariant, size: 20),
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
                  const Text('Fund Secure Vault', 
                      style: TextStyle(color: NTColors.primary, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  const Text('Finalize your escrow commitment through our secured gateways.', 
                      style: TextStyle(color: NTColors.onSurfaceVariant, fontSize: 13)),
                  const SizedBox(height: 32),
                  _buildSummaryCard(amount, fee, levy, total),
                  const SizedBox(height: 40),
                  const Text('SELECT PAYMENT INSTRUMENT', 
                      style: TextStyle(color: NTColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  _buildPaymentOption('esewa', 'eSewa Wallet', 'Instant confirmation via eSewa gateway', const Color(0xFF60BB46), Icons.account_balance_wallet_rounded),
                  const SizedBox(height: 12),
                  _buildPaymentOption('khalti', 'Khalti Payment', 'Pay via Khalti balance or linked bank', const Color(0xFF5C2D91), Icons.wallet_rounded),
                  const SizedBox(height: 40),
                  _buildSecurityBanner(),
                  const SizedBox(height: 40),
                  _buildConfirmBtn(payState.isLoading, total),
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
      color: NTColors.primary.withOpacity(0.03),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: NTColors.secondary, size: 14),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('SECURE TRANSACTION ENCRYPTED (AES-256)', 
                style: TextStyle(color: NTColors.secondary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double amount, double fee, double levy, double total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NTRadius.lg),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
        border: const Border(top: BorderSide(color: Color(0xFFC5AB02), width: 3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(child: Text('Transaction Amount', style: TextStyle(color: NTColors.onSurfaceVariant, fontSize: 14))),
              const SizedBox(width: 8),
              Text('NPR ${_currencyFormat.format(total)}', 
                  style: const TextStyle(color: NTColors.primary, fontWeight: FontWeight.w900, fontSize: 20)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1),
          ),
          _summaryDetailRow('Principal Escrow', amount),
          const SizedBox(height: 12),
          _summaryDetailRow('Trust Nepal Fee (0.5%)', fee),
          const SizedBox(height: 12),
          _summaryDetailRow('Regulatory Levy', levy),
        ],
      ),
    );
  }

  Widget _summaryDetailRow(String label, double val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Text(label, style: const TextStyle(color: NTColors.onSurfaceVariant, fontSize: 12))),
        const SizedBox(width: 8),
        Text('NPR ${_currencyFormat.format(val)}', style: const TextStyle(color: NTColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildPaymentOption(String id, String name, String sub, Color color, IconData icon) {
    final active = _selected == id;
    return GestureDetector(
      onTap: () => setState(() => _selected = id),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: active ? Colors.white : NTColors.background,
          borderRadius: BorderRadius.circular(NTRadius.md),
          border: Border.all(color: active ? NTColors.secondary : NTColors.outlineVariant.withOpacity(0.3), width: active ? 2 : 1),
          boxShadow: active ? [BoxShadow(color: NTColors.secondary.withOpacity(0.1), blurRadius: 10)] : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: NTColors.primary, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(sub, style: TextStyle(color: NTColors.onSurfaceVariant.withOpacity(0.6), fontSize: 11)),
                ],
              ),
            ),
            Icon(active ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, 
                color: active ? NTColors.secondary : NTColors.outlineVariant.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: NTColors.primary, borderRadius: BorderRadius.circular(NTRadius.md)),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: Color(0xFFC5AB02), size: 24),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Your capital is held in a segregated NRB-nodal account. Release is only possible after mutual confirmation or arbitrator ruling.',
              style: TextStyle(color: Colors.white, fontSize: 11, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmBtn(bool loading, double total) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: loading ? null : () => ref.read(paymentViewModelProvider.notifier).initiatePayment(widget.vaultId, _selected),
        style: ElevatedButton.styleFrom(
          backgroundColor: NTColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NTRadius.md)),
        ),
        child: loading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text('CONFIRM NPR ${_currencyFormat.format(total)}', 
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
      ),
    );
  }
}
