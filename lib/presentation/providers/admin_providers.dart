import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_config.dart';
import '../../data/models/website_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/suggestion_model.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/suggestion_repository.dart';
import '../../data/models/collection_model.dart';
import '../../data/models/draft_model.dart';

final _client = SupabaseConfig.client;

// --------------- Admin Websites CRUD ---------------

final adminWebsitesProvider = FutureProvider<List<WebsiteModel>>((ref) async {
  final response = await _client
      .from('websites')
      .select()
      .order('created_at', ascending: false);
  return (response as List).map((e) => WebsiteModel.fromJson(e)).toList();
});

// --------------- Admin Filter State ---------------

final adminSearchQueryProvider = StateProvider<String>((ref) => '');
final adminContentTypeFilterProvider = StateProvider<String?>((ref) => null);
final adminSortAscendingProvider = StateProvider<bool>((ref) => false);

// --------------- Paginated Admin Websites (8 items/page) ---------------

const int kAdminPageSize = 5;

class PaginatedAdminState<T> {
  final List<T> items;
  final bool isLoading;
  final bool hasMore;
  final bool isInitialLoad;
  final Object? error;

  const PaginatedAdminState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.isInitialLoad = true,
    this.error,
  });

  PaginatedAdminState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? hasMore,
    bool? isInitialLoad,
    Object? error,
    bool clearError = false,
  }) {
    return PaginatedAdminState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      isInitialLoad: isInitialLoad ?? this.isInitialLoad,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AdminWebsitesPaginatedNotifier
    extends StateNotifier<PaginatedAdminState<WebsiteModel>> {
  final Ref _ref;

  AdminWebsitesPaginatedNotifier(this._ref)
    : super(const PaginatedAdminState<WebsiteModel>()) {
    loadMore();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final from = state.items.length;
      final to = from + kAdminPageSize - 1;
      final searchQuery = _ref.read(adminSearchQueryProvider).trim();
      final contentType = _ref.read(adminContentTypeFilterProvider);
      final ascending = _ref.read(adminSortAscendingProvider);

      var query = _client.from('websites').select();

      if (contentType != null && contentType.isNotEmpty) {
        query = query.eq('content_type', contentType);
      }
      if (searchQuery.isNotEmpty) {
        query = query.ilike('title', '%$searchQuery%');
      }

      final response = await query
          .order('created_at', ascending: ascending)
          .range(from, to);

      final newItems = (response as List)
          .map((e) => WebsiteModel.fromJson(e))
          .toList();

      state = state.copyWith(
        items: [...state.items, ...newItems],
        isLoading: false,
        hasMore: newItems.length >= kAdminPageSize,
        isInitialLoad: false,
      );
    } catch (e, stack) {
      debugPrint('AdminWebsitesPaginatedNotifier error: $e\n$stack');
      state = state.copyWith(isLoading: false, isInitialLoad: false, error: e);
    }
  }

  void reset() {
    state = const PaginatedAdminState<WebsiteModel>();
    loadMore();
  }
}

final adminWebsitesPaginatedProvider =
    StateNotifierProvider<
      AdminWebsitesPaginatedNotifier,
      PaginatedAdminState<WebsiteModel>
    >((ref) {
      return AdminWebsitesPaginatedNotifier(ref);
    });

// --------------- Paginated Admin Users (client-side, 20/page) ---------------

const int kAdminUsersPageSize = 20;

class AdminUsersPaginatedNotifier
    extends StateNotifier<PaginatedAdminState<Map<String, dynamic>>> {
  List<Map<String, dynamic>> _allUsers = [];

  AdminUsersPaginatedNotifier()
    : super(const PaginatedAdminState<Map<String, dynamic>>()) {
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _client.functions.invoke(
        'admin-user-actions',
        body: {'action': 'list_users'},
      );
      final data = response.data as List;
      _allUsers = data.map((e) => e as Map<String, dynamic>).toList();

      // Show first page
      final firstPage = _allUsers.take(kAdminUsersPageSize).toList();
      state = PaginatedAdminState<Map<String, dynamic>>(
        items: firstPage,
        isLoading: false,
        hasMore: _allUsers.length > kAdminUsersPageSize,
        isInitialLoad: false,
      );
    } catch (e) {
      debugPrint('Error loading users: $e');
      state = state.copyWith(isLoading: false, isInitialLoad: false, error: e);
    }
  }

  void loadMore() {
    if (state.isLoading || !state.hasMore) return;
    final currentLen = state.items.length;
    final nextBatch = _allUsers
        .skip(currentLen)
        .take(kAdminUsersPageSize)
        .toList();

    state = state.copyWith(
      items: [...state.items, ...nextBatch],
      hasMore: currentLen + nextBatch.length < _allUsers.length,
    );
  }

  void reset() {
    state = const PaginatedAdminState<Map<String, dynamic>>();
    _fetchAll();
  }
}

final adminUsersPaginatedProvider =
    StateNotifierProvider<
      AdminUsersPaginatedNotifier,
      PaginatedAdminState<Map<String, dynamic>>
    >((ref) {
      return AdminUsersPaginatedNotifier();
    });

Future<String?> adminAddWebsite(Map<String, dynamic> data) async {
  final user = _client.auth.currentUser;
  data['created_by'] = user?.id;
  final res = await _client.from('websites').insert(data).select('id').single();
  return res['id'] as String?;
}

Future<void> adminUpdateWebsite(String id, Map<String, dynamic> data) async {
  await _client.from('websites').update(data).eq('id', id);
}

Future<void> adminDeleteWebsite(String id) async {
  await _client.from('websites').delete().eq('id', id);
}

// --------------- Admin Categories CRUD ---------------

final adminCategoriesProvider = FutureProvider<List<CategoryModel>>((
  ref,
) async {
  final response = await _client
      .from('categories')
      .select()
      .order('sort_order');
  return (response as List).map((e) => CategoryModel.fromJson(e)).toList();
});

Future<void> adminAddCategory(Map<String, dynamic> data) async {
  await _client.from('categories').insert(data);
}

Future<void> adminUpdateCategory(String id, Map<String, dynamic> data) async {
  await _client.from('categories').update(data).eq('id', id);
}

Future<void> adminDeleteCategory(String id) async {
  await _client.from('categories').delete().eq('id', id);
}

// --------------- Admin Notifications ---------------

Future<Map<String, dynamic>> adminSendNotification(Map<String, dynamic> data) async {
  final user = _client.auth.currentUser;
  data['created_by'] = user?.id;

  // 1. Insert into DB for history and get ID
  final insertedData = await _client.from('notifications').insert(data).select().single();
  final notificationId = insertedData['id'];

  // 2. Trigger Edge Function to push via FCM
  try {
    final response = await _client.functions.invoke(
      'send-notification',
      body: {
        'title': data['title'],
        'body': data['body'],
        'type': data['type'],
        'target_url': data['target_url'],
        'image_url': data['image_url'],
        'created_by': user?.id,
      },
    );
    
    int sentCount = 0;
    int failedCount = 0;
    int totalTargeted = 0;
    
    if (response.data is Map) {
      final resData = response.data as Map;
      sentCount = resData['sent_count'] ?? 0;
      failedCount = resData['failed_count'] ?? 0;
      totalTargeted = resData['total_targeted'] ?? 0;
      
      // Update DB record with the returned counts
      await _client.from('notifications').update({
        'sent_count': sentCount,
        'failed_count': failedCount,
        'total_targeted': totalTargeted,
      }).eq('id', notificationId);
    }
    
    return {
      'sent_count': sentCount,
      'failed_count': failedCount,
      'total_targeted': totalTargeted,
    };
  } catch (e) {
    debugPrint('Edge Function invoke failed: $e');
    // Don't swallow - rethrow so admin sees push failed
    rethrow;
  }
}

// --------------- Admin FCM User Stats ---------------

final adminFCMStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final totalUsers =
      await _client.from('profiles').count(CountOption.exact) as int? ?? 0;

  // Active = has token AND token has not been marked invalid by a past send.
  final activeResp = await _client
      .from('profiles')
      .select('id')
      .not('fcm_token', 'is', null)
      .filter('fcm_token_invalid_at', 'is', null);
  final activeFCM = (activeResp as List).length;

  // Uninstalled = had a token but FCM marked it dead during a send.
  final uninstalledResp = await _client
      .from('profiles')
      .select('id')
      .not('fcm_token_invalid_at', 'is', null);
  final uninstalled = (uninstalledResp as List).length;

  final now = DateTime.now().toUtc();
  final cutoff7 = now.subtract(const Duration(days: 7)).toIso8601String();
  final cutoff30 = now.subtract(const Duration(days: 30)).toIso8601String();

  final uninstalled7Resp = await _client
      .from('profiles')
      .select('id')
      .gte('fcm_token_invalid_at', cutoff7);
  final uninstalled7 = (uninstalled7Resp as List).length;

  final uninstalled30Resp = await _client
      .from('profiles')
      .select('id')
      .gte('fcm_token_invalid_at', cutoff30);
  final uninstalled30 = (uninstalled30Resp as List).length;

  return {
    'total': totalUsers,
    'active': activeFCM,
    'uninstalled': uninstalled,
    'uninstalled_7d': uninstalled7,
    'uninstalled_30d': uninstalled30,
  };
});

// --------------- Admin Notifications CRUD & Pagination ---------------

const int kAdminNotificationsPageSize = 5;

class AdminNotificationsPaginatedNotifier
    extends StateNotifier<PaginatedAdminState<NotificationModel>> {
  AdminNotificationsPaginatedNotifier()
    : super(const PaginatedAdminState<NotificationModel>()) {
    loadMore();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final from = state.items.length;
      final to = from + kAdminNotificationsPageSize - 1;

      final response = await _client
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .range(from, to);

      final newItems = (response as List)
          .map((e) => NotificationModel.fromJson(e))
          .toList();

      state = state.copyWith(
        items: [...state.items, ...newItems],
        isLoading: false,
        hasMore: newItems.length >= kAdminNotificationsPageSize,
        isInitialLoad: false,
      );
    } catch (e) {
      debugPrint('Error loading admin notifications: $e');
      state = state.copyWith(isLoading: false, isInitialLoad: false, error: e);
    }
  }

  void reset() {
    state = const PaginatedAdminState<NotificationModel>();
    loadMore();
  }
}

final adminNotificationsPaginatedProvider =
    StateNotifierProvider<
      AdminNotificationsPaginatedNotifier,
      PaginatedAdminState<NotificationModel>
    >((ref) {
      return AdminNotificationsPaginatedNotifier();
    });

Future<void> adminDeleteNotification(String id) async {
  await _client.from('notifications').delete().eq('id', id);
}

Future<void> adminDeleteAllNotifications() async {
  // To delete all we can do a neq to something impossible or just eq on something always true.
  // Using an open delete.
  await _client
      .from('notifications')
      .delete()
      .neq('id', '00000000-0000-0000-0000-000000000000');
}

// --------------- Admin In-App Messages ---------------

final adminInAppMessagesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final response = await _client
      .from('in_app_messages')
      .select()
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

Future<void> adminCreateInAppMessage(Map<String, dynamic> data) async {
  await _client.from('in_app_messages').insert(data);
}

Future<void> adminToggleInAppMessage(String id, bool isActive) async {
  // If activating one, we optionally could deactivate all others to avoid clashes,
  // but for now we'll just let the UI handle it or trust the query limit(1) logic in the service.
  await _client
      .from('in_app_messages')
      .update({'is_active': isActive})
      .eq('id', id);
}

Future<void> adminDeleteInAppMessage(String id) async {
  await _client.from('in_app_messages').delete().eq('id', id);
}

Future<void> adminUpdateInAppMessage(
  String id,
  Map<String, dynamic> data,
) async {
  await _client.from('in_app_messages').update(data).eq('id', id);
}

// --------------- Admin Stats ---------------

final adminStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final websitesCount = await _client.from('websites').count(CountOption.exact);
  final categoriesCount = await _client
      .from('categories')
      .count(CountOption.exact);
  final profilesCount = await _client.from('profiles').count(CountOption.exact);

  return {
    'websites': websitesCount,
    'categories': categoriesCount,
    'users': profilesCount,
  };
});

// --------------- Admin User Management ---------------

final adminUsersProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  try {
    final response = await _client.functions.invoke(
      'admin-user-actions',
      body: {'action': 'list_users'},
    );
    final data = response.data as List;
    return data.map((e) => e as Map<String, dynamic>).toList();
  } catch (e) {
    debugPrint('Error listing users: $e');
    throw Exception('Failed to load users');
  }
});

Future<void> adminCreateUser(
  String email,
  String password,
  String fullName,
  String role,
) async {
  await _client.functions.invoke(
    'admin-user-actions',
    body: {
      'action': 'create_user',
      'email': email,
      'password': password,
      'fullName': fullName,
      'role': role,
    },
  );
}

Future<void> adminUpdateUser(
  String userId, {
  String? role,
  List<String>? permissions,
}) async {
  await _client.functions.invoke(
    'admin-user-actions',
    body: {
      'action': 'update_user',
      'userId': userId,
      'role': role,
      'permissions': permissions,
    },
  );
}

Future<void> adminDeleteUser(String userId) async {
  await _client.functions.invoke(
    'admin-user-actions',
    body: {'action': 'delete_user', 'userId': userId},
  );
}
// --------------- Admin Suggestions ---------------

final suggestionRepositoryProvider = Provider<SuggestionRepository>((ref) {
  return SuggestionRepository();
});

final adminSuggestionsProvider = StreamProvider<List<SuggestionModel>>((ref) {
  return SupabaseConfig.client
      .from('page_suggestions')
      .stream(primaryKey: ['id'])
      .eq('status', 'pending')
      .order('created_at', ascending: false)
      .map((data) => data.map((e) => SuggestionModel.fromJson(e)).toList());
});

Future<void> adminUpdateSuggestion(String id, String status) async {
  await SupabaseConfig.client
      .from('page_suggestions')
      .update({'status': status})
      .eq('id', id);
}

// Re-export repository for convenience if needed, but usually we use provider

// --------------- Admin Collections ---------------

final adminCollectionsProvider = FutureProvider<List<CollectionModel>>((
  ref,
) async {
  final response = await _client
      .from('featured_collections')
      .select('*, collection_items(id)')
      .order('sort_order', ascending: true);

  return (response as List).map((json) {
    final itemCount = (json['collection_items'] as List?)?.length ?? 0;
    json['item_count'] = itemCount;
    return CollectionModel.fromJson(json);
  }).toList();
});

Future<void> adminCreateCollection(Map<String, dynamic> data) async {
  await _client.from('featured_collections').insert(data);
}

Future<void> adminUpdateCollection(String id, Map<String, dynamic> data) async {
  await _client.from('featured_collections').update(data).eq('id', id);
}

Future<void> adminDeleteCollection(String id) async {
  await _client.from('featured_collections').delete().eq('id', id);
}

// --------------- Premium Collection Members ---------------

/// Represents a user who has access to a referral-exclusive collection,
/// either via a manual admin grant, via referral campaigns, or both.
class CollectionMember {
  final String userId;
  final String displayName;
  final String? email;
  final String? avatarUrl;
  final bool isManual;
  /// Title of the referral campaign that grants access (if any).
  final String? viaCampaignTitle;

  const CollectionMember({
    required this.userId,
    required this.displayName,
    this.email,
    this.avatarUrl,
    required this.isManual,
    this.viaCampaignTitle,
  });

  bool get isReferralEligible => viaCampaignTitle != null;
}

/// Lists all users with access to a premium collection.
/// Combines manually-granted users with users who qualified via referrals.
final collectionMembersProvider =
    FutureProvider.family<List<CollectionMember>, String>((ref, collectionId) async {
  // 1. Manual user IDs
  final col = await _client
      .from('featured_collections')
      .select('manual_user_ids')
      .eq('id', collectionId)
      .maybeSingle();
  final manualIds = (col?['manual_user_ids'] as List?)
          ?.map((e) => e.toString())
          .toSet() ??
      <String>{};

  // 2. Referral-eligible users via active campaigns linked to this collection
  final campaigns = await _client
      .from('referral_campaigns')
      .select('id, title, required_referrals')
      .eq('reward_type', 'collection_access')
      .eq('reward_collection_id', collectionId)
      .eq('is_active', true);

  // userId -> campaign title (first one that grants access)
  final Map<String, String> referralEligible = {};
  for (final c in campaigns as List) {
    final cId = c['id'] as String;
    final cTitle = (c['title'] as String?) ?? '';
    final required = (c['required_referrals'] as num).toInt();
    final referrals = await _client
        .from('referrals')
        .select('referrer_id')
        .eq('campaign_id', cId)
        .eq('status', 'confirmed');
    final Map<String, int> counts = {};
    for (final r in referrals as List) {
      final rid = r['referrer_id'] as String;
      counts[rid] = (counts[rid] ?? 0) + 1;
    }
    counts.forEach((uid, count) {
      if (count >= required && !referralEligible.containsKey(uid)) {
        referralEligible[uid] = cTitle;
      }
    });
  }

  // 3. Fetch profile info for the union
  final allIds = {...manualIds, ...referralEligible.keys}.toList();
  if (allIds.isEmpty) return const <CollectionMember>[];

  final profiles = await _client
      .from('profiles')
      .select('id, full_name, username, email, avatar_url')
      .inFilter('id', allIds);

  return (profiles as List).map((p) {
    final uid = p['id'] as String;
    final name = (p['full_name'] as String?)?.trim().isNotEmpty == true
        ? p['full_name'] as String
        : ((p['username'] as String?) ?? 'Unknown');
    return CollectionMember(
      userId: uid,
      displayName: name,
      email: p['email'] as String?,
      avatarUrl: p['avatar_url'] as String?,
      isManual: manualIds.contains(uid),
      viaCampaignTitle: referralEligible[uid],
    );
  }).toList()
    ..sort((a, b) {
      // Manual first, then alphabetical
      if (a.isManual != b.isManual) return a.isManual ? -1 : 1;
      return a.displayName.compareTo(b.displayName);
    });
});

/// Add a user to a collection's manual access list.
/// Returns true if added, false if already present.
Future<bool> adminAddCollectionMember(
  String collectionId,
  String userId,
) async {
  final row = await _client
      .from('featured_collections')
      .select('manual_user_ids')
      .eq('id', collectionId)
      .single();
  final current = (row['manual_user_ids'] as List?)
          ?.map((e) => e.toString())
          .toSet() ??
      <String>{};
  if (current.contains(userId)) return false;
  current.add(userId);
  await _client
      .from('featured_collections')
      .update({'manual_user_ids': current.toList()})
      .eq('id', collectionId);
  return true;
}

/// Remove a user from a collection's manual access list.
Future<void> adminRemoveCollectionMember(
  String collectionId,
  String userId,
) async {
  final row = await _client
      .from('featured_collections')
      .select('manual_user_ids')
      .eq('id', collectionId)
      .single();
  final current = (row['manual_user_ids'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
      <String>[];
  current.remove(userId);
  await _client
      .from('featured_collections')
      .update({'manual_user_ids': current})
      .eq('id', collectionId);
}

/// Send a targeted push notification to a single user via FCM.
/// Uses the Edge Function `send-notification` with mode=direct_to_user,
/// so it bypasses the chat preference toggle (only the master push toggle gates it).
///
/// Returns true if delivery was attempted (does not guarantee receipt).
Future<bool> notifyUser({
  required String userId,
  required String title,
  required String body,
  String type = 'general',
  String? targetUrl,
  String? imageUrl,
}) async {
  try {
    final user = _client.auth.currentUser;
    final response = await _client.functions.invoke(
      'send-notification',
      body: {
        'mode': 'direct_to_user',
        'target_user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'target_url': targetUrl,
        'image_url': imageUrl,
        'created_by': user?.id,
      },
    );
    if (response.data is Map) {
      final res = response.data as Map;
      final sent = (res['sent_count'] as int?) ?? 0;
      return sent > 0;
    }
    return false;
  } catch (e) {
    debugPrint('notifyUser failed for $userId: $e');
    return false;
  }
}

Future<void> adminAddItemToCollection(
  String collectionId,
  String websiteId,
) async {
  await _client.from('collection_items').insert({
    'collection_id': collectionId,
    'website_id': websiteId,
  });
  // Auto-sync: if collection is premium → mark item as premium
  await syncWebsitePremiumFlag(websiteId);
}

Future<void> adminRemoveItemFromCollection(
  String collectionId,
  String websiteId,
) async {
  await _client
      .from('collection_items')
      .delete()
      .eq('collection_id', collectionId)
      .eq('website_id', websiteId);
  // Auto-sync: re-check if item still belongs to any premium collection
  await syncWebsitePremiumFlag(websiteId);
}

/// Core sync helper: sets is_premium_only = true if the website belongs
/// to at least one referral-exclusive collection, false otherwise.
Future<void> syncWebsitePremiumFlag(String websiteId) async {
  // Get all collection IDs this website belongs to
  final rows = await _client
      .from('collection_items')
      .select('collection_id')
      .eq('website_id', websiteId);
  final collectionIds = (rows as List)
      .map((r) => r['collection_id'] as String)
      .toList();

  bool shouldBePremium = false;
  if (collectionIds.isNotEmpty) {
    // Check if ANY of those collections is referral-exclusive
    final premiumCols = await _client
        .from('featured_collections')
        .select('id')
        .inFilter('id', collectionIds)
        .eq('is_referral_exclusive', true)
        .limit(1);
    shouldBePremium = (premiumCols as List).isNotEmpty;
  }

  await _client.from('websites').update({
    'is_premium_only': shouldBePremium,
  }).eq('id', websiteId);
}

final collectionItemsProvider =
    FutureProvider.family<List<WebsiteModel>, String>((
      ref,
      collectionId,
    ) async {
      final response = await _client
          .from('collection_items')
          .select('*, websites(*)')
          .eq('collection_id', collectionId)
          .order('sort_order', ascending: true);

      return (response as List)
          .where((ci) => ci['websites'] != null)
          .map((ci) => WebsiteModel.fromJson(ci['websites']))
          .toList();
    });

// --------------- Admin Content Drafts ---------------

/// Real-time stream of all drafts, ordered by priority (urgent first) then newest
final adminDraftsProvider = StreamProvider<List<DraftModel>>((ref) {
  try {
    return _client
        .from('content_drafts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
          try {
            return data.map((e) => DraftModel.fromJson(e)).toList()
              ..sort((a, b) {
                const priorityOrder = {'urgent': 0, 'high': 1, 'normal': 2, 'low': 3};
                final pa = priorityOrder[a.priority] ?? 2;
                final pb = priorityOrder[b.priority] ?? 2;
                if (pa != pb) return pa.compareTo(pb);
                return b.createdAt.compareTo(a.createdAt);
              });
          } catch (e) {
            // Log parsing error but don't kill the stream
            return [];
          }
        });
  } catch (e) {
    // If stream initialization fails (e.g. Realtime disabled)
    return Stream.error(e);
  }
});

/// Count of unpublished drafts (for badges)
final adminDraftCountProvider = Provider<int>((ref) {
  final drafts = ref.watch(adminDraftsProvider).valueOrNull ?? [];
  return drafts.where((d) => !d.isPublished).length;
});

/// Count of ready-to-publish drafts
final adminReadyDraftCountProvider = Provider<int>((ref) {
  final drafts = ref.watch(adminDraftsProvider).valueOrNull ?? [];
  return drafts.where((d) => d.status == 'ready' && !d.isPublished).length;
});

Future<String?> adminAddDraft(Map<String, dynamic> data) async {
  final user = _client.auth.currentUser;
  data['created_by'] = user?.id;
  final res = await _client.from('content_drafts').insert(data).select('id').single();
  return res['id'] as String?;
}

Future<void> adminUpdateDraft(String id, Map<String, dynamic> data) async {
  await _client.from('content_drafts').update(data).eq('id', id);
}

Future<void> adminDeleteDraft(String id) async {
  await _client.from('content_drafts').delete().eq('id', id);
}

/// Mark a draft as published and link it to the website
Future<void> adminMarkDraftPublished(String draftId, String websiteId) async {
  await _client.from('content_drafts').update({
    'published_website_id': websiteId,
    'status': 'ready',
  }).eq('id', draftId);
}
