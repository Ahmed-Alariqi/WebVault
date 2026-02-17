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
  // Remove this method to stop OneSignal Debugging
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize(SupabaseConfig.oneSignalAppId);
  // The promptForPushNotificationsWithUserResponse function will show the iOS or Android push notification prompt. We recommend removing the following code and instead using an In-App Message to prompt for notification permission
  OneSignal.Notifications.requestPermission(true);

  // FORCE SHOW notification in foreground (User request: "appears even if user outside app", but also consistency)
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    // Prevent the default behavior (which might be to suppress)
    // Actually, to SHow it, we usually don't need to do anything if default is show.
    // But if we want to ensure it shows as a system notification:
    event.notification.display();
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

  runApp(const ProviderScope(child: WebVaultApp()));
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
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeMode,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
