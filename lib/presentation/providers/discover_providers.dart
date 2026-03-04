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

// --------------- Paginated Discover (10 items/page) ---------------

const int kDiscoverPageSize = 10;

class PaginatedWebsitesState {
  final List<WebsiteModel> items;
  final bool isLoading;
  final bool hasMore;
  final bool isInitialLoad;

  const PaginatedWebsitesState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.isInitialLoad = true,
  });

  PaginatedWebsitesState copyWith({
    List<WebsiteModel>? items,
    bool? isLoading,
    bool? hasMore,
    bool? isInitialLoad,
  }) {
    return PaginatedWebsitesState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      isInitialLoad: isInitialLoad ?? this.isInitialLoad,
    );
  }
}

class PaginatedWebsitesNotifier extends StateNotifier<PaginatedWebsitesState> {
  final String?
  _filterField; // e.g. 'is_trending', 'is_popular', 'is_featured', or null for all
  final Ref _ref;

  PaginatedWebsitesNotifier(this._ref, this._filterField)
    : super(const PaginatedWebsitesState()) {
    loadMore();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);

    try {
      final categoryId = _ref.read(selectedCategoryProvider);
      final search = _ref.read(discoverSearchProvider);
      final contentType = _ref.read(selectedContentTypeProvider);

      var query = _client.from('websites').select().eq('is_active', true);

      if (_filterField != null) {
        query = query.eq(_filterField, true);
      }
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }
      if (contentType != null) {
        query = query.eq('content_type', contentType);
      }
      if (search.isNotEmpty) {
        query = query.or('title.ilike.%$search%,description.ilike.%$search%');
      }

      final from = state.items.length;
      final to = from + kDiscoverPageSize - 1;

      final response = await query
          .order('created_at', ascending: false)
          .range(from, to);

      final newItems = (response as List)
          .map((e) => WebsiteModel.fromJson(e))
          .toList();
      final filtered = _filterActive(newItems);

      state = state.copyWith(
        items: [...state.items, ...filtered],
        isLoading: false,
        hasMore: newItems.length >= kDiscoverPageSize,
        isInitialLoad: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, isInitialLoad: false);
    }
  }

  void reset() {
    state = const PaginatedWebsitesState();
    loadMore();
  }
}

// Provider for "All / Newly Added" section
final discoverPaginatedProvider =
    StateNotifierProvider.autoDispose<
      PaginatedWebsitesNotifier,
      PaginatedWebsitesState
    >((ref) {
      // Watch filters so the provider rebuilds when they change
      ref.watch(selectedCategoryProvider);
      ref.watch(discoverSearchProvider);
      ref.watch(selectedContentTypeProvider);
      return PaginatedWebsitesNotifier(ref, null);
    });

// Provider for "Trending" section
final trendingPaginatedProvider =
    StateNotifierProvider.autoDispose<
      PaginatedWebsitesNotifier,
      PaginatedWebsitesState
    >((ref) {
      ref.watch(selectedCategoryProvider);
      ref.watch(discoverSearchProvider);
      ref.watch(selectedContentTypeProvider);
      return PaginatedWebsitesNotifier(ref, 'is_trending');
    });

// Provider for "Popular" section
final popularPaginatedProvider =
    StateNotifierProvider.autoDispose<
      PaginatedWebsitesNotifier,
      PaginatedWebsitesState
    >((ref) {
      ref.watch(selectedCategoryProvider);
      ref.watch(discoverSearchProvider);
      ref.watch(selectedContentTypeProvider);
      return PaginatedWebsitesNotifier(ref, 'is_popular');
    });

// Provider for "Featured" section
final featuredPaginatedProvider =
    StateNotifierProvider.autoDispose<
      PaginatedWebsitesNotifier,
      PaginatedWebsitesState
    >((ref) {
      ref.watch(selectedCategoryProvider);
      ref.watch(discoverSearchProvider);
      ref.watch(selectedContentTypeProvider);
      return PaginatedWebsitesNotifier(ref, 'is_featured');
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

// --------------- Discover Bookmarks ---------------

final showBookmarksOnlyProvider = StateProvider<bool>((ref) => false);

final bookmarkedIdsProvider = FutureProvider<Set<String>>((ref) async {
  final user = _client.auth.currentUser;
  if (user == null) return {};
  final response = await _client
      .from('discover_bookmarks')
      .select('website_id')
      .eq('user_id', user.id);
  return (response as List).map((e) => e['website_id'] as String).toSet();
});

final bookmarkedWebsitesProvider = FutureProvider<List<WebsiteModel>>((
  ref,
) async {
  final user = _client.auth.currentUser;
  if (user == null) return [];
  // Get bookmarked website IDs
  final bookmarkRows = await _client
      .from('discover_bookmarks')
      .select('website_id')
      .eq('user_id', user.id)
      .order('created_at', ascending: false);
  final ids = (bookmarkRows as List)
      .map((e) => e['website_id'] as String)
      .toList();
  if (ids.isEmpty) return [];
  // Fetch the websites
  final response = await _client.from('websites').select().inFilter('id', ids);
  final items = (response as List)
      .map((e) => WebsiteModel.fromJson(e))
      .toList();
  // Preserve bookmark order
  final idOrder = {for (var i = 0; i < ids.length; i++) ids[i]: i};
  items.sort((a, b) => (idOrder[a.id] ?? 999).compareTo(idOrder[b.id] ?? 999));
  return _filterActive(items);
});

Future<void> toggleBookmark(String websiteId) async {
  final user = _client.auth.currentUser;
  if (user == null) return;
  // Check if already bookmarked
  final existing = await _client
      .from('discover_bookmarks')
      .select('id')
      .eq('user_id', user.id)
      .eq('website_id', websiteId)
      .maybeSingle();
  if (existing != null) {
    await _client.from('discover_bookmarks').delete().eq('id', existing['id']);
  } else {
    await _client.from('discover_bookmarks').insert({
      'user_id': user.id,
      'website_id': websiteId,
    });
  }
}
