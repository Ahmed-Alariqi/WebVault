import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/supabase_config.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/website_model.dart';
import 'website_details_dialog.dart';
import 'event_detail_dialogs.dart';
import '../../presentation/providers/events_providers.dart';
import '../../l10n/app_localizations.dart';

class NotificationDetailsDialog extends ConsumerWidget {
  final NotificationModel notification;

  const NotificationDetailsDialog({super.key, required this.notification});

  Future<void> _openUrl(
    BuildContext context,
    String url, {
    bool inApp = true,
  }) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: inApp ? LaunchMode.inAppWebView : LaunchMode.externalApplication,
      );
    }
  }

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
      case 'giveaway':
        return AppTheme.primaryColor;
      case 'poll':
        return AppTheme.accentColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'alert':
        return PhosphorIcons.warningCircle(PhosphorIconsStyle.fill);
      case 'update':
        return PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.fill);
      case 'announcement':
        return PhosphorIcons.megaphone(PhosphorIconsStyle.fill);
      case 'new_item':
        return PhosphorIcons.sparkle(PhosphorIconsStyle.fill);
      case 'giveaway':
        return PhosphorIcons.gift(PhosphorIconsStyle.fill);
      case 'poll':
        return PhosphorIcons.chartBar(PhosphorIconsStyle.fill);
      default:
        return PhosphorIcons.info(PhosphorIconsStyle.fill);
    }
  }

  String _getLocalizedType(BuildContext context, String type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type.toLowerCase()) {
      case 'alert':
        return l10n.notifAlert;
      case 'update':
        return l10n.notifTypeUpdate;
      case 'announcement':
        return l10n.notifTypeAnnouncement;
      case 'new_item':
        return l10n.notifTypeNewItem;
      case 'giveaway':
        return l10n.notifTypeGiveaway;
      case 'poll':
        return l10n.notifTypePoll;
      default:
        return l10n.notifTypeGeneral;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getTypeColor(notification.type);
    final l10n = AppLocalizations.of(context)!;
    final timeAgo = _formatTimeAgo(context, notification.createdAt);
    final typeLabel = _getLocalizedType(context, notification.type);

    return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: -5,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Image Box
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      child:
                          notification.imageUrl != null &&
                              notification.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: notification.imageUrl!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 180,
                                color: color.withValues(alpha: 0.1),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 180,
                                color: color.withValues(alpha: 0.1),
                                child: const Center(
                                  child: Icon(Icons.broken_image),
                                ),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(vertical: 36),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    color.withValues(alpha: 0.2),
                                    color.withValues(alpha: 0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child:
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: color.withValues(alpha: 0.2),
                                            blurRadius: 20,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        _getTypeIcon(notification.type),
                                        size: 64,
                                        color: color,
                                      ),
                                    ),
                                  ).animate().scale(
                                    duration: 400.ms,
                                    curve: Curves.easeOutBack,
                                  ),
                            ),
                    ),

                    // Content Body
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.lightTextPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Badges row
                            Row(
                              children: [
                                _badge(typeLabel.toUpperCase(), color, isDark),
                                const SizedBox(width: 8),
                                Text(
                                  timeAgo,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Divider
                            Divider(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.05),
                            ),
                            const SizedBox(height: 16),

                            // Full Description
                            Text(
                              notification.body,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                            ),

                            if (notification.targetUrl != null &&
                                notification.targetUrl!.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Divider(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.05),
                              ),
                              const SizedBox(height: 16),

                              // Check if this is an event notification
                              if (notification.targetUrl!.contains(
                                    'app://events/giveaway/',
                                  ) ||
                                  notification.targetUrl!.contains(
                                    'app://events/poll/',
                                  )) ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final navContext = Navigator.of(
                                        context,
                                        rootNavigator: true,
                                      ).context;
                                      Navigator.of(context).pop();

                                      final url = notification.targetUrl!;
                                      if (url.contains(
                                        'app://events/giveaway/',
                                      )) {
                                        final gId = url.replaceFirst(
                                          'app://events/giveaway/',
                                          '',
                                        );
                                        try {
                                          final g = await ref.read(
                                            giveawayByIdProvider(gId).future,
                                          );
                                          if (g != null && navContext.mounted) {
                                            showDialog(
                                              context: navContext,
                                              builder: (_) =>
                                                  GiveawayDetailDialog(
                                                    giveaway: g,
                                                  ),
                                            );
                                            return;
                                          }
                                        } catch (_) {}
                                      } else {
                                        final pId = url.replaceFirst(
                                          'app://events/poll/',
                                          '',
                                        );
                                        try {
                                          final p = await ref.read(
                                            pollByIdProvider(pId).future,
                                          );
                                          if (p != null && navContext.mounted) {
                                            showDialog(
                                              context: navContext,
                                              builder: (_) =>
                                                  PollDetailDialog(poll: p),
                                            );
                                            return;
                                          }
                                        } catch (_) {}
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: color,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    icon: Icon(
                                      notification.targetUrl!.contains(
                                            'giveaway',
                                          )
                                          ? PhosphorIcons.gift(
                                              PhosphorIconsStyle.fill,
                                            )
                                          : PhosphorIcons.chartBar(
                                              PhosphorIconsStyle.fill,
                                            ),
                                      size: 20,
                                    ),
                                    label: Text(
                                      notification.targetUrl!.contains(
                                            'giveaway',
                                          )
                                          ? l10n.viewGiveaway
                                          : l10n.viewPoll,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ] else if (notification.type == 'new_item' ||
                                  notification.targetUrl!.contains(
                                    'app://discover/item/',
                                  )) ...[
                                // "Explore Now" single button for new item notifications
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      // Capture the root navigator context BEFORE popping
                                      final navContext = Navigator.of(
                                        context,
                                        rootNavigator: true,
                                      ).context;
                                      Navigator.of(context).pop();

                                      // Try to extract item ID and open its card
                                      final itemId = _extractItemId(
                                        notification.targetUrl!,
                                      );
                                      if (itemId != null) {
                                        try {
                                          final resp = await SupabaseConfig
                                              .client
                                              .from('websites')
                                              .select()
                                              .eq('id', itemId)
                                              .maybeSingle();

                                          if (resp != null &&
                                              navContext.mounted) {
                                            final site = WebsiteModel.fromJson(
                                              resp,
                                            );
                                            GoRouter.of(
                                              navContext,
                                            ).go('/discover');
                                            // Small delay to let route settle
                                            await Future.delayed(
                                              const Duration(milliseconds: 300),
                                            );
                                            if (navContext.mounted) {
                                              showDialog(
                                                context: navContext,
                                                builder: (ctx) =>
                                                    WebsiteDetailsDialog(
                                                      site: site,
                                                    ),
                                              );
                                            }
                                            return;
                                          }
                                        } catch (_) {
                                          // Fallback to just navigating
                                        }
                                      }
                                      if (navContext.mounted) {
                                        GoRouter.of(navContext).go('/discover');
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: color,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    icon: Icon(
                                      PhosphorIcons.compassTool(
                                        PhosphorIconsStyle.fill,
                                      ),
                                      size: 20,
                                    ),
                                    label: Text(
                                      l10n.exploreNow,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                // Standard URL notification
                                Text(
                                  l10n.attachedLink,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          if (notification.targetUrl!
                                              .startsWith('app://')) {
                                            final route = notification
                                                .targetUrl!
                                                .replaceFirst('app:/', '');
                                            Navigator.of(context).pop();
                                            context.go(route);
                                          } else {
                                            _openUrl(
                                              context,
                                              notification.targetUrl!,
                                              inApp: true,
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: color,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        icon: Icon(
                                          PhosphorIcons.rocketLaunch(
                                            PhosphorIconsStyle.fill,
                                          ),
                                          size: 20,
                                        ),
                                        label: Text(
                                          l10n.openLink,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (!notification.targetUrl!.startsWith(
                                      'app://',
                                    )) ...[
                                      const SizedBox(width: 12),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.05,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.05,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: IconButton(
                                          onPressed: () {
                                            _openUrl(
                                              context,
                                              notification.targetUrl!,
                                              inApp: false,
                                            );
                                          },
                                          icon: Icon(
                                            PhosphorIcons.browser(),
                                            size: 22,
                                          ),
                                          color: isDark
                                              ? AppTheme.darkTextPrimary
                                              : AppTheme.lightTextPrimary,
                                          tooltip: l10n.openInBrowser,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Close Button Overlay
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack);
  }

  Widget _badge(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  String _formatTimeAgo(BuildContext context, DateTime dateTime) {
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 7) {
      return DateFormat('MMM d, yyyy').format(dateTime);
    } else if (diff.inDays >= 1) {
      return l10n.timeDaysAgoFull(diff.inDays);
    } else if (diff.inHours >= 1) {
      return l10n.timeHoursAgoFull(diff.inHours);
    } else if (diff.inMinutes >= 1) {
      return l10n.timeMinutesAgoFull(diff.inMinutes);
    } else {
      return l10n.timeJustNow;
    }
  }

  /// Extract item ID from app://discover/item/[id] URL format
  String? _extractItemId(String url) {
    const prefix = 'app://discover/item/';
    if (url.startsWith(prefix)) {
      return url.substring(prefix.length);
    }
    return null;
  }
}
