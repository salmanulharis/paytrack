import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/auth/presentation/lock_screen.dart';
import '../../features/auth/presentation/pin_setup_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/expenses/presentation/expense_detail_screen.dart';
import '../../features/expenses/presentation/manual_expense_screen.dart';
import '../../features/expenses/presentation/search_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/payment/presentation/expense_metadata_screen.dart';
import '../../features/payment/presentation/payment_confirmation_sheet.dart';
import '../../features/scanner/presentation/scanner_screen.dart';
import '../../features/settings/presentation/backup_screen.dart';
import '../../features/settings/presentation/manage_tags_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../providers/app_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authServiceProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final onboardingDone = auth.isOnboardingComplete;
      final onOnboarding = state.matchedLocation == '/onboarding';
      final onLock = state.matchedLocation == '/lock';

      if (!onboardingDone && !onOnboarding) return '/onboarding';
      if (onboardingDone && onOnboarding) return '/';

      if (onboardingDone && await auth.shouldLock() && !onLock && state.matchedLocation != '/pin-setup') {
        final hasPin = await auth.hasPin();
        if (hasPin || auth.isBiometricEnabled) {
          // Lock handled in shell
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/pin-setup',
        builder: (_, __) => const PinSetupScreen(),
      ),
      GoRoute(
        path: '/lock',
        builder: (_, __) => const LockScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/scanner',
            builder: (_, __) => const ScannerScreen(),
          ),
          GoRoute(
            path: '/metadata',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return ExpenseMetadataScreen(
                upiId: extra['upiId'] as String? ?? '',
                merchantName: extra['merchantName'] as String?,
                prefilledAmount: extra['amount'] as double?,
              );
            },
          ),
          GoRoute(
            path: '/manual-expense',
            builder: (_, __) => const ManualExpenseScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (_, __) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (_, __) => const SearchScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/manage-tags',
            builder: (_, __) => const ManageTagsScreen(),
          ),
          GoRoute(
            path: '/backup',
            builder: (_, __) => const BackupScreen(),
          ),
          GoRoute(
            path: '/expense/:id',
            builder: (context, state) {
              return ExpenseDetailScreen(id: state.pathParameters['id']!);
            },
          ),
        ],
      ),
    ],
  );
});

class _AppShell extends ConsumerStatefulWidget {
  const _AppShell({required this.child});

  final Widget child;

  @override
  ConsumerState<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<_AppShell> with WidgetsBindingObserver {
  bool _locked = false;
  bool _checkedLock = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLockOnStart();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPendingPayment());
  }

  Future<void> _checkLockOnStart() async {
    final session = ref.read(authSessionServiceProvider);
    final required = await session.shouldRequireLock(isColdStart: true);
    setState(() {
      _locked = required;
      _checkedLock = true;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final session = ref.read(authSessionServiceProvider);
    final flow = ref.read(paymentFlowServiceProvider);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (flow.activePendingId != null) {
        session.suspendLockForExternalFlow();
      }
    }

    if (state == AppLifecycleState.resumed) {
      session.suspendLockForExternalFlow();
      _checkPendingPayment();
      session.shouldRequireLock().then((required) {
        if (mounted) {
          setState(() => _locked = required);
        }
      });
    }
  }

  Future<void> _checkPendingPayment() async {
    final flow = ref.read(paymentFlowServiceProvider);
    final pending = await flow.checkPendingOnResume();
    if (pending != null && mounted) {
      ref.read(pendingPaymentProvider.notifier).state = pending;
      await PaymentConfirmationSheet.show(context, pending.id);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_checkedLock) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_locked) {
      return LockScreen(
        onUnlocked: () {
          ref.read(authSessionServiceProvider).recordUnlock();
          setState(() => _locked = false);
        },
      );
    }

    return widget.child;
  }
}
