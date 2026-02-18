import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/supabase_config.dart';
import '../../presentation/providers/providers.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/pages/pages_screen.dart';
import '../../features/discover/discover_screen.dart';
import '../../features/clipboard/clipboard_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/pin_lock_screen.dart';
import '../../features/settings/security_settings_screen.dart';
import '../../features/pages/add_edit_page_screen.dart';
import '../../features/folders/folders_screen.dart';
import '../../features/folders/folder_detail_screen.dart';
import '../../features/browser/browser_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/admin/admin_dashboard_screen.dart';
import '../../features/admin/manage_websites_screen.dart';
import '../../features/admin/manage_categories_screen.dart';
import '../../features/admin/send_notification_screen.dart';
import '../../features/admin/manage_users_screen.dart';
import '../../features/admin/admin_suggestions_screen.dart';
import '../../features/discover/notifications_screen.dart';
import '../../presentation/widgets/app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// A listenable that notifies GoRouter when auth state changes
class AuthNotifier extends ChangeNotifier {
  AuthNotifier() {
    SupabaseConfig.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }
}

final _authNotifier = AuthNotifier();

/// Single GoRouter instance — never recreated
final routerProvider = Provider<GoRouter>((ref) {
  // Watch settings for PIN lock feature
  final settings = ref.watch(settingsProvider);
  final isLocked = ref.watch(appLockedProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: _authNotifier,
    redirect: (context, state) {
      final isLoggedIn = SupabaseConfig.client.auth.currentSession != null;
      final location = state.matchedLocation;

      // Auth routes (no guard)
      final authRoutes = ['/login', '/signup', '/forgot-password'];
      final onAuthRoute = authRoutes.contains(location);

      // Not logged in — force to login (unless already on an auth route)
      if (!isLoggedIn) {
        return onAuthRoute ? null : '/login';
      }

      // Logged in but on auth route — redirect to dashboard
      if (isLoggedIn && onAuthRoute) {
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

      return null;
    },
    routes: [
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

      // ---- Profile ----
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
        path: '/admin/users',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ManageUsersScreen(),
      ),
      GoRoute(
        path: '/admin/suggestions',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminSuggestionsScreen(),
      ),
      GoRoute(
        path: '/pin-setup',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PinLockScreen(isSetup: true),
      ),
    ],
  );
});
