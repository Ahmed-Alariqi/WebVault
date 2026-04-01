import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/widgets/offline_warning_widget.dart';
import '../../data/models/community_model.dart';
import '../../presentation/providers/community_providers.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../presentation/widgets/shimmer_loading.dart';
import '../../presentation/widgets/modern_fab.dart';
import 'community_new_post_sheet.dart';
import '../../l10n/app_localizations.dart';

void _showReactionPicker(BuildContext context, WidgetRef ref, String postId) {
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
                    ref
                        .read(communityPostsPaginatedProvider.notifier)
                        .toggleReaction(postId, e);
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
  String _searchQuery = '';

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
    final readOnlyAsync = ref.watch(communityReadOnlyProvider);
    final banStatusAsync = ref.watch(userBanStatusProvider);
    final welcomeAsync = ref.watch(communityWelcomeMessageProvider);

    final isReadOnly = readOnlyAsync.valueOrNull ?? false;
    final banStatus = banStatusAsync.valueOrNull ?? const BanStatus();
    final isRestricted = isReadOnly || banStatus.isBanned;

    // Client-side category + search filtering
    var filteredPosts = selectedCategory == 'all'
        ? pState.items
        : pState.items.where((p) => p.category == selectedCategory).toList();
    if (_searchQuery.isNotEmpty) {
      filteredPosts = filteredPosts
          .where(
            (p) => p.content.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

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
              AppLocalizations.of(context)!.communityTitle,
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
          // Search Toggle
          IconButton(
            icon: Icon(
              PhosphorIcons.magnifyingGlass(),
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            tooltip: AppLocalizations.of(context)!.search,
            onPressed: () {
              showSearch(
                context: context,
                delegate: _CommunitySearchDelegate(
                  posts: pState.items,
                  isDark: isDark,
                  onQuery: (q) => setState(() => _searchQuery = q),
                ),
              );
            },
          ),
          Consumer(
            builder: (context, ref, _) {
              final isAdmin = ref.watch(isAdminProvider).valueOrNull == true;
              if (isAdmin) {
                return IconButton(
                  icon: Icon(
                    PhosphorIcons.crown(PhosphorIconsStyle.fill),
                    color: AppTheme.primaryColor,
                  ),
                  tooltip: AppLocalizations.of(context)!.adminDashboard,
                  onPressed: () => context.push('/admin/community'),
                ).animate().fadeIn().scale();
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Welcome Banner ---
          welcomeAsync.when(
            data: (msg) {
              if (msg.isEmpty) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIcons.megaphone(PhosphorIconsStyle.fill),
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        msg,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.1);
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // --- Read-Only / Ban Banner ---
          if (isReadOnly)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_outline,
                    color: Colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.communityReadOnlyBanner,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn()
          else if (banStatus.isBanned)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.errorColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.block, color: AppTheme.errorColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      banStatus.banType == 'mute'
                          ? AppLocalizations.of(context)!.communityMutedBanner
                          : AppLocalizations.of(context)!.communityBannedBanner,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),

          // Category Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                _FilterChip(
                  label: AppLocalizations.of(context)!.categoryAll,
                  value: 'all',
                  selectedValue: selectedCategory,
                ),
                _FilterChip(
                  label: AppLocalizations.of(context)!.categoryGeneral,
                  value: 'general',
                  selectedValue: selectedCategory,
                ),
                _FilterChip(
                  label: AppLocalizations.of(context)!.categoryQuestions,
                  value: 'question',
                  selectedValue: selectedCategory,
                ),
                _FilterChip(
                  label: AppLocalizations.of(context)!.categoryTips,
                  value: 'tip',
                  selectedValue: selectedCategory,
                ),
                _FilterChip(
                  label: AppLocalizations.of(context)!.categoryResources,
                  value: 'resource',
                  selectedValue: selectedCategory,
                ),
              ],
            ),
          ),

          Expanded(
            child: pState.error != null
                ? Center(
                    child: GestureDetector(
                      onTap: () => ref
                          .read(communityPostsPaginatedProvider.notifier)
                          .reset(),
                      child: OfflineWarningWidget(error: pState.error!),
                    ),
                  )
                : pState.isInitialLoad
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: isRestricted
          ? null
          : ModernFab.extended(
              onPressed: () => _showNewPostSheet(context),
              icon: Icon(PhosphorIcons.plusCircle(PhosphorIconsStyle.fill)),
              label: Text(AppLocalizations.of(context)!.post),
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
      onLongPress: () => _showReactionPicker(context, ref, post.id),
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
                            AppLocalizations.of(
                              context,
                            )!.pinnedPost.toUpperCase(),
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
                          await ref
                              .read(communityPostsPaginatedProvider.notifier)
                              .deletePost(post.id);
                        } else if (value == 'edit') {
                          final canEdit =
                              DateTime.now()
                                  .difference(post.createdAt)
                                  .inMinutes <=
                              15;
                          if (!canEdit) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.communityEditTimeExpired,
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                          final controller = TextEditingController(
                            text: post.content,
                          );
                          final result = await showDialog<String>(
                            context: context,
                            builder: (c) => AlertDialog(
                              backgroundColor: isDark
                                  ? AppTheme.darkCard
                                  : Colors.white,
                              title: Text(
                                AppLocalizations.of(context)!.communityEditPost,
                              ),
                              content: TextField(
                                controller: controller,
                                maxLines: 5,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(c),
                                  child: Text(
                                    AppLocalizations.of(context)!.cancel,
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(c, controller.text.trim()),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!.save,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (result != null &&
                              result.isNotEmpty &&
                              result != post.content) {
                            await ref
                                .read(communityPostsPaginatedProvider.notifier)
                                .editPost(post.id, result);
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        if (isOwner)
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  PhosphorIcons.pencilSimple(),
                                  color: AppTheme.primaryColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.communityEditPost,
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.content,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.black87,
                    ),
                  ),
                  if (post.isEdited)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '(${AppLocalizations.of(context)!.communityEdited})',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ),
                ],
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

class _ReactionsRow extends ConsumerWidget {
  final Map<String, dynamic> reactions;
  final String postId;

  const _ReactionsRow({required this.reactions, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reactions.isEmpty) return const SizedBox.shrink(); // rely on long press

    return Row(
      children: reactions.entries.take(4).map((entry) {
        return GestureDetector(
          onTap: () => ref
              .read(communityPostsPaginatedProvider.notifier)
              .toggleReaction(postId, entry.key),
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
          AppLocalizations.of(context)!.beTheFirstToPost,
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
          AppLocalizations.of(context)!.shareAResourceAskAQuestion,
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
          icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold)),
          label: Text(
            AppLocalizations.of(context)!.createAPost,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

// --- Search Delegate for Community Posts ---
class _CommunitySearchDelegate extends SearchDelegate<String> {
  final List<CommunityPost> posts;
  final bool isDark;
  final void Function(String) onQuery;

  _CommunitySearchDelegate({
    required this.posts,
    required this.isDark,
    required this.onQuery,
  });

  @override
  String get searchFieldLabel => '';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          onQuery('');
        },
      ),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: Icon(PhosphorIcons.caretLeft()),
    onPressed: () {
      onQuery('');
      close(context, '');
    },
  );

  @override
  Widget buildResults(BuildContext context) {
    onQuery(query);
    close(context, query);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = query.isEmpty
        ? <CommunityPost>[]
        : posts
              .where(
                (p) => p.content.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();

    if (query.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.communitySearchHint,
          style: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
        ),
      );
    }

    if (results.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.communityNoSearchResults,
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final post = results[index];
        return ListTile(
          title: Text(
            post.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            DateFormat.yMMMd().format(post.createdAt),
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 12,
            ),
          ),
          onTap: () {
            onQuery('');
            close(context, '');
            context.push('/community/post/${post.id}', extra: post);
          },
        );
      },
    );
  }
}
