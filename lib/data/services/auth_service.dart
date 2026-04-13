import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart' as gs;
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/supabase_config.dart';
import '../../core/constants.dart';

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
      emailRedirectTo: kIsWeb
          ? 'http://localhost:5789'
          : 'io.supabase.webvault://login-callback',
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

  // --------------- Google Sign In ---------------

  Future<AuthResponse?> signInWithGoogle() async {
    // For Web, use Supabase's native OAuth redirect directly
    if (kIsWeb) {
      await _client.auth.signInWithOAuth(OAuthProvider.google);
      return null; // Return null since it redirects the page
    }

    const webClientId =
        '344480808876-tnmifigbi96sjgo7kgoqdaobk30oaqng.apps.googleusercontent.com';
    const iosClientId =
        '344480808876-r1qbuol918n8s6arkcrncap49off5tah.apps.googleusercontent.com';

    await gs.GoogleSignIn.instance.initialize(
      clientId: iosClientId,
      serverClientId: webClientId,
    );

    final googleUser = await gs.GoogleSignIn.instance.authenticate();

    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw 'No ID Token found from Google.';
    }

    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
  }

  // --------------- Sign Out ---------------

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // --------------- Password Reset (OTP) ---------------

  /// Step 1: Send recovery OTP email
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Step 2: Verify the 6-digit OTP token from the email
  Future<void> verifyRecoveryOtp(String email, String token) async {
    final res = await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.recovery,
    );
    if (res.session == null) {
      throw const AuthException('OTP verification failed');
    }
  }

  /// Step 3: Update the password (user must be authenticated via OTP first)
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  // --------------- Profile ---------------

  Future<Map<String, dynamic>?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final box = Hive.box(kSettingsBox);
    final cacheKey = 'profile_${user.id}';

    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      // Cache it for offline use
      box.put(cacheKey, response);
      return response;
    } catch (e) {
      // If offline or request fails, attempt to read from cache
      final cached = box.get(cacheKey);
      if (cached != null) {
        return Map<String, dynamic>.from(cached as Map);
      }
      rethrow;
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? username,
    String? avatarUrl,
    String? fcmToken,
    bool updateUsernameTimestamp = false,
  }) async {
    final user = currentUser;
    if (user == null) return;

    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (username != null) updates['username'] = username;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (fcmToken != null) {
      updates['fcm_token'] = fcmToken;
    }
    if (updateUsernameTimestamp) {
      updates['username_changed_at'] = DateTime.now().toUtc().toIso8601String();
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
