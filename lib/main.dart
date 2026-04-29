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
import 'presentation/providers/auth_providers.dart';
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

  // ── Step 1: Hive must be initialized before opening boxes ───────────────
  await Hive.initFlutter();

  // ── Step 2: Open all Hive boxes + Supabase in PARALLEL ──────────────────
  // All box opens are independent of each other, and Supabase
  // is a pure network operation — none of these depend on each other.
  await Future.wait([
    Hive.openBox(kPagesBox),
    Hive.openBox(kFoldersBox),
    Hive.openBox(kClipboardBox),
    Hive.openBox(kClipboardGroupsBox),
    Hive.openBox(kSettingsBox),
    Hive.openBox(kDiscoverCacheBox),
    Hive.openBox(kSyncQueueBox),
    Hive.openBox('ai_chats'),
    Hive.openBox(kExpertSessionsBox),
    Hive.openBox(kExpertPersonasCacheBox),
    SupabaseConfig.initialize(),   // runs while Hive boxes open
  ]);

  // Set up timeago arabic locales (synchronous — free)
  timeago.setLocaleMessages('ar', timeago.ArMessages());

  // Create global container for provider access outside widget tree
  final container = ProviderContainer();
  final authService = AuthService();

  // ── Step 3: Firebase init ────────────────────────────────────────────────
  // Firebase.initializeApp() reads google-services.json from APK (local, fast).
  // Everything AFTER initializeApp (permission, token) is non-blocking.
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp(); // fast — local file read

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;

      // Helper to persist FCM token to the user's profile
      Future<void> storeFcmToken(String? token) async {
        if (token == null || token.isEmpty) return;
        final user = SupabaseConfig.client.auth.currentUser;
        if (user != null) {
          try {
            await authService.updateProfile(fcmToken: token);
            debugPrint('[FCM] Stored token: ${token.substring(0, 20)}...');
          } catch (e) {
            debugPrint('[FCM] Failed to store token: $e');
          }
        }
      }

      // ── Non-blocking: permission dialog & network token fetch ─────────
      // The UI does NOT need these to start — fire and continue.
      unawaited(
        messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        ),
      );

      unawaited(
        messaging.getToken().then((token) {
          debugPrint('[FCM] Token: ${token?.substring(0, 20)}...');
          storeFcmToken(token);
        }).catchError((e) {
          debugPrint('[FCM] Failed to get token: $e');
        }),
      );

      // ── Event listeners (synchronous registration — free) ────────────
      messaging.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM] Token refreshed: ${newToken.substring(0, 20)}...');
        storeFcmToken(newToken);
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM] Foreground: ${message.notification?.title}');
        container.invalidate(notificationCountProvider);
      });

      // Resolve the in-app destination from an FCM payload.
      // For chat pushes: admins go to /admin/user-chats, users to /chat.
      Future<String> routeForMessage(RemoteMessage m) async {
        final type = (m.data['type'] ?? '').toString();
        if (type == 'chat') {
          try {
            final isAdmin = await container.read(hasAdminAccessProvider.future);
            return isAdmin ? '/admin/user-chats' : '/chat';
          } catch (_) {
            return '/chat';
          }
        }
        return '/notifications';
      }

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
        debugPrint('[FCM] Tapped: ${message.notification?.title}');
        container.invalidate(notificationCountProvider);
        final route = await routeForMessage(message);
        container.read(routerProvider).go(route);
      });

      // ── Non-blocking: check initial message ───────────────────────────
      unawaited(
        messaging.getInitialMessage().then((initialMessage) async {
          if (initialMessage != null) {
            debugPrint('[FCM] App opened from terminated notification');
            await Future.delayed(const Duration(milliseconds: 500));
            container.invalidate(notificationCountProvider);
            final route = await routeForMessage(initialMessage);
            container.read(routerProvider).go(route);
          }
        }),
      );
    } catch (e) {
      debugPrint('[Firebase/FCM] Initialization error: $e');
    }
  }

  // ── Store FCM token whenever auth state changes ─────────────────────────
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
  });

  // ── Seed dummy data on first launch (synchronous check) ─────────────────
  final settingsRepo = SettingsRepository();
  if (settingsRepo.isFirstLaunch()) {
    await DummyData.seed(
      pageRepo: PageRepository(),
      folderRepo: FolderRepository(),
      clipboardRepo: ClipboardRepository(),
    );
    await settingsRepo.setFirstLaunch(false);
  }

  // ── Splash version migration ─────────────────────────────────────────────
  final settingsBox = Hive.box(kSettingsBox);
  final storedSplashVersion = settingsBox.get(kSplashVersion, defaultValue: 0) as int;
  if (storedSplashVersion < kCurrentSplashVersion) {
    await settingsRepo.setHasSeenWelcomeScreen(false);
    await settingsBox.put(kSplashVersion, kCurrentSplashVersion);
    debugPrint('[Splash] Reset welcome screen flag (v$storedSplashVersion → v$kCurrentSplashVersion)');
  }

  // Set system UI style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Track app open — fire and forget, no blocking
  unawaited(AnalyticsService.trackAppOpen());

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
