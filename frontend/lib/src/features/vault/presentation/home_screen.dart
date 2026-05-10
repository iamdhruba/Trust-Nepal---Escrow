import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/nt_theme.dart';
import 'vault_viewmodel.dart';
import '../../auth/presentation/auth_viewmodel.dart';
import 'notifications_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Socket listeners are managed globally in MainShell
  }

  int _tabIndex = 0; // 0=Global, 1=Buying, 2=Selling
  final _currencyFormat = NumberFormat('#,##0');

  Color _stateColor(String s) {
    switch (s) {
      case 'FUNDED': return const Color(0xFF3B82F6);
      case 'SHIPPED': return const Color(0xFFB59410);
      case 'DELIVERED': return const Color(0xFF6366F1);
      case 'COMPLETED': return NTColors.secondary;
      case 'DISPUTED':
      case 'REFUNDED': return NTColors.error;
      default: return NTColors.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vaultViewModelProvider);
    final authState = ref.watch(authViewModelProvider);
    final vaults = state.vaults;
    

    final filtered = _tabIndex == 0
        ? vaults
        : _tabIndex == 1
            ? vaults.where((v) => v['role'] == 'buyer').toList()
            : vaults.where((v) => v['role'] == 'seller').toList();

    return Scaffold(
      backgroundColor: NTColors.background,
      body: Column(
        children: [
          _buildInstitutionalCommandBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(vaultViewModelProvider.notifier).fetchVaults(),
              color: NTColors.secondary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildHeader(context, authState),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPortfolioCard(state),
                          const SizedBox(height: 32),
                          _buildQuickOperations(),
                          const SizedBox(height: 40),
                          _buildVaultHeader(filtered.length),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  if (filtered.isEmpty)
                    _buildEmptyState()
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _buildVaultCard(filtered[i]),
                          childCount: filtered.length,
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildComplianceAudit(),
                          const SizedBox(height: 24),
                          _buildSecurityAdvisory(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/home/create'),
        backgroundColor: NTColors.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NTRadius.md)),
        child: const Icon(Icons.add_moderator_rounded, size: 28),
      ),
    );
  }

  Widget _buildInstitutionalCommandBar() {
    return Container(
      height: 40,
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_user, color: NTColors.secondary, size: 14),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'NRB LICENSED: #NFT-2024-889',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: NTColors.onSurfaceVariant.withOpacity(0.8),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: NTColors.secondary, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              const Text(
                'ENCRYPTED',
                style: TextStyle(
                  color: NTColors.secondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthState authState) {
    final displayName = authState.user?['phone'] ?? 'Trust Nepal User';
    return SliverAppBar(
      floating: false,
      pinned: false,
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 80,
      centerTitle: false,
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: NTColors.outlineVariant.withOpacity(0.5)),
              image: DecorationImage(
                image: const NetworkImage('https://images.unsplash.com/photo-1560250097-0b93528c311a?w=100&h=100&fit=crop'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: NTColors.primary,
                  fontSize: 16,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'INSTITUTIONAL ACCESS',
                style: TextStyle(
                  color: NTColors.onSurfaceVariant.withOpacity(0.6),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Consumer(
          builder: (context, ref, child) {
            final unreadCount = ref.watch(unreadNotificationsProvider);
            return IconButton(
              icon: Badge(
                label: Text(unreadCount.toString()),
                isLabelVisible: unreadCount > 0,
                backgroundColor: NTColors.error,
                child: const Icon(Icons.notifications_none_rounded, color: NTColors.primary, size: 24),
              ),
              onPressed: () => context.push('/notifications'),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildPortfolioCard(VaultStateModel state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NTRadius.lg),
        border: const Border(top: BorderSide(color: Color(0xFFB59410), width: 4)),
        boxShadow: [
          BoxShadow(
            color: NTColors.primary.withOpacity(0.04),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL ESCROW VALUE',
            style: TextStyle(
              color: NTColors.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text('NPR', style: TextStyle(color: NTColors.onSurfaceVariant, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _currencyFormat.format(state.totalLocked),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: NTColors.primary,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const Text('.00', style: TextStyle(color: NTColors.onSurfaceVariant, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, color: NTColors.secondary, size: 16),
              const SizedBox(width: 6),
              const Text(
                '+12.4% vs last month',
                style: TextStyle(color: NTColors.secondary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              SizedBox(
                width: 80,
                height: 20,
                child: CustomPaint(painter: SparklinePainter()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickOperations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUICK OPERATIONS',
          style: TextStyle(
            color: NTColors.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildOpBtn('New Vault', 'Initialize', Icons.add_moderator_rounded, const Color(0xFF0F172A), () => context.push('/home/create')),
            const SizedBox(width: 12),
            _buildOpBtn('Scan QR', 'Verify Code', Icons.qr_code_scanner_rounded, const Color(0xFF059669), () => context.push('/scanner')),
            const SizedBox(width: 12),
            _buildOpBtn('My Vaults', 'All Escrows', Icons.account_balance_wallet_rounded, const Color(0xFFB59410), () => context.push('/vaults')),
          ],
        ),
      ],
    );
  }

  Widget _buildOpBtn(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(NTRadius.md),
          border: Border.all(color: NTColors.outlineVariant.withOpacity(0.5)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(NTRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(color: NTColors.primary, fontSize: 13, fontWeight: FontWeight.w900)),
                Text(subtitle, style: TextStyle(color: NTColors.onSurfaceVariant.withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVaultHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Flexible(
          child: Text(
            'ACTIVE PROTOCOLS',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: NTColors.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterChip('GLOBAL', 0),
            const SizedBox(width: 8),
            _buildFilterChip('BUYING', 1),
            const SizedBox(width: 8),
            _buildFilterChip('SELLING', 2),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final active = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: Text(
        label,
        style: TextStyle(
          color: active ? NTColors.primary : NTColors.onSurfaceVariant.withOpacity(0.4),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildVaultCard(dynamic vault) {
    final state = vault['state'] as String? ?? 'INITIATED';
    final color = _stateColor(state);
    final progress = _stateProgress(state);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NTRadius.lg),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/vault/${vault['_id']}'),
        borderRadius: BorderRadius.circular(NTRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_stateIcon(state), color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vault['title'],
                          style: const TextStyle(color: NTColors.primary, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'ID: #${vault['_id'].toString().substring(0, 8).toUpperCase()}',
                              style: TextStyle(color: NTColors.onSurfaceVariant.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Container(width: 3, height: 3, decoration: BoxDecoration(color: NTColors.outlineVariant, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(
                              vault['role'] == 'buyer' ? 'PURCHASE' : 'SALE',
                              style: TextStyle(color: NTColors.onSurfaceVariant.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'NPR ${_currencyFormat.format(vault['amount'])}',
                        style: const TextStyle(color: NTColors.primary, fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(state, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: NTColors.surfaceLow,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${(progress * 100).toInt()}%', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _stateProgress(String state) {
    switch (state) {
      case 'INITIATED': return 0.25;
      case 'FUNDED': return 0.5;
      case 'SHIPPED': return 0.75;
      case 'DELIVERED':
      case 'COMPLETED': return 1.0;
      default: return 0.1;
    }
  }

  IconData _stateIcon(String state) {
    switch (state) {
      case 'INITIATED': return Icons.add_moderator_rounded;
      case 'FUNDED': return Icons.lock_rounded;
      case 'SHIPPED': return Icons.local_shipping_rounded;
      case 'DELIVERED': return Icons.inventory_2_rounded;
      case 'COMPLETED': return Icons.verified_user_rounded;
      default: return Icons.info_rounded;
    }
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.layers_clear_outlined, size: 64, color: NTColors.outlineVariant.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('No active escrow protocols found.', style: TextStyle(color: NTColors.onSurfaceVariant, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceAudit() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: NTColors.surfaceLow,
        borderRadius: BorderRadius.circular(NTRadius.lg),
        border: Border.all(color: NTColors.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: NTColors.secondary, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Compliance Audit Trail',
                style: TextStyle(color: NTColors.primary, fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildAuditItem('14:22 NST • TODAY', 'System Sync Complete', 'Ledger synchronized with Central Bank gateway.', true),
          _buildAuditItem('10:05 NST • TODAY', 'Biometric Lock Active', 'Authorized withdrawal key verified.', true),
          _buildAuditItem('09:00 NST • YESTERDAY', 'KYC Batch Renewal', '3 Counterparty profiles re-verified.', false),
        ],
      ),
    );
  }

  Widget _buildAuditItem(String time, String title, String desc, bool active) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: active ? NTColors.secondary : NTColors.outlineVariant,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              Container(width: 1, height: 30, color: NTColors.outlineVariant.withOpacity(0.3)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time, style: TextStyle(color: NTColors.onSurfaceVariant.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.w900)),
                Text(title, style: const TextStyle(color: NTColors.primary, fontSize: 13, fontWeight: FontWeight.w900)),
                Text(desc, style: TextStyle(color: NTColors.onSurfaceVariant.withOpacity(0.7), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityAdvisory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: NTColors.primary,
        borderRadius: BorderRadius.circular(NTRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_moon_rounded, color: Color(0xFFB59410), size: 32),
          const SizedBox(height: 16),
          const Text(
            'Security Advisory',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Always ensure the "NRB Verified" badge appears before initiating high-value property escrow releases.',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('STATUS: SHIELD ON', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.w900)),
              Text('LEVEL 4 SEC', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}

class SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NTColors.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.7, size.width * 0.4, size.height * 0.4);
    path.quadraticBezierTo(size.width * 0.6, size.height * 0.1, size.width * 0.8, size.height * 0.3);
    path.lineTo(size.width, size.height * 0.1);

    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
