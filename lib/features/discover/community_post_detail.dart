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
import '../../l10n/app_localizations.dart';

class CommunityPostDetail extends ConsumerStatefulWidget {
  final CommunityPost post;

  const CommunityPostDetail({super.key, required this.post});

  @override
  ConsumerState<CommunityPostDetail> createState() =>
      _CommunityPostDetailState();
}

class _CommunityPostDetailState extends ConsumerState<CommunityPostDetail> {
  final _replyCtrl = TextEditingController();
  bool _isReplying = false;

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _isReplying = true);

    try {
      await ref
          .read(communityPostsPaginatedProvider.notifier)
          .createReply(widget.post.id, text);
      if (!mounted) return;
      _replyCtrl.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reply: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isReplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // We watch the stream of replies for this specific post
    final repliesAsync = ref.watch(communityRepliesProvider(widget.post.id));
    final isReadOnly =
        ref.watch(communityReadOnlyProvider).valueOrNull ?? false;
    final banStatus =
        ref.watch(userBanStatusProvider).valueOrNull ?? const BanStatus();
    final isRestricted = isReadOnly || banStatus.isBanned;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            PhosphorIcons.caretLeft(),
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Post Thread',
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _OriginalPostDetail(post: widget.post),
                ),
                const SliverToBoxAdapter(
                  child: Divider(height: 1, color: Colors.black12),
                ),

                // Replies Section
                repliesAsync.when(
                  data: (replies) {
                    if (replies.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 40,
                            horizontal: 20,
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                PhosphorIcon(
                                  PhosphorIcons.chatTeardrop(
                                    PhosphorIconsStyle.fill,
                                  ),
                                  size: 48,
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.beTheFirstToReply,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final reply = replies[index];
                          return _ReplyTile(
                            reply: reply,
                            postId: widget.post.id,
                          );
                        }, childCount: replies.length),
                      ),
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => SliverFillRemaining(
                    child: Center(child: Text('Error loading replies: $err')),
                  ),
                ),
              ],
            ),
          ),

          // Reply Input Bar (hidden when restricted)
          if (!isRestricted)
            Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 8,
                top: 8,
                left: 16,
                right: 16,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppTheme.darkDivider
                        : AppTheme.lightDivider,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyCtrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitReply(),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(
                          context,
                        )!.communityAddReply,
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                        prefixIcon: Icon(
                          PhosphorIcons.chatCircle(),
                          size: 20,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                        filled: true,
                        fillColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isReplying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                      onPressed: _isReplying ? null : _submitReply,
                    ),
                  ).animate().scale(curve: Curves.elasticOut),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OriginalPostDetail extends ConsumerWidget {
  final CommunityPost post;

  const _OriginalPostDetail({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pState = ref.watch(communityPostsPaginatedProvider);
    final currentPost = pState.items.firstWhere(
      (p) => p.id == post.id,
      orElse: () => post,
    );
    final authorNameAsync = ref.watch(profileNameProvider(currentPost.userId));
    final currentUser = ref.watch(currentUserProvider);
    final isOwner = currentUser?.id == currentPost.userId;
    final isAdmin = ref.watch(isAdminProvider).valueOrNull == true;

    return GestureDetector(
      onLongPress: () => _showReactionPicker(context, ref, currentPost.id),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: authorNameAsync.when(
                    data: (name) => Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) =>
                        const Icon(Icons.person, color: AppTheme.primaryColor),
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
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        loading: () => Container(
                          width: 100,
                          height: 16,
                          color: isDark ? Colors.white10 : Colors.black12,
                        ),
                        error: (_, _) => const Text('User'),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getLocalizedCategory(
                                context,
                                post.category,
                              ).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat(
                              'MMM d, yy • h:mm a',
                            ).format(post.createdAt),
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
                if (isOwner || isAdmin)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isOwner)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () async {
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
                                    AppLocalizations.of(
                                      context,
                                    )!.communityEditPost,
                                  ),
                                  content: TextField(
                                    controller: controller,
                                    maxLines: 5,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
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
                                      onPressed: () => Navigator.pop(
                                        c,
                                        controller.text.trim(),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                      ),
                                      child: Text(
                                        AppLocalizations.of(context)!.save,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (result != null &&
                                  result.isNotEmpty &&
                                  result != post.content) {
                                await ref
                                    .read(
                                      communityPostsPaginatedProvider.notifier,
                                    )
                                    .editPost(post.id, result);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                PhosphorIcons.pencilSimple(),
                                size: 16,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      GestureDetector(
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              backgroundColor: isDark
                                  ? AppTheme.darkCard
                                  : Colors.white,
                              title: Text(
                                AppLocalizations.of(context)!.deletePostTitle,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              content: Text(
                                AppLocalizations.of(context)!.deletePostContent,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(c, false),
                                  child: Text(
                                    AppLocalizations.of(context)!.cancelLabel,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.errorColor,
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!.deleteLabel,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ref
                                .read(communityPostsPaginatedProvider.notifier)
                                .deletePost(post.id);
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            PhosphorIcons.trash(),
                            size: 16,
                            color: AppTheme.errorColor,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Content
            Text(
              post.content,
              style: TextStyle(
                fontSize: 17,
                height: 1.6,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.95)
                    : Colors.black87,
              ),
            ),

            // Attached Image
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: post.imageUrl!,
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
                      child: const Icon(
                        Icons.error,
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ),
                ),
              ),

            // Shared Link
            if (post.linkUrl != null && post.linkUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse(post.linkUrl!);
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            PhosphorIcons.link(),
                            size: 20,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.linkTitle ?? 'Shared Resource',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                post.linkUrl!,
                                style: const TextStyle(
                                  fontSize: 12,
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

            if (post.reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: _ReactionsRow(
                  reactions: post.reactions,
                  postId: post.id,
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _getLocalizedCategory(BuildContext context, String category) {
    final l10n = AppLocalizations.of(context)!;
    switch (category.toLowerCase()) {
      case 'tip':
        return l10n.categoryTip;
      case 'question':
        return l10n.categoryQuestion;
      case 'resource':
        return l10n.categoryResource;
      default:
        return l10n.categoryGeneral;
    }
  }
}

class _ReplyTile extends ConsumerWidget {
  final CommunityReply reply;
  final String postId;

  const _ReplyTile({required this.reply, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authorNameAsync = ref.watch(profileNameProvider(reply.userId));

    final currentUser = ref.watch(currentUserProvider);
    final isOwner = currentUser?.id == reply.userId;
    final isAdmin = ref.watch(isAdminProvider).valueOrNull == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.accentColor.withValues(alpha: 0.1),
            child: authorNameAsync.when(
              data: (name) => Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const Icon(
                Icons.person,
                color: AppTheme.accentColor,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border.all(
                  color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
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
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        loading: () => Container(
                          width: 60,
                          height: 12,
                          color: isDark ? Colors.white10 : Colors.black12,
                        ),
                        error: (_, _) => const Text('User'),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _timeAgo(reply.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                      const Spacer(),
                      // Delete button for owner/admin
                      if (isOwner || isAdmin)
                        GestureDetector(
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: Text(
                                  AppLocalizations.of(context)!.deleteReply,
                                ),
                                content: const Text(
                                  'This action cannot be undone.',
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
                                      style: TextStyle(
                                        color: AppTheme.errorColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await ref
                                  .read(
                                    communityPostsPaginatedProvider.notifier,
                                  )
                                  .deleteReply(reply.id, postId);
                            }
                          },
                          child: Icon(
                            PhosphorIcons.trash(),
                            size: 14,
                            color: AppTheme.errorColor.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reply.content,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ).animate().fadeIn().slideX(begin: 0.1),
    );
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inDays > 7) return DateFormat('MMM d').format(t);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

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
