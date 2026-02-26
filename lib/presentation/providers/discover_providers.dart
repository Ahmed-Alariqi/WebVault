import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_config.dart';
import '../../data/models/website_model.dart';
import '../../data/models/tool_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/notification_model.dart';

// --------------- Supabase Client ---------------

final _client = SupabaseConfig.client;

// --------------- Helper: filter expired + inactive ---------------

List<WebsiteModel> _filterActive(List<WebsiteModel> items) {
  final now = DateTime.now();
  return items.where((item) {
    if (!item.isActive) return false;
    if (item.expiresAt != null && item.expiresAt!.isBefore(now)) return false;
    return true;
  }).toList();
}

// --------------- Discover Items ---------------

final discoverWebsitesProvider = FutureProvider<List<WebsiteModel>>((
  ref,
) async {
  final categoryId = ref.watch(selectedCategoryProvider);
  final search = ref.watch(discoverSearchProvider);
  final contentType = ref.watch(selectedContentTypeProvider);

  var query = _client.from('websites').select().eq('is_active', true);

  if (categoryId != null) {
    query = query.eq('category_id', categoryId);
  }
  if (contentType != null) {
    query = query.eq('content_type', contentType);
  }
  if (search.isNotEmpty) {
    query = query.or('title.ilike.%$search%,description.ilike.%$search%');
  }

  final response = await query.order('created_at', ascending: false);
  final items = (response as List)
      .map((e) => WebsiteModel.fromJson(e))
      .toList();
  return _filterActive(items);
});

final trendingWebsitesProvider = FutureProvider<List<WebsiteModel>>((
  ref,
) async {
  final categoryId = ref.watch(selectedCategoryProvider);
  final search = ref.watch(discoverSearchProvider);
  final contentType = ref.watch(selectedContentTypeProvider);

  var query = _client
      .from('websites')
      .select()
      .eq('is_trending', true)
      .eq('is_active', true);

  if (categoryId != null) {
    query = query.eq('category_id', categoryId);
  }
  if (contentType != null) {
    query = query.eq('content_type', contentType);
  }
  if (search.isNotEmpty) {
    query = query.or('title.ilike.%$search%,description.ilike.%$search%');
  }

  final response = await query.order('created_at', ascending: false).limit(20);
  final items = (response as List)
      .map((e) => WebsiteModel.fromJson(e))
      .toList();
  return _filterActive(items);
});

final popularWebsitesProvider = FutureProvider<List<WebsiteModel>>((ref) async {
  final categoryId = ref.watch(selectedCategoryProvider);
  final search = ref.watch(discoverSearchProvider);
  final contentType = ref.watch(selectedContentTypeProvider);

  var query = _client
      .from('websites')
      .select()
      .eq('is_popular', true)
      .eq('is_active', true);

  if (categoryId != null) {
    query = query.eq('category_id', categoryId);
  }
  if (contentType != null) {
    query = query.eq('content_type', contentType);
  }
  if (search.isNotEmpty) {
    query = query.or('title.ilike.%$search%,description.ilike.%$search%');
  }

  final response = await query.order('created_at', ascending: false).limit(20);
  final items = (response as List)
      .map((e) => WebsiteModel.fromJson(e))
      .toList();
  return _filterActive(items);
});

final featuredWebsitesProvider = FutureProvider<List<WebsiteModel>>((
  ref,
) async {
  final categoryId = ref.watch(selectedCategoryProvider);
  final search = ref.watch(discoverSearchProvider);
  final contentType = ref.watch(selectedContentTypeProvider);

  var query = _client
      .from('websites')
      .select()
      .eq('is_featured', true)
      .eq('is_active', true);

  if (categoryId != null) {
    query = query.eq('category_id', categoryId);
  }
  if (contentType != null) {
    query = query.eq('content_type', contentType);
  }
  if (search.isNotEmpty) {
    query = query.or('title.ilike.%$search%,description.ilike.%$search%');
  }

  final response = await query.order('created_at', ascending: false).limit(20);
  final items = (response as List)
      .map((e) => WebsiteModel.fromJson(e))
      .toList();
  return _filterActive(items);
});

// --------------- Tools ---------------

final discoverToolsProvider = FutureProvider<List<ToolModel>>((ref) async {
  final search = ref.watch(discoverSearchProvider);

  var query = _client.from('tools').select();

  if (search.isNotEmpty) {
    query = query.or('name.ilike.%$search%,description.ilike.%$search%');
  }

  final response = await query.order('created_at', ascending: false);
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
final selectedContentTypeProvider = StateProvider<String?>((ref) => null);

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
