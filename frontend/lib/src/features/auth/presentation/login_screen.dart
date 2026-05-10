import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/nt_theme.dart';
import '../presentation/auth_viewmodel.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authViewModelProvider);

    ref.listen(authViewModelProvider, (prev, next) {
      if (!next.isLoading && next.error == null) {
        if (!_otpSent && next.otpSent) {
          setState(() => _otpSent = true);
        } else if (_otpSent && prev?.otpSent == true && !next.otpSent) {
          context.go('/home');
        }
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: NTColors.error),
        );
      }
    });

    return Scaffold(
      backgroundColor: NTColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: NTColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(NTRadius.md),
                ),
                child: const Icon(Icons.shield_rounded, color: NTColors.secondary, size: 32),
              ),
              const SizedBox(height: 32),
              Text(
                _otpSent ? 'Verification Code' : 'Institutional Access',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: NTColors.primary,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                _otpSent
                    ? 'Enter the 6-digit security code sent to +977 ${_phoneCtrl.text}'
                    : 'Secure your transactions with Trust Nepal\'s institutional escrow platform.',
                style: const TextStyle(color: NTColors.onSurfaceVariant, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 48),
              if (!_otpSent) ...[
                _buildLabel('REGISTERED PHONE NUMBER'),
                _buildField(
                  controller: _phoneCtrl,
                  hint: '98XXXXXXXX',
                  prefix: '+977 ',
                  keyboardType: TextInputType.phone,
                ),
              ] else ...[
                _buildLabel('SECURE OTP'),
                _buildField(
                  controller: _otpCtrl,
                  hint: '● ● ● ● ● ●',
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: NTColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 12,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() {
                      _otpSent = false;
                      _otpCtrl.clear();
                    }),
                    child: const Text(
                      'Change phone number',
                      style: TextStyle(color: NTColors.secondary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : _handlePress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NTColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: NTColors.outlineVariant,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NTRadius.md)),
                    elevation: 0,
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          _otpSent ? 'Authenticate' : 'Get Security Code',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 80),
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_user_rounded, size: 16, color: NTColors.secondary),
                        const SizedBox(width: 8),
                        Text(
                          'NRB REGULATED ENTITY',
                          style: TextStyle(
                            color: NTColors.onSurfaceVariant.withOpacity(0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Secured by banking-grade encryption',
                      style: TextStyle(color: NTColors.onSurfaceVariant.withOpacity(0.5), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePress() {
    if (!_otpSent) {
      ref.read(authViewModelProvider.notifier).sendOTP(_phoneCtrl.text.trim());
    } else {
      ref.read(authViewModelProvider.notifier).verifyOTP(_phoneCtrl.text.trim(), _otpCtrl.text.trim());
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(text,
          style: const TextStyle(
              color: NTColors.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    String? prefix,
    TextInputType? keyboardType,
    int? maxLength,
    TextAlign textAlign = TextAlign.start,
    TextStyle? style,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NTRadius.md),
        border: Border.all(color: NTColors.outlineVariant),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        textAlign: textAlign,
        style: style ?? const TextStyle(color: NTColors.primary, fontSize: 18, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          counterText: '',
          hintStyle: TextStyle(color: NTColors.onSurfaceVariant.withOpacity(0.3)),
          prefixText: prefix,
          prefixStyle: const TextStyle(color: NTColors.primary, fontSize: 18, fontWeight: FontWeight.bold),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(NTRadius.md),
            borderSide: const BorderSide(color: NTColors.primary, width: 2),
          ),
        ),
      ),
    );
  }
}
