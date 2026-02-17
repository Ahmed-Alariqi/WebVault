import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_config.dart';
import '../../data/models/website_model.dart';
import '../../data/models/tool_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/notification_model.dart';

// --------------- Supabase Client ---------------

final _client = SupabaseConfig.client;

// --------------- Websites ---------------

final discoverWebsitesProvider = FutureProvider<List<WebsiteModel>>((
  ref,
) async {
  final response = await _client
      .from('websites')
      .select()
      .order('created_at', ascending: false);
  return (response as List).map((e) => WebsiteModel.fromJson(e)).toList();
});

final trendingWebsitesProvider = FutureProvider<List<WebsiteModel>>((
  ref,
) async {
  final response = await _client
      .from('websites')
      .select()
      .eq('is_trending', true)
      .order('created_at', ascending: false)
      .limit(10);
  return (response as List).map((e) => WebsiteModel.fromJson(e)).toList();
});

final popularWebsitesProvider = FutureProvider<List<WebsiteModel>>((ref) async {
  final response = await _client
      .from('websites')
      .select()
      .eq('is_popular', true)
      .order('created_at', ascending: false)
      .limit(10);
  return (response as List).map((e) => WebsiteModel.fromJson(e)).toList();
});

final featuredWebsitesProvider = FutureProvider<List<WebsiteModel>>((
  ref,
) async {
  final response = await _client
      .from('websites')
      .select()
      .eq('is_featured', true)
      .order('created_at', ascending: false)
      .limit(10);
  return (response as List).map((e) => WebsiteModel.fromJson(e)).toList();
});

// --------------- Tools ---------------

final discoverToolsProvider = FutureProvider<List<ToolModel>>((ref) async {
  final response = await _client
      .from('tools')
      .select()
      .order('created_at', ascending: false);
  return (response as List).map((e) => ToolModel.fromJson(e)).toList();
});

// --------------- Categories ---------------

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final response = await _client
      .from('categories')
      .select()
      .order('sort_order');
  return (response as List).map((e) => CategoryModel.fromJson(e)).toList();
});

// --------------- Notifications ---------------

final notificationsProvider = FutureProvider<List<NotificationModel>>((
  ref,
) async {
  final response = await _client
      .from('notifications')
      .select()
      .order('created_at', ascending: false)
      .limit(50);
  return (response as List).map((e) => NotificationModel.fromJson(e)).toList();
});

// --------------- Search / Filter ---------------

final discoverSearchProvider = StateProvider<String>((ref) => '');
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// --------------- User Saved ---------------

final savedWebsiteIdsProvider = FutureProvider<Set<String>>((ref) async {
  final user = _client.auth.currentUser;
  if (user == null) return {};
  final response = await _client
      .from('user_saved_websites')
      .select('website_id')
      .eq('user_id', user.id);
  return (response as List).map((e) => e['website_id'] as String).toSet();
});
