import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'paytrack_bottom_nav.dart';

/// Bottom navigation for main tabs (no primary actions — those live on Home).
class MainTabBottomChrome extends ConsumerWidget {
  const MainTabBottomChrome({super.key});

  static int indexForLocation(String location) {
    if (location.startsWith('/expenses')) return 1;
    if (location.startsWith('/analytics')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = indexForLocation(location);

    return PayTrackBottomChrome(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/');
          case 1:
            context.go('/expenses');
          case 2:
            context.go('/analytics');
        }
      },
    );
  }
}
