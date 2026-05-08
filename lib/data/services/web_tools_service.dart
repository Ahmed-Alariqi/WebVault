import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/supabase_config.dart';
import '../models/web_tools_models.dart';

/// Service for web search and URL content reading via Jina AI.
///
/// Calls the `web-tools` Edge Function which proxies requests to
/// Jina's s.jina.ai (search) and r.jina.ai (read) endpoints.
class WebToolsService {
  static const _functionName = 'web-tools';

  static String get _baseUrl =>
      '${SupabaseConfig.url}/functions/v1/$_functionName';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'apikey': SupabaseConfig.anonKey,
        'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
      };

  /// Search the web for a given query. Returns up to [maxResults] results.
  static Future<List<WebSearchResult>> search(
    String query, {
    int maxResults = 5,
  }) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: jsonEncode({
        'action': 'search',
        'query': query,
        'max_results': maxResults,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Web search failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List? ?? [];
    return results
        .map((e) => WebSearchResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Read and extract the content of a URL as clean Markdown.
  static Future<WebReadResult> readUrl(String url) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: jsonEncode({
        'action': 'read',
        'url': url,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'URL read failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return WebReadResult.fromJson(data);
  }
}
