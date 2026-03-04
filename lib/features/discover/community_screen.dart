import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/community_model.dart';
import '../../presentation/providers/community_providers.dart';
import '../../presentation/providers/auth_providers.dart';
import 'community_new_post_sheet.dart';
import '../../presentation/widgets/shimmer_loading.dart';

void _showReactionPicker(BuildContext context, String postId) {
  final emojis = ['👍', '❤️', '🔥', '💡', '😂', '👏'];
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.min,
          children: emojis
              .map(
                (e) => GestureDetector(
                  onTap: () {
                    CommunityActions.toggleReaction(postId, e);
                    Navigator.pop(context);
                  },
                  child:
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 28)),
                      ).animate().scale(
                        curve: Curves.easeOutBack,
                        duration: 400.ms,
                      ),
                ),
              )
              .toList(),
        ),
      );
    },
  );
}

// State provider for the currently selected category filter
final communityCategoryFilterProvider = StateProvider<String>((ref) => 'all');

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pState = ref.watch(communityPostsPaginatedProvider);
    final selectedCategory = ref.watch(communityCategoryFilterProvider);

    // Client-side category filtering
    final filteredPosts = selectedCategory == 'all'
        ? pState.items
        : pState.items.where((p) => p.category == selectedCategory).toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            PhosphorIcons.caretLeft(),
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.globeHemisphereWest(PhosphorIconsStyle.fill),
              color: AppTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Community',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final isAdmin = ref.watch(isAdminProvider).valueOrNull == true;
              if (isAdmin) {
                return IconButton(
                  icon: Icon(
                    PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
                    color: AppTheme.primaryColor,
                  ),
                  tooltip: 'Admin Panel',
                  onPressed: () => context.push('/admin/community'),
                ).animate().fadeIn().scale();
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: Icon(
              PhosphorIcons.notePencil(PhosphorIconsStyle.fill),
              color: AppTheme.accentColor,
            ),
            tooltip: 'New Post',
            onPressed: () => _showNewPostSheet(context),
          ).animate().fadeIn().scale(),
        ],
      ),
      body: Column(
        children: [
          // Category Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  value: 'all',
                  selectedValue: selectedCategory,
                ),
                _FilterChip(
                  label: 'General',
                  value: 'general',
                  selectedValue: selectedCategory,
                ),
                _FilterChip(
                  label: 'Questions',
                  value: 'question',
                  selectedValue: selectedCategory,
                ),
                _FilterChip(
                  label: 'Tips',
                  value: 'tip',
                  selectedValue: selectedCategory,
                ),
                _FilterChip(
                  label: 'Resources',
                  value: 'resource',
                  selectedValue: selectedCategory,
                ),
              ],
            ),
          ),

          Expanded(
            child: pState.isInitialLoad
                ? const ShimmerListColumn(count: 4)
                : filteredPosts.isEmpty
                ? _EmptyCommunityState(
                    isDark: isDark,
                    onPostTap: () => _showNewPostSheet(context),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: filteredPosts.length + (pState.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= filteredPosts.length) {
                        return const ShimmerListTile();
                      }
                      final post = filteredPosts[index];
                      return _CommunityPostCard(
                        key: ValueKey(post.id),
                        post: post,
                        isDark: isDark,
                        index: index,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewPostSheet(context),
        backgroundColor: AppTheme.primaryColor,
        icon: Icon(
          PhosphorIcons.pencilSimple(PhosphorIconsStyle.bold),
          color: Colors.white,
        ),
        label: const Text(
          'Post',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ).animate().slideY(begin: 1.0, curve: Curves.easeOutBack),
    );
  }

  void _showNewPostSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CommunityNewPostSheet(),
    );
  }
}

class _FilterChip extends ConsumerWidget {
  final String label;
  final String value;
  final String selectedValue;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selectedValue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = value == selectedValue;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
        selected: isSelected,
        onSelected: (_) {
          ref.read(communityCategoryFilterProvider.notifier).state = value;
        },
        selectedColor: AppTheme.primaryColor,
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        side: BorderSide(
          color: isSelected
              ? Colors.transparent
              : (isDark ? Colors.white12 : Colors.black12),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class _CommunityPostCard extends ConsumerWidget {
  final CommunityPost post;
  final bool isDark;
  final int index;

  const _CommunityPostCard({
    super.key,
    required this.post,
    required this.isDark,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorNameAsync = ref.watch(profileNameProvider(post.userId));
    final currentUser = ref.watch(currentUserProvider);
    final isOwner = currentUser?.id == post.userId;
    final isAdmin = ref.watch(isAdminProvider).valueOrNull == true;

    return GestureDetector(
      onTap: () => context.push('/community/post/${post.id}', extra: post),
      onLongPress: () => _showReactionPicker(context, post.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: post.isPinned
                ? AppTheme.accentColor.withValues(alpha: 0.5)
                : (isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
            width: post.isPinned ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Author & Time
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primaryColor.withValues(
                      alpha: 0.1,
                    ),
                    child: authorNameAsync.when(
                      data: (name) => Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const Icon(
                        Icons.person,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        authorNameAsync.when(
                          data: (name) => Text(
                            name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          loading: () => Container(
                            width: 80,
                            height: 14,
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                          error: (_, _) => const Text('User'),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              post.category.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: _getCategoryColor(post.category),
                              ),
                            ),
                            Text(
                              ' • ${DateFormat.yMMMd().format(post.createdAt)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (post.isPinned)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            PhosphorIcons.pushPin(PhosphorIconsStyle.fill),
                            size: 12,
                            color: AppTheme.accentColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'PINNED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (isOwner || isAdmin)
                    PopupMenuButton<String>(
                      icon: Icon(
                        PhosphorIcons.dotsThree(),
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                      color: isDark ? AppTheme.darkCard : Colors.white,
                      onSelected: (value) async {
                        if (value == 'delete') {
                          await CommunityActions.deletePost(post.id);
                        }
                      },
                      itemBuilder: (context) => [
                        if (isOwner || isAdmin)
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  PhosphorIcons.trash(),
                                  color: AppTheme.errorColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Delete',
                                  style: TextStyle(color: AppTheme.errorColor),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                post.content,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.black87,
                ),
              ),
            ),

            // Link Preview
            if (post.linkUrl != null && post.linkUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12, left: 20, right: 20),
                child: GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse(post.linkUrl!);
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            PhosphorIcons.link(),
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.linkTitle ?? 'Shared Link',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                post.linkUrl!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Attached Image
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: isDark ? Colors.white10 : Colors.black12,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 100,
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    child: const Icon(Icons.error, color: AppTheme.errorColor),
                  ),
                ),
              ),

            // Footer (Reactions & Replies)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  _ReactionsRow(reactions: post.reactions, postId: post.id),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        PhosphorIcons.chatTeardrop(),
                        size: 18,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.repliesCount}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'tip':
        return const Color(0xFF10B981); // Emerald
      case 'question':
        return const Color(0xFFF59E0B); // Amber
      case 'resource':
        return const Color(0xFF6366F1); // Indigo
      default:
        return AppTheme.primaryColor;
    }
  }
}

class _ReactionsRow extends StatelessWidget {
  final Map<String, dynamic> reactions;
  final String postId;

  const _ReactionsRow({required this.reactions, required this.postId});

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink(); // rely on long press

    return Row(
      children: reactions.entries.take(4).map((entry) {
        return GestureDetector(
          onTap: () => CommunityActions.toggleReaction(postId, entry.key),
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Text(entry.key, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text(
                  '${entry.value}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ).animate().scale(duration: 200.ms, curve: Curves.easeOut),
        );
      }).toList(),
    );
  }
}

class _EmptyCommunityState extends StatelessWidget {
  final bool isDark;
  final VoidCallback onPostTap;

  const _EmptyCommunityState({required this.isDark, required this.onPostTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            PhosphorIcons.usersThree(PhosphorIconsStyle.duotone),
            color: AppTheme.primaryColor,
            size: 48,
          ),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 24),
        Text(
          'Be the first to post!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Share a resource, ask a question,\nor give a tip to the community.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: onPostTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), size: 18),
          label: const Text(
            'Create Post',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
