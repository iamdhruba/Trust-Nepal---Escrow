import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/nt_theme.dart';
import 'vault_viewmodel.dart';

class QrDeliverScreen extends ConsumerStatefulWidget {
  final String vaultId;
  const QrDeliverScreen({super.key, required this.vaultId});

  @override
  ConsumerState<QrDeliverScreen> createState() => _QrDeliverScreenState();
}

class _QrDeliverScreenState extends ConsumerState<QrDeliverScreen> {
  final _manualCtrl = TextEditingController();
  late final MobileScannerController _scanner;
  bool _scanned = false;
  bool _manualMode = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scanner = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    _scanner.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanned) return;
    final token = capture.barcodes.firstOrNull?.rawValue;
    if (token == null || token.length != 64) return;

    setState(() => _scanned = true);
    await _submit(token);
  }

  Future<void> _submit(String token) async {
    setState(() => _isLoading = true);
    final success = await ref.read(vaultViewModelProvider.notifier).transitionVault(
      widget.vaultId,
      'deliver',
      {'qrToken': token},
    );
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Delivery Authenticated. Payment release protocol initiated.'),
            backgroundColor: NTColors.secondary,
          ),
        );
        context.go('/vault/${widget.vaultId}');
      } else {
        setState(() => _scanned = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification Failed: Invalid or expired delivery token.'),
            backgroundColor: NTColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: NTColors.primary, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _manualMode ? 'Manual Verification' : 'Scanner Authentication',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: NTColors.primary,
              ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: () => setState(() => _manualMode = !_manualMode),
              child: Text(
                _manualMode ? 'USE SCANNER' : 'ENTER TOKEN',
                style: const TextStyle(
                  color: NTColors.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: NTColors.secondary))
          : _manualMode
              ? _buildManualEntry()
              : _buildQrScanner(),
    );
  }

  Widget _buildQrScanner() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              MobileScanner(
                controller: _scanner,
                onDetect: _onDetect,
              ),
              // Institutional Overlay
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.5),
                  BlendMode.srcOut,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        backgroundBlendMode: BlendMode.dstOut,
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(NTRadius.lg),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Corner guides
              Center(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.transparent),
                  ),
                  child: Stack(
                    children: [
                      _guideCorner(top: 0, left: 0, angle: 0),
                      _guideCorner(top: 0, right: 0, angle: 90),
                      _guideCorner(bottom: 0, left: 0, angle: 270),
                      _guideCorner(bottom: 0, right: 0, angle: 180),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: NTColors.primary.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'ALIGN DELIVERY QR WITHIN FRAME',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    IconButton(
                      onPressed: () => _scanner.toggleTorch(),
                      icon: const Icon(Icons.flashlight_on_rounded, color: Colors.white, size: 32),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _guideCorner({double? top, double? bottom, double? left, double? right, required double angle}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: angle * 3.14159 / 180,
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: NTColors.secondary, width: 4),
              left: BorderSide(color: NTColors.secondary, width: 4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManualEntry() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(NTSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: NTColors.secondary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(NTRadius.md),
              border: Border.all(color: NTColors.secondary.withOpacity(0.1)),
            ),
            child: const Row(
              children: [
                Icon(Icons.vpn_key_outlined, color: NTColors.secondary, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Input the secure 64-character token provided by the seller to authorize fund release.',
                    style: TextStyle(color: NTColors.primary, fontSize: 13, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'INSTITUTIONAL DELIVERY TOKEN',
              style: TextStyle(
                color: NTColors.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(NTRadius.md),
              border: Border.all(color: NTColors.outlineVariant),
            ),
            child: TextField(
              controller: _manualCtrl,
              maxLength: 64,
              style: const TextStyle(
                color: NTColors.primary,
                fontSize: 13,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter 64-character SHA-256 token...',
                hintStyle: TextStyle(color: NTColors.onSurfaceVariant.withOpacity(0.3)),
                contentPadding: const EdgeInsets.all(20),
                border: InputBorder.none,
                counterText: '',
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(NTRadius.md),
                  borderSide: const BorderSide(color: NTColors.primary, width: 2),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${_manualCtrl.text.length} / 64 characters entered',
            style: TextStyle(
              color: _manualCtrl.text.length == 64 ? NTColors.secondary : NTColors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 80),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _manualCtrl.text.length == 64 ? () => _submit(_manualCtrl.text) : null,
              icon: const Icon(Icons.verified_user_rounded, size: 20),
              label: const Text('AUTHENTICATE DELIVERY',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: NTColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: NTColors.outlineVariant,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NTRadius.md)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
