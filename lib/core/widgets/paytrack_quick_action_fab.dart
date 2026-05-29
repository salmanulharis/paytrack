import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/floating_action_position.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';

/// Whether the global quick-action menu overlay is open.
final quickActionMenuOpenProvider = StateProvider<bool>((ref) => false);

/// Global expandable FAB: Scan QR + Add expense.
///
/// Mounted only via [QuickActionFabHost] on main tab screens.
class PayTrackQuickActionFab extends ConsumerStatefulWidget {
  const PayTrackQuickActionFab({super.key});

  @override
  ConsumerState<PayTrackQuickActionFab> createState() =>
      _PayTrackQuickActionFabState();
}

class _PayTrackQuickActionFabState extends ConsumerState<PayTrackQuickActionFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expand;

  static const _positionDuration = Duration(milliseconds: 320);
  static const _horizontalInset = 16.0;
  static const _verticalInset = 16.0;
  static const _navClearance = 72.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _expand = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setOpen(bool value) {
    ref.read(quickActionMenuOpenProvider.notifier).state = value;
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    final open = ref.read(quickActionMenuOpenProvider);
    _setOpen(!open);
  }

  void _close() {
    if (ref.read(quickActionMenuOpenProvider)) _setOpen(false);
  }

  void _navigate(String path) {
    HapticFeedback.mediumImpact();
    _close();
    context.push(path);
  }

  @override
  Widget build(BuildContext context) {
    final userPrefs = ref.watch(userPreferencesProvider);
    final menuOpen = ref.watch(quickActionMenuOpenProvider);
    final position = userPrefs.floatingActionPosition;

    ref.listen<bool>(quickActionMenuOpenProvider, (previous, next) {
      if (!mounted) return;
      if (next) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });

    final padding = MediaQuery.paddingOf(context);
    final bottomInset = padding.bottom + _navClearance;

    return Positioned.fill(
      child: Padding(
        padding: EdgeInsets.only(
          left: padding.left + _horizontalInset,
          right: padding.right + _horizontalInset,
          top: padding.top + _verticalInset,
          bottom: bottomInset,
        ),
        child: AnimatedAlign(
          alignment: position.alignment,
          duration: _positionDuration,
          curve: Curves.easeOutCubic,
          child: _FabLauncher(
            position: position,
            menuOpen: menuOpen,
            expandAnimation: _expand,
            onToggle: _toggle,
            onScan: () => _navigate('/scanner'),
            onAddExpense: () => _navigate('/manual-expense'),
          ),
        ),
      ),
    );
  }
}

class _FabLauncher extends StatelessWidget {
  const _FabLauncher({
    required this.position,
    required this.menuOpen,
    required this.expandAnimation,
    required this.onToggle,
    required this.onScan,
    required this.onAddExpense,
  });

  final FloatingActionPosition position;
  final bool menuOpen;
  final Animation<double> expandAnimation;
  final VoidCallback onToggle;
  final VoidCallback onScan;
  final VoidCallback onAddExpense;

  @override
  Widget build(BuildContext context) {
    final cross = position.menuCrossAxisAlignment;
    final menuBelowFab = _menuOpensBelowFab(position);

    final scanChip = _QuickActionChip(
      label: 'Scan QR',
      icon: Icons.qr_code_scanner_rounded,
      delay: 0,
      animation: expandAnimation,
      onTap: onScan,
    );
    final addChip = _QuickActionChip(
      label: 'Add Expense',
      icon: Icons.edit_rounded,
      delay: 0.05,
      animation: expandAnimation,
      onTap: onAddExpense,
    );

    final menu = SizeTransition(
      sizeFactor: expandAnimation,
      axisAlignment: menuBelowFab ? 0 : 1,
      child: FadeTransition(
        opacity: expandAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: cross,
          children: [
            if (!menuBelowFab) ...[
              addChip,
              const SizedBox(height: 10),
              scanChip,
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );

    final fab = FloatingActionButton(
      heroTag: 'paytrack_quick_action_fab',
      elevation: menuOpen ? 5 : 3,
      highlightElevation: 8,
      onPressed: onToggle,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: AnimatedRotation(
        turns: menuOpen ? 0.125 : 0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        child: const Icon(Icons.add_rounded, size: 24),
      ),
    );

    if (menuBelowFab) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: cross,
        children: [
          fab,
          menu,
          SizeTransition(
            sizeFactor: expandAnimation,
            axisAlignment: 0,
            child: FadeTransition(
              opacity: expandAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: cross,
                children: [
                  const SizedBox(height: 12),
                  scanChip,
                  const SizedBox(height: 10),
                  addChip,
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: cross,
      children: [
        menu,
        fab,
      ],
    );
  }

  bool _menuOpensBelowFab(FloatingActionPosition position) {
    return position == FloatingActionPosition.centerRight ||
        position == FloatingActionPosition.centerLeft;
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.animation,
    required this.delay,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Animation<double> animation;
  final double delay;

  @override
  Widget build(BuildContext context) {
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Interval(delay, 1, curve: Curves.easeOutCubic),
    ));

    return SlideTransition(
      position: slide,
      child: Material(
        elevation: 4,
        shadowColor: AppColors.primary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).cardColor,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
