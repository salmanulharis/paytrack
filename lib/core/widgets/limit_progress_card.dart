import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../../domain/entities/limit_status.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import 'glass_card.dart';

class LimitProgressCard extends StatelessWidget {
  const LimitProgressCard({
    super.key,
    required this.status,
    this.onTap,
  });

  final LimitStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (!status.isActive) return const SizedBox.shrink();

    final percent = status.percentUsed.clamp(0.0, 1.0);
    final color = status.isExceeded
        ? AppColors.error
        : status.isApproaching
            ? AppColors.warning
            : AppColors.success;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  status.isExceeded
                      ? Icons.warning_amber_rounded
                      : Icons.speed_rounded,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${status.label} limit',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                Text(
                  '${CurrencyFormatter.format(status.spent)} / ${CurrencyFormatter.format(status.effectiveLimit)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (status.compensationReduction > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Compensating limit: −${CurrencyFormatter.format(status.compensationReduction)} from yesterday',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            LinearPercentIndicator(
              lineHeight: 10,
              percent: percent,
              backgroundColor: color.withValues(alpha: 0.15),
              progressColor: color,
              barRadius: const Radius.circular(6),
              animation: true,
              animationDuration: 600,
              padding: EdgeInsets.zero,
            ),
            if (status.message != null) ...[
              const SizedBox(height: 10),
              Text(
                status.message!,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .shimmer(
                    duration: 1200.ms,
                    color: color.withValues(alpha: 0.3),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
