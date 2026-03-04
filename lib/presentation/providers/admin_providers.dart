import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_config.dart';
import '../../data/models/website_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/suggestion_model.dart';
import '../../data/repositories/suggestion_repository.dart';

final _client = SupabaseConfig.client;

// --------------- Admin Websites CRUD ---------------

final adminWebsitesProvider = FutureProvider<List<WebsiteModel>>((ref) async {
  final response = await _client
      .from('websites')
      .select()
      .order('created_at', ascending: false);
  return (response as List).map((e) => WebsiteModel.fromJson(e)).toList();
});

// --------------- Paginated Admin Websites (15 items/page) ---------------

const int kAdminPageSize = 15;

class PaginatedAdminState<T> {
  final List<T> items;
  final bool isLoading;
  final bool hasMore;
  final bool isInitialLoad;

  const PaginatedAdminState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.isInitialLoad = true,
  });

  PaginatedAdminState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? hasMore,
    bool? isInitialLoad,
  }) {
    return PaginatedAdminState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      isInitialLoad: isInitialLoad ?? this.isInitialLoad,
    );
  }
}

class AdminWebsitesPaginatedNotifier
    extends StateNotifier<PaginatedAdminState<WebsiteModel>> {
  AdminWebsitesPaginatedNotifier()
    : super(const PaginatedAdminState<WebsiteModel>()) {
    loadMore();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);

    try {
      final from = state.items.length;
      final to = from + kAdminPageSize - 1;

      final response = await _client
          .from('websites')
          .select()
          .order('created_at', ascending: false)
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
    } catch (e) {
      state = state.copyWith(isLoading: false, isInitialLoad: false);
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
      return AdminWebsitesPaginatedNotifier();
    });

// --------------- Paginated Admin Users (client-side, 15/page) ---------------

class AdminUsersPaginatedNotifier
    extends StateNotifier<PaginatedAdminState<Map<String, dynamic>>> {
  List<Map<String, dynamic>> _allUsers = [];

  AdminUsersPaginatedNotifier()
    : super(const PaginatedAdminState<Map<String, dynamic>>()) {
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _client.functions.invoke(
        'admin-user-actions',
        body: {'action': 'list_users'},
      );
      final data = response.data as List;
      _allUsers = data.map((e) => e as Map<String, dynamic>).toList();

      // Show first page
      final firstPage = _allUsers.take(kAdminPageSize).toList();
      state = PaginatedAdminState<Map<String, dynamic>>(
        items: firstPage,
        isLoading: false,
        hasMore: _allUsers.length > kAdminPageSize,
        isInitialLoad: false,
      );
    } catch (e) {
      debugPrint('Error loading users: $e');
      state = state.copyWith(isLoading: false, isInitialLoad: false);
    }
  }

  void loadMore() {
    if (state.isLoading || !state.hasMore) return;
    final currentLen = state.items.length;
    final nextBatch = _allUsers.skip(currentLen).take(kAdminPageSize).toList();

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

Future<void> adminSendNotification(Map<String, dynamic> data) async {
  final user = _client.auth.currentUser;
  data['created_by'] = user?.id;

  // 1. Insert into DB for history
  await _client.from('notifications').insert(data);

  // 2. Trigger Edge Function to push via OneSignal
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
    debugPrint('OneSignal push response: ${response.status} ${response.data}');
    // Log detailed info for debugging
    if (response.data is Map) {
      final data2 = response.data as Map;
      debugPrint('  Recipients: ${data2['recipients'] ?? 'unknown'}');
      if (data2['_debug'] != null) {
        debugPrint('  Debug: ${data2['_debug']}');
      }
    }
  } catch (e) {
    debugPrint('Edge Function invoke failed: $e');
    // Don't swallow - rethrow so admin sees push failed
    rethrow;
  }
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

Future<void> adminUpdateUser(String userId, {String? role}) async {
  await _client.functions.invoke(
    'admin-user-actions',
    body: {'action': 'update_user', 'userId': userId, 'role': role},
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
