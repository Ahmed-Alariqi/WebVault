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
import 'features/clipboard/overlay_clipboard.dart';

// ============================================================
// Overlay entry point — runs in its own isolate
// ============================================================
@pragma("vm:entry-point")
void overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OverlayClipboard(),
    ),
  );
}

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

  // Listen for text shared from outside the app (Android Share Sheet)
  const MethodChannel('com.webvault.app/overlay').setMethodCallHandler((
    call,
  ) async {
    if (call.method == 'shareReceived') {
      final args = Map<String, dynamic>.from(call.arguments as Map);
      final label = args['label'] as String? ?? 'Shared item';
      final text = args['text'] as String? ?? '';
      if (text.isNotEmpty) {
        final id = DateTime.now().millisecondsSinceEpoch.toString();
        final item = {
          'id': id,
          'label': label,
          'value': text,
          'type': 0,
          'isPinned': false,
          'sortOrder': Hive.box(kClipboardBox).length,
          'isEncrypted': false,
          'createdAt': DateTime.now().toIso8601String(),
          'autoDeleteAt': null,
          'groupId': null,
        };
        await Hive.box(kClipboardBox).put(id, item);
      }
    }
  });

  // Initialize Supabase
  await SupabaseConfig.initialize();

  // Initialize OneSignal
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize(SupabaseConfig.oneSignalAppId);

  // Request push notification permission
  OneSignal.Notifications.requestPermission(true);

  // Enable push subscription explicitly (OneSignal v5+ requires this)
  OneSignal.User.pushSubscription.optIn();

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
    router.push('/notifications');
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
