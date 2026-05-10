import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/kyc/presentation/kyc_screen.dart';
import '../../features/kyc/presentation/kyc_pending_screen.dart';
import '../../features/vault/presentation/home_screen.dart';
import '../../features/vault/presentation/create_vault_screen.dart';
import '../../features/vault/presentation/vault_detail_screen.dart';
import '../../features/vault/presentation/payment_screen.dart';
import '../../features/vault/presentation/ship_screen.dart';

import '../../features/vault/presentation/dispute_screen.dart';
import '../../features/vault/presentation/profile_screen.dart';
import '../../features/vault/presentation/identity_protocol_screen.dart';
import '../../features/vault/presentation/security_protocol_screen.dart';
import '../../features/vault/presentation/vaults_list_screen.dart';
import '../../features/vault/presentation/notifications_screen.dart';
import '../../features/vault/presentation/payment_webview_screen.dart';
import '../../features/vault/presentation/qr_deliver_screen.dart';
import '../../features/vault/presentation/global_scanner_screen.dart';
import '../../features/vault/presentation/main_shell.dart';

const _storage = FlutterSecureStorage();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/kyc', builder: (_, __) => const KycScreen()),
      GoRoute(path: '/kyc/pending', builder: (_, __) => const KycPendingScreen()),
      GoRoute(path: '/scanner', builder: (_, __) => const GlobalScannerScreen()),
      GoRoute(path: '/profile/identity', builder: (_, __) => const IdentityProtocolScreen()),
      GoRoute(path: '/profile/security', builder: (_, __) => const SecurityProtocolScreen()),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/vaults',
                builder: (_, __) => const VaultsListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/activity',
                builder: (_, __) => const NotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: '/home/create',
        builder: (_, __) => const CreateVaultScreen(),
      ),
      GoRoute(
        path: '/vault/:id',
        builder: (ctx, state) => VaultDetailScreen(vaultId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'pay',
            builder: (ctx, state) => PaymentScreen(vaultId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'pay/checkout',
            builder: (ctx, state) => PaymentWebViewScreen(
              checkoutUrl: state.uri.queryParameters['url'] ?? '',
              vaultId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'ship',
            builder: (ctx, state) => ShipScreen(vaultId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'deliver',
            builder: (ctx, state) => QrDeliverScreen(vaultId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'dispute',
            builder: (ctx, state) => DisputeScreen(vaultId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
    ],
    redirect: (context, state) async {
      final isAuth = await _storage.read(key: 'nt.access_token') != null;
      final onAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/splash' ||
          state.matchedLocation == '/onboarding';
      if (!isAuth && !onAuthRoute) return '/splash';
      return null;
    },
  );
});
