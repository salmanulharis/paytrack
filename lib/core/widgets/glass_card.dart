import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/paytrack_theme_extension.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final extras = PayTrackThemeExtension.of(context);
    final blurSigma = extras.useSoftGlassBlur ? 8.0 : 12.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    extras.glassGradientStart,
                    extras.glassGradientEnd,
                  ],
                ),
                border: Border.all(color: extras.glassBorder),
                boxShadow: extras.cardShadows,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
