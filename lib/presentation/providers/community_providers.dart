import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_config.dart';
import '../../data/models/community_model.dart';
import 'auth_providers.dart';

final _client = SupabaseConfig.client;

// -----------------------------------------------------------------------------
// PAGINATED POSTS (15 per page) — for user-facing screens
// -----------------------------------------------------------------------------

const int kCommunityPageSize = 15;

class PaginatedPostsState {
  final List<CommunityPost> items;
  final bool isLoading;
  final bool hasMore;
  final bool isInitialLoad;
  final String? error;

  const PaginatedPostsState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.isInitialLoad = true,
    this.error,
  });

  PaginatedPostsState copyWith({
    List<CommunityPost>? items,
    bool? isLoading,
    bool? hasMore,
    bool? isInitialLoad,
    String? error,
    bool clearError = false,
  }) {
    return PaginatedPostsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      isInitialLoad: isInitialLoad ?? this.isInitialLoad,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PaginatedPostsNotifier extends StateNotifier<PaginatedPostsState> {
  PaginatedPostsNotifier() : super(const PaginatedPostsState()) {
    loadMore();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final from = state.items.length;
      final to = from + kCommunityPageSize - 1;

      final response = await _client
          .from('community_posts')
          .select()
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false)
          .range(from, to);

      final newItems = (response as List)
          .map((item) => CommunityPost.fromJson(item))
          .toList();

      state = state.copyWith(
        items: [...state.items, ...newItems],
        isLoading: false,
        hasMore: newItems.length >= kCommunityPageSize,
        isInitialLoad: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isInitialLoad: false,
        error: e.toString(),
      );
    }
  }

  void reset() {
    state = const PaginatedPostsState();
    loadMore();
  }

  Future<void> createPost({
    required String content,
    String? imageUrl,
    String? linkUrl,
    String? linkTitle,
    String category = 'general',
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final response = await _client
        .from('community_posts')
        .insert({
          'user_id': user.id,
          'content': content,
          'image_url': imageUrl,
          'link_url': linkUrl,
          'link_title': linkTitle,
          'category': category,
        })
        .select()
        .single();

    final newPost = CommunityPost.fromJson(response);
    state = state.copyWith(items: [newPost, ...state.items]);
  }

  Future<void> deletePost(String postId) async {
    // Optimistic UI update
    state = state.copyWith(
      items: state.items.where((p) => p.id != postId).toList(),
    );
    await _client.from('community_posts').delete().eq('id', postId);
  }

  Future<void> createReply(String postId, String content) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('community_replies').insert({
      'post_id': postId,
      'user_id': user.id,
      'content': content,
    });

    await _client.rpc(
      'increment_reply_count',
      params: {'p_post_id': postId, 'p_amount': 1},
    );

    // Update local state instantly
    state = state.copyWith(
      items: state.items.map((p) {
        if (p.id == postId) {
          return p.copyWith(repliesCount: p.repliesCount + 1);
        }
        return p;
      }).toList(),
    );
  }

  Future<void> deleteReply(String replyId, String postId) async {
    await _client.from('community_replies').delete().eq('id', replyId);

    await _client.rpc(
      'increment_reply_count',
      params: {'p_post_id': postId, 'p_amount': -1},
    );

    // Update local state instantly
    state = state.copyWith(
      items: state.items.map((p) {
        if (p.id == postId) {
          return p.copyWith(
            repliesCount: (p.repliesCount - 1).clamp(
              0,
              999999,
            ), // Prevent negative
          );
        }
        return p;
      }).toList(),
    );
  }

  Future<void> toggleReaction(String postId, String emoji) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.rpc(
      'toggle_community_reaction',
      params: {'p_post_id': postId, 'p_user_id': user.id, 'p_emoji': emoji},
    );

    // Re-fetch the updated post to get accurate reaction counts instantly
    final response = await _client
        .from('community_posts')
        .select()
        .eq('id', postId)
        .single();
    final updatedPost = CommunityPost.fromJson(response);

    state = state.copyWith(
      items: state.items.map((p) => p.id == postId ? updatedPost : p).toList(),
    );
  }

  Future<void> editPost(String postId, String newContent) async {
    await _client
        .from('community_posts')
        .update({
          'content': newContent,
          'is_edited': true,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', postId);

    // Update local state
    state = state.copyWith(
      items: state.items.map((p) {
        if (p.id == postId) {
          return p.copyWith(content: newContent, isEdited: true);
        }
        return p;
      }).toList(),
    );
  }
}

final communityPostsPaginatedProvider =
    StateNotifierProvider.autoDispose<
      PaginatedPostsNotifier,
      PaginatedPostsState
    >((ref) {
      return PaginatedPostsNotifier();
    });

// -----------------------------------------------------------------------------
// STREAM POSTS (kept for admin only — loads all)
// -----------------------------------------------------------------------------

final communityPostsProvider = StreamProvider.autoDispose<List<CommunityPost>>((
  ref,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  return _client.from('community_posts').stream(primaryKey: ['id']).map((data) {
    final posts = data.map((item) => CommunityPost.fromJson(item)).toList();
    posts.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return posts;
  });
});

// Since streams don't do complex joins cleanly, we'll fetch authors separately in the UI
// or define a view if we want. For now, we will rely on a simple provider to fetch a profile name.
final profileNameProvider = FutureProvider.family<String, String>((
  ref,
  userId,
) async {
  final response = await _client
      .from('profiles')
      .select('full_name')
      .eq('id', userId)
      .single();
  return response['full_name'] as String? ?? 'Anonymous';
});

// -----------------------------------------------------------------------------
// SINGLE POST + REPLIES STREAM
// -----------------------------------------------------------------------------

final communityRepliesProvider = StreamProvider.family
    .autoDispose<List<CommunityReply>, String>((ref, postId) {
      return _client
          .from('community_replies')
          .stream(primaryKey: ['id'])
          .eq('post_id', postId)
          .order('created_at', ascending: true) // oldest first (chronological)
          .map(
            (data) =>
                data.map((item) => CommunityReply.fromJson(item)).toList(),
          );
    });

// -----------------------------------------------------------------------------
// APP SETTINGS (remote, from Supabase app_settings table)
// -----------------------------------------------------------------------------

/// Fetches a single app setting value by key
Future<String> _getAppSetting(String key) async {
  try {
    final response = await _client
        .from('app_settings')
        .select('value')
        .eq('key', key)
        .single();
    return response['value'] as String? ?? '';
  } catch (_) {
    return '';
  }
}

/// Updates a single app setting value by key
Future<void> updateAppSetting(String key, String value) async {
  await _client
      .from('app_settings')
      .update({'value': value, 'updated_at': DateTime.now().toIso8601String()})
      .eq('key', key);
}

/// Whether the community is in read-only mode
final communityReadOnlyProvider = FutureProvider.autoDispose<bool>((ref) async {
  final val = await _getAppSetting('community_read_only');
  return val == 'true';
});

/// The community welcome/rules message set by admin
final communityWelcomeMessageProvider = FutureProvider.autoDispose<String>((
  ref,
) async {
  return _getAppSetting('community_welcome_message');
});

// -----------------------------------------------------------------------------
// USER BAN STATUS
// -----------------------------------------------------------------------------

/// Result object for ban status
class BanStatus {
  final bool isBanned;
  final String banType; // 'mute', 'ban', or ''
  final DateTime? expiresAt;

  const BanStatus({this.isBanned = false, this.banType = '', this.expiresAt});
}

/// Checks if the current user is banned/muted from the community
final userBanStatusProvider = FutureProvider.autoDispose<BanStatus>((
  ref,
) async {
  final user = _client.auth.currentUser;
  if (user == null) return const BanStatus();

  try {
    final response = await _client
        .from('profiles')
        .select('community_ban_type, community_ban_expires_at')
        .eq('id', user.id)
        .single();

    final banType = response['community_ban_type'] as String?;
    if (banType == null) return const BanStatus();

    final expiresAtStr = response['community_ban_expires_at'] as String?;
    DateTime? expiresAt;
    if (expiresAtStr != null) {
      expiresAt = DateTime.tryParse(expiresAtStr);
      // If mute has expired, clear it and return not banned
      if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
        await _client
            .from('profiles')
            .update({
              'community_ban_type': null,
              'community_ban_expires_at': null,
              'community_banned_by': null,
            })
            .eq('id', user.id);
        return const BanStatus();
      }
    }

    return BanStatus(isBanned: true, banType: banType, expiresAt: expiresAt);
  } catch (_) {
    return const BanStatus();
  }
});

// -----------------------------------------------------------------------------
// COMMUNITY STATS (for admin dashboard)
// -----------------------------------------------------------------------------

final communityStatsProvider = FutureProvider.autoDispose<Map<String, int>>((
  ref,
) async {
  final postsCount = await _client
      .from('community_posts')
      .count(CountOption.exact);
  final repliesCount = await _client
      .from('community_replies')
      .count(CountOption.exact);

  // Posts today
  final todayStart = DateTime.now().toUtc().toIso8601String().substring(0, 10);
  final postsToday = await _client
      .from('community_posts')
      .select()
      .gte('created_at', '${todayStart}T00:00:00Z');

  return {
    'totalPosts': postsCount,
    'totalReplies': repliesCount,
    'postsToday': (postsToday as List).length,
  };
});

// -----------------------------------------------------------------------------
// ADMIN BAN/UNBAN HELPERS
// -----------------------------------------------------------------------------

/// Ban or mute a user from the community
Future<void> banCommunityUser({
  required String userId,
  required String banType, // 'mute' or 'ban'
  required String bannedBy,
  Duration? muteDuration,
}) async {
  DateTime? expiresAt;
  if (banType == 'mute' && muteDuration != null) {
    expiresAt = DateTime.now().add(muteDuration);
  }

  await _client
      .from('profiles')
      .update({
        'community_ban_type': banType,
        'community_ban_expires_at': expiresAt?.toIso8601String(),
        'community_banned_by': bannedBy,
      })
      .eq('id', userId);
}

/// Unban a user from the community
Future<void> unbanCommunityUser(String userId) async {
  await _client
      .from('profiles')
      .update({
        'community_ban_type': null,
        'community_ban_expires_at': null,
        'community_banned_by': null,
      })
      .eq('id', userId);
}

/// Get list of all currently banned/muted users
final bannedUsersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final response = await _client
          .from('profiles')
          .select('id, full_name, community_ban_type, community_ban_expires_at')
          .not('community_ban_type', 'is', null);
      return List<Map<String, dynamic>>.from(response);
    });
