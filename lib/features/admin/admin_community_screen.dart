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
import '../../presentation/providers/auth_providers.dart';
import '../../presentation/widgets/shimmer_loading.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/admin_ui_utils.dart';

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
            Text(AppLocalizations.of(context)!.wipeChatTitle),
          ],
        ),
        content: Text(AppLocalizations.of(context)!.wipeChatContent),
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
            child: Text(
              AppLocalizations.of(context)!.wipeChatAction,
              style: const TextStyle(
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
          AdminUIUtils.showSuccess(
            context,
            AppLocalizations.of(context)!.chatWipedSuccess,
          );
        }
      } catch (e) {
        if (mounted) {
          AdminUIUtils.showError(
            context,
            AppLocalizations.of(context)!.chatWipedFailed(e.toString()),
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
        AdminUIUtils.showError(
          context,
          AppLocalizations.of(context)!.pinPostFailed(e.toString()),
        );
      }
    }
  }

  Future<void> _toggleReadOnly(bool current) async {
    await updateAppSetting('community_read_only', (!current).toString());
    ref.invalidate(communityReadOnlyProvider);
  }

  Future<void> _editWelcomeMessage() async {
    final currentMsg = await ref.read(communityWelcomeMessageProvider.future);
    if (!mounted) return;
    final controller = TextEditingController(text: currentMsg);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        title: Text(AppLocalizations.of(context)!.communityWelcomeMessage),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.communityWelcomeMessageHint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              await updateAppSetting(
                'community_welcome_message',
                controller.text.trim(),
              );
              ref.invalidate(communityWelcomeMessageProvider);
              if (c.mounted) Navigator.pop(c);
              if (mounted) {
                AdminUIUtils.showSuccess(
                  context,
                  AppLocalizations.of(context)!.communityWelcomeMessageSaved,
                );
              }
            },
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
  }

  void _showBanDialog(CommunityPost post) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.read(currentUserProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.communityBanUser,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  PhosphorIcons.clockCountdown(),
                  color: Colors.orange,
                ),
                title: Text(AppLocalizations.of(context)!.communityMute24h),
                onTap: () async {
                  Navigator.pop(c);
                  await banCommunityUser(
                    userId: post.userId,
                    banType: 'mute',
                    bannedBy: currentUser!.id,
                    muteDuration: const Duration(hours: 24),
                  );
                  ref.invalidate(bannedUsersProvider);
                  if (mounted) {
                  AdminUIUtils.showSuccess(
                    context,
                    AppLocalizations.of(context)!.communityMuted,
                  );
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  PhosphorIcons.clockCountdown(),
                  color: Colors.deepOrange,
                ),
                title: Text(AppLocalizations.of(context)!.communityMute1w),
                onTap: () async {
                  Navigator.pop(c);
                  await banCommunityUser(
                    userId: post.userId,
                    banType: 'mute',
                    bannedBy: currentUser!.id,
                    muteDuration: const Duration(days: 7),
                  );
                  ref.invalidate(bannedUsersProvider);
                  if (mounted) {
                  AdminUIUtils.showSuccess(
                    context,
                    AppLocalizations.of(context)!.communityMuted,
                  );
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  PhosphorIcons.prohibit(),
                  color: AppTheme.errorColor,
                ),
                title: Text(
                  AppLocalizations.of(context)!.communityBanPermanent,
                ),
                onTap: () async {
                  Navigator.pop(c);
                  await banCommunityUser(
                    userId: post.userId,
                    banType: 'ban',
                    bannedBy: currentUser!.id,
                  );
                  ref.invalidate(bannedUsersProvider);
                  if (mounted) {
                  AdminUIUtils.showSuccess(
                    context,
                    AppLocalizations.of(context)!.communityBanned,
                  );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBannedUsers() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (c) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        builder: (_, scrollCtrl) => Consumer(
          builder: (context, ref, _) {
            final bannedAsync = ref.watch(bannedUsersProvider);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.communityBannedUsers,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: bannedAsync.when(
                    data: (users) {
                      if (users.isEmpty) {
                        return Center(
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!.communityNoBannedUsers,
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: scrollCtrl,
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final banType =
                              user['community_ban_type'] as String? ?? '';
                          final expiresAt =
                              user['community_ban_expires_at'] as String?;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.errorColor.withValues(
                                alpha: 0.1,
                              ),
                              child: Icon(
                                PhosphorIcons.userMinus(),
                                color: AppTheme.errorColor,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              user['full_name'] as String? ?? 'Unknown',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              banType == 'ban'
                                  ? AppLocalizations.of(
                                      context,
                                    )!.communityBanType
                                  : expiresAt != null
                                  ? AppLocalizations.of(
                                      context,
                                    )!.communityMuteExpires(
                                      DateFormat(
                                        'MMM d, h:mm a',
                                      ).format(DateTime.parse(expiresAt)),
                                    )
                                  : AppLocalizations.of(
                                      context,
                                    )!.communityMuteType,
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                            trailing: TextButton(
                              onPressed: () async {
                                await unbanCommunityUser(user['id'] as String);
                                ref.invalidate(bannedUsersProvider);
                                if (context.mounted) {
                                  AdminUIUtils.showSuccess(
                                    context,
                                    AppLocalizations.of(context)!
                                        .communityUnbanned,
                                  );
                                }
                              },
                              child: Text(
                                AppLocalizations.of(context)!.communityUnban,
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pState = ref.watch(communityPostsPaginatedProvider);
    final readOnlyAsync = ref.watch(communityReadOnlyProvider);
    final statsAsync = ref.watch(communityStatsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.communityManagement),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Banned users
          IconButton(
            onPressed: _showBannedUsers,
            icon: Icon(
              PhosphorIcons.identificationCard(),
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            tooltip: AppLocalizations.of(context)!.communityBannedUsers,
          ),
          // Welcome message
          IconButton(
            onPressed: _editWelcomeMessage,
            icon: Icon(
              PhosphorIcons.megaphone(),
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            tooltip: AppLocalizations.of(context)!.communityWelcomeMessage,
          ),
          // Wipe
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
            tooltip: AppLocalizations.of(context)!.wipeAllChatTooltip,
          ).animate().fadeIn(),
        ],
      ),
      body: Column(
        children: [
          // --- Stats Row ---
          statsAsync.when(
            data: (stats) => Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(
                    icon: PhosphorIcons.chatTeardrop(PhosphorIconsStyle.fill),
                    value: '${stats['totalPosts'] ?? 0}',
                    label: AppLocalizations.of(context)!.communityTotalPosts,
                    color: AppTheme.primaryColor,
                    isDark: isDark,
                  ),
                  _StatItem(
                    icon: PhosphorIcons.chatCircle(PhosphorIconsStyle.fill),
                    value: '${stats['totalReplies'] ?? 0}',
                    label: AppLocalizations.of(context)!.communityTotalReplies,
                    color: AppTheme.accentColor,
                    isDark: isDark,
                  ),
                  _StatItem(
                    icon: PhosphorIcons.calendarCheck(PhosphorIconsStyle.fill),
                    value: '${stats['postsToday'] ?? 0}',
                    label: AppLocalizations.of(context)!.communityPostsToday,
                    color: Colors.green,
                    isDark: isDark,
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // --- Read-Only Toggle ---
          readOnlyAsync.when(
            data: (isReadOnly) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isReadOnly
                    ? Colors.orange.withValues(alpha: 0.1)
                    : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isReadOnly
                      ? Colors.orange.withValues(alpha: 0.3)
                      : (isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
                ),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  AppLocalizations.of(context)!.communityReadOnlyAdmin,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!.communityReadOnlyAdminSub,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
                value: isReadOnly,
                activeThumbColor: Colors.orange,
                onChanged: (_) => _toggleReadOnly(isReadOnly),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 12),

          // --- Posts List ---
          Expanded(
            child: pState.isInitialLoad
                ? const ShimmerListColumn(count: 5)
                : pState.items.isEmpty
                ? Center(
                    child: Text(AppLocalizations.of(context)!.noCommunityPosts),
                  )
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
                        onBan: () => _showBanDialog(post),
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

// --- Stats Item Widget ---
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
      ],
    );
  }
}

// --- Post Tile ---
class _AdminPostTile extends ConsumerWidget {
  final CommunityPost post;
  final VoidCallback onTogglePin;
  final VoidCallback onBan;
  final bool isDark;

  const _AdminPostTile({
    required this.post,
    required this.onTogglePin,
    required this.onBan,
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
              if (post.isPinned) ...[
                const SizedBox(width: 6),
                Icon(
                  PhosphorIcons.pushPin(PhosphorIconsStyle.fill),
                  size: 14,
                  color: AppTheme.accentColor,
                ),
              ],
              const Spacer(),
              // Ban Button
              IconButton(
                icon: Icon(
                  PhosphorIcons.prohibit(),
                  color: Colors.orange,
                  size: 18,
                ),
                onPressed: onBan,
                tooltip: AppLocalizations.of(context)!.communityBanUser,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
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
                tooltip: post.isPinned
                    ? AppLocalizations.of(context)!.unpinPostTooltip
                    : AppLocalizations.of(context)!.pinPostTooltip,
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
                      title: Text(
                        AppLocalizations.of(context)!.deletePostTitle,
                      ),
                      content: Text(
                        AppLocalizations.of(context)!.deletePostContent,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: Text(AppLocalizations.of(context)!.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: Text(
                            AppLocalizations.of(context)!.deletePostAction,
                            style: const TextStyle(color: AppTheme.errorColor),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    ref
                        .read(communityPostsPaginatedProvider.notifier)
                        .deletePost(post.id);
                  }
                },
                tooltip: AppLocalizations.of(context)!.deletePostAction,
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
