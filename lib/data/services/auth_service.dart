import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_config.dart';

/// Service handling all Supabase Auth operations
class AuthService {
  final SupabaseClient _client = SupabaseConfig.client;

  // --------------- Getters ---------------

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // --------------- Sign Up ---------------

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? username,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'username': username},
    );
    return response;
  }

  // --------------- Sign In ---------------

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  // --------------- Sign Out ---------------

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // --------------- Password Reset ---------------

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // --------------- Profile ---------------

  Future<Map<String, dynamic>?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    return response;
  }

  Future<void> updateProfile({
    String? fullName,
    String? username,
    String? avatarUrl,
    String? onesignalPlayerId,
  }) async {
    final user = currentUser;
    if (user == null) return;

    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (username != null) updates['username'] = username;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (onesignalPlayerId != null) {
      updates['onesignal_player_id'] = onesignalPlayerId;
    }

    if (updates.isNotEmpty) {
      await _client.from('profiles').update(updates).eq('id', user.id);
    }
  }

  Future<String?> uploadAvatar(File imageFile) async {
    final user = currentUser;
    if (user == null) return null;

    final fileName = '${user.id}/avatar.jpg';
    await _client.storage
        .from('avatars')
        .upload(
          fileName,
          imageFile,
          fileOptions: const FileOptions(upsert: true),
        );

    final publicUrl = _client.storage.from('avatars').getPublicUrl(fileName);

    await updateProfile(avatarUrl: publicUrl);
    return publicUrl;
  }

  // --------------- Role Check ---------------

  Future<String> getUserRole() async {
    final profile = await getProfile();
    return profile?['role'] as String? ?? 'user';
  }

  Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role == 'admin';
  }
}
