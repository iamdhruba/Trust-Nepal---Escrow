import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/nt_theme.dart';

class GlobalScannerScreen extends StatefulWidget {
  const GlobalScannerScreen({super.key});

  @override
  State<GlobalScannerScreen> createState() => _GlobalScannerScreenState();
}

class _GlobalScannerScreenState extends State<GlobalScannerScreen> {
  late final MobileScannerController _scanner;
  bool _scanned = false;

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
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;

    setState(() => _scanned = true);
    
    // Logic: If it's a valid hex ID (24 or 64 chars), navigate to vault
    if (code.length >= 24) {
      context.push('/vault/$code');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unrecognized Protocol QR Code')),
      );
      setState(() => _scanned = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'INSTITUTIONAL SCANNER',
          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scanner,
            onDetect: _onDetect,
          ),
          // Custom Overlay
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6),
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
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Decorative border
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: NTColors.secondary.withOpacity(0.5), width: 1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Stack(
                children: [
                  _corner(top: 0, left: 0, angle: 0),
                  _corner(top: 0, right: 0, angle: 90),
                  _corner(bottom: 0, left: 0, angle: 270),
                  _corner(bottom: 0, right: 0, angle: 180),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  'ALIGN PROTOCOL QR OR BARCODE',
                  style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _toolBtn(Icons.flashlight_on_rounded, () => _scanner.toggleTorch()),
                    const SizedBox(width: 20),
                    _toolBtn(Icons.flip_camera_ios_rounded, () => _scanner.switchCamera()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _corner({double? top, double? left, double? right, double? bottom, required double angle}) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
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

  Widget _toolBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
