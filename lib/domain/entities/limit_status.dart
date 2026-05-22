class LimitStatus {
  const LimitStatus({
    required this.label,
    required this.spent,
    required this.effectiveLimit,
    required this.baseLimit,
    required this.percentUsed,
    required this.isExceeded,
    required this.isApproaching,
    this.compensationReduction = 0,
    this.excessOverLimit = 0,
    this.message,
  });

  final String label;
  final double spent;
  final double effectiveLimit;
  final double baseLimit;
  final double percentUsed;
  final bool isExceeded;
  final bool isApproaching;
  final double compensationReduction;
  final double excessOverLimit;
  final String? message;

  bool get isActive => effectiveLimit > 0;
}
