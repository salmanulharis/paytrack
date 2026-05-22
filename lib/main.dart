import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers/app_providers.dart';
import 'data/datasources/local/hive_storage.dart';
import 'data/sample/sample_data_seeder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefs = await SharedPreferences.getInstance();
  await HiveStorage.instance.init();
  await SampleDataSeeder.seedIfEmpty(HiveStorage.instance, prefs);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const _BootstrapApp(),
    ),
  );
}

class _BootstrapApp extends ConsumerStatefulWidget {
  const _BootstrapApp();

  @override
  ConsumerState<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends ConsumerState<_BootstrapApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(notificationServiceProvider).init());
  }

  @override
  Widget build(BuildContext context) {
    return const PayTrackApp();
  }
}
