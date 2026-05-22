import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/app_platform.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/upi_app_info.dart';

class UpiAppPickerSheet {
  UpiAppPickerSheet._();

  static Future<UpiAppInfo?> show(BuildContext context) {
    return showModalBottomSheet<UpiAppInfo>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: _UpiAppPickerContent(
          onSelected: (app) => Navigator.pop(ctx, app),
        ),
      ),
    );
  }
}

class _UpiAppPickerContent extends ConsumerStatefulWidget {
  const _UpiAppPickerContent({required this.onSelected});

  final void Function(UpiAppInfo app) onSelected;

  @override
  ConsumerState<_UpiAppPickerContent> createState() => _UpiAppPickerContentState();
}

class _UpiAppPickerContentState extends ConsumerState<_UpiAppPickerContent> {
  List<UpiAppInfo> _apps = [];
  bool _loading = true;
  String? _recommendedId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = ref.read(upiPaymentServiceProvider);
    final flow = ref.read(paymentFlowServiceProvider);

    var apps = await service.getInstalledUpiApps();
    // Show known wallets when detection is empty so user can still try payment.
    if (apps.isEmpty) {
      apps = UpiAppInfo.knownApps
          .map((a) => a.copyWith(isInstalled: false))
          .toList();
    }

    apps = apps.map((app) {
      return app.copyWith(usageCount: flow.getAppUsageCount(app.id));
    }).toList()
      ..sort((a, b) => b.usageCount.compareTo(a.usageCount));

    _recommendedId = flow.getLastUsedAppId() ?? (apps.isNotEmpty ? apps.first.id : null);

    setState(() {
      _apps = apps;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Pay with', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Choose your UPI app',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            ..._apps.map((app) => _AppTile(
                  app: app,
                  isRecommended: app.id == _recommendedId,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onSelected(app);
                  },
                )),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.apps_rounded),
            title: const Text('Other UPI apps'),
            subtitle: Text(
              appPlatform == AppPlatformKind.ios
                  ? 'Opens the iOS app picker for UPI'
                  : 'Opens Android UPI app chooser',
            ),
            onTap: () {
              widget.onSelected(const UpiAppInfo(
                id: 'other',
                name: 'Other',
                packageName: '',
              ));
            },
          ),
        ],
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  const _AppTile({
    required this.app,
    required this.isRecommended,
    required this.onTap,
  });

  final UpiAppInfo app;
  final bool isRecommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
        child: Text(
          app.name[0],
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Row(
        children: [
          Text(app.name),
          if (isRecommended) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Recommended',
                style: TextStyle(fontSize: 10, color: AppColors.accent),
              ),
            ),
          ],
        ],
      ),
      subtitle: app.isInstalled
          ? null
          : Text(
              appPlatform == AppPlatformKind.ios
                  ? 'Not detected — tap to try anyway'
                  : 'May open via chooser',
            ),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
