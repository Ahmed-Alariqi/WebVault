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

Future<void> adminAddWebsite(Map<String, dynamic> data) async {
  final user = _client.auth.currentUser;
  data['created_by'] = user?.id;
  await _client.from('websites').insert(data);
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
        'created_by': user?.id,
      },
    );
    debugPrint('OneSignal push response: ${response.status} ${response.data}');
  } catch (e) {
    debugPrint('Edge Function invoke failed: $e');
    // Don't swallow - rethrow so admin sees push failed
    rethrow;
  }
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
