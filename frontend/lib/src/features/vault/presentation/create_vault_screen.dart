import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/nt_theme.dart';
import 'vault_viewmodel.dart';

class CreateVaultScreen extends ConsumerStatefulWidget {
  const CreateVaultScreen({super.key});
  @override
  ConsumerState<CreateVaultScreen> createState() => _CreateVaultScreenState();
}

class _CreateVaultScreenState extends ConsumerState<CreateVaultScreen> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _sellerPhoneCtrl = TextEditingController();
  final _customCategoryCtrl = TextEditingController();
  
  String _selectedCategory = 'Smartphones & Electronics';
  bool _isCustomCategory = false;

  @override
  void initState() {
    super.initState();
    _sellerPhoneCtrl.addListener(_onPhoneChanged);
  }

  void _onPhoneChanged() {
    final phone = _sellerPhoneCtrl.text;
    if (phone.length == 10 && RegExp(r'^9[678]\d{8}$').hasMatch(phone)) {
      _performLookup(phone);
    }
  }

  Future<void> _performLookup(String phone) async {
    final data = await ref.read(vaultViewModelProvider.notifier).lookupUser(phone);
    // Even though we don't show the fields, we can use this to show a "Verified Seller" badge or similar
    if (data != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verified Seller: ${data['fullName']}'),
          backgroundColor: NTColors.secondary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _sellerPhoneCtrl.dispose();
    _customCategoryCtrl.dispose();
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            const Text('New Secure Escrow', 
                style: TextStyle(color: NTColors.primary, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            const SizedBox(height: 8),
            const Text('Simple, secure, and institutional-grade protection.', 
                style: TextStyle(color: NTColors.onSurfaceVariant, fontSize: 14)),
            const SizedBox(height: 32),
            
            _buildSectionCard(
              title: 'Deal Specifications',
              icon: Icons.assignment_outlined,
              children: [
                _buildFieldLabel('WHAT ARE YOU BUYING?'),
                _buildInputField(controller: _titleCtrl, hint: 'e.g. iPhone 15 Pro Max'),
                const SizedBox(height: 24),
                
                _buildFieldLabel('CATEGORY'),
                _buildCategorySelector(),
                if (_isCustomCategory) ...[
                  const SizedBox(height: 12),
                  _buildInputField(controller: _customCategoryCtrl, hint: 'Enter custom category'),
                ],
                
                const SizedBox(height: 24),
                _buildFieldLabel('ESCROW AMOUNT (NPR)', isSecondary: true),
                _buildAmountField(),
              ],
            ),
            
            const SizedBox(height: 20),
            
            _buildSectionCard(
              title: 'Seller Identification',
              icon: Icons.person_search_outlined,
              children: [
                _buildFieldLabel('SELLER PHONE NUMBER'),
                _buildInputField(controller: _sellerPhoneCtrl, hint: '98XXXXXXXX', keyboardType: TextInputType.phone),
                const SizedBox(height: 8),
                const Text('The seller will receive a secure link to join this vault.', 
                    style: TextStyle(color: NTColors.onSurfaceVariant, fontSize: 11, fontStyle: FontStyle.italic)),
              ],
            ),
            
            const SizedBox(height: 40),
            _buildSummaryAndSubmit(),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categories = [
      'Smartphones & Electronics',
      'Vehicles & Parts',
      'Real Estate',
      'Freelance Services',
      'Fashion & Luxury',
      'Other / Custom'
    ];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: NTColors.background, borderRadius: BorderRadius.circular(NTRadius.md)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          style: const TextStyle(color: NTColors.primary, fontWeight: FontWeight.bold),
          items: categories.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (val) {
            setState(() {
              _selectedCategory = val!;
              _isCustomCategory = val == 'Other / Custom';
            });
          },
        ),
      ),
    );
  }

  Widget _buildSummaryAndSubmit() {
    final state = ref.watch(vaultViewModelProvider);
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    final fee = amount * 0.005;
    final total = amount + fee + 150;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total Liability', style: TextStyle(color: NTColors.onSurfaceVariant, fontSize: 14)),
            Text('NPR ${NumberFormat('#,##0.00').format(total)}', 
                style: const TextStyle(color: NTColors.secondary, fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        const SizedBox(height: 24),
        _buildPrimaryActionBtn(
          'CREATE SECURE VAULT', 
          _createVault,
          isLoading: state.isLoading,
          icon: Icons.shield_outlined,
        ),
      ],
    );
  }

  Future<void> _createVault() async {
    final amountText = _amountCtrl.text.replaceAll(',', '');
    final amount = double.tryParse(amountText);
    
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }

    final category = _isCustomCategory ? _customCategoryCtrl.text : _selectedCategory;

    final result = await ref.read(vaultViewModelProvider.notifier).createVaultWithResponse({
      'title': _titleCtrl.text,
      'amount': amount,
      'sellerPhone': _sellerPhoneCtrl.text,
      'category': category,
    });
    
    if (result != null && mounted) {
      final vaultId = result['_id'] ?? result['id'];
      context.pushReplacement('/vault/$vaultId');
    }
  }

  Widget _buildSectionCard({required String title, required IconData icon, Color? borderColor, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NTRadius.lg),
        border: borderColor != null ? Border(top: BorderSide(color: borderColor, width: 2)) : Border.all(color: NTColors.outlineVariant.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: NTColors.secondary, size: 20),
              const SizedBox(width: 12),
              Flexible(child: Text(title, style: const TextStyle(color: NTColors.primary, fontWeight: FontWeight.w900, fontSize: 16))),
            ],
          ),
          const SizedBox(height: 32),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool isSecondary = false}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(label, style: TextStyle(color: isSecondary ? NTColors.secondary : NTColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1))),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String hint, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: NTColors.primary, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: NTColors.outlineVariant.withOpacity(0.5), fontWeight: FontWeight.normal),
        filled: true,
        fillColor: NTColors.background,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(NTRadius.md), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(NTRadius.md), borderSide: const BorderSide(color: NTColors.secondary, width: 1.5)),
      ),
    );
  }

  Widget _buildAmountField() {
    return TextField(
      controller: _amountCtrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: NTColors.primary, fontWeight: FontWeight.w900, fontSize: 24),
      decoration: InputDecoration(
        prefixIcon: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('NPR', style: TextStyle(color: NTColors.onSurfaceVariant, fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        hintText: '0.00',
        hintStyle: TextStyle(color: NTColors.outlineVariant.withOpacity(0.5), fontWeight: FontWeight.w900),
        filled: true,
        fillColor: NTColors.background,
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(NTRadius.md), borderSide: const BorderSide(color: Color(0x33006C49), width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(NTRadius.md), borderSide: const BorderSide(color: NTColors.secondary, width: 2)),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildPrimaryActionBtn(String label, VoidCallback onTap, {bool isLoading = false, IconData? icon}) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: NTColors.secondary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NTRadius.md)),
        ),
        child: isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 12)],
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
                ],
              ),
      ),
    );
  }
}
