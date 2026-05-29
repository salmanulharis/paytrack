import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/core/router/quick_action_fab_routes.dart';

void main() {
  group('normalizeRoutePath', () {
    test('empty becomes root', () {
      expect(normalizeRoutePath(''), '/');
    });

    test('strips query and trailing slash', () {
      expect(normalizeRoutePath('/settings?tab=1'), '/settings');
      expect(normalizeRoutePath('/expenses/'), '/expenses');
    });
  });

  group('quickActionFabVisibleOnRoute', () {
    test('shows only on main tabs', () {
      expect(quickActionFabVisibleOnRoute('/'), isTrue);
      expect(quickActionFabVisibleOnRoute('/expenses'), isTrue);
      expect(quickActionFabVisibleOnRoute('/analytics'), isTrue);
    });

    test('hides workflow and settings routes', () {
      const hidden = [
        '/settings',
        '/scanner',
        '/manual-expense',
        '/edit-expense/abc',
        '/metadata',
        '/expense/abc',
        '/search',
        '/manage-tags',
        '/backup',
        '/onboarding',
        '/pin-setup',
        '/lock',
      ];
      for (final route in hidden) {
        expect(quickActionFabVisibleOnRoute(route), isFalse, reason: route);
      }
    });

    test('hides during payment confirmation', () {
      expect(
        quickActionFabVisibleOnRoute('/', paymentInProgress: true),
        isFalse,
      );
    });
  });

  group('shouldShowQuickActionFab', () {
    test('respects user toggle', () {
      expect(
        shouldShowQuickActionFab(
          location: '/',
          floatingEnabled: false,
        ),
        isFalse,
      );
      expect(
        shouldShowQuickActionFab(
          location: '/',
          floatingEnabled: true,
        ),
        isTrue,
      );
    });
  });
}
