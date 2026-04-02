import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/discover_providers.dart';
import '../../presentation/providers/providers.dart';
import '../../data/models/notification_model.dart';
import '../../presentation/widgets/notification_details_dialog.dart';
import '../../presentation/widgets/offline_warning_widget.dart';
import '../../presentation/widgets/shimmer_loading.dart';
import '../../l10n/app_localizations.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      markNotificationsRead(ref);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(notificationsPaginatedProvider.notifier).loadMore();
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
    final pState = ref.watch(notificationsPaginatedProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notifications),
        forceMaterialTransparency: true,
      ),
      body: pState.isInitialLoad
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: List.generate(5, (_) => const ShimmerListTile()),
              ),
            )
          : pState.items.isEmpty && !pState.isLoading
          ? _buildEmptyState(context, isDark)
          : RefreshIndicator(
              onRefresh: () async =>
                  ref.read(notificationsPaginatedProvider.notifier).reset(),
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: pState.items.length + (pState.hasMore ? 1 : 0),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index >= pState.items.length) {
                    return const ShimmerListTile();
                  }
                  final notification = pState.items[index];
                  return _NotificationCard(
                    notification: notification,
                    isDark: isDark,
                  ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    // If we have an error and items list is empty, we show offline/error warning
    final pState = ref.watch(notificationsPaginatedProvider);
    if (pState.error != null) {
      return Center(
        child: GestureDetector(
          onTap: () =>
              ref.read(notificationsPaginatedProvider.notifier).reset(),
          child: OfflineWarningWidget(error: pState.error!),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.bellSlash(),
            size: 64,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noNotifications,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final bool isDark;

  const _NotificationCard({required this.notification, required this.isDark});

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'alert':
        return Colors.redAccent;
      case 'update':
        return Colors.blueAccent;
      case 'announcement':
        return Colors.orangeAccent;
      case 'new_item':
        return const Color(0xFF4CAF50);
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'alert':
        return PhosphorIcons.warningCircle();
      case 'update':
        return PhosphorIcons.arrowsClockwise();
      case 'announcement':
        return PhosphorIcons.megaphone();
      case 'new_item':
        return PhosphorIcons.sparkle();
      default:
        return PhosphorIcons.info();
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeAgo = _formatTimeAgo(context, notification.createdAt);
    final color = _getTypeColor(notification.type);
    final isUnread = !notification.isRead;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark ? AppTheme.darkCard : AppTheme.lightCard,
            isDark
                ? color.withValues(alpha: 0.06)
                : color.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isUnread
              ? color.withValues(alpha: 0.3)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : color.withValues(alpha: 0.08)),
          width: isUnread ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isUnread ? 0.08 : 0.03),
            blurRadius: isUnread ? 20 : 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Unify tapping to open the beautiful Notification dialog popup
            showDialog(
              context: context,
              builder: (ctx) =>
                  NotificationDetailsDialog(notification: notification),
            );
          },
          borderRadius: BorderRadius.circular(24),
          highlightColor: color.withValues(alpha: 0.05),
          splashColor: color.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Badge Container
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    image:
                        notification.imageUrl != null &&
                            notification.imageUrl!.isNotEmpty
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(
                              notification.imageUrl!,
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child:
                      notification.imageUrl == null ||
                          notification.imageUrl!.isEmpty
                      ? Icon(
                          _getTypeIcon(notification.type),
                          color: color,
                          size: 24,
                        )
                      : null,
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isUnread
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.lightTextPrimary,
                              ),
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.6),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              timeAgo,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Action Pill snippet
                      if (notification.targetUrl != null &&
                          notification.targetUrl!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    notification.type == 'new_item'
                                        ? PhosphorIcons.sparkle()
                                        : PhosphorIcons.link(),
                                    size: 12,
                                    color: color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    notification.type == 'new_item'
                                        ? AppLocalizations.of(context)!.trending
                                        : AppLocalizations.of(context)!.openUrl,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(BuildContext context, DateTime dateTime) {
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 7) {
      return DateFormat('MMM d').format(dateTime);
    } else if (diff.inDays >= 1) {
      return l10n.timeDaysAgo(diff.inDays);
    } else if (diff.inHours >= 1) {
      return l10n.timeHoursAgo(diff.inHours);
    } else if (diff.inMinutes >= 1) {
      return l10n.timeMinutesAgo(diff.inMinutes);
    } else {
      return l10n.timeJustNow;
    }
  }
}
