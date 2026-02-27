import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _client = Supabase.instance.client;

class AdminAnalyticsData {
  final int totalUsers;
  final int activeToday;
  final int activeThisWeek;
  final int totalItemViews;
  final int totalBookmarks;
  final int totalNotifications;
  final int pendingSuggestions;

  final List<Map<String, dynamic>> dauData; // Daily Active Users over 15 days
  final List<Map<String, dynamic>> topViewedItems;
  final List<Map<String, dynamic>> topBookmarkedItems;
  final List<Map<String, dynamic>> topSearches;

  const AdminAnalyticsData({
    required this.totalUsers,
    required this.activeToday,
    required this.activeThisWeek,
    required this.totalItemViews,
    required this.totalBookmarks,
    required this.totalNotifications,
    required this.pendingSuggestions,
    required this.dauData,
    required this.topViewedItems,
    required this.topBookmarkedItems,
    required this.topSearches,
  });
}

final adminAnalyticsProvider = FutureProvider<AdminAnalyticsData>((ref) async {
  // 1. Basic Counts
  final profilesCount = await _client.from('profiles').count(CountOption.exact);
  final itemViewsCount = await _client
      .from('item_views')
      .count(CountOption.exact);
  final bookmarksCount = await _client
      .from('discover_bookmarks')
      .count(CountOption.exact);
  final notificationsCount = await _client
      .from('notifications')
      .count(CountOption.exact);
  final suggestionsRes = await _client
      .from('page_suggestions')
      .select('id')
      .eq('status', 'pending')
      .count(CountOption.exact);
  final suggestionsCount = suggestionsRes.count;

  final today = DateTime.now();
  final startOfToday = DateTime(
    today.year,
    today.month,
    today.day,
  ).toUtc().toIso8601String();
  final startOfWeek = today
      .subtract(Duration(days: today.weekday - 1))
      .toUtc()
      .toIso8601String();

  // 2. Active Users (Unique users who opened app/logged in)
  dynamic todayActive = 0;
  dynamic weekActive = 0;
  try {
    todayActive = await _client.rpc(
      'get_unique_active_users_count',
      params: {'start_date': startOfToday},
    );
  } catch (_) {}

  try {
    weekActive = await _client.rpc(
      'get_unique_active_users_count',
      params: {'start_date': startOfWeek},
    );
  } catch (_) {}

  // 3. DAU Chart Data (Last 15 days)
  final dauDataRes = await _client
      .rpc('get_daily_active_users', params: {'days': 15})
      .catchError((_) => <Map<String, dynamic>>[]);

  // 4. Top Viewed Items
  final topViewedRes = await _client
      .from('item_views')
      .select('website_id, websites!inner(title, image_url)')
      // Use 15 days filter for local aggregation since the cleanup handles older data anyway,
      // but ensure we limit to recent to match logic.
      .gte(
        'created_at',
        DateTime.now()
            .subtract(const Duration(days: 15))
            .toUtc()
            .toIso8601String(),
      )
      .limit(1000)
      .catchError((_) => <Map<String, dynamic>>[]);

  final viewCounts = <String, int>{};
  final siteCache = <String, Map<String, dynamic>>{};
  for (final row in (topViewedRes as List)) {
    final wid = row['website_id'] as String;
    viewCounts[wid] = (viewCounts[wid] ?? 0) + 1;
    siteCache[wid] = row['websites'] as Map<String, dynamic>;
  }

  var topViewed = viewCounts.entries.map((e) {
    return {
      'website_id': e.key,
      'views': e.value,
      'title': siteCache[e.key]?['title'] ?? 'Unknown',
      'image_url': siteCache[e.key]?['image_url'],
    };
  }).toList()..sort((a, b) => (b['views'] as int).compareTo(a['views'] as int));

  if (topViewed.length > 10) topViewed = topViewed.sublist(0, 10);

  // 5. Top Bookmarked Items
  final topBookmarkedRes = await _client
      .from('discover_bookmarks')
      .select('website_id, websites!inner(title, image_url)')
      .gte(
        'created_at',
        DateTime.now()
            .subtract(const Duration(days: 15))
            .toUtc()
            .toIso8601String(),
      )
      .limit(1000)
      .catchError((_) => <Map<String, dynamic>>[]);

  final bookmarkCounts = <String, int>{};
  for (final row in (topBookmarkedRes as List)) {
    final wid = row['website_id'] as String;
    bookmarkCounts[wid] = (bookmarkCounts[wid] ?? 0) + 1;
    siteCache[wid] = row['websites'] as Map<String, dynamic>; // Reuse cache
  }

  var topBookmarked =
      bookmarkCounts.entries.map((e) {
        return {
          'website_id': e.key,
          'bookmarks': e.value,
          'title': siteCache[e.key]?['title'] ?? 'Unknown',
          'image_url': siteCache[e.key]?['image_url'],
        };
      }).toList()..sort(
        (a, b) => (b['bookmarks'] as int).compareTo(a['bookmarks'] as int),
      );

  if (topBookmarked.length > 10) topBookmarked = topBookmarked.sublist(0, 10);

  // 6. Top Searches
  final topSearchesRes = await _client
      .rpc('get_top_searches', params: {'days_limit': 15, 'result_limit': 20})
      .catchError((_) => <Map<String, dynamic>>[]);

  // Filter out searches with 2 or less counts
  final filteredSearches = (topSearchesRes as List)
      .cast<Map<String, dynamic>>()
      .where((s) => (s['search_count'] as num) > 2)
      .toList();

  return AdminAnalyticsData(
    totalUsers: profilesCount,
    activeToday: todayActive is num ? todayActive.toInt() : 0,
    activeThisWeek: weekActive is num ? weekActive.toInt() : 0,
    totalItemViews: itemViewsCount,
    totalBookmarks: bookmarksCount,
    totalNotifications: notificationsCount,
    pendingSuggestions: suggestionsCount,
    dauData: (dauDataRes as List).cast<Map<String, dynamic>>(),
    topViewedItems: topViewed,
    topBookmarkedItems: topBookmarked,
    topSearches: filteredSearches,
  );
});
