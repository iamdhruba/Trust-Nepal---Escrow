import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/nt_theme.dart';
import 'vault_viewmodel.dart';

class VaultsListScreen extends ConsumerStatefulWidget {
  const VaultsListScreen({super.key});
  @override
  ConsumerState<VaultsListScreen> createState() => _VaultsListScreenState();
}

class _VaultsListScreenState extends ConsumerState<VaultsListScreen> {
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
    final vaults = state.vaults;

    final filtered = _tabIndex == 0
        ? vaults
        : _tabIndex == 1
            ? vaults.where((v) => v['role'] == 'buyer').toList()
            : vaults.where((v) => v['role'] == 'seller').toList();

    return Scaffold(
      backgroundColor: NTColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Escrow Vaults', style: TextStyle(color: NTColors.primary, fontWeight: FontWeight.w900, fontSize: 18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip('GLOBAL', 0),
                const SizedBox(width: 16),
                _buildFilterChip('BUYING', 1),
                const SizedBox(width: 16),
                _buildFilterChip('SELLING', 2),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(vaultViewModelProvider.notifier).fetchVaults(),
        color: NTColors.secondary,
        child: filtered.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _buildVaultCard(filtered[i]),
              ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final active = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? NTColors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : NTColors.onSurfaceVariant.withOpacity(0.5),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_clear_outlined, size: 64, color: NTColors.outlineVariant.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No active escrow protocols found.', style: TextStyle(color: NTColors.onSurfaceVariant, fontSize: 13)),
        ],
      ),
    );
  }
}
