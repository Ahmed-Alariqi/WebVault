import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_config.dart';
import '../../data/models/website_model.dart';
import '../../data/models/tool_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/collection_model.dart';
import '../../presentation/providers/membership_providers.dart';
import 'providers.dart';

// --------------- Supabase Client ---------------

final _client = SupabaseConfig.client;

// --------------- Featured Collections ---------------

final featuredCollectionsProvider = FutureProvider<List<CollectionModel>>((
  ref,
) async {
  final response = await _client
      .from('featured_collections')
      .select('*, collection_items(*, websites(*))')
      .eq('is_active', true)
      .order('sort_order', ascending: true);

  return (response as List).map((e) => CollectionModel.fromJson(e)).toList();
});

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
  final Object? error;

  const PaginatedWebsitesState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.isInitialLoad = true,
    this.error,
  });

  PaginatedWebsitesState copyWith({
    List<WebsiteModel>? items,
    bool? isLoading,
    bool? hasMore,
    bool? isInitialLoad,
    Object? error,
    bool clearError = false,
  }) {
    return PaginatedWebsitesState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      isInitialLoad: isInitialLoad ?? this.isInitialLoad,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PaginatedWebsitesNotifier extends StateNotifier<PaginatedWebsitesState> {
  final String?
  _filterField; // e.g. 'is_trending', 'is_popular', 'is_featured', or null for all
  final Ref _ref;
  int _dbOffset = 0;

  PaginatedWebsitesNotifier(this._ref, this._filterField)
    : super(const PaginatedWebsitesState()) {
    loadMore();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final categoryId = _ref.read(selectedCategoryProvider);
      final search = _ref.read(discoverSearchProvider);
      final contentType = _ref.read(selectedContentTypeProvider);
      final pricingModel = _ref.read(selectedPricingModelProvider);
      final sortBy = _ref.read(discoverSortByProvider);
      final showPremiumOnly = _ref.read(showPremiumOnlyProvider);

      var query = _client.from('websites').select().eq('is_active', true);

      if (_filterField != null) {
        query = query.eq(_filterField, true);
      }
      if (showPremiumOnly) {
        query = query.eq('is_premium_only', true);
      }
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }
      if (contentType != null) {
        query = query.eq('content_type', contentType);
      }
      if (pricingModel != null) {
        query = query.eq('pricing_model', pricingModel);
      }
      if (search.isNotEmpty) {
        query = query.or('title.ilike.%$search%,description.ilike.%$search%');
      }

      // Sort logic
      // If we are in the main lists and not a specific tab like trending/popular
      if (_filterField == null) {
        if (sortBy == 'popular') {
          query = query.eq('is_popular', true);
        } else if (sortBy == 'trending') {
          query = query.eq('is_trending', true);
        }
      }

      bool ascending = false;
      if (_filterField == null && sortBy == 'oldest') {
        ascending = true;
      }

      final from = _dbOffset;
      final to = from + kDiscoverPageSize - 1;

      final response = await query
          .order('created_at', ascending: ascending)
          .range(from, to);

      final rawList = response as List;
      final newItems = <WebsiteModel>[];
      for (final item in rawList) {
        try {
          newItems.add(WebsiteModel.fromJson(item as Map<String, dynamic>));
        } catch (e) {
          print('Error parsing website item: $e');
        }
      }
      
      _dbOffset += rawList.length;
      final activeItems = _filterActive(newItems);
      final filtered = showPremiumOnly
          ? activeItems.where((item) => item.isPremiumOnly).toList()
          : activeItems;

      state = state.copyWith(
        items: [...state.items, ...filtered],
        isLoading: false,
        hasMore: rawList.length >= kDiscoverPageSize,
        isInitialLoad: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, isInitialLoad: false, error: e);
    }
  }

  void reset() {
    _dbOffset = 0;
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
      ref.watch(selectedPricingModelProvider);
      ref.watch(discoverSortByProvider);
      ref.watch(showPremiumOnlyProvider);
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
      ref.watch(selectedPricingModelProvider);
      ref.watch(showPremiumOnlyProvider);
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
      ref.watch(selectedPricingModelProvider);
      ref.watch(showPremiumOnlyProvider);
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
      ref.watch(selectedPricingModelProvider);
      ref.watch(showPremiumOnlyProvider);
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

const int kNotificationsPageSize = 10;

class PaginatedNotificationsState {
  final List<NotificationModel> items;
  final bool isLoading;
  final bool hasMore;
  final bool isInitialLoad;
  final String? error;

  const PaginatedNotificationsState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.isInitialLoad = true,
    this.error,
  });

  PaginatedNotificationsState copyWith({
    List<NotificationModel>? items,
    bool? isLoading,
    bool? hasMore,
    bool? isInitialLoad,
    String? error,
    bool clearError = false,
  }) {
    return PaginatedNotificationsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      isInitialLoad: isInitialLoad ?? this.isInitialLoad,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PaginatedNotificationsNotifier
    extends StateNotifier<PaginatedNotificationsState> {
  final Ref _ref;

  PaginatedNotificationsNotifier(this._ref)
    : super(const PaginatedNotificationsState()) {
    loadMore();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final from = state.items.length;
      final to = from + kNotificationsPageSize - 1;

      final userId = _client.auth.currentUser?.id;
      var query = _client
          .from('notifications')
          .select();
      
      if (userId != null) {
        query = query.or('user_id.is.null,user_id.eq.$userId');
      } else {
        query = query.filter('user_id', 'is', null);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(from, to);

      final lastSeen = _ref.read(lastSeenNotificationProvider);
      var newItems = (response as List).map((e) {
        final notification = NotificationModel.fromJson(e);
        return notification.copyWith(
          isRead: notification.createdAt.isBefore(lastSeen),
        );
      }).toList();

      // Personalize notifications that have personalize_name enabled
      final hasPersonalized = newItems.any((n) => n.personalizeWithName);
      if (hasPersonalized) {
        final user = _client.auth.currentUser;
        String userName = 'User';
        if (user != null) {
          try {
            final profile = await _client
                .from('profiles')
                .select('full_name')
                .eq('id', user.id)
                .maybeSingle();
            if (profile != null &&
                profile['full_name'] != null &&
                (profile['full_name'] as String).isNotEmpty) {
              userName = profile['full_name'] as String;
            }
          } catch (_) {}
        }
        newItems = newItems
            .map((n) => n.withPersonalizedName(userName))
            .toList();
      }

      state = state.copyWith(
        items: [...state.items, ...newItems],
        isLoading: false,
        hasMore: newItems.length >= kNotificationsPageSize,
        isInitialLoad: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isInitialLoad: false,
        error: e.toString(),
      );
    }
  }

  void reset() {
    state = const PaginatedNotificationsState();
    loadMore();
  }
}

final notificationsPaginatedProvider =
    StateNotifierProvider.autoDispose<
      PaginatedNotificationsNotifier,
      PaginatedNotificationsState
    >((ref) {
      return PaginatedNotificationsNotifier(ref);
    });

// A legacy provider for places that still expect the old future, if any.
// Though we should migrate UI to use notificationsPaginatedProvider instead.
final notificationsProvider = FutureProvider<List<NotificationModel>>((
  ref,
) async {
  final state = ref.watch(notificationsPaginatedProvider);
  return state.items;
});

// --------------- Search / Filter ---------------

final discoverSearchProvider = StateProvider<String>((ref) => '');
final selectedCategoryProvider = StateProvider<String?>((ref) => null);
final selectedContentTypeProvider = StateProvider<String?>((ref) => null);
final selectedPricingModelProvider = StateProvider<String?>((ref) => null);
final discoverSortByProvider = StateProvider<String>((ref) => 'newest');
final showPremiumOnlyProvider = StateProvider<bool>((ref) => false);
/// Layout mode for Newly Added section: true = grid layout, false = list (horizontal) layout
final discoverViewModeProvider = StateProvider<bool>((ref) => true);

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

// --------------- Premium Access ---------------

/// Set of premium collection IDs the current user has access to.
/// Combines: (1) manual admin grants, (2) referral campaign rewards,
/// (3) approved membership requests, and (4) default invite threshold.
final userPremiumCollectionIdsProvider = FutureProvider<Set<String>>((ref) async {
  final user = _client.auth.currentUser;
  if (user == null) return const <String>{};

  final uid = user.id;

  // 1. Collections where user is in manual_user_ids
  final allCollections = await _client
      .from('featured_collections')
      .select('id, manual_user_ids, is_referral_exclusive')
      .eq('is_referral_exclusive', true);

  final premiumCollectionIds = <String>{};
  final manualAccess = <String>{};
  for (final c in allCollections as List) {
    premiumCollectionIds.add(c['id'] as String);
    final ids = (c['manual_user_ids'] as List?)?.map((e) => e.toString()).toSet() ?? <String>{};
    if (ids.contains(uid)) {
      manualAccess.add(c['id'] as String);
    }
  }

  // 2. Referral-earned access (campaign-based)
  final campaigns = await _client
      .from('referral_campaigns')
      .select('id, reward_collection_id, required_referrals')
      .eq('reward_type', 'collection_access')
      .eq('is_active', true);

  final referralAccess = <String>{};
  for (final c in campaigns as List) {
    final campaignId = c['id'] as String;
    final collectionId = c['reward_collection_id'] as String?;
    final required = (c['required_referrals'] as num).toInt();
    if (collectionId == null) continue;

    final referrals = await _client
        .from('referrals')
        .select('id')
        .eq('campaign_id', campaignId)
        .eq('referrer_id', uid)
        .eq('status', 'confirmed');

    if ((referrals as List).length >= required) {
      referralAccess.add(collectionId);
    }
  }

  // 3. Granular Membership Access (from profile permissions)
  final memStatus = ref.watch(membershipStatusProvider);
  
  if (memStatus.isGlobal) {
    return {...premiumCollectionIds, ...manualAccess, ...referralAccess};
  }

  // Add specific collections from permissions
  final grantedCollectionIds = memStatus.permissions
      .where((p) => p.startsWith('premium:col_'))
      .map((p) => p.replaceFirst('premium:col_', ''))
      .toSet();

  // 4. Default invite threshold → if total confirmed >= required, opens ALL
  bool metDefaultThreshold = false;
  // We only check threshold if they don't already have global access
  final settingsResp = await _client
      .from('app_settings')
      .select('value')
      .eq('key', 'default_required_invites')
      .limit(1);
  final defaultRequired = (settingsResp as List).isNotEmpty
      ? int.tryParse(settingsResp.first['value'] as String? ?? '3') ?? 3
      : 3;

  final totalConfirmed = await _client
      .from('referrals')
      .select('id')
      .eq('referrer_id', uid)
      .eq('status', 'confirmed');

  if ((totalConfirmed as List).length >= defaultRequired) {
    metDefaultThreshold = true;
  }

  // Combine all access paths
  if (metDefaultThreshold) {
    return {...premiumCollectionIds, ...manualAccess, ...referralAccess};
  }
  
  return {...manualAccess, ...referralAccess, ...grantedCollectionIds};
});


/// Given a website ID that is premium-only, find the parent premium collection.
/// Returns the first matching CollectionModel or null.
Future<CollectionModel?> findPremiumCollectionForItem(String websiteId) async {
  final rows = await _client
      .from('collection_items')
      .select('collection_id')
      .eq('website_id', websiteId);

  if ((rows as List).isEmpty) return null;

  final collectionIds = rows.map((r) => r['collection_id'] as String).toList();

  final collections = await _client
      .from('featured_collections')
      .select()
      .inFilter('id', collectionIds)
      .eq('is_referral_exclusive', true)
      .limit(1);

  if ((collections as List).isEmpty) return null;
  return CollectionModel.fromJson(collections.first);
}
