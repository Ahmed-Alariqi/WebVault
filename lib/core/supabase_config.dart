import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration for WebVault Manager
class SupabaseConfig {
  static const String url = 'https://poepodtageytnzucrsmg.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBvZXBvZHRhZ2V5dG56dWNyc21nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyMjQyNTgsImV4cCI6MjA4NjgwMDI1OH0.V7km9Yd3_sHLUMnpJq4qh03Soj0SfS0LUblKatjhgnM';

  // OneSignal App ID removed — now using FCM directly
  // (see docs/ONESIGNAL_ROLLBACK.md for original value)

  /// Initialize the Supabase client
  static Future<void> initialize() async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  /// Get the Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;
}
