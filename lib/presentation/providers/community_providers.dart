import 'package:flutter_riverpod/flutter_riverpod.dart';
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
// ACTIONS (Create/Delete)
// -----------------------------------------------------------------------------

class CommunityActions {
  static Future<void> createPost({
    required String content,
    String? imageUrl,
    String? linkUrl,
    String? linkTitle,
    String category = 'general',
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('community_posts').insert({
      'user_id': user.id,
      'content': content,
      'image_url': imageUrl,
      'link_url': linkUrl,
      'link_title': linkTitle,
      'category': category,
    });
  }

  static Future<void> deletePost(String postId) async {
    await _client.from('community_posts').delete().eq('id', postId);
  }

  static Future<void> createReply(String postId, String content) async {
    // React/Reply triggers count update via RPC
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('community_replies').insert({
      'post_id': postId,
      'user_id': user.id,
      'content': content,
    });

    // Use RPC safely to increment the reply count globally for all users
    await _client.rpc(
      'increment_reply_count',
      params: {'p_post_id': postId, 'p_amount': 1},
    );
  }

  static Future<void> deleteReply(String replyId, String postId) async {
    await _client.from('community_replies').delete().eq('id', replyId);

    // Decrement reply count safely via RPC
    await _client.rpc(
      'increment_reply_count',
      params: {'p_post_id': postId, 'p_amount': -1},
    );
  }

  static Future<void> toggleReaction(String postId, String emoji) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    // Call the newly created Supabase RPC which handles upsert/delete and reactions math safely regardless of the post's author.
    await _client.rpc(
      'toggle_community_reaction',
      params: {'p_post_id': postId, 'p_user_id': user.id, 'p_emoji': emoji},
    );
  }
}
