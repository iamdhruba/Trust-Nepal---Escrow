import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/nt_theme.dart';
import 'kyc_viewmodel.dart';
import 'kyc_upload_service.dart';

class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});
  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  int _step = 0;
  String? _selectedIdType;
  final _nameCtrl = TextEditingController();
  final _idNumCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();

  // Upload state
  XFile? _idFront;
  XFile? _idBack;
  XFile? _selfie;
  bool _uploading = false;

  final _idTypes = ['CITIZENSHIP', 'PASSPORT', 'DRIVING LICENSE'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idNumCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(kycViewModelProvider, (prev, next) {
      if (next.isSubmitted) context.go('/home');
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: NTColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: NTColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'IDENTITY PROTOCOL',
          style: TextStyle(color: NTColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: NTColors.primary, size: 18),
                onPressed: () => setState(() => _step--))
            : IconButton(
                icon: const Icon(Icons.close, color: NTColors.primary),
                onPressed: () => context.pop(),
              ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: NTSpacing.lg, vertical: 8),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(NTRadius.full),
                  child: LinearProgressIndicator(
                    value: (_step + 1) / 3,
                    backgroundColor: NTColors.outlineVariant,
                    valueColor: const AlwaysStoppedAnimation<Color>(NTColors.secondary),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('STEP ${_step + 1} OF 3',
                        style: const TextStyle(
                            color: NTColors.onSurfaceVariant,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                    Text(['PERSONAL DATA', 'SECURE UPLOAD', 'BIOMETRIC VERIFY'][_step],
                        style: const TextStyle(
                            color: NTColors.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: [_buildStep0(), _buildStep1(), _buildStep2()][_step],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 0: Personal Information ─────────────────────────────────────────
  Widget _buildStep0() {
    return SingleChildScrollView(
      key: const ValueKey('step0'),
      padding: const EdgeInsets.all(NTSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NTColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(NTRadius.md),
              border: Border.all(color: NTColors.primary.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: NTColors.primary, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('REGULATORY COMPLIANCE',
                          style: TextStyle(
                              color: NTColors.primary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text('Official verification is mandatory for high-value escrow participation.',
                          style: TextStyle(color: NTColors.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _buildLabel('LEGAL FULL NAME (AS PER DOCUMENT)'),
          _buildField(controller: _nameCtrl, hint: 'e.g., Ram Bahadur Shrestha'),
          const SizedBox(height: 24),
          _buildLabel('DATE OF BIRTH'),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: DateTime(1995),
                firstDate: DateTime(1940),
                lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                builder: (ctx, child) => Theme(
                  data: ThemeData.light().copyWith(
                    colorScheme: const ColorScheme.light(primary: NTColors.primary, onPrimary: Colors.white, surface: Colors.white, onSurface: NTColors.primary),
                  ),
                  child: child!,
                ),
              );
              if (d != null) {
                _dobCtrl.text =
                    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                setState(() {});
              }
            },
            child: AbsorbPointer(child: _buildField(controller: _dobCtrl, hint: 'YYYY-MM-DD', suffixIcon: Icons.calendar_today_rounded)),
          ),
          const SizedBox(height: 24),
          _buildLabel('IDENTIFICATION PROTOCOL'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(NTRadius.md),
              border: Border.all(color: NTColors.outlineVariant),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedIdType,
                isExpanded: true,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: NTColors.primary),
                hint: Text('Select ID type',
                    style: TextStyle(color: NTColors.onSurfaceVariant.withOpacity(0.35), fontSize: 15)),
                items: _idTypes
                    .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t, style: const TextStyle(color: NTColors.primary, fontSize: 15, fontWeight: FontWeight.w500))))
                    .toList(),
                onChanged: (v) => setState(() => _selectedIdType = v),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildLabel('DOCUMENT SERIAL NUMBER'),
          _buildField(controller: _idNumCtrl, hint: 'e.g., 1234-56789'),
          const SizedBox(height: 60),
          _buildNextBtn(
            text: 'CONTINUE TO UPLOADS',
            onPressed: _nameCtrl.text.isNotEmpty && _idNumCtrl.text.isNotEmpty && _selectedIdType != null
                ? () => setState(() => _step = 1)
                : null,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Step 1: Document Uploads ──────────────────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.all(NTSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SECURE ASSET CAPTURE',
              style: TextStyle(color: NTColors.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 12),
          Text(
            'Ensure your document is original, unexpired, and positioned within the frame.',
            style: TextStyle(color: NTColors.onSurfaceVariant.withOpacity(0.8), fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 40),
          _buildUploadBox('FRONT SIDE OF YOUR ${_selectedIdType ?? "ID"}', Icons.badge_outlined, _idFront,
              () => _pickImage('front')),
          const SizedBox(height: 16),
          _buildUploadBox('BACK SIDE OF YOUR ${_selectedIdType ?? "ID"}', Icons.credit_card_outlined, _idBack,
              () => _pickImage('back')),
          const SizedBox(height: 60),
          _buildNextBtn(
            text: 'CONTINUE TO VERIFICATION',
            onPressed: _idFront != null && _idBack != null ? () => setState(() => _step = 2) : null,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Step 2: Selfie ────────────────────────────────────────────────────────
  Widget _buildStep2() {
    final kycState = ref.watch(kycViewModelProvider);
    final isLoading = kycState.isLoading || _uploading;

    return SingleChildScrollView(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.all(NTSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BIOMETRIC CONFIRMATION',
              style: TextStyle(color: NTColors.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 12),
          Text(
            'Final audit: Take a clear selfie while holding your ID document to finalize clearance.',
            style: TextStyle(color: NTColors.onSurfaceVariant.withOpacity(0.8), fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 40),
          _buildUploadBox('SELFIE WITH AUTHORIZED DOCUMENT', Icons.face_retouching_natural_rounded, _selfie,
              () => _pickImage('selfie'),
              height: 280),
          const SizedBox(height: 60),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: (_selfie != null && !isLoading) ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: NTColors.secondary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: NTColors.outlineVariant,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NTRadius.md)),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('SUBMIT FOR CLEARANCE',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Future<void> _pickImage(String field) async {
    final source = await _showSourceDialog();
    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2048,
    );
    if (picked == null) return;

    setState(() {
      if (field == 'front') _idFront = picked;
      if (field == 'back') _idBack = picked;
      if (field == 'selfie') _selfie = picked;
    });
  }

  Future<ImageSource?> _showSourceDialog() => showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: NTColors.outlineVariant, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: NTColors.primary),
              title: const Text('Direct Camera Capture', style: TextStyle(color: NTColors.primary, fontWeight: FontWeight.bold, fontSize: 15)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: NTColors.primary),
              title: const Text('Browse Secure Storage', style: TextStyle(color: NTColors.primary, fontWeight: FontWeight.bold, fontSize: 15)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ]),
        ),
      );

  Future<void> _submit() async {
    setState(() => _uploading = true);
    try {
      final uploadSvc = ref.read(kycUploadServiceProvider);

      final results = await Future.wait([
        uploadSvc.uploadFile(_idFront!, 'idFront'),
        uploadSvc.uploadFile(_idBack!, 'idBack'),
        uploadSvc.uploadFile(_selfie!, 'selfie'),
      ]);

      final frontUrl = results[0];
      final backUrl = results[1];
      final selfieUrl = results[2];

      if (frontUrl == null || backUrl == null || selfieUrl == null) {
        throw Exception('Institutional document encryption or upload failed');
      }

      await ref.read(kycViewModelProvider.notifier).submitKyc(
            fullName: _nameCtrl.text.trim(),
            dob: _dobCtrl.text.trim(),
            idType: _selectedIdType!,
            idNumber: _idNumCtrl.text.trim(),
            frontUrl: frontUrl,
            backUrl: backUrl,
            selfieUrl: selfieUrl,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification protocol failure: $e'), backgroundColor: NTColors.error, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Widget _buildUploadBox(String label, IconData icon, XFile? file, VoidCallback onTap,
      {double height = 160}) {
    final bool isUploaded = file != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isUploaded ? Colors.white : NTColors.surfaceLow,
          borderRadius: BorderRadius.circular(NTRadius.md),
          border: Border.all(
            color: isUploaded ? NTColors.secondary : NTColors.outlineVariant,
            width: isUploaded ? 2 : 1,
          ),
        ),
        child: isUploaded
            ? ClipRRect(
                borderRadius: BorderRadius.circular(NTRadius.md - 2),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    kIsWeb ? Image.network(file.path, fit: BoxFit.cover) : Image.file(File(file.path), fit: BoxFit.cover),
                    Container(color: Colors.black.withOpacity(0.05)),
                    PositionRectangleOverlay(color: NTColors.secondary),
                    const Center(
                      child: CircleAvatar(
                        backgroundColor: NTColors.secondary,
                        child: Icon(Icons.check, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: NTColors.outlineVariant.withOpacity(0.5))),
                    child: Icon(icon, color: NTColors.primary, size: 28),
                  ),
                  const SizedBox(height: 16),
                  Text(label, style: const TextStyle(color: NTColors.primary, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  Text('Tap to capture or upload', style: TextStyle(color: NTColors.onSurfaceVariant.withOpacity(0.6), fontSize: 11)),
                ],
              ),
      ),
    );
  }

  Widget _buildNextBtn({required String text, VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: NTColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: NTColors.outlineVariant,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NTRadius.md)),
          elevation: 0,
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(text,
            style: const TextStyle(
                color: NTColors.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
      );

  Widget _buildField({required TextEditingController controller, required String hint, IconData? suffixIcon}) {
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
          hintStyle: TextStyle(color: NTColors.onSurfaceVariant.withOpacity(0.35)),
          contentPadding: const EdgeInsets.all(20),
          suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: NTColors.primary, size: 18) : null,
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

class PositionRectangleOverlay extends StatelessWidget {
  final Color color;
  const PositionRectangleOverlay({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.5), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
