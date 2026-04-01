import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/auth_service.dart';

// --------------- Auth Service Provider ---------------

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// --------------- Auth State Provider ---------------

final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// --------------- Current User Provider ---------------

final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider); // Re-evaluate when auth state changes
  final authService = ref.watch(authServiceProvider);
  return authService.currentUser;
});

// --------------- User Profile Provider ---------------

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  ref.watch(authStateProvider); // Re-evaluate when auth state changes
  final authService = ref.watch(authServiceProvider);
  if (!authService.isAuthenticated) return null;
  return authService.getProfile();
});

// --------------- Is Admin Provider ---------------

final isAdminProvider = FutureProvider<bool>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return profile?['role'] == 'admin';
});

// --------------- Permissions System ---------------

/// All possible admin panel section keys
const kAllPermissions = [
  'analytics',
  'suggestions',
  'websites',
  'categories',
  'notifications',
  'in_app_messages',
  'users',
  'community',
  'advertisements',
  'collections',
];

/// Preset permissions for the Content Creator role
const kContentCreatorPermissions = [
  'websites',
  'categories',
  'notifications',
  'suggestions',
  'community',
];

/// Returns the effective list of permission keys for the current user
final userPermissionsProvider = FutureProvider<List<String>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  if (profile == null) return [];

  final role = profile['role'] as String? ?? 'user';
  if (role == 'admin') return List<String>.from(kAllPermissions);
  if (role == 'content_creator') {
    return List<String>.from(kContentCreatorPermissions);
  }

  // For regular users, check custom permissions
  final perms = profile['permissions'];
  if (perms is List) return perms.cast<String>();
  return [];
});

/// Returns true if the user should see the admin panel at all
final hasAdminAccessProvider = FutureProvider<bool>((ref) async {
  final perms = await ref.watch(userPermissionsProvider.future);
  return perms.isNotEmpty;
});

/// Family provider: check if user has access to a specific section
final hasPermissionProvider = FutureProvider.family<bool, String>((
  ref,
  section,
) async {
  final perms = await ref.watch(userPermissionsProvider.future);
  return perms.contains(section);
});

// --------------- Is Authenticated Provider ---------------

final isAuthenticatedProvider = Provider<bool>((ref) {
  ref.watch(authStateProvider); // Re-evaluate when auth state changes
  final authService = ref.watch(authServiceProvider);
  return authService.isAuthenticated;
});
