import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/giveaway_model.dart';
import '../../presentation/providers/events_providers.dart';
import '../../l10n/app_localizations.dart';

class GiveawayDetailScreen extends ConsumerStatefulWidget {
  final String giveawayId;
  const GiveawayDetailScreen({super.key, required this.giveawayId});

  @override
  ConsumerState<GiveawayDetailScreen> createState() =>
      _GiveawayDetailScreenState();
}

class _GiveawayDetailScreenState extends ConsumerState<GiveawayDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final giveawayAsync = ref.watch(giveawayByIdProvider(widget.giveawayId));

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: giveawayAsync.when(
        data: (giveaway) {
          if (giveaway == null) {
            return Center(child: Text(l10n.notFound));
          }
          return _buildContent(context, giveaway, isDark, l10n);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Giveaway g,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return CustomScrollView(
      slivers: [
        // App bar with image
        SliverAppBar(
          expandedHeight: g.imageUrl != null ? 250 : 160,
          pinned: true,
          backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: g.imageUrl != null && g.imageUrl!.isNotEmpty
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        g.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _gradientBg(),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : _gradientBg(),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status + prize type row
                Row(
                  children: [
                    _StatusBadge(giveaway: g, l10n: l10n),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _prizeLabel(g.prizeType, l10n),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  g.title,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                    height: 1.2,
                  ),
                ).animate().fadeIn().slideX(begin: -0.1),
                const SizedBox(height: 8),

                if (g.description != null && g.description!.isNotEmpty)
                  Text(
                    g.description!,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white60 : Colors.black54,
                      height: 1.5,
                    ),
                  ),
                const SizedBox(height: 24),

                // Stats cards
                Row(
                  children: [
                    Expanded(
                      child: _InfoCard(
                        icon: PhosphorIcons.users(PhosphorIconsStyle.fill),
                        label: l10n.participants,
                        value: g.entryCount.toString(),
                        color: const Color(0xFF6366F1),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoCard(
                        icon: PhosphorIcons.clockCountdown(
                          PhosphorIconsStyle.fill,
                        ),
                        label: l10n.timeLeft,
                        value: g.isActive
                            ? _formatTime(g.timeRemaining, l10n)
                            : l10n.ended,
                        color: const Color(0xFFE11D48),
                        isDark: isDark,
                      ),
                    ),
                    if (g.maxEntries != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          icon: PhosphorIcons.usersThree(
                            PhosphorIconsStyle.fill,
                          ),
                          label: l10n.maxLabel,
                          value: g.maxEntries.toString(),
                          color: const Color(0xFF10B981),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // End date
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
                      Icon(
                        PhosphorIcons.calendarBlank(),
                        size: 18,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${l10n.endsOn} ${DateFormat('EEEE, MMM d, yyyy • h:mm a').format(g.endsAt)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                // Winner section (multiple)
                if (g.isDrawn && g.winnerIds.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.congratulations,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...g.winnerIds.map(
                          (wId) => Consumer(
                            builder: (context, ref, _) {
                              final nameAsync = ref.watch(
                                winnerNameProvider(wId),
                              );
                              return nameAsync.when(
                                data: (name) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 3,
                                  ),
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                loading: () => const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                error: (_, _) => const Text(
                                  '?',
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            },
                          ),
                        ),
                        if (g.winnerAnnouncedAt != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            DateFormat.yMMMd().add_jm().format(
                              g.winnerAnnouncedAt!,
                            ),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ).animate().shimmer(
                    duration: 2500.ms,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ],

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _gradientBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE11D48), Color(0xFFBE185D)],
        ),
      ),
      child: Center(
        child: Icon(
          PhosphorIcons.gift(PhosphorIconsStyle.fill),
          size: 64,
          color: Colors.white.withValues(alpha: 0.2),
        ),
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

  String _formatTime(Duration d, AppLocalizations l10n) {
    if (d.isNegative) return l10n.ended;
    if (d.inDays > 0) return '${d.inDays}d';
    if (d.inHours > 0) return '${d.inHours}h';
    return '${d.inMinutes}m';
  }
}

class _StatusBadge extends StatelessWidget {
  final Giveaway giveaway;
  final AppLocalizations l10n;
  const _StatusBadge({required this.giveaway, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    if (giveaway.isDrawn) {
      color = const Color(0xFF10B981);
      label = l10n.drawn;
    } else if (giveaway.isActive) {
      color = const Color(0xFFE11D48);
      label = l10n.active;
    } else {
      color = const Color(0xFF6B7280);
      label = l10n.ended;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }
}
