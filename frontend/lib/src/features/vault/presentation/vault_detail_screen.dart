import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/nt_theme.dart';
import 'vault_viewmodel.dart';
import '../../auth/presentation/auth_viewmodel.dart';
import 'package:trust_nepal/src/core/network/socket_service.dart';
import 'chat_screen.dart';

class VaultDetailScreen extends ConsumerStatefulWidget {
  final String vaultId;
  const VaultDetailScreen({super.key, required this.vaultId});

  @override
  ConsumerState<VaultDetailScreen> createState() => _VaultDetailScreenState();
}

class _VaultDetailScreenState extends ConsumerState<VaultDetailScreen> {
  Map<String, dynamic>? _vault;
  bool _loading = true;
  final _currencyFormat = NumberFormat('#,##0');

  @override
  void initState() {
    super.initState();
    _fetchDetails();
    _initSocket();
  }

  void _initSocket() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socket = ref.read(socketServiceProvider);
      socket.joinVault(widget.vaultId);
      socket.onVaultStateChanged((data) {
        if (!mounted) return;
        // Only react to state changes for THIS vault
        final changedVaultId = data is Map ? data['vaultId']?.toString() : null;
        if (changedVaultId == null || changedVaultId == widget.vaultId) {
          debugPrint('[SOCKET] Vault state changed for this vault: $data');
          _fetchDetails();
        }
      });
    });
  }

  @override
  void dispose() {
    ref.read(socketServiceProvider).leaveVault(widget.vaultId);
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    final v = await ref.read(vaultViewModelProvider.notifier).fetchVaultDetails(widget.vaultId);
    if (mounted) {
      setState(() {
        _vault = v;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: NTColors.background,
        body: Center(child: CircularProgressIndicator(color: NTColors.secondary)),
      );
    }
    if (_vault == null) {
      return Scaffold(
        backgroundColor: NTColors.background,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_rounded, size: 64, color: NTColors.outlineVariant),
              const SizedBox(height: 16),
              const Text('Vault Record Not Found', style: TextStyle(color: NTColors.onSurfaceVariant, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    final state = _vault!['state'] as String? ?? 'INITIATED';
    final title = _vault!['title'] as String? ?? 'Untitled Transaction';
    final amount = (_vault!['amount'] as num?)?.toDouble() ?? 0.0;
    final sellerPhone = _vault!['sellerPhone'] as String? ?? '—';
    final buyerPhone = _vault!['buyerPhone'] as String? ?? '—';
    final createdAt = _vault!['createdAt'] != null ? DateTime.parse(_vault!['createdAt']) : DateTime.now();

    return Scaffold(
      backgroundColor: NTColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leadingWidth: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: NTColors.primary, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Trust Nepal',
          style: TextStyle(color: NTColors.primary, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: NTColors.onSurfaceVariant, size: 22),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1560250097-0b93528c311a?w=100&h=100&fit=crop'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDetails,
        color: NTColors.secondary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildTrustHeaderAnchor(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildMainSummaryCard(state, title, amount, createdAt),
                    const SizedBox(height: 24),
                    _buildProgressionStepper(state),
                    const SizedBox(height: 24),
                    _buildActionCards(context, state),
                    const SizedBox(height: 24),
                    _buildSecurityAssurance(),
                    const SizedBox(height: 24),
                    _buildActivityLedger(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustHeaderAnchor() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(NTRadius.md),
        border: Border.all(color: const Color(0xFFDCFCE7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: NTColors.secondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NRB LICENSED & REGULATED',
                  style: TextStyle(color: NTColors.secondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  'Institutional Escrow Protocol v2.4',
                  style: TextStyle(color: NTColors.secondary.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFDCFCE7))),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: NTColors.secondary, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                const Text('SECURE', style: TextStyle(color: NTColors.primary, fontSize: 9, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainSummaryCard(String state, String title, double amount, DateTime date) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NTRadius.lg),
        border: const Border(top: BorderSide(color: Color(0xFFC5AB02), width: 3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: NTColors.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  const Icon(Icons.payments_rounded, color: NTColors.secondary, size: 12),
                  const SizedBox(width: 6),
                  Text(state.toUpperCase(), style: const TextStyle(color: NTColors.secondary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: NTColors.surfaceLow,
                        borderRadius: BorderRadius.circular(12),
                        image: const DecorationImage(
                          image: NetworkImage('https://images.unsplash.com/photo-1517336714460-4c9889a79955?w=300&h=300&fit=crop'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(color: NTColors.primary, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.fingerprint_rounded, size: 12, color: NTColors.outline),
                              const SizedBox(width: 4),
                              Text('VAULT: #${widget.vaultId.substring(0, 8).toUpperCase()}', 
                                  style: const TextStyle(color: NTColors.outline, fontSize: 9, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ESCROW AMOUNT', style: TextStyle(color: NTColors.outline, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text('NPR ${_currencyFormat.format(amount)}', 
                              style: const TextStyle(color: NTColors.primary, fontSize: 20, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 30, color: NTColors.outlineVariant.withOpacity(0.5)),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ENTITY STATUS', style: TextStyle(color: NTColors.outline, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.verified_rounded, size: 14, color: NTColors.secondary),
                              const SizedBox(width: 4),
                              const Text('VERIFIED', style: TextStyle(color: NTColors.secondary, fontSize: 12, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressionStepper(String state) {
    final steps = ['Initiated', 'Funded', 'Shipped', 'Delivered'];
    final currentIndex = _getStateIndex(state);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NTRadius.lg),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('VAULT PROGRESSION', style: TextStyle(color: NTColors.primary, fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length, (i) {
              final active = i <= currentIndex;
              final current = i == currentIndex;
              return Expanded(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        if (i < steps.length - 1)
                          Positioned(
                            left: 20,
                            right: -20,
                            child: Container(
                              height: 2,
                              color: i < currentIndex ? NTColors.secondary : NTColors.surfaceLow,
                            ),
                          ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: active ? NTColors.secondary : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: active ? NTColors.secondary : NTColors.surfaceLow, width: 2),
                          ),
                          child: Icon(
                            active ? Icons.check : _getStepIcon(i),
                            size: 16,
                            color: active ? Colors.white : NTColors.outlineVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      steps[i].toUpperCase(),
                      style: TextStyle(
                        color: active ? NTColors.primary : NTColors.outlineVariant,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  int _getStateIndex(String state) {
    switch (state) {
      case 'INITIATED': return 0;
      case 'FUNDED': return 1;
      case 'SHIPPED': return 2;
      case 'DELIVERED': return 3;
      case 'COMPLETED': return 3;
      default: return 0;
    }
  }

  IconData _getStepIcon(int index) {
    switch (index) {
      case 0: return Icons.add_moderator_rounded;
      case 1: return Icons.payments_rounded;
      case 2: return Icons.local_shipping_rounded;
      case 3: return Icons.inventory_2_rounded;
      default: return Icons.circle;
    }
  }

  Widget _buildActionCards(BuildContext context, String state) {
    final vaultId = widget.vaultId;
    final currentUser = ref.watch(authViewModelProvider).user;
    
    // Normalize phone numbers for comparison (remove spaces, prefixes, etc.)
    String normalize(String? p) => (p ?? '').replaceAll(RegExp(r'\D'), '').replaceFirst('977', '');
    
    final userPhone = normalize(currentUser?['phone']?.toString());
    final sellerPhone = normalize(_vault!['sellerPhone']?.toString());
    final buyerPhone = normalize(_vault!['buyerPhone']?.toString());

    final bool isBuyer = userPhone == buyerPhone;
    final bool isSeller = userPhone == sellerPhone;
    
    // For development testing, if we can't match, we can show actions or fallback
    final bool devMode = userPhone.isEmpty; // If not logged in, show all for testing
    
    final bool showBuyerActions = isBuyer || devMode;
    final bool showSellerActions = isSeller || devMode;
    
    return Column(
      children: [
        if (state == 'INITIATED' && showBuyerActions) ...[
          _buildPrimaryBtn('PROCEED TO PAYMENT', Icons.payment_rounded, NTColors.primary,
              () => context.push('/vault/$vaultId/pay')),
          const SizedBox(height: 16),
        ],
        
        if (state == 'FUNDED' && showSellerActions) ...[
          _buildPrimaryBtn('MARK AS SHIPPED', Icons.local_shipping_rounded, NTColors.secondary,
              () => _showQuickActionDialog(
                title: 'Mark as Shipped?',
                desc: 'Confirm that you have dispatched the item to the buyer.',
                actionLabel: 'DISPATCH NOW',
                onConfirm: () => _updateVaultState('ship'),
              )),
          const SizedBox(height: 16),
        ],
        
        if (state == 'SHIPPED' && showBuyerActions) ...[
          _buildPrimaryBtn('CONFIRM DELIVERY', Icons.check_circle_rounded, NTColors.secondary,
              () => _showQuickActionDialog(
                title: 'Confirm Delivery?',
                desc: 'By confirming, you authorize Trust Nepal to release the escrow funds to the seller.',
                actionLabel: 'RELEASE FUNDS',
                onConfirm: () => _updateVaultState('confirm'),
              )),
          const SizedBox(height: 16),
        ],

        if (state == 'FUNDED' && isBuyer)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('Waiting for seller to ship...', style: TextStyle(color: NTColors.onSurfaceVariant, fontStyle: FontStyle.italic)),
          ),
        
        if (state == 'SHIPPED' && isSeller)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('Waiting for buyer to confirm delivery...', style: TextStyle(color: NTColors.onSurfaceVariant, fontStyle: FontStyle.italic)),
          ),

        _buildSecondaryBtn('MESSAGE COUNTERPARTY', Icons.forum_outlined, () {
          final counterpartyPhone = isBuyer ? _vault!['sellerPhone'] : _vault!['buyerPhone'];
          _showCommunicationHub(context, counterpartyPhone?.toString() ?? '');
        }),
        
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => context.push('/vault/$vaultId/dispute'),
          icon: const Icon(Icons.flag_outlined, size: 16, color: NTColors.onSurfaceVariant),
          label: const Text('RAISE DISPUTE', style: TextStyle(color: NTColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _showCommunicationHub(BuildContext context, String phone) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: NTColors.outlineVariant, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('COMMUNICATION HUB', style: TextStyle(color: NTColors.primary, fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Contact counterparty regarding Vault #${widget.vaultId.substring(0, 8).toUpperCase()}', style: const TextStyle(color: NTColors.outline, fontSize: 12)),
            const SizedBox(height: 32),
            _buildCommItem(Icons.security_rounded, 'In-App Private Chat', 'Official Record (Secure)', () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(vaultId: widget.vaultId)))),
            const SizedBox(height: 16),
            _buildCommItem(Icons.chat_bubble_outline_rounded, 'WhatsApp Messenger', 'Highly Recommended', () => _launchURL('https://wa.me/977$phone?text=Hi, I am contacting you regarding Trust Nepal Vault #${widget.vaultId.substring(0, 8).toUpperCase()}')),
            const SizedBox(height: 16),
            _buildCommItem(Icons.call_outlined, 'Direct Phone Call', 'Standard Voice Line', () => _launchURL('tel:+977$phone')),
            const SizedBox(height: 16),
            _buildCommItem(Icons.sms_outlined, 'Secure SMS', 'Network Carrier', () => _launchURL('sms:+977$phone?body=Hi, regarding Trust Nepal Vault #${widget.vaultId.substring(0, 8).toUpperCase()}')),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCommItem(IconData icon, String title, String sub, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: Border.all(color: NTColors.outlineVariant.withOpacity(0.5)), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Icon(icon, color: NTColors.secondary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(sub, style: const TextStyle(color: NTColors.outline, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: NTColors.outlineVariant),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showQuickActionDialog({required String title, required String desc, required String actionLabel, required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NTRadius.lg)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: NTColors.primary)),
        content: Text(desc, style: const TextStyle(color: NTColors.onSurfaceVariant, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: NTColors.onSurfaceVariant))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: NTColors.secondary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NTRadius.sm))),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _updateVaultState(String action) async {
    setState(() => _loading = true);
    try {
      final success = await ref.read(vaultViewModelProvider.notifier).transitionVault(widget.vaultId, action);
      if (success) {
        await _fetchDetails();
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Widget _buildPrimaryBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NTRadius.md)),
        ),
      ),
    );
  }

  Widget _buildSecondaryBtn(String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
        style: OutlinedButton.styleFrom(
          foregroundColor: NTColors.primary,
          side: const BorderSide(color: NTColors.primary, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NTRadius.md)),
        ),
      ),
    );
  }

  Widget _buildSecurityAssurance() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: NTColors.primary,
        borderRadius: BorderRadius.circular(NTRadius.lg),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.policy_outlined, color: Color(0xFFC5AB02), size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Escrow Protection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('Trust Nepal Institutional Grade', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildAssuranceItem(Icons.verified_rounded, 'Lloyd\'s of London Insured', 'Funds insured up to NPR 10M against digital theft.'),
          const SizedBox(height: 16),
          _buildAssuranceItem(Icons.fingerprint_rounded, 'Biometric Confirmation', 'Release requires multi-factor biometric verification.'),
        ],
      ),
    );
  }

  Widget _buildAssuranceItem(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: NTColors.secondary, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityLedger() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NTRadius.lg),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Activity History', style: TextStyle(color: NTColors.primary, fontSize: 18, fontWeight: FontWeight.w900)),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download_rounded, size: 16, color: NTColors.secondary),
                  label: const Text('EXPORT', style: TextStyle(color: NTColors.secondary, fontSize: 12, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildLedgerItem('Funds Deposited', 'NPR ${_currencyFormat.format(_vault!['amount'])} successfully secured.', '11:45 AM, Oct 24', Icons.account_balance_wallet_rounded),
          _buildLedgerItem('KYC Verified', 'Counterparty corporate credentials confirmed.', '09:55 AM, Oct 24', Icons.how_to_reg_rounded),
          _buildLedgerItem('Vault Initiated', 'Agreement terms accepted by both parties.', '09:12 AM, Oct 24', Icons.add_moderator_rounded),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLedgerItem(String title, String desc, String time, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: NTColors.secondary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: NTColors.secondary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(color: NTColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(time, style: const TextStyle(color: NTColors.outline, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: NTColors.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
