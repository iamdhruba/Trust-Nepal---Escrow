import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/nt_theme.dart';
import 'package:trust_nepal/src/core/network/socket_service.dart';
import '../../auth/presentation/auth_viewmodel.dart';

final notificationsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.get('/notifications');
    return res.data;
  } catch (_) {
    return {'data': [], 'meta': {'unread': 0}};
  }
});

final unreadNotificationsProvider = Provider<int>((ref) {
  final asyncValue = ref.watch(notificationsProvider);
  return asyncValue.maybeWhen(
    data: (data) => (data['meta']?['unread'] as num?)?.toInt() ?? 0,
    orElse: () => 0,
  );
});

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});
  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Listeners managed globally in MainShell
  }

  @override
  Widget build(BuildContext context) {
    final notifsAsync = ref.watch(notificationsProvider);
    

    return Scaffold(
      backgroundColor: NTColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('ALERT PROTOCOL', style: TextStyle(color: NTColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: NTColors.primary, size: 20),
            onPressed: () => ref.invalidate(notificationsProvider),
          ),
        ],
      ),
      body: notifsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: NTColors.secondary)),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (result) {
          final items = List<Map<String, dynamic>>.from(result['data'] ?? []);
          if (items.isEmpty) {
            return const Center(child: Text('NO ARCHIVED ALERTS'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notif = items[index];
                final isRead = notif['read'] == true;
                final type = notif['type'] as String? ?? 'INFO';
                
                return InkWell(
                  onTap: () async {
                    final vaultId = notif['data']?['vaultId'];
                    if (vaultId != null) context.push('/vault/$vaultId');
                    if (!isRead) {
                      try {
                        await ref.read(apiClientProvider).patch('/notifications/${notif['_id']}/read');
                        ref.invalidate(notificationsProvider);
                      } catch (_) {}
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isRead ? Colors.white : Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isRead ? Colors.grey.shade300 : Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active, color: Colors.blue),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(type, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  if (!isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                                ],
                              ),
                              Text(notif['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(notif['body'] ?? '', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'INITIATED': return Icons.add_moderator_rounded;
      case 'FUNDED': return Icons.account_balance_wallet_rounded;
      case 'SHIPPED': return Icons.local_shipping_rounded;
      case 'DELIVERED': return Icons.inventory_2_rounded;
      case 'DISPUTED': return Icons.gavel_rounded;
      case 'COMPLETED': return Icons.verified_rounded;
      default: return Icons.notifications_active_rounded;
    }
  }

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    try {
      final diff = DateTime.now().difference(DateTime.parse(iso));
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}
