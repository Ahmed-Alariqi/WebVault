import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration for WebVault Manager
class SupabaseConfig {
  static const String url = 'https://poepodtageytnzucrsmg.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBvZXBvZHRhZ2V5dG56dWNyc21nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyMjQyNTgsImV4cCI6MjA4NjgwMDI1OH0.V7km9Yd3_sHLUMnpJq4qh03Soj0SfS0LUblKatjhgnM';

  static const String oneSignalAppId =
      '488da896-9e12-4b54-ac4c-b766a9358d55'; // TODO: Replace with your actual OneSignal App ID

  /// Initialize the Supabase client
  static Future<void> initialize() async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  /// Get the Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;
}
