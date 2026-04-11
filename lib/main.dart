import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'core/constants.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/dummy_data.dart';
import 'data/repositories/page_repository.dart';
import 'data/repositories/folder_repository.dart';
import 'data/repositories/clipboard_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/services/auth_service.dart';
import 'presentation/providers/providers.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'core/services/analytics_service.dart';
import 'package:timeago/timeago.dart' as timeago;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox(kPagesBox);
  await Hive.openBox(kFoldersBox);
  await Hive.openBox(kClipboardBox);
  await Hive.openBox(kClipboardGroupsBox);
  await Hive.openBox(kSettingsBox);
  await Hive.openBox(kDiscoverCacheBox);
  await Hive.openBox(kSyncQueueBox);
  await Hive.openBox('ai_chats');

  // ── Share Intent handling ──
  // Channel for communicating with native Android code
  const shareChannel = MethodChannel('com.webvault.app/overlay');

  // Function to check and process all pending shared items from the queue
  Future<void> checkAndProcessPendingShares() async {
    try {
      final result = await shareChannel.invokeMethod('getPendingShares');
      if (result != null) {
        final items = List<Map<dynamic, dynamic>>.from(result as List);
        final box = Hive.box(kClipboardBox);
        for (final raw in items) {
          final args = Map<String, dynamic>.from(raw);
          final label = args['label'] as String? ?? 'Shared item';
          final text = args['text'] as String? ?? '';
          if (text.isNotEmpty) {
            final id = DateTime.now().microsecondsSinceEpoch.toString();
            final item = {
              'id': id,
              'label': label,
              'value': text,
              'type': 0,
              'isPinned': false,
              'sortOrder': box.length,
              'isEncrypted': false,
              'createdAt': DateTime.now().toIso8601String(),
              'autoDeleteAt': null,
              'groupId': null,
            };
            await box.put(id, item);
            debugPrint('[Share] Saved shared item: label=$label');
          }
        }
        debugPrint('[Share] Processed ${items.length} pending shares');
      }
    } catch (e) {
      debugPrint('[Share] Error checking pending shares: $e');
    }
  }

  // Check for pending shares on startup
  await checkAndProcessPendingShares();

  // Also check on every app resume (user shared while app was in background)
  // ignore: unused_local_variable
  final lifecycleListener = AppLifecycleListener(
    onResume: () => checkAndProcessPendingShares(),
  );

  // Set up timeago arabic locales
  timeago.setLocaleMessages('ar', timeago.ArMessages());

  // Initialize Supabase
  await SupabaseConfig.initialize();

  // Initialize OneSignal
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize(SupabaseConfig.oneSignalAppId);

  // Request push notification permission
  OneSignal.Notifications.requestPermission(true);

  // Enable push subscription explicitly (OneSignal v5+ requires this)
  OneSignal.User.pushSubscription.optIn();

  // ── OneSignal registration is now handled by the Fix Notifications button ──
  // In blocked regions, the user opens VPN and taps "Fix Notifications" in
  // Settings, which restarts the app so OneSignal can re-register cleanly.

  // Create a global container so we can invalidate providers from callbacks
  final container = ProviderContainer();
  final authService = AuthService();

  // ── Monitor push subscription changes ──
  // This fires when the device first gets a push token,
  // or when subscription status changes.
  OneSignal.User.pushSubscription.addObserver((state) {
    debugPrint('[OneSignal] Push subscription changed:');
    debugPrint('[OneSignal]   ID: ${state.current.id}');
    debugPrint('[OneSignal]   Token: ${state.current.token}');
    debugPrint('[OneSignal]   OptedIn: ${state.current.optedIn}');

    // Store the subscription ID in the user's profile whenever it's available
    final subId = state.current.id;
    final user = SupabaseConfig.client.auth.currentUser;
    if (subId != null && subId.isNotEmpty && user != null) {
      authService
          .updateProfile(onesignalPlayerId: subId)
          .then((_) {
            debugPrint('[OneSignal] Stored subscription ID to profile: $subId');
          })
          .catchError((e) {
            debugPrint('[OneSignal] Failed to store sub ID: $e');
          });
    }
  });

  // ── Link Supabase user to OneSignal on auth state changes ──
  SupabaseConfig.client.auth.onAuthStateChange.listen((data) async {
    final event = data.event;
    final session = data.session;

    if (event == AuthChangeEvent.signedIn ||
        event == AuthChangeEvent.tokenRefreshed ||
        event == AuthChangeEvent.initialSession) {
      final userId = session?.user.id;
      if (userId != null) {
        // Link this device to the Supabase user in OneSignal
        await OneSignal.login(userId);
        debugPrint('[OneSignal] Logged in user: $userId');

        // Also ensure push subscription is opted in
        OneSignal.User.pushSubscription.optIn();

        // Tag the user's name so OneSignal can personalize push content
        final meta = session?.user.userMetadata;
        final userName =
            meta?['username'] as String? ??
            meta?['full_name'] as String? ??
            meta?['name'] as String? ??
            session?.user.email ??
            'there';
        OneSignal.User.addTagWithKey('user_name', userName);
        debugPrint('[OneSignal] Tagged user_name=$userName');

        // Try to store the subscription ID right away
        final subId = OneSignal.User.pushSubscription.id;
        final token = OneSignal.User.pushSubscription.token;
        debugPrint('[OneSignal] Current sub ID: $subId, token: $token');
        if (subId != null && subId.isNotEmpty) {
          try {
            await authService.updateProfile(onesignalPlayerId: subId);
            debugPrint('[OneSignal] Stored subscription ID: $subId');
          } catch (e) {
            debugPrint('[OneSignal] Failed to store sub ID: $e');
          }
        }
      }
    } else if (event == AuthChangeEvent.signedOut) {
      OneSignal.logout();
      debugPrint('[OneSignal] Logged out');
    }
  });

  // Show notification in foreground AND refresh badge count
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    debugPrint(
      '[OneSignal] Foreground notification received: ${event.notification.title}',
    );
    event.notification.display();
    container.invalidate(notificationCountProvider);
  });

  // Also refresh count when notification is clicked (user returns from background)
  OneSignal.Notifications.addClickListener((event) {
    debugPrint('[OneSignal] Notification clicked: ${event.notification.title}');
    container.invalidate(notificationCountProvider);
    // Route to notifications screen
    final router = container.read(routerProvider);
    router.go('/notifications');
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

  // ── Splash version migration ──
  // If the splash was redesigned (version bumped), reset the flag so users
  // see the new splash once more.
  final settingsBox = Hive.box(kSettingsBox);
  final storedSplashVersion =
      settingsBox.get(kSplashVersion, defaultValue: 0) as int;
  if (storedSplashVersion < kCurrentSplashVersion) {
    await settingsRepo.setHasSeenWelcomeScreen(false);
    await settingsBox.put(kSplashVersion, kCurrentSplashVersion);
    debugPrint(
      '[Splash] Reset welcome screen flag (v$storedSplashVersion → v$kCurrentSplashVersion)',
    );
  }

  // Set system UI style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Track app open asynchronously
  AnalyticsService.trackAppOpen();

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
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
