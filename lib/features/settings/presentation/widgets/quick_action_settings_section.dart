import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/paytrack_theme_extension.dart';
import '../../../../core/widgets/paytrack_quick_action_fab.dart';
import '../../../../domain/entities/floating_action_position.dart';

/// Settings → Quick Actions: toggle, position, live preview.
class QuickActionSettingsSection extends ConsumerWidget {
  const QuickActionSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPrefs = ref.watch(userPreferencesProvider);
    final notifier = ref.read(userPreferencesProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('Quick actions'),
        SwitchListTile(
          title: const Text('Show floating quick actions'),
          subtitle: const Text(
            'Global + button for Scan QR and Add expense on Home, '
            'Expenses, and Analytics.',
          ),
          value: userPrefs.showFloatingQuickActions,
          onChanged: (v) {
            HapticFeedback.selectionClick();
            notifier.update(userPrefs.copyWith(showFloatingQuickActions: v));
            if (!v) {
              ref.read(quickActionMenuOpenProvider.notifier).state = false;
            }
          },
        ),
        AnimatedOpacity(
          opacity: userPrefs.showFloatingQuickActions ? 1 : 0.45,
          duration: const Duration(milliseconds: 220),
          child: IgnorePointer(
            ignoring: !userPrefs.showFloatingQuickActions,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'Floating button position',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Preview updates as you choose a position.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _PositionPreview(
                    position: userPrefs.floatingActionPosition,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: FloatingActionPosition.values.map((pos) {
                      final selected =
                          userPrefs.floatingActionPosition == pos;
                      return FilterChip(
                        label: Text(pos.label),
                        selected: selected,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          notifier.update(
                            userPrefs.copyWith(floatingActionPosition: pos),
                          );
                        },
                        selectedColor:
                            AppColors.primary.withValues(alpha: 0.18),
                        checkmarkColor: AppColors.primary,
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PositionPreview extends StatelessWidget {
  const _PositionPreview({required this.position});

  final FloatingActionPosition position;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final extras = PayTrackThemeExtension.of(context);

    return AspectRatio(
      aspectRatio: 2.1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: extras.cardShadows,
        ),
        child: Stack(
          children: [
            Positioned(
              left: 12,
              top: 10,
              child: Text(
                'Screen preview',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: AnimatedAlign(
                alignment: position.alignment,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: extras.heroShadow,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
