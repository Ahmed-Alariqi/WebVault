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

final currentUserProvider = StateProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUser;
});

// --------------- User Profile Provider ---------------

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  if (!authService.isAuthenticated) return null;
  return authService.getProfile();
});

// --------------- Is Admin Provider ---------------

final isAdminProvider = FutureProvider<bool>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return profile?['role'] == 'admin';
});

// --------------- Is Authenticated Provider ---------------

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.isAuthenticated;
});
