import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/nt_theme.dart';
import 'vault_viewmodel.dart';

class ShipScreen extends ConsumerStatefulWidget {
  final String vaultId;
  const ShipScreen({super.key, required this.vaultId});
  @override
  ConsumerState<ShipScreen> createState() => _ShipScreenState();
}

class _ShipScreenState extends ConsumerState<ShipScreen> {
  final _trackingCtrl = TextEditingController();
  final _courierCtrl = TextEditingController();
  bool _isLoading = false;

  final _couriers = ['Aramex Nepal', 'DHL Express', 'Shree Mahakali', 'Sagarmatha Cargo', 'Namaste Logistic', 'Other'];
  String? _selectedCourier;

  @override
  void dispose() {
    _trackingCtrl.dispose();
    _courierCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NTColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: NTColors.primary, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Shipping Authentication',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: NTColors.primary,
              ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(NTSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NTColors.tertiary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(NTRadius.md),
                border: Border.all(color: NTColors.tertiary.withOpacity(0.1)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: NTColors.tertiary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please provide verifiable tracking information. The counterparty will use this data for real-time transit monitoring.',
                      style: TextStyle(color: NTColors.primary, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildLabel('AUTHORIZED COURIER PARTNER'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(NTRadius.md),
                border: Border.all(color: NTColors.outlineVariant),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCourier,
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: NTColors.onSurfaceVariant),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  hint: const Text('Select institutional partner',
                      style: TextStyle(color: NTColors.onSurfaceVariant, fontSize: 15)),
                  items: _couriers
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c,
                                style: const TextStyle(
                                    color: NTColors.primary, fontSize: 15, fontWeight: FontWeight.w500)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCourier = v),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildLabel('TRACKING IDENTIFICATION NUMBER'),
            _buildField(controller: _trackingCtrl, hint: 'e.g., NT-100-293-847'),
            const SizedBox(height: 60),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: (_isLoading || _selectedCourier == null || _trackingCtrl.text.isEmpty) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: NTColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: NTColors.outlineVariant,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NTRadius.md)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('AUTHENTICATE SHIPMENT',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final success = await ref
        .read(vaultViewModelProvider.notifier)
        .transitionVault(widget.vaultId, 'ship', {'courier': _selectedCourier, 'trackingNumber': _trackingCtrl.text});
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) context.pop();
    }
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(text,
            style: const TextStyle(
                color: NTColors.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
      );

  Widget _buildField({required TextEditingController controller, required String hint}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NTRadius.md),
        border: Border.all(color: NTColors.outlineVariant),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: NTColors.primary, fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: NTColors.onSurfaceVariant.withOpacity(0.4)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(NTRadius.md),
            borderSide: const BorderSide(color: NTColors.primary, width: 2),
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}
