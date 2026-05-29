import 'package:flutter/material.dart';

/// User-configurable anchor for the global quick-action FAB.
enum FloatingActionPosition {
  bottomRight,
  bottomLeft,
  bottomCenter,
  centerRight,
  centerLeft;

  String get label => switch (this) {
        FloatingActionPosition.bottomRight => 'Bottom right',
        FloatingActionPosition.bottomLeft => 'Bottom left',
        FloatingActionPosition.bottomCenter => 'Bottom center',
        FloatingActionPosition.centerRight => 'Center right',
        FloatingActionPosition.centerLeft => 'Center left',
      };

  Alignment get alignment => switch (this) {
        FloatingActionPosition.bottomRight => Alignment.bottomRight,
        FloatingActionPosition.bottomLeft => Alignment.bottomLeft,
        FloatingActionPosition.bottomCenter => Alignment.bottomCenter,
        FloatingActionPosition.centerRight => Alignment.centerRight,
        FloatingActionPosition.centerLeft => Alignment.centerLeft,
      };

  CrossAxisAlignment get menuCrossAxisAlignment => switch (this) {
        FloatingActionPosition.bottomRight ||
        FloatingActionPosition.centerRight =>
          CrossAxisAlignment.end,
        FloatingActionPosition.bottomLeft ||
        FloatingActionPosition.centerLeft =>
          CrossAxisAlignment.start,
        FloatingActionPosition.bottomCenter => CrossAxisAlignment.center,
      };

  static FloatingActionPosition fromString(String? value) {
    return FloatingActionPosition.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FloatingActionPosition.bottomRight,
    );
  }
}
