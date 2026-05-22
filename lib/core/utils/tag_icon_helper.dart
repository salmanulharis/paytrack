import 'package:flutter/material.dart';

class TagIconHelper {
  TagIconHelper._();

  static IconData iconFor(String iconName) {
    return switch (iconName) {
      'restaurant' => Icons.restaurant_rounded,
      'flight' => Icons.flight_rounded,
      'local_gas_station' => Icons.local_gas_station_rounded,
      'shopping_cart' => Icons.shopping_cart_rounded,
      'shopping_bag' => Icons.shopping_bag_rounded,
      'home' => Icons.home_rounded,
      'receipt_long' => Icons.receipt_long_rounded,
      'movie' => Icons.movie_rounded,
      'favorite' => Icons.favorite_rounded,
      'school' => Icons.school_rounded,
      'trending_up' => Icons.trending_up_rounded,
      'account_balance' => Icons.account_balance_rounded,
      'subscriptions' => Icons.subscriptions_rounded,
      'family_restroom' => Icons.family_restroom_rounded,
      'commute' => Icons.commute_rounded,
      'fitness_center' => Icons.fitness_center_rounded,
      'pets' => Icons.pets_rounded,
      'work' => Icons.work_rounded,
      _ => Icons.label_rounded,
    };
  }

  static const List<String> availableIcons = [
    'restaurant',
    'flight',
    'local_gas_station',
    'shopping_cart',
    'shopping_bag',
    'home',
    'receipt_long',
    'movie',
    'favorite',
    'school',
    'trending_up',
    'account_balance',
    'subscriptions',
    'family_restroom',
    'commute',
    'fitness_center',
    'pets',
    'work',
    'more_horiz',
  ];

  static const List<int> tagColors = [
    0xFFFF6B6B,
    0xFF4ECDC4,
    0xFFFFBE0B,
    0xFF95E1D3,
    0xFF6C5CE7,
    0xFF74B9FF,
    0xFFA29BFE,
    0xFFFD79A8,
    0xFF00B894,
    0xFFE17055,
    0xFF636E72,
    0xFFFF7675,
  ];
}
