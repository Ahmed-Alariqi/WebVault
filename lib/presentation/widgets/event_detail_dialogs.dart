import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/giveaway_model.dart';
import '../../data/models/poll_model.dart';
import '../../presentation/providers/events_providers.dart';
import '../../l10n/app_localizations.dart';

// ════════════════════════════════════════
//  GIVEAWAY DETAIL DIALOG
// ════════════════════════════════════════

class GiveawayDetailDialog extends ConsumerWidget {
  final Giveaway giveaway;
  const GiveawayDetailDialog({super.key, required this.giveaway});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final isActive = giveaway.isActive;
    final isDrawn = giveaway.isDrawn;
    final color = isDrawn
        ? AppTheme.successColor
        : isActive
        ? AppTheme.primaryColor
        : Colors.grey;

    final statusLabel = isDrawn
        ? l10n.drawn
        : isActive
        ? l10n.active
        : l10n.ended;

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
                    // Header Image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      child:
                          giveaway.imageUrl != null &&
                              giveaway.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: giveaway.imageUrl!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                height: 200,
                                color: color.withValues(alpha: 0.1),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (_, __, ___) => _iconHeader(color),
                            )
                          : _iconHeader(color),
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
                              giveaway.title,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Badges
                            Row(
                              children: [
                                _badge(statusLabel, color, isDark),
                                const SizedBox(width: 8),
                                _badge(
                                  _prizeLabel(giveaway.prizeType, l10n),
                                  AppTheme.accentColor,
                                  isDark,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Description
                            if (giveaway.description != null &&
                                giveaway.description!.isNotEmpty) ...[
                              Divider(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.06),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                giveaway.description!,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.6,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Stats Row
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : Colors.black.withValues(alpha: 0.02),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.black.withValues(alpha: 0.04),
                                ),
                              ),
                              child: Row(
                                children: [
                                  _stat(
                                    PhosphorIcons.users(),
                                    '${giveaway.entryCount}',
                                    l10n.entries,
                                    isDark,
                                  ),
                                  Container(
                                    width: 1,
                                    height: 32,
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.black12,
                                  ),
                                  _stat(
                                    PhosphorIcons.clockCountdown(),
                                    _timeValue(giveaway.endsAt),
                                    isActive ? l10n.timeLeft : l10n.ended,
                                    isDark,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Enter button
                            if (isActive)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: giveaway.hasEntered
                                      ? null
                                      : () async {
                                          await enterGiveaway(giveaway.id, ref);
                                          if (context.mounted) {
                                            Navigator.of(context).pop();
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: giveaway.hasEntered
                                        ? (isDark
                                              ? Colors.white10
                                              : Colors.black12)
                                        : AppTheme.primaryColor,
                                    foregroundColor: giveaway.hasEntered
                                        ? (isDark
                                              ? Colors.white38
                                              : Colors.black38)
                                        : Colors.white,
                                    disabledBackgroundColor: isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : Colors.black.withValues(alpha: 0.06),
                                    disabledForegroundColor: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  icon: Icon(
                                    giveaway.hasEntered
                                        ? PhosphorIcons.checkCircle(
                                            PhosphorIconsStyle.fill,
                                          )
                                        : PhosphorIcons.ticket(
                                            PhosphorIconsStyle.fill,
                                          ),
                                    size: 20,
                                  ),
                                  label: Text(
                                    giveaway.hasEntered
                                        ? l10n.alreadyEntered
                                        : l10n.enterGiveaway,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),

                            // Winner announcement
                            if (isDrawn && giveaway.winnerId != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.successColor.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme.successColor.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      PhosphorIcons.trophy(
                                        PhosphorIconsStyle.fill,
                                      ),
                                      color: AppTheme.successColor,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.winnerSelected,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.successColor,
                                            ),
                                          ),
                                          Consumer(
                                            builder: (ctx, cRef, _) {
                                              final nameAsync = cRef.watch(
                                                winnerNameProvider(
                                                  giveaway.winnerId!,
                                                ),
                                              );
                                              return nameAsync.when(
                                                data: (name) => Text(
                                                  name,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: isDark
                                                        ? Colors.white60
                                                        : Colors.black54,
                                                  ),
                                                ),
                                                loading: () => const SizedBox(
                                                  height: 14,
                                                  width: 14,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 1.5,
                                                      ),
                                                ),
                                                error: (_, __) =>
                                                    const SizedBox(),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Close button
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

  Widget _iconHeader(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
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
            PhosphorIcons.gift(PhosphorIconsStyle.fill),
            size: 56,
            color: color,
          ),
        ),
      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
    );
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

  Widget _stat(IconData icon, String value, String label, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: isDark ? Colors.white38 : Colors.black38),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  String _prizeLabel(String type, AppLocalizations l10n) {
    switch (type) {
      case 'account':
        return l10n.prizeAccount;
      case 'subscription':
        return l10n.prizeSubscription;
      case 'code':
        return l10n.prizeCode;
      default:
        return l10n.prizeOther;
    }
  }

  String _timeValue(DateTime endsAt) {
    final diff = endsAt.difference(DateTime.now());
    if (diff.isNegative) return '—';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    return '${diff.inMinutes}m';
  }
}

// ════════════════════════════════════════
//  POLL DETAIL DIALOG
// ════════════════════════════════════════

class PollDetailDialog extends ConsumerWidget {
  final Poll poll;
  const PollDetailDialog({super.key, required this.poll});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final isActive = poll.isActive;
    final color = isActive ? AppTheme.accentColor : Colors.grey;
    final statusLabel = isActive ? l10n.active : l10n.ended;
    final totalVotes = poll.totalVotes;

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
                    // Gradient header
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      child: Container(
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
                                  PhosphorIcons.chartBar(
                                    PhosphorIconsStyle.fill,
                                  ),
                                  size: 56,
                                  color: color,
                                ),
                              ),
                            ).animate().scale(
                              duration: 400.ms,
                              curve: Curves.easeOutBack,
                            ),
                      ),
                    ),

                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Question
                            Text(
                              poll.question,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Badges row
                            Row(
                              children: [
                                _badge(statusLabel, color, isDark),
                                const SizedBox(width: 8),
                                Text(
                                  '$totalVotes ${l10n.votes}',
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
                            const SizedBox(height: 8),

                            // Description
                            if (poll.description != null &&
                                poll.description!.isNotEmpty) ...[
                              Text(
                                poll.description!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            Divider(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.06),
                            ),
                            const SizedBox(height: 12),

                            // Options
                            ...poll.options.asMap().entries.map((entry) {
                              final i = entry.key;
                              final option = entry.value;
                              final count = poll.voteCounts[i] ?? 0;
                              final pct = totalVotes > 0
                                  ? count / totalVotes
                                  : 0.0;
                              final hasVoted = poll.userVotes.contains(i);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: GestureDetector(
                                  onTap: isActive && !hasVoted
                                      ? () async {
                                          await votePoll(poll.id, i, ref);
                                          if (context.mounted) {
                                            Navigator.of(context).pop();
                                          }
                                        }
                                      : null,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: hasVoted
                                            ? AppTheme.accentColor
                                            : (isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.08,
                                                    )
                                                  : Colors.black.withValues(
                                                      alpha: 0.06,
                                                    )),
                                        width: hasVoted ? 2 : 1,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(11),
                                      child: Stack(
                                        children: [
                                          // Progress fill
                                          FractionallySizedBox(
                                            widthFactor: pct,
                                            child: Container(
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: hasVoted
                                                    ? AppTheme.accentColor
                                                          .withValues(
                                                            alpha: 0.15,
                                                          )
                                                    : AppTheme.primaryColor
                                                          .withValues(
                                                            alpha: 0.06,
                                                          ),
                                              ),
                                            ),
                                          ),
                                          // Content
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 12,
                                            ),
                                            child: Row(
                                              children: [
                                                if (hasVoted) ...[
                                                  Icon(
                                                    PhosphorIcons.checkCircle(
                                                      PhosphorIconsStyle.fill,
                                                    ),
                                                    size: 16,
                                                    color: AppTheme.accentColor,
                                                  ),
                                                  const SizedBox(width: 8),
                                                ],
                                                Expanded(
                                                  child: Text(
                                                    option,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: hasVoted
                                                          ? FontWeight.w700
                                                          : FontWeight.w500,
                                                      color: isDark
                                                          ? Colors.white
                                                          : Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  '${(pct * 100).round()}%',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: isDark
                                                        ? Colors.white54
                                                        : Colors.black45,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Close button
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
}
