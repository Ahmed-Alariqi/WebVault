import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_config.dart';
import '../models/suggestion_model.dart';
import '../models/website_model.dart';

class SuggestionRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<void> createSuggestion({
    required String title,
    required String url,
    String? description,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null)
      throw Exception('User must be logged in to suggest pages');

    await _client.from('page_suggestions').insert({
      'user_id': user.id,
      'page_title': title,
      'page_url': url,
      'page_description': description,
    });
  }

  Future<List<SuggestionModel>> getPendingSuggestions() async {
    final response = await _client
        .from('page_suggestions')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List).map((e) => SuggestionModel.fromJson(e)).toList();
  }

  Future<void> rejectSuggestion(String id) async {
    await _client
        .from('page_suggestions')
        .update({'status': 'rejected'})
        .eq('id', id);
  }

  Future<void> approveSuggestion(String id, WebsiteModel website) async {
    // 1. Insert into websites
    await _client.from('websites').insert(website.toJson());

    // 2. Update suggestion status
    await _client
        .from('page_suggestions')
        .update({'status': 'approved'})
        .eq('id', id);
  }
}
