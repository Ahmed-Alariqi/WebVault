import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/supabase_config.dart';
import '../../data/models/chat_model.dart';
import 'auth_providers.dart';

final _supabase = SupabaseConfig.client;

// -------------------------------------------------------------
// USER PROVIDERS
// -------------------------------------------------------------

/// Provides the current user's conversation (Creates one if it doesn't exist)
final userConversationProvider = FutureProvider.autoDispose<ConversationModel?>(
  (ref) async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;

    final response = await _supabase
        .from('conversations')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (response != null) {
      return ConversationModel.fromJson(response);
    } else {
      // Attempt to create a new conversation for this user
      final newConv = await _supabase
          .from('conversations')
          .insert({'user_id': user.id})
          .select()
          .single();
      return ConversationModel.fromJson(newConv);
    }
  },
);

/// Streams messages for the CURRENT user
final userMessagesStreamProvider = StreamProvider.autoDispose<List<MessageModel>>((
  ref,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  // We stream messages where the sender_id is user or the conversation belongs to the user
  // To keep it simple, we stream based on conversation_id. But since RLS enforces users only see their own,
  // we can just stream all rows the user has access to.
  return _supabase
      .from('messages')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: true)
      .map((data) => data.map((e) => MessageModel.fromJson(e)).toList());
});

/// Streams the unread count for the current user (used for Badge)
final userUnreadCountStreamProvider = StreamProvider.autoDispose<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  return _supabase
      .from('conversations')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .map((data) {
        if (data.isEmpty) return 0;
        return data.first['unread_user_count'] as int? ?? 0;
      });
});

// -------------------------------------------------------------
// ADMIN PROVIDERS
// -------------------------------------------------------------

/// Streams all active conversations for the generic admin panel.
final adminConversationsStreamProvider =
    StreamProvider.autoDispose<List<ConversationModel>>((ref) {
      // Use a query combined with view?
      // `.stream` doesn't do joins. So we stream conversations, then we might fetch Profiles manually,
      // or we just query normally if we need profiles immediately.
      // Actually, Supabase Realtime doesn't magically join. Let's stream conversations.
      return _supabase
          .from('conversations')
          .stream(primaryKey: ['id'])
          .order('last_message_at', ascending: false) // freshest first
          .map(
            (data) => data.map((e) => ConversationModel.fromJson(e)).toList(),
          );
    });

/// Streams the sum of all unread_admin_count for the Badge on Admin Dashboard
final adminTotalUnreadCountProvider = StreamProvider.autoDispose<int>((ref) {
  return ref.watch(adminConversationsStreamProvider.stream).map((
    conversations,
  ) {
    int total = 0;
    for (var conv in conversations) {
      total += conv.unreadAdminCount;
    }
    return total;
  });
});

/// Fetches the profile for a specific conversation
final conversationProfileProvider = FutureProvider.family
    .autoDispose<Map<String, dynamic>?, String>((ref, userId) async {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    });

/// Streams messages for a SPECIFIC conversation (Admin Side)
final adminConversationMessagesProvider = StreamProvider.family
    .autoDispose<List<MessageModel>, String>((ref, conversationId) {
      return _supabase
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true)
          .map((data) => data.map((e) => MessageModel.fromJson(e)).toList());
    });

// -------------------------------------------------------------
// ACTIONS (RPC / MUTATIONS)
// -------------------------------------------------------------

/// Fetches a Conversation by its ID
final conversationByIdProvider = FutureProvider.family
    .autoDispose<ConversationModel?, String>((ref, id) async {
      final response = await _supabase
          .from('conversations')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return ConversationModel.fromJson(response);
    });

/// Fetches user's email since profiles might not store it natively without RPC or triggers.
/// We can check if `email` exists in profiles, or fallback to an RPC.
/// If `full_name` is our only metadata, that's okay, but let's try getting email via RPC if possible.
/// Wait, Admin user management fetches users via `admin-user-actions`.
/// We can use the existing profiles table directly if email is stored there or just use `full_name`.

Future<void> userSendMessage(String conversationId, String content) async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) return;

  // Insert message
  await _supabase.from('messages').insert({
    'conversation_id': conversationId,
    'sender_id': userId,
    'is_admin': false,
    'content': content,
  });

  // Update conversation
  await _supabase
      .from('conversations')
      .update({
        'last_message': content,
        'last_message_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      })
      .eq('id', conversationId);

  // We should increment unread_admin_count. Supabase allows RPC or we can just fetch and update.
  // A clean way without RPC is executing a direct +1 if concurrency is low, or using postgres functions.
  // We'll use a direct Postgres function call if available, otherwise just update normally.
  // By default, we let's fetch then update:
  final conv = await _supabase
      .from('conversations')
      .select('unread_admin_count')
      .eq('id', conversationId)
      .single();
  final currentAdminUnread = conv['unread_admin_count'] as int? ?? 0;
  await _supabase
      .from('conversations')
      .update({'unread_admin_count': currentAdminUnread + 1})
      .eq('id', conversationId);
}

Future<void> adminSendMessage(String conversationId, String content) async {
  final userId = _supabase.auth.currentUser?.id; // Admin's user ID
  if (userId == null) return;

  // Insert message
  await _supabase.from('messages').insert({
    'conversation_id': conversationId,
    'sender_id': userId,
    'is_admin': true,
    'content': content,
  });

  // Update conversation
  await _supabase
      .from('conversations')
      .update({
        'last_message': content,
        'last_message_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      })
      .eq('id', conversationId);

  // Increment unread_user_count
  final conv = await _supabase
      .from('conversations')
      .select('unread_user_count')
      .eq('id', conversationId)
      .single();
  final currentUserUnread = conv['unread_user_count'] as int? ?? 0;
  await _supabase
      .from('conversations')
      .update({'unread_user_count': currentUserUnread + 1})
      .eq('id', conversationId);
}

Future<void> markConversationReadByUser(String conversationId) async {
  await _supabase
      .from('conversations')
      .update({'unread_user_count': 0})
      .eq('id', conversationId);
}

Future<void> markConversationReadByAdmin(String conversationId) async {
  await _supabase
      .from('conversations')
      .update({'unread_admin_count': 0})
      .eq('id', conversationId);
}

Future<void> deleteConversation(String conversationId) async {
  try {
    // 1. Fetch messages to delete images from storage
    final messages = await _supabase
        .from('messages')
        .select('content')
        .eq('conversation_id', conversationId);

    final List<String> imagesToDelete = [];
    for (final msg in messages) {
      final content = msg['content'] as String;
      if (content.startsWith('[IMAGE] ')) {
        final url = content.replaceFirst('[IMAGE] ', '');
        final uri = Uri.tryParse(url);
        if (uri != null && uri.pathSegments.contains('avatars')) {
          final avatarsIndex = uri.pathSegments.indexOf('avatars');
          if (avatarsIndex + 1 < uri.pathSegments.length) {
            final filePath = uri.pathSegments
                .sublist(avatarsIndex + 1)
                .join('/');
            imagesToDelete.add(Uri.decodeComponent(filePath));
          }
        }
      }
    }

    if (imagesToDelete.isNotEmpty) {
      await _supabase.storage.from('avatars').remove(imagesToDelete);
    }

    // 2. Clear Database using bypass RPC
    await _supabase.rpc(
      'delete_chat_admin',
      params: {'conv_id': conversationId},
    );
  } catch (e) {
    // Rethrow to be caught by UI
    throw Exception('Failed to delete conversation: $e');
  }
}

Future<String?> uploadChatImageBytes(
  Uint8List imageBytes,
  String conversationId,
  String extension,
) async {
  try {
    final fileName = 'chat/$conversationId/${const Uuid().v4()}.$extension';

    await _supabase.storage
        .from('avatars')
        .uploadBinary(
          fileName,
          imageBytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: 'image/$extension',
          ),
        );

    return _supabase.storage.from('avatars').getPublicUrl(fileName);
  } catch (e) {
    debugPrint('Error uploading chat image: $e');
    return null;
  }
}
