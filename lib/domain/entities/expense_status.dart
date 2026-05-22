enum ExpenseStatus {
  pending,
  success,
  failed,
  cancelled;

  String get label {
    switch (this) {
      case ExpenseStatus.pending:
        return 'Pending';
      case ExpenseStatus.success:
        return 'Success';
      case ExpenseStatus.failed:
        return 'Failed';
      case ExpenseStatus.cancelled:
        return 'Cancelled';
    }
  }

  static ExpenseStatus fromString(String value) {
    return ExpenseStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExpenseStatus.pending,
    );
  }
}
