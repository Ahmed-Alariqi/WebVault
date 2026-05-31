import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/supabase_config.dart';
import '../models/ai_chat_model.dart';
import '../models/website_model.dart';
import '../../core/utils/text_utils.dart';

/// Service to communicate with the AI Assistant Edge Function
class AiAssistantService {
  /// Send a message to the AI assistant and get a response
  static Future<String> sendMessage({
    WebsiteModel? item,
    required List<AiChatMessage> chatHistory,
    String? pageContent,
    String? externalUrlOrText,
  }) async {
    // Build item context
    // Build item context (if available)
    final Map<String, dynamic>? itemContext = item != null ? {
      'title': item.title,
      'description': TextUtils.getPlainTextFromDescription(item.description),
      'url': item.url,
      'tags': item.tags,
      'content_type': item.contentType,
      'pricing_model': item.pricingModel,
    } : null;

    // Build messages array (only user and assistant messages)
    final messages = chatHistory
        .where((m) => !m.isLoading)
        .map((m) => m.toApiMessage())
        .toList();

    final url = '${SupabaseConfig.url}/functions/v1/ai-assistant';
    
    final Map<String, dynamic> requestBody = {
      'messages': messages,
    };
    if (itemContext != null) {
      requestBody['item_context'] = itemContext;
    }
    if (pageContent != null && pageContent.isNotEmpty) {
      requestBody['page_content'] = pageContent;
    }
    if (externalUrlOrText != null && externalUrlOrText.isNotEmpty) {
      requestBody['external_context'] = externalUrlOrText;
    }

    final response = await http
        .post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'apikey': SupabaseConfig.anonKey,
          },
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(minutes: 3));

    if (response.statusCode != 200) {
      String errorMsg = 'AI assistant request failed';
      try {
        final errorBody = jsonDecode(response.body);
        if (errorBody is Map && errorBody['error'] != null) {
          errorMsg = errorBody['error'].toString();
        }
      } catch (_) {}
      throw Exception(errorMsg);
    }

    final data = jsonDecode(response.body);
    return data['content'] as String? ?? '';
  }

  /// Send a message to the AI assistant and get a response stream
  static Stream<String> sendMessageStream({
    WebsiteModel? item,
    required List<AiChatMessage> chatHistory,
    String? pageContent,
    String? externalUrlOrText,
  }) async* {
    final Map<String, dynamic>? itemContext = item != null
        ? {
            'title': item.title,
            'description': TextUtils.getPlainTextFromDescription(item.description),
            'url': item.url,
            'tags': item.tags,
            'content_type': item.contentType,
            'pricing_model': item.pricingModel,
          }
        : null;

    final messages = chatHistory
        .where((m) => !m.isLoading)
        .map((m) => m.toApiMessage())
        .toList();

    final url = '${SupabaseConfig.url}/functions/v1/ai-assistant';
    final client = http.Client();
    try {
      final req = http.Request('POST', Uri.parse(url));
      req.headers['Content-Type'] = 'application/json';
      req.headers['apikey'] = SupabaseConfig.anonKey;
      req.headers['Accept'] = 'text/event-stream';

      final Map<String, dynamic> requestBody = {
        'messages': messages,
        'stream': true,
      };
      if (itemContext != null) {
        requestBody['item_context'] = itemContext;
      }
      if (pageContent != null && pageContent.isNotEmpty) {
        requestBody['page_content'] = pageContent;
      }
      if (externalUrlOrText != null && externalUrlOrText.isNotEmpty) {
        requestBody['external_context'] = externalUrlOrText;
      }
      req.body = jsonEncode(requestBody);

      final res = await client.send(req).timeout(const Duration(minutes: 5));

      if (res.statusCode != 200) {
        final body = await res.stream.bytesToString();
        String errorMsg = 'AI assistant request failed';
        try {
          final j = jsonDecode(body);
          if (j is Map && j['error'] != null) {
            errorMsg = j['error'].toString();
          }
        } catch (_) {}
        throw Exception(errorMsg);
      }

      String buffer = '';
      await for (final chunk in res.stream.transform(utf8.decoder)) {
        buffer += chunk;
        while (true) {
          final idx = buffer.indexOf('\n');
          if (idx == -1) break;
          final rawLine = buffer.substring(0, idx);
          buffer = buffer.substring(idx + 1);
          final line = rawLine.trim();
          if (line.isEmpty || !line.startsWith('data:')) continue;
          final dataStr = line.substring(5).trim();
          if (dataStr == '[DONE]') return;
          try {
            final data = jsonDecode(dataStr);
            if (data is Map) {
              if (data['error'] is String) {
                throw Exception(data['error'] as String);
              }
              final content = data['content'];
              if (content is String && content.isNotEmpty) {
                yield content;
              }
            }
          } catch (e) {
            if (e is Exception) rethrow;
          }
        }
      }
    } finally {
      client.close();
    }
  }
}
