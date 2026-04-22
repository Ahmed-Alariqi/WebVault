import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/supabase_config.dart';
import '../../data/models/website_model.dart';
import '../../data/models/suggestion_model.dart';
import '../../presentation/providers/providers.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/pages/pages_screen.dart';
import '../../features/discover/discover_screen.dart';
import '../../features/clipboard/clipboard_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/about_screen.dart';
import '../../features/settings/pin_lock_screen.dart';
import '../../features/settings/security_settings_screen.dart';
import '../../features/settings/clipboard_settings_screen.dart';
import '../../features/pages/add_edit_page_screen.dart';
import '../../features/folders/folders_screen.dart';
import '../../features/folders/folder_detail_screen.dart';
import '../../features/browser/browser_screen.dart';
import '../../features/discover/discover_browser_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/admin/admin_dashboard_screen.dart';
import '../../features/admin/manage_websites_screen.dart';
import '../../features/admin/manage_categories_screen.dart';
import '../../features/admin/send_notification_screen.dart';
import '../../features/admin/manage_in_app_messages_screen.dart';
import '../../features/admin/manage_users_screen.dart';
import '../../features/admin/admin_suggestions_screen.dart';
import '../../features/admin/admin_analytics_screen.dart';
import '../../features/admin/admin_community_screen.dart';
import '../../features/admin/add_edit_website_screen.dart';
import '../../features/admin/manage_advertisements_screen.dart';
import '../../features/admin/manage_collections_screen.dart';
import '../../features/admin/edit_advertisement_sheet.dart';
import '../../features/admin/admin_events_screen.dart';
import '../../features/discover/notifications_screen.dart';
import '../../features/discover/community_screen.dart';
import '../../features/discover/community_post_detail.dart';
import '../../features/discover/giveaway_detail_screen.dart';
import '../../data/models/community_model.dart';
import '../../data/models/collection_model.dart';
import '../../presentation/widgets/app_shell.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/admin/manage_user_chats_screen.dart';
import '../../features/admin/admin_chat_screen.dart';
import '../../features/discover/collection_items_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/welcome_splash_screen.dart';
import '../../domain/models/advertisement.dart';
import '../../data/repositories/settings_repository.dart';
import '../../features/discover/advertisement_detail_screen.dart';
import '../../features/ai_assistant/ai_chat_screen.dart';
import '../../features/ai_assistant/zad_share_hub_screen.dart';
import '../../features/ai_assistant/external_ai_chat_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// A listenable that notifies GoRouter when auth or lock state changes
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(Ref ref) {
    SupabaseConfig.client.auth.onAuthStateChange.listen((_) {
      // Skip notifying during OTP recovery to prevent auto-redirect
      if (ForgotPasswordScreen.isRecoveryInProgress) return;
      notifyListeners();
    });

    ref.listen(appLockedProvider, (prev, next) {
      if (prev != next) notifyListeners();
    });

    ref.listen(settingsProvider.select((s) => s['pinEnabled'] == true), (
      prev,
      next,
    ) {
      if (prev != next) notifyListeners();
    });
  }
}

/// Single GoRouter instance — never recreated
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isLoggedIn = SupabaseConfig.client.auth.currentSession != null;
      final location = state.matchedLocation;

      final settings = ref.read(settingsProvider);
      final isLocked = ref.read(appLockedProvider);

      // Auth & onboarding routes (no guard)
      final authRoutes = [
        '/login',
        '/signup',
        '/forgot-password',
        '/onboarding',
        '/welcome',
      ];
      final onAuthRoute = authRoutes.contains(location);

      final settingsRepo = SettingsRepository();

      // 1. Welcome Screen Guard (First-ever run)
      if (!settingsRepo.hasSeenWelcomeScreen()) {
        if (location == '/welcome') return null;
        return '/welcome';
      }

      // Not logged in
      if (!isLoggedIn) {
        // Check onboarding completion first
        if (!settingsRepo.isOnboardingCompleted()) {
          if (location == '/onboarding') return null;
          return '/onboarding';
        }
        if (onAuthRoute) return null;
        return '/login';
      }

      // Logged in but on auth route — redirect to dashboard
      // EXCEPT during OTP recovery flow (user needs to stay on /forgot-password)
      if (isLoggedIn && onAuthRoute) {
        if (location == '/forgot-password' &&
            ForgotPasswordScreen.isRecoveryInProgress) {
          return null; // Stay on forgot-password during recovery
        }
        return '/dashboard';
      }

      // PIN lock guard
      final pinEnabled = settings['pinEnabled'] == true;
      final goingToPin = location == '/pin-lock';

      if (pinEnabled && isLocked && !goingToPin) {
        return '/pin-lock';
      }
      if (goingToPin && (!pinEnabled || !isLocked)) {
        return '/dashboard';
      }

      // Admin route guards
      if (location.startsWith('/admin')) {
        final profile = ref.read(userProfileProvider).valueOrNull;

        // If profile is still loading, we might restrict access temporarily.
        // It's safer to block until we know their role.
        if (profile == null) return '/dashboard';

        final role = profile['role'] as String? ?? 'user';
        final List<String> perms;
        if (role == 'admin') {
          perms = const [
            'analytics',
            'suggestions',
            'websites',
            'categories',
            'notifications',
            'in_app_messages',
            'users',
            'community',
            'advertisements',
            'events',
          ];
        } else if (role == 'content_creator') {
          perms = const [
            'websites',
            'categories',
            'notifications',
            'suggestions',
            'community',
            'events',
          ];
        } else {
          final p = profile['permissions'];
          perms = p is List ? p.cast<String>() : [];
        }

        if (perms.isEmpty) return '/dashboard';

        if (location.startsWith('/admin/analytics') &&
            !perms.contains('analytics')) {
          return '/admin';
        }
        if (location.startsWith('/admin/suggestions') &&
            !perms.contains('suggestions')) {
          return '/admin';
        }
        if (location.startsWith('/admin/websites') &&
            !perms.contains('websites')) {
          return '/admin';
        }
        if (location.startsWith('/admin/categories') &&
            !perms.contains('categories')) {
          return '/admin';
        }
        if (location.startsWith('/admin/notifications') &&
            !perms.contains('notifications')) {
          return '/admin';
        }
        if (location.startsWith('/admin/in-app-messages') &&
            !perms.contains('in_app_messages')) {
          return '/admin';
        }
        if (location.startsWith('/admin/users') && !perms.contains('users')) {
          return '/admin';
        }
        if (location.startsWith('/admin/community') &&
            !perms.contains('community')) {
          return '/admin';
        }
        if ((location.startsWith('/admin/user-chats') ||
                location.startsWith('/admin/chats')) &&
            !perms.contains('users') &&
            !perms.contains('community')) {
          return '/admin';
        }
        if (location.startsWith('/admin/advertisements') &&
            !perms.contains('advertisements')) {
          return '/admin';
        }
        if (location.startsWith('/admin/events') && !perms.contains('events')) {
          return '/admin';
        }
      }

      return null;
    },
    routes: [
      // ---- Welcome Splash (first launch only) ----
      GoRoute(
        path: '/welcome',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WelcomeSplashScreen(),
      ),

      // ---- Onboarding Route ----
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ---- Auth Routes ----
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // ---- PIN Lock ----
      GoRoute(
        path: '/pin-lock',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PinLockScreen(),
      ),

      // ---- Main App Shell (5 tabs) ----
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/pages',
            builder: (context, state) => const PagesScreen(),
          ),
          GoRoute(
            path: '/discover',
            builder: (context, state) => const DiscoverScreen(),
          ),
          GoRoute(
            path: '/clipboard',
            builder: (context, state) => const ClipboardScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/community',
            builder: (context, state) => const CommunityScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),

      // ---- Full-screen routes ----
      GoRoute(
        path: '/security-settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SecuritySettingsScreen(),
      ),
      GoRoute(
        path: '/clipboard-settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ClipboardSettingsScreen(),
      ),
      GoRoute(
        path: '/about',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/add-page',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddEditPageScreen(),
      ),
      GoRoute(
        path: '/edit-page/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AddEditPageScreen(pageId: id);
        },
      ),
      GoRoute(
        path: '/folders',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FoldersScreen(),
      ),
      GoRoute(
        path: '/folders/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return FolderDetailScreen(folderId: id);
        },
      ),
      GoRoute(
        path: '/browser/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BrowserScreen(pageId: id);
        },
      ),
      GoRoute(
        path: '/discover-browser',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final site = state.extra as WebsiteModel;
          return DiscoverBrowserScreen(site: site);
        },
      ),
      GoRoute(
        path: '/community/post/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final post = state.extra as CommunityPost;
          return CommunityPostDetail(post: post);
        },
      ),
      GoRoute(
        path: '/admin/advertisements',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ManageAdvertisementsScreen(),
      ),
      GoRoute(
        path: '/admin/advertisements/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final existing = state.extra as Advertisement?;
          return EditAdvertisementSheet(ad: existing);
        },
      ),

      // ---- Profile & Account ----
      GoRoute(
        path: '/chat',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(),
      ),

      // ---- Admin Routes ----
      GoRoute(
        path: '/admin',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/websites',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ManageWebsitesScreen(),
      ),
      GoRoute(
        path: '/admin/websites/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          WebsiteModel? existing;
          SuggestionModel? suggestion;

          if (extra is WebsiteModel) {
            existing = extra;
          } else if (extra is Map) {
            existing = extra['existing'] as WebsiteModel?;
            suggestion = extra['suggestion'] as SuggestionModel?;
          }

          return AddEditWebsiteScreen(
            existing: existing,
            suggestion: suggestion,
          );
        },
      ),
      GoRoute(
        path: '/admin/categories',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ManageCategoriesScreen(),
      ),
      GoRoute(
        path: '/admin/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SendNotificationScreen(),
      ),
      GoRoute(
        path: '/admin/in-app-messages',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ManageInAppMessagesScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ManageUsersScreen(),
      ),
      GoRoute(
        path: '/admin/community',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminCommunityScreen(),
      ),
      GoRoute(
        path: '/admin/suggestions',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminSuggestionsScreen(),
      ),
      GoRoute(
        path: '/admin/analytics',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminAnalyticsScreen(),
      ),
      GoRoute(
        path: '/admin/collections',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ManageCollectionsScreen(),
      ),
      GoRoute(
        path: '/admin/events',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminEventsScreen(),
      ),
      GoRoute(
        path: '/giveaway/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return GiveawayDetailScreen(giveawayId: id);
        },
      ),
      GoRoute(
        path: '/collection-items',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final col = state.extra as CollectionModel;
          return CollectionItemsScreen(collection: col);
        },
      ),
      GoRoute(
        path: '/advertisement-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final ad = state.extra as Advertisement;
          return AdvertisementDetailScreen(advertisement: ad);
        },
      ),
      GoRoute(
        path: '/admin/user-chats',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ManageUserChatsScreen(),
      ),
      GoRoute(
        path: '/admin/chats/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AdminChatScreen(conversationId: id);
        },
      ),
      GoRoute(
        path: '/pin-setup',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PinLockScreen(isSetup: true),
      ),
      // ---- AI Assistant Chat ----
      GoRoute(
        path: '/ai-chat',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final site = state.extra as WebsiteModel;
          return AiChatScreen(site: site);
        },
      ),
      // ---- Share Hub & External AI ----
      GoRoute(
        path: '/share-hub',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ZadShareHubScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/external-ai-assistant',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final text = state.extra as String? ?? state.uri.queryParameters['text'] ?? '';
          return ExternalAiChatScreen(initialText: text);
        },
      ),
    ],
  );
});
