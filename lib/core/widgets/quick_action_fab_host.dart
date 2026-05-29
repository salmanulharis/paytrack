import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import 'paytrack_quick_action_fab.dart';

/// Wraps a main-tab screen with the global quick-action FAB overlay.
///
/// Only use on Home, Expenses, and Analytics. Do not use on settings, forms,
/// scanner, or payment flows — those screens must not include this host.
class QuickActionFabHost extends ConsumerStatefulWidget {
  const QuickActionFabHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<QuickActionFabHost> createState() => _QuickActionFabHostState();
}

class _QuickActionFabHostState extends ConsumerState<QuickActionFabHost> {
  @override
  void dispose() {
    if (ref.read(quickActionMenuOpenProvider)) {
      ref.read(quickActionMenuOpenProvider.notifier).state = false;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(userPreferencesProvider).showFloatingQuickActions;
    final pending = ref.watch(pendingPaymentProvider);

    if (!enabled || pending != null) {
      return widget.child;
    }

    final menuOpen = ref.watch(quickActionMenuOpenProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (menuOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                ref.read(quickActionMenuOpenProvider.notifier).state = false;
              },
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.38),
              ),
            ),
          ),
        const PayTrackQuickActionFab(),
      ],
    );
  }
}
