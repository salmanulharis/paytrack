import 'package:flutter/material.dart';

/// Semantic colors and elevations shared across PayTrack widgets.
@immutable
class PayTrackThemeExtension extends ThemeExtension<PayTrackThemeExtension> {
  const PayTrackThemeExtension({
    required this.glassGradientStart,
    required this.glassGradientEnd,
    required this.glassBorder,
    required this.cardShadow,
    required this.elevatedShadow,
    required this.tonalSurface,
    required this.tonalBorder,
    required this.tonalIconBackground,
    required this.inputFill,
    required this.inputBorder,
    required this.inputFocusedBorder,
    required this.navBarBackground,
    required this.navIndicator,
    required this.chartAreaFill,
    required this.heroShadow,
    required this.useSoftGlassBlur,
  });

  final Color glassGradientStart;
  final Color glassGradientEnd;
  final Color glassBorder;
  final Color cardShadow;
  final Color elevatedShadow;
  final Color tonalSurface;
  final Color tonalBorder;
  final Color tonalIconBackground;
  final Color inputFill;
  final Color inputBorder;
  final Color inputFocusedBorder;
  final Color navBarBackground;
  final Color navIndicator;
  final Color chartAreaFill;
  final Color heroShadow;
  final bool useSoftGlassBlur;

  static PayTrackThemeExtension of(BuildContext context) {
    return Theme.of(context).extension<PayTrackThemeExtension>()!;
  }

  List<BoxShadow> get cardShadows => [
        BoxShadow(
          color: cardShadow,
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  List<BoxShadow> get elevatedShadows => [
        BoxShadow(
          color: elevatedShadow,
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
      ];

  @override
  PayTrackThemeExtension copyWith({
    Color? glassGradientStart,
    Color? glassGradientEnd,
    Color? glassBorder,
    Color? cardShadow,
    Color? elevatedShadow,
    Color? tonalSurface,
    Color? tonalBorder,
    Color? tonalIconBackground,
    Color? inputFill,
    Color? inputBorder,
    Color? inputFocusedBorder,
    Color? navBarBackground,
    Color? navIndicator,
    Color? chartAreaFill,
    Color? heroShadow,
    bool? useSoftGlassBlur,
  }) {
    return PayTrackThemeExtension(
      glassGradientStart: glassGradientStart ?? this.glassGradientStart,
      glassGradientEnd: glassGradientEnd ?? this.glassGradientEnd,
      glassBorder: glassBorder ?? this.glassBorder,
      cardShadow: cardShadow ?? this.cardShadow,
      elevatedShadow: elevatedShadow ?? this.elevatedShadow,
      tonalSurface: tonalSurface ?? this.tonalSurface,
      tonalBorder: tonalBorder ?? this.tonalBorder,
      tonalIconBackground: tonalIconBackground ?? this.tonalIconBackground,
      inputFill: inputFill ?? this.inputFill,
      inputBorder: inputBorder ?? this.inputBorder,
      inputFocusedBorder: inputFocusedBorder ?? this.inputFocusedBorder,
      navBarBackground: navBarBackground ?? this.navBarBackground,
      navIndicator: navIndicator ?? this.navIndicator,
      chartAreaFill: chartAreaFill ?? this.chartAreaFill,
      heroShadow: heroShadow ?? this.heroShadow,
      useSoftGlassBlur: useSoftGlassBlur ?? this.useSoftGlassBlur,
    );
  }

  @override
  PayTrackThemeExtension lerp(
    ThemeExtension<PayTrackThemeExtension>? other,
    double t,
  ) {
    if (other is! PayTrackThemeExtension) return this;
    return PayTrackThemeExtension(
      glassGradientStart:
          Color.lerp(glassGradientStart, other.glassGradientStart, t)!,
      glassGradientEnd:
          Color.lerp(glassGradientEnd, other.glassGradientEnd, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
      elevatedShadow: Color.lerp(elevatedShadow, other.elevatedShadow, t)!,
      tonalSurface: Color.lerp(tonalSurface, other.tonalSurface, t)!,
      tonalBorder: Color.lerp(tonalBorder, other.tonalBorder, t)!,
      tonalIconBackground:
          Color.lerp(tonalIconBackground, other.tonalIconBackground, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      inputFocusedBorder:
          Color.lerp(inputFocusedBorder, other.inputFocusedBorder, t)!,
      navBarBackground:
          Color.lerp(navBarBackground, other.navBarBackground, t)!,
      navIndicator: Color.lerp(navIndicator, other.navIndicator, t)!,
      chartAreaFill: Color.lerp(chartAreaFill, other.chartAreaFill, t)!,
      heroShadow: Color.lerp(heroShadow, other.heroShadow, t)!,
      useSoftGlassBlur: t < 0.5 ? useSoftGlassBlur : other.useSoftGlassBlur,
    );
  }
}
