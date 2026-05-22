import '../../domain/entities/expense_tag.dart';

class DefaultTags {
  DefaultTags._();

  static List<ExpenseTag> get all => [
        ExpenseTag(id: 'food', name: 'Food', iconName: 'restaurant', colorValue: 0xFFFF6B6B),
        ExpenseTag(id: 'travel', name: 'Travel', iconName: 'flight', colorValue: 0xFF4ECDC4),
        ExpenseTag(id: 'fuel', name: 'Fuel', iconName: 'local_gas_station', colorValue: 0xFFFFBE0B),
        ExpenseTag(id: 'groceries', name: 'Groceries', iconName: 'shopping_cart', colorValue: 0xFF95E1D3),
        ExpenseTag(id: 'shopping', name: 'Shopping', iconName: 'shopping_bag', colorValue: 0xFFF38181),
        ExpenseTag(id: 'rent', name: 'Rent', iconName: 'home', colorValue: 0xFF6C5CE7),
        ExpenseTag(id: 'bills', name: 'Bills', iconName: 'receipt_long', colorValue: 0xFF74B9FF),
        ExpenseTag(id: 'entertainment', name: 'Entertainment', iconName: 'movie', colorValue: 0xFFA29BFE),
        ExpenseTag(id: 'health', name: 'Health', iconName: 'favorite', colorValue: 0xFFFD79A8),
        ExpenseTag(id: 'education', name: 'Education', iconName: 'school', colorValue: 0xFF00B894),
        ExpenseTag(id: 'investments', name: 'Investments', iconName: 'trending_up', colorValue: 0xFF00CEC9),
        ExpenseTag(id: 'emi', name: 'EMI', iconName: 'account_balance', colorValue: 0xFFE17055),
        ExpenseTag(id: 'subscriptions', name: 'Subscriptions', iconName: 'subscriptions', colorValue: 0xFF636E72),
        ExpenseTag(id: 'family', name: 'Family', iconName: 'family_restroom', colorValue: 0xFFFF7675),
        ExpenseTag(id: 'misc', name: 'Miscellaneous', iconName: 'more_horiz', colorValue: 0xFFB2BEC3),
      ];
}
