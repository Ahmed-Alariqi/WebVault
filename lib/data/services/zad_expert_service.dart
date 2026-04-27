import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/supabase_config.dart';
import '../models/ai_chat_model.dart';
import '../models/ai_persona_model.dart';

/// Service for the Zad Expert AI system — completely independent from the existing AI assistant.
class ZadExpertService {
  // ─────────────────────────────────────────────────────────────────────────
  // Personas
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetch all active personas (for users)
  static Future<List<AiPersonaModel>> fetchPersonas() async {
    final response = await SupabaseConfig.client
        .from('ai_personas')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return (response as List)
        .map((e) => AiPersonaModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Fetch all personas (admin — including inactive)
  static Future<List<AiPersonaModel>> fetchAllPersonas() async {
    final response = await SupabaseConfig.client
        .from('ai_personas')
        .select()
        .order('sort_order', ascending: true);

    return (response as List)
        .map((e) => AiPersonaModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Save (create or update) a persona
  static Future<void> savePersona(AiPersonaModel persona, {String? existingId}) async {
    final data = persona.toJson();
    data['updated_at'] = DateTime.now().toUtc().toIso8601String();

    if (existingId != null) {
      await SupabaseConfig.client
          .from('ai_personas')
          .update(data)
          .eq('id', existingId);
    } else {
      await SupabaseConfig.client.from('ai_personas').insert(data);
    }
  }

  /// Delete a persona
  static Future<void> deletePersona(String id) async {
    await SupabaseConfig.client.from('ai_personas').delete().eq('id', id);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Providers (admin only)
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetch all providers (admin only)
  static Future<List<AiProviderModel>> fetchProviders() async {
    final response = await SupabaseConfig.client
        .from('ai_providers')
        .select()
        .order('created_at', ascending: true);

    return (response as List)
        .map((e) => AiProviderModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Save (create or update) a provider
  static Future<void> saveProvider(AiProviderModel provider, {String? existingId}) async {
    final data = provider.toJson();

    if (existingId != null) {
      await SupabaseConfig.client
          .from('ai_providers')
          .update(data)
          .eq('id', existingId);
    } else {
      await SupabaseConfig.client.from('ai_providers').insert(data);
    }
  }

  /// Delete a provider
  static Future<void> deleteProvider(String id) async {
    await SupabaseConfig.client.from('ai_providers').delete().eq('id', id);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Chat — send message via zad-expert Edge Function
  // ─────────────────────────────────────────────────────────────────────────

  /// Send a message to a persona and get a response
  static Future<String> sendMessage({
    required String personaId,
    required List<AiChatMessage> chatHistory,
  }) async {
    final messages = chatHistory
        .where((m) => !m.isLoading)
        .map((m) => m.toApiMessage())
        .toList();

    final url = '${SupabaseConfig.url}/functions/v1/zad-expert';

    final response = await http
        .post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'apikey': SupabaseConfig.anonKey,
          },
          body: jsonEncode({
            'persona_id': personaId,
            'messages': messages,
          }),
        )
        .timeout(const Duration(minutes: 3));

    if (response.statusCode != 200) {
      String errorMsg = 'خطأ في خدمة الذكاء الاصطناعي';
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

  /// Streamed variant — yields incremental content chunks as they arrive
  /// from the model. The edge function pipes upstream SSE through unchanged,
  /// so the format is OpenAI-compatible (`data: {choices:[{delta:{content}}]}`
  /// terminated by `data: [DONE]`).
  ///
  /// Always prefer this over [sendMessage] for chat: it avoids 90s timeouts
  /// and gives the user immediate feedback (first token typically < 1s).
  static Stream<String> sendMessageStream({
    required String personaId,
    required List<AiChatMessage> chatHistory,
  }) async* {
    final messages = chatHistory
        .where((m) => !m.isLoading)
        .map((m) => m.toApiMessage())
        .toList();

    final url = '${SupabaseConfig.url}/functions/v1/zad-expert';
    final client = http.Client();
    try {
      final req = http.Request('POST', Uri.parse(url));
      req.headers['Content-Type'] = 'application/json';
      req.headers['apikey'] = SupabaseConfig.anonKey;
      req.headers['Accept'] = 'text/event-stream';
      req.body = jsonEncode({
        'persona_id': personaId,
        'messages': messages,
        'stream': true,
      });

      final res = await client
          .send(req)
          .timeout(const Duration(minutes: 5));

      if (res.statusCode != 200) {
        final body = await res.stream.bytesToString();
        String errorMsg = 'خطأ في خدمة الذكاء الاصطناعي';
        try {
          final j = jsonDecode(body);
          if (j is Map && j['error'] != null) {
            errorMsg = j['error'].toString();
          }
        } catch (_) {/* keep default */}
        throw Exception(errorMsg);
      }

      // Parse Server-Sent Events line by line. Chunks may be split across
      // network packets, so we keep a rolling buffer.
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
            // Edge function normalises every provider into {content: "..."}
            // (or {error: "..."} on upstream failure mid-stream).
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
            // Re-throw real errors (from server-emitted {error}); silently
            // ignore JSON-parse failures on malformed lines.
            if (e is Exception) rethrow;
          }
        }
      }
    } finally {
      client.close();
    }
  }
}
