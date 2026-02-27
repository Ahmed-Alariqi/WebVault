import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A service to track user activities and metrics.
class AnalyticsService {
  static final _supabase = Supabase.instance.client;

  static Future<void> _logActivity(
    String type, [
    Map<String, dynamic>? metadata,
  ]) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return; // Only track authenticated users

      await _supabase.from('user_activity').insert({
        'user_id': user.id,
        'activity_type': type,
        'metadata': ?metadata,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Fail silently for analytics
      debugPrint('Analytics error ($type): $e');
    }
  }

  /// Triggers on app startup after successful auth or login.
  static Future<void> trackAppOpen() async {
    // Wait slightly to ensure auth state is settled
    await Future.delayed(const Duration(seconds: 2));
    final prefs = _supabase.auth.currentSession;
    if (prefs != null) {
      await _logActivity('app_open', {'platform': defaultTargetPlatform.name});
    }
  }

  /// Triggers when a user searches in the discover section.
  static Future<void> trackSearch(String query) async {
    if (query.trim().isEmpty) return;
    await _logActivity('search', {'query': query.trim()});
  }

  /// Triggers when a user bookmarks an item.
  static Future<void> trackBookmark(String websiteId, bool isBookmarked) async {
    await _logActivity('bookmark', {
      'website_id': websiteId,
      'action': isBookmarked ? 'added' : 'removed',
    });
  }

  /// Triggers when a user views an item's details.
  static Future<void> trackItemView(String websiteId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase.from('item_views').insert({
        'user_id': user.id,
        'website_id': websiteId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Analytics error (item_view): $e');
    }
  }
}
