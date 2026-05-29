import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';
import '../theme/paytrack_theme_extension.dart';

/// Dominant Add expense / Scan QR actions on the Home dashboard.
class HomePrimaryActions extends StatelessWidget {
  const HomePrimaryActions({
    super.key,
    required this.onAddExpense,
    required this.onScan,
  });

  final VoidCallback onAddExpense;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Each card is ~half the content width (dashboard uses 20px side padding).
    final cardWidth = (MediaQuery.sizeOf(context).width - 40 - 14) / 2;
    final useCompactLayout = cardWidth < 180;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _HomeActionCard(
            icon: Icons.add_rounded,
            label: 'Add Expense',
            subtitle: 'Log manually',
            isDark: isDark,
            compact: useCompactLayout,
            style: _HomeActionStyle.tonal,
            onPressed: () {
              HapticFeedback.lightImpact();
              onAddExpense();
            },
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _HomeActionCard(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Scan QR',
            subtitle: 'Pay with UPI',
            isDark: isDark,
            compact: useCompactLayout,
            style: _HomeActionStyle.gradient,
            onPressed: () {
              HapticFeedback.mediumImpact();
              onScan();
            },
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 380.ms, delay: 60.ms)
        .slideY(begin: 0.1, end: 0, duration: 420.ms, curve: Curves.easeOutCubic);
  }
}

enum _HomeActionStyle { tonal, gradient }

class _HomeActionCard extends StatefulWidget {
  const _HomeActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isDark,
    required this.compact,
    required this.style,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool isDark;
  final bool compact;
  final _HomeActionStyle style;
  final VoidCallback onPressed;

  @override
  State<_HomeActionCard> createState() => _HomeActionCardState();
}

class _HomeActionCardState extends State<_HomeActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isGradient = widget.style == _HomeActionStyle.gradient;
    final extras = PayTrackThemeExtension.of(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: widget.compact ? 100 : 124,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 12 : 14,
                vertical: widget.compact ? 14 : 16,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
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
                        ? extras.tonalSurface
                        : extras.tonalSurface,
                border: Border.all(
                  color: isGradient
                      ? Colors.white.withValues(alpha: 0.12)
                      : extras.tonalBorder,
                  width: 1.2,
                ),
                boxShadow: isGradient
                    ? [
                        BoxShadow(
                          color: extras.heroShadow,
                          blurRadius: _pressed ? 12 : 22,
                          offset: Offset(0, _pressed ? 4 : 10),
                        ),
                      ]
                    : extras.cardShadows,
              ),
              alignment: Alignment.center,
              child: widget.compact
                  ? _buildHorizontalContent(isGradient)
                  : _buildVerticalContent(isGradient),
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBadge(
    bool isGradient, {
    required double size,
    required double padding,
  }) {
    final extras = PayTrackThemeExtension.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: isGradient
            ? Colors.white.withValues(alpha: 0.2)
            : extras.tonalIconBackground,
        shape: BoxShape.circle,
      ),
      child: Icon(
        widget.icon,
        size: size,
        color: isGradient
            ? Colors.white
            : widget.isDark
                ? Colors.white
                : scheme.onPrimaryContainer,
      ),
    );
  }

  Widget _labelText(
    bool isGradient, {
    required double fontSize,
    required TextAlign textAlign,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      widget.label,
      textAlign: textAlign,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        height: 1.15,
        color: isGradient
            ? Colors.white
            : widget.isDark
                ? Colors.white
                : scheme.onPrimaryContainer,
      ),
    );
  }

  Widget _subtitleText(
    bool isGradient, {
    required double fontSize,
    required TextAlign textAlign,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      widget.subtitle,
      textAlign: textAlign,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: isGradient
            ? Colors.white.withValues(alpha: 0.85)
            : widget.isDark
                ? Colors.white60
                : scheme.onPrimaryContainer.withValues(alpha: 0.72),
      ),
    );
  }

  Widget _buildVerticalContent(bool isGradient) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _iconBadge(isGradient, size: 32, padding: 10),
        const SizedBox(height: 10),
        _labelText(isGradient, fontSize: 16, textAlign: TextAlign.center),
        const SizedBox(height: 3),
        _subtitleText(isGradient, fontSize: 11, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildHorizontalContent(bool isGradient) {
    return Row(
      children: [
        _iconBadge(isGradient, size: 28, padding: 8),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _labelText(isGradient, fontSize: 15, textAlign: TextAlign.start),
              const SizedBox(height: 2),
              _subtitleText(
                isGradient,
                fontSize: 10,
                textAlign: TextAlign.start,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
