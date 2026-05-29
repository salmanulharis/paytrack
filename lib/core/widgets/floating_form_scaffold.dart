import 'package:flutter/material.dart';

import 'gradient_button.dart';

/// Scrollable form with a pinned floating CTA above system safe areas.
class FloatingFormScaffold extends StatelessWidget {
  const FloatingFormScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    this.actionIcon,
    this.isLoading = false,
    this.secondaryAction,
    this.leading,
  });

  final String title;
  final Widget body;
  final String actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final bool isLoading;
  final Widget? secondaryAction;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const ctaHeight = 72.0;
    final scrollBottomPadding = ctaHeight + bottomInset + 24;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: leading,
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, scrollBottomPadding),
                sliver: SliverToBoxAdapter(child: body),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _FloatingCtaBar(
              bottomInset: bottomInset,
              actionLabel: actionLabel,
              actionIcon: actionIcon,
              isLoading: isLoading,
              onAction: onAction,
              secondaryAction: secondaryAction,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingCtaBar extends StatelessWidget {
  const _FloatingCtaBar({
    required this.bottomInset,
    required this.actionLabel,
    required this.onAction,
    required this.isLoading,
    this.actionIcon,
    this.secondaryAction,
  });

  final double bottomInset;
  final String actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final bool isLoading;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Material(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomInset),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              bg.withValues(alpha: 0),
              scheme.surface,
            ],
          ),
          border: Border(
            top: BorderSide(color: scheme.outlineVariant),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (secondaryAction != null) ...[
              secondaryAction!,
              const SizedBox(height: 8),
            ],
            GradientButton(
              label: actionLabel,
              icon: actionIcon,
              isLoading: isLoading,
              onPressed: onAction,
            ),
          ],
        ),
      ),
    );
  }
}
