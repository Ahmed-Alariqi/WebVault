import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/supabase_config.dart';
import '../../data/models/community_model.dart';
import '../../presentation/providers/community_providers.dart';
import '../../presentation/widgets/shimmer_loading.dart';

class AdminCommunityScreen extends ConsumerStatefulWidget {
  const AdminCommunityScreen({super.key});

  @override
  ConsumerState<AdminCommunityScreen> createState() =>
      _AdminCommunityScreenState();
}

class _AdminCommunityScreenState extends ConsumerState<AdminCommunityScreen> {
  bool _isWiping = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(communityPostsPaginatedProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _wipeAllChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkCard
            : AppTheme.lightCard,
        title: Row(
          children: [
            Icon(
              PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
              color: AppTheme.errorColor,
            ),
            const SizedBox(width: 8),
            const Text('WIPE ALL CHAT?'),
          ],
        ),
        content: const Text(
          'This will permanently delete ALL posts, replies, and reactions in the Community '
          'to free up database storage. This action CANNOT be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text(
              'WIPE CHAT',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (mounted) setState(() => _isWiping = true);
      try {
        await SupabaseConfig.client.rpc('wipe_community_chat');
        if (mounted) {
          ref.read(communityPostsPaginatedProvider.notifier).reset();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chat successfully wiped.'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to wipe chat: \$e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isWiping = false);
      }
    }
  }

  Future<void> _togglePin(CommunityPost post) async {
    try {
      await SupabaseConfig.client
          .from('community_posts')
          .update({'is_pinned': !post.isPinned})
          .eq('id', post.id);
      ref.read(communityPostsPaginatedProvider.notifier).reset();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pin post: \$e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pState = ref.watch(communityPostsPaginatedProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Community Management'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Storage Nuclear Button
          IconButton(
            onPressed: _isWiping ? null : _wipeAllChat,
            icon: _isWiping
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    PhosphorIcons.trash(PhosphorIconsStyle.fill),
                    color: AppTheme.errorColor,
                  ),
            tooltip: 'WIPE ALL CHAT',
          ).animate().fadeIn(),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppTheme.errorColor.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.info(),
                  color: AppTheme.errorColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Use the Trash icon in the top right to permanently wipe all '
                    'community posts and free up Supabase storage space.',
                    style: TextStyle(fontSize: 13, color: AppTheme.errorColor),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: pState.isInitialLoad
                ? const ShimmerListColumn(count: 5)
                : pState.items.isEmpty
                ? const Center(child: Text('No posts in the community.'))
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: pState.items.length + (pState.hasMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index >= pState.items.length) {
                        return const ShimmerListTile();
                      }
                      final post = pState.items[index];
                      return _AdminPostTile(
                        post: post,
                        onTogglePin: () => _togglePin(post),
                        isDark: isDark,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AdminPostTile extends ConsumerWidget {
  final CommunityPost post;
  final VoidCallback onTogglePin;
  final bool isDark;

  const _AdminPostTile({
    required this.post,
    required this.onTogglePin,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorNameAsync = ref.watch(profileNameProvider(post.userId));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: post.isPinned
              ? AppTheme.accentColor
              : (isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
          width: post.isPinned ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              authorNameAsync.when(
                data: (name) => Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                loading: () => const Text('Loading...'),
                error: (_, _) => const Text('Unknown'),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('MMM d').format(post.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              const Spacer(),
              // Pin Button
              IconButton(
                icon: Icon(
                  post.isPinned
                      ? PhosphorIcons.pushPin(PhosphorIconsStyle.fill)
                      : PhosphorIcons.pushPin(),
                  color: post.isPinned ? AppTheme.accentColor : Colors.grey,
                  size: 20,
                ),
                onPressed: onTogglePin,
                tooltip: post.isPinned ? 'Unpin Post' : 'Pin Post',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
              // Delete Button
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppTheme.errorColor,
                  size: 20,
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Delete Post?'),
                      content: const Text(
                        'Are you sure you want to delete this post?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: AppTheme.errorColor),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    CommunityActions.deletePost(post.id);
                  }
                },
                tooltip: 'Delete Post',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            post.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
          if (post.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl!,
                  height: 60,
                  width: 60,
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
