import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/nt_theme.dart';
import 'vault_viewmodel.dart';

class DeliverScreen extends ConsumerStatefulWidget {
  final String vaultId;
  const DeliverScreen({super.key, required this.vaultId});
  @override
  ConsumerState<DeliverScreen> createState() => _DeliverScreenState();
}

class _DeliverScreenState extends ConsumerState<DeliverScreen> {
  final _qrCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() { _qrCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NTColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: NTColors.secondary, size: 20), onPressed: () => context.pop()),
        title: const Text('Confirm Delivery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // QR Scanner placeholder
            Container(
              height: 240,
              decoration: BoxDecoration(color: NTColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: NTColors.primary.withOpacity(0.3))),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_scanner, color: NTColors.primary, size: 64),
                    const SizedBox(height: 16),
                    Text('Tap to Scan QR Code', style: TextStyle(color: NTColors.secondary, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Ask seller to show the vault QR', style: TextStyle(color: NTColors.secondary.withOpacity(0.6), fontSize: 13)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Center(child: Text('— or enter code manually —', style: TextStyle(color: NTColors.secondary))),
            const SizedBox(height: 16),
            _buildLabel('DELIVERY TOKEN'),
            Container(
              decoration: BoxDecoration(color: NTColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: NTColors.outline)),
              child: TextField(
                controller: _qrCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: '64-character delivery token',
                  hintStyle: TextStyle(color: NTColors.secondary.withOpacity(0.4)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton.icon(
                onPressed: _qrCtrl.text.isNotEmpty && !_isLoading ? _submit : null,
                icon: const Icon(Icons.verified_outlined),
                label: const Text('Confirm I Received the Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NTColors.primary, foregroundColor: NTColors.background,
                  disabledBackgroundColor: NTColors.outline,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final success = await ref.read(vaultViewModelProvider.notifier).transitionVault(
      widget.vaultId, 
      'deliver', 
      {'qrToken': _qrCtrl.text}
    );
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) context.pop();
    }
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(text, style: TextStyle(color: NTColors.secondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
  );
}
