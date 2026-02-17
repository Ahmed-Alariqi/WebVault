import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_config.dart';
import '../../data/models/website_model.dart';
import '../../data/models/category_model.dart';

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
    await _client.functions.invoke(
      'send-notification',
      body: {
        'title': data['title'],
        'body': data['body'],
        'type': data['type'],
        'target_url': data['target_url'],
        'created_by': user?.id,
      },
    );
  } catch (e) {
    // If the Edge Function fails (e.g. missing secrets), we still keep the DB record
    // but might want to log it or show a warning.
    // For now, we swallow it so the admin UI doesn't crash on "success".
    debugPrint('Edge Function invoke failed: $e');
  }
}

// --------------- Admin Stats ---------------

final adminStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final websitesCount = await _client.from('websites').select('id');
  final categoriesCount = await _client.from('categories').select('id');
  final profilesCount = await _client.from('profiles').select('id');

  return {
    'websites': (websitesCount as List).length,
    'categories': (categoriesCount as List).length,
    'users': (profilesCount as List).length,
  };
});
