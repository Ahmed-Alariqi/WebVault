import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/supabase_config.dart';
import '../models/ai_content_result.dart';

/// Service to communicate with the AI Content Prep Edge Function
class AiContentPrepService {
  /// Generate structured content from raw input (text or URL)
  static Future<AiContentResult> generate({
    required String input,
    required List<String> categories,
    required List<String> contentTypes,
    required String model,
  }) async {
    final url = '${SupabaseConfig.url}/functions/v1/ai-content-prep';

    final response = await http
        .post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'apikey': SupabaseConfig.anonKey,
          },
          body: jsonEncode({
            'input': input,
            'categories': categories,
            'content_types': contentTypes,
            'model': model,
          }),
        )
        .timeout(const Duration(seconds: 90));

    if (response.statusCode != 200) {
      String errorMsg = 'AI content preparation failed';
      try {
        final errorBody = jsonDecode(response.body);
        if (errorBody is Map && errorBody['error'] != null) {
          errorMsg = errorBody['error'].toString();
        }
      } catch (_) {}
      throw Exception(errorMsg);
    }

    final data = jsonDecode(response.body);
    return AiContentResult.fromJson(data as Map<String, dynamic>);
  }

  /// Regenerate a specific field based on current context
  static Future<String> regenerateField({
    required String fieldName,
    required Map<String, dynamic> currentData,
    required String originalInput,
    required String model,
  }) async {
    final url = '${SupabaseConfig.url}/functions/v1/ai-content-prep';

    final response = await http
        .post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'apikey': SupabaseConfig.anonKey,
          },
          body: jsonEncode({
            'regenerate_field': fieldName,
            'current_data': currentData,
            'original_input': originalInput,
            'model': model,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception('Failed to regenerate field');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    // Handle tags specially - return as comma-separated string
    if (fieldName == 'tags' && data['tags'] is List) {
      return (data['tags'] as List).join(', ');
    }

    return data[fieldName]?.toString() ?? '';
  }
}
