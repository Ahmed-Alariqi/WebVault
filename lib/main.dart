import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'core/constants.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/supabase_config.dart';
import 'data/dummy_data.dart';
import 'data/repositories/page_repository.dart';
import 'data/repositories/folder_repository.dart';
import 'data/repositories/clipboard_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'presentation/providers/providers.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox(kPagesBox);
  await Hive.openBox(kFoldersBox);
  await Hive.openBox(kClipboardBox);
  await Hive.openBox(kSettingsBox);
  await Hive.openBox(kDiscoverCacheBox);
  await Hive.openBox(kSyncQueueBox);

  // Initialize Supabase
  await SupabaseConfig.initialize();

  // Initialize OneSignal
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize(SupabaseConfig.oneSignalAppId);
  OneSignal.Notifications.requestPermission(true);

  // Create a global container so we can invalidate providers from callbacks
  final container = ProviderContainer();

  // Show notification in foreground AND refresh badge count
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    event.notification.display();
    // Refresh the unread notifications count
    container.invalidate(notificationCountProvider);
  });

  // Also refresh count when notification is clicked (user returns from background)
  OneSignal.Notifications.addClickListener((event) {
    container.invalidate(notificationCountProvider);
  });

  // Seed dummy data on first launch
  final settingsRepo = SettingsRepository();
  if (settingsRepo.isFirstLaunch()) {
    await DummyData.seed(
      pageRepo: PageRepository(),
      folderRepo: FolderRepository(),
      clipboardRepo: ClipboardRepository(),
    );
    await settingsRepo.setFirstLaunch(false);
  }

  // Set system UI style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    UncontrolledProviderScope(container: container, child: const WebVaultApp()),
  );
}

class WebVaultApp extends ConsumerWidget {
  const WebVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(locale.languageCode),
      darkTheme: AppTheme.darkTheme(locale.languageCode),
      themeMode: themeMode,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
