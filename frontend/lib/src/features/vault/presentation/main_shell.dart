import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/nt_theme.dart';
import 'package:trust_nepal/src/core/network/socket_service.dart';
import '../../auth/presentation/auth_viewmodel.dart';
import 'vault_viewmodel.dart';
import 'notifications_screen.dart';

import '../../../core/services/biometric_service.dart';

class MainShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> with WidgetsBindingObserver {
  bool _listenersAttached = false;
  bool _isUnlocked = false;
  final _biometric = BiometricService();
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometrics();
    });
  }

  Future<void> _checkBiometrics() async {
    final available = await _biometric.isBiometricAvailable();
    if (!available) {
      setState(() => _isUnlocked = true);
      _setupApp();
      return;
    }

    final authenticated = await _biometric.authenticate();
    if (authenticated) {
      setState(() => _isUnlocked = true);
      _setupApp();
    } else {
      // Re-prompt or stay locked
      _checkBiometrics();
    }
  }

  void _setupApp() {
    _setupSocket();
    _startPolling();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Immediately refresh when switching back to this tab/app
      ref.read(vaultViewModelProvider.notifier).fetchVaults();
      ref.invalidate(notificationsProvider);
      
      // Ensure socket is connected
      final socket = ref.read(socketServiceProvider);
      socket.connect();
    }
  }

  void _startPolling() {
    // Poll every 10 seconds as a guaranteed fallback
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      ref.read(vaultViewModelProvider.notifier).fetchVaults();
      ref.invalidate(notificationsProvider);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _setupSocket() {
    final socket = ref.read(socketServiceProvider);
    socket.connect();

    final user = ref.read(authViewModelProvider).user;
    if (user != null) {
      socket.joinUser(user['_id'].toString());
    }

    _attachListeners(socket);
  }

  void _attachListeners(SocketService socket) {
    if (_listenersAttached) return;
    _listenersAttached = true;

    // 🔔 New notification → refresh badge + list + vault list
    socket.onNotification((_) {
      if (!mounted) return;
      ref.invalidate(notificationsProvider);
      ref.read(vaultViewModelProvider.notifier).fetchVaults();
    });

    // 🔄 Vault state changed → refresh vault list (covers Home & My Vaults)
    socket.onVaultStateChanged((_) {
      if (!mounted) return;
      ref.read(vaultViewModelProvider.notifier).fetchVaults();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Re-join user room if user logs in after shell mounts
    ref.listen<AuthState>(authViewModelProvider, (prev, next) {
      if (prev?.user == null && next.user != null) {
        final socket = ref.read(socketServiceProvider);
        socket.connect();
        socket.joinUser(next.user!['_id'].toString());
        _attachListeners(socket);
      }
    });

    if (!_isUnlocked) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('App Locked', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Please authenticate to continue'),
            ],
          ),
        ),
      );
    }

    final unreadCount = ref.watch(unreadNotificationsProvider);

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: Container(
        height: 110,
        padding: const EdgeInsets.only(top: 12, bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(index: 0, label: 'HOME', icon: Icons.home_outlined, activeIcon: Icons.home_rounded),
            _buildNavItem(index: 1, label: 'MY VAULTS', icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded),
            _buildCenterNavItem(context),
            _buildNavItem(index: 2, label: 'ACTIVITY', icon: Icons.history_rounded, activeIcon: Icons.history_rounded, badgeCount: unreadCount),
            _buildNavItem(index: 3, label: 'PROFILE', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    int badgeCount = 0,
  }) {
    final bool isActive = widget.navigationShell.currentIndex == index;
    return GestureDetector(
      onTap: () => widget.navigationShell.goBranch(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? NTColors.secondary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? NTColors.secondary : NTColors.onSurfaceVariant.withOpacity(0.5),
                  size: 24,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: NTColors.error, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        badgeCount > 9 ? '9+' : badgeCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? NTColors.secondary : NTColors.onSurfaceVariant.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterNavItem(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/scanner'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: NTColors.secondary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Color(0x33006C49), blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 6),
          const Text(
            'SCAN',
            style: TextStyle(color: NTColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}
