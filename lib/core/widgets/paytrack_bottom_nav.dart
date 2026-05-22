import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';

/// Bottom chrome: dual actions (horizontal) + navigation bar.
class PayTrackBottomChrome extends StatelessWidget {
  const PayTrackBottomChrome({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onAddExpense,
    required this.onScan,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onAddExpense;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: PayTrackDualActionBar(
            onAddExpense: onAddExpense,
            onScan: onScan,
          ),
        ),
        PayTrackBottomNav(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
        ),
        SizedBox(height: bottom > 0 ? 0 : 0),
      ],
    );
  }
}

class PayTrackBottomNav extends StatelessWidget {
  const PayTrackBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      height: 64,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart_rounded),
          label: 'Analytics',
        ),
      ],
    );
  }
}

/// Option 1: balanced side-by-side primary actions (Wallet / CRED style).
class PayTrackDualActionBar extends StatelessWidget {
  const PayTrackDualActionBar({
    super.key,
    required this.onAddExpense,
    required this.onScan,
  });

  final VoidCallback onAddExpense;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark
                ? AppColors.darkCard.withValues(alpha: 0.88)
                : Colors.white.withValues(alpha: 0.92),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _DualActionTile(
                  icon: Icons.add_rounded,
                  label: 'Add expense',
                  isDark: isDark,
                  style: _DualActionStyle.tonal,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onAddExpense();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DualActionTile(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Scan QR',
                  isDark: isDark,
                  style: _DualActionStyle.gradient,
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onScan();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 320.ms, curve: Curves.easeOut)
        .slideY(begin: 0.12, end: 0, duration: 380.ms, curve: Curves.easeOutCubic);
  }
}

enum _DualActionStyle { tonal, gradient }

class _DualActionTile extends StatefulWidget {
  const _DualActionTile({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.style,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final _DualActionStyle style;
  final VoidCallback onPressed;

  @override
  State<_DualActionTile> createState() => _DualActionTileState();
}

class _DualActionTileState extends State<_DualActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isGradient = widget.style == _DualActionStyle.gradient;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: isGradient
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  )
                : null,
            color: isGradient
                ? null
                : widget.isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.primary.withValues(alpha: 0.08),
            boxShadow: isGradient
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: _pressed ? 8 : 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 22,
                color: isGradient
                    ? Colors.white
                    : widget.isDark
                        ? Colors.white
                        : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: isGradient
                        ? Colors.white
                        : widget.isDark
                            ? Colors.white
                            : AppColors.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
