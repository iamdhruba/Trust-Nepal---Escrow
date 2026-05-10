import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/nt_theme.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String checkoutUrl;
  final String vaultId;

  const PaymentWebViewScreen({
    super.key,
    required this.checkoutUrl,
    required this.vaultId,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  static const _successPath = '/payment-success';
  static const _failurePath = '/payment-failed';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) => setState(() => _loading = false),
        onNavigationRequest: (request) {
          final url = request.url;
          if (url.contains(_successPath)) {
            _onPaymentSuccess(url);
            return NavigationDecision.prevent;
          }
          if (url.contains(_failurePath)) {
            _onPaymentFailed();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  void _onPaymentSuccess(String url) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Transaction authenticated. Vault successfully funded.'),
          backgroundColor: NTColors.secondary,
        ),
      );
      context.go('/vault/${widget.vaultId}');
    }
  }

  void _onPaymentFailed() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Institutional transaction failed or was declined.'),
          backgroundColor: NTColors.error,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: NTColors.primary),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NTRadius.lg)),
                title: const Text('Cancel Transaction?', style: TextStyle(color: NTColors.primary, fontWeight: FontWeight.bold)),
                content: const Text(
                  'The escrow funding process is incomplete. Returning will cancel the current session.',
                  style: TextStyle(color: NTColors.onSurfaceVariant),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('PROCEED WITH PAYMENT', style: TextStyle(color: NTColors.secondary, fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.pop();
                    },
                    child: const Text('CANCEL', style: TextStyle(color: NTColors.error)),
                  ),
                ],
              ),
            );
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded, color: NTColors.secondary, size: 16),
            const SizedBox(width: 8),
            Text(
              widget.checkoutUrl.contains('esewa') ? 'SECURE ESEWA PORTAL' : 'SECURE KHALTI PORTAL',
              style: const TextStyle(color: NTColors.primary, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ],
        ),
        bottom: _loading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(
                  color: NTColors.secondary,
                  backgroundColor: NTColors.outlineVariant,
                  minHeight: 2,
                ),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
