import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
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

/// Handle background messages (called when app is not in foreground)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('[FCM] Background init failed: $e');
    }
  }
  debugPrint('[FCM] Background message received: ${message.notification?.title}');
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

  // Create a global container so we can invalidate providers from callbacks
  final container = ProviderContainer();
  final authService = AuthService();

  // ── Initialize Firebase & FCM (replacing OneSignal) ──
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();

      // Register background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request push notification permission
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // ── Get and store FCM token ──
      Future<void> storeFcmToken(String? token) async {
        if (token == null || token.isEmpty) return;
        final user = SupabaseConfig.client.auth.currentUser;
        if (user != null) {
          try {
            await authService.updateProfile(fcmToken: token);
            debugPrint('[FCM] Stored token to profile: ${token.substring(0, 20)}...');
          } catch (e) {
            debugPrint('[FCM] Failed to store token: $e');
          }
        }
      }

      try {
        final token = await messaging.getToken();
        debugPrint('[FCM] Token: ${token?.substring(0, 20)}...');
        await storeFcmToken(token);
      } catch (e) {
        debugPrint('[FCM] Failed to get token: $e');
      }

      // ── Monitor token refresh ──
      messaging.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM] Token refreshed: ${newToken.substring(0, 20)}...');
        storeFcmToken(newToken);
      });

      // ── Foreground notification handling ──
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          '[FCM] Foreground notification received: ${message.notification?.title}',
        );
        // Refresh badge count
        container.invalidate(notificationCountProvider);
      });

      // ── Notification tap handler (app was in background) ──
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM] Notification clicked: ${message.notification?.title}');
        container.invalidate(notificationCountProvider);
        // Route to notifications screen
        final router = container.read(routerProvider);
        router.go('/notifications');
      });

      // ── Check if app was opened from a terminated state notification ──
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[FCM] App opened from terminated notification');
        // Will be handled after app is fully built
        Future.delayed(const Duration(milliseconds: 500), () {
          container.invalidate(notificationCountProvider);
          final router = container.read(routerProvider);
          router.go('/notifications');
        });
      }
    } catch (e) {
      debugPrint('[Firebase/FCM] Initialization error: $e');
    }
  }

  // ── Store FCM token on auth state changes ──
  SupabaseConfig.client.auth.onAuthStateChange.listen((data) async {
    final event = data.event;
    final session = data.session;

    if (event == AuthChangeEvent.signedIn ||
        event == AuthChangeEvent.tokenRefreshed ||
        event == AuthChangeEvent.initialSession) {
      final userId = session?.user.id;
      if (userId != null) {
        debugPrint('[FCM] User signed in: $userId');

        if (!kIsWeb) {
          // Get and store FCM token for this user
          try {
            final token = await FirebaseMessaging.instance.getToken();
            debugPrint('[FCM] Current token: ${token?.substring(0, 20)}...');
            if (token != null && token.isNotEmpty) {
              await authService.updateProfile(fcmToken: token);
              debugPrint('[FCM] Stored token for user: $userId');
            }
          } catch (e) {
            debugPrint('[FCM] Failed to store token: $e');
          }
        }
      }
    }
    // No logout action needed for FCM (token stays on device)
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
