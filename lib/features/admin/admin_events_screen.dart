import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/events_providers.dart';
import '../../data/models/giveaway_model.dart';
import '../../data/models/poll_model.dart';
import '../../l10n/app_localizations.dart';
import 'edit_giveaway_sheet.dart';
import 'edit_poll_sheet.dart';

class AdminEventsScreen extends ConsumerStatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  ConsumerState<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends ConsumerState<AdminEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── Gradient Header ──
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -10,
                      child: Icon(
                        PhosphorIcons.confetti(PhosphorIconsStyle.fill),
                        size: 160,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        MediaQuery.of(context).padding.top + 60,
                        20,
                        20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l10n.eventsManagement,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.eventsTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            l10n.eventsSubtitle,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
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
          // ── Independent Tab Bar ──
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              Container(
                color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Container(
                  margin: EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: isDark ? Colors.white : Colors.black87,
                    unselectedLabelColor: isDark
                        ? Colors.white54
                        : Colors.black54,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                    padding: const EdgeInsets.all(4),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(PhosphorIcons.gift(), size: 18),
                            const SizedBox(width: 6),
                            Text(l10n.giveawaysTab),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(PhosphorIcons.chartBar(), size: 18),
                            const SizedBox(width: 6),
                            Text(l10n.pollsTab),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _GiveawaysTab(isDark: isDark),
            _PollsTab(isDark: isDark),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════
//  GIVEAWAYS TAB
// ════════════════════════════════════════════

class _GiveawaysTab extends ConsumerWidget {
  final bool isDark;
  const _GiveawaysTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final giveawaysAsync = ref.watch(giveawaysProvider);
    final l10n = AppLocalizations.of(context)!;

    return giveawaysAsync.when(
      data: (giveaways) {
        if (giveaways.isEmpty) {
          return _EmptyState(
            icon: PhosphorIcons.gift(PhosphorIconsStyle.duotone),
            title: l10n.noGiveaways,
            subtitle: l10n.noGiveawaysDesc,
            buttonLabel: l10n.createGiveaway,
            onTap: () => _openGiveawayEditor(context),
            isDark: isDark,
          );
        }

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async => ref.invalidate(giveawaysProvider),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                itemCount: giveaways.length,
                itemBuilder: (context, index) {
                  return _GiveawayCard(
                    giveaway: giveaways[index],
                    isDark: isDark,
                  ).animate(delay: (index * 60).ms).fadeIn().slideY(begin: 0.1);
                },
              ),
            ),
            // FAB
            Positioned(
              bottom: 24,
              right: 20,
              left: 20,
              child: _GradientButton(
                label: l10n.createGiveaway,
                icon: PhosphorIcons.plus(PhosphorIconsStyle.bold),
                onTap: () => _openGiveawayEditor(context),
              ).animate().slideY(begin: 1, curve: Curves.elasticOut),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _openGiveawayEditor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditGiveawaySheet()),
    );
  }
}

class _GiveawayCard extends ConsumerWidget {
  final Giveaway giveaway;
  final bool isDark;

  const _GiveawayCard({required this.giveaway, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = giveaway.isDrawn
        ? AppTheme.successColor
        : giveaway.isActive
        ? AppTheme.primaryColor
        : (isDark ? Colors.white38 : Colors.black38);

    final statusLabel = giveaway.isDrawn
        ? l10n.drawn
        : giveaway.isActive
        ? l10n.active
        : l10n.ended;

    final statusIcon = giveaway.isDrawn
        ? PhosphorIcons.trophy(PhosphorIconsStyle.fill)
        : giveaway.isActive
        ? PhosphorIcons.sealCheck(PhosphorIconsStyle.fill)
        : PhosphorIcons.clockCountdown(PhosphorIconsStyle.fill);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
        border: Border.all(
          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with image and badges
          Stack(
            children: [
              if (giveaway.imageUrl != null && giveaway.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: Image.network(
                    giveaway.imageUrl!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _buildFallbackImage(statusColor),
                  ),
                )
              else
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: _buildFallbackImage(statusColor),
                ),
              // Gradient overlay for better text/badge visibility
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                ),
              ),
              // Status Badge
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Menu Button
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 20,
                    ),
                    onSelected: (v) async {
                      if (v == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EditGiveawaySheet(giveaway: giveaway),
                          ),
                        );
                      } else if (v == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: Text(l10n.deleteGiveaway),
                            content: Text(l10n.deleteGiveawayConfirm),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: Text(l10n.cancel),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: Text(
                                  l10n.delete,
                                  style: const TextStyle(
                                    color: AppTheme.errorColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await deleteGiveaway(giveaway.id, ref);
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          l10n.delete,
                          style: const TextStyle(color: AppTheme.errorColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  giveaway.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (giveaway.description != null &&
                    giveaway.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    giveaway.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 16),

                // Stats row
                Row(
                  children: [
                    _StatChip(
                      icon: PhosphorIcons.users(),
                      label: '${giveaway.entryCount} ${l10n.entries}',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 12),
                    _StatChip(
                      icon: PhosphorIcons.clockCountdown(),
                      label: giveaway.isActive
                          ? _formatTimeRemaining(giveaway.timeRemaining, l10n)
                          : l10n.ended,
                      isDark: isDark,
                    ),
                    if (giveaway.maxEntries != null) ...[
                      const SizedBox(width: 12),
                      _StatChip(
                        icon: PhosphorIcons.usersThree(),
                        label: '${l10n.maxLabel} ${giveaway.maxEntries}',
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),

                // Winner display
                if (giveaway.isDrawn && giveaway.winnerId != null)
                  Container(
                    margin: const EdgeInsets.only(top: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: AppTheme.successColor,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Consumer(
                            builder: (context, ref, _) {
                              final nameAsync = ref.watch(
                                winnerNameProvider(giveaway.winnerId!),
                              );
                              return nameAsync.when(
                                data: (name) => Text(
                                  '${l10n.winner}: $name 🎉',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                loading: () => const Text('...'),
                                error: (_, __) => const Text('?'),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ).animate().shimmer(duration: 2000.ms),

                // Body Action buttons
                if (giveaway.isEnded &&
                    !giveaway.isDrawn &&
                    giveaway.entryCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showEntries(context, ref, giveaway),
                            icon: Icon(PhosphorIcons.listBullets(), size: 18),
                            label: Text(l10n.viewEntries),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark
                                  ? Colors.white70
                                  : Colors.black87,
                              side: BorderSide(
                                color: isDark
                                    ? AppTheme.darkDivider
                                    : AppTheme.lightDivider,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _drawWinner(context, ref, giveaway),
                            icon: Icon(PhosphorIcons.trophy(), size: 18),
                            label: Text(l10n.drawWinner),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (giveaway.isActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showEntries(context, ref, giveaway),
                        icon: Icon(PhosphorIcons.listBullets(), size: 18),
                        label: Text(
                          '${l10n.viewEntries} (${giveaway.entryCount})',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? Colors.white70
                              : Colors.black87,
                          side: BorderSide(
                            color: isDark
                                ? AppTheme.darkDivider
                                : AppTheme.lightDivider,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackImage(Color statusColor) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Center(
        child: Icon(
          PhosphorIcons.gift(PhosphorIconsStyle.fill),
          size: 36,
          color: statusColor.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  void _showEntries(BuildContext context, WidgetRef ref, Giveaway giveaway) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (_, scrollCtrl) {
          final entriesAsync = ref.watch(giveawayEntriesProvider(giveaway.id));
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(PhosphorIcons.users(), color: AppTheme.primaryColor),
                      const SizedBox(width: 10),
                      Text(
                        '${l10n.entries} — ${giveaway.title}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: entriesAsync.when(
                    data: (entries) {
                      if (entries.isEmpty) {
                        return Center(
                          child: Text(
                            l10n.noEntries,
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: entries.length,
                        itemBuilder: (_, i) {
                          final entry = entries[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              child: Text(
                                (entry.userName ?? '?')[0].toUpperCase(),
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              entry.userName ?? entry.userId.substring(0, 8),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              DateFormat.yMMMd().add_jm().format(
                                entry.enteredAt,
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                            trailing: Text(
                              '#${i + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white24 : Colors.black26,
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
            ),
          );
        },
      ),
    );
  }

  Future<void> _drawWinner(
    BuildContext context,
    WidgetRef ref,
    Giveaway giveaway,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l10n.drawWinner),
        content: Text(l10n.drawWinnerConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
            ),
            child: Text(l10n.draw, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    HapticFeedback.heavyImpact();
    final winnerId = await drawGiveawayWinner(giveaway.id, ref);

    if (context.mounted) {
      if (winnerId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.winnerSelected} 🎉'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.noEntries)));
      }
    }
  }

  String _formatTimeRemaining(Duration d, AppLocalizations l10n) {
    if (d.isNegative) return l10n.ended;
    if (d.inDays > 0) return l10n.daysLeft(d.inDays.toString());
    if (d.inHours > 0) return l10n.hoursLeft(d.inHours.toString());
    return '${d.inMinutes} ${l10n.minutesLeft}';
  }
}

// ════════════════════════════════════════════
//  POLLS TAB
// ════════════════════════════════════════════

class _PollsTab extends ConsumerWidget {
  final bool isDark;
  const _PollsTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pollsAsync = ref.watch(pollsProvider);
    final l10n = AppLocalizations.of(context)!;

    return pollsAsync.when(
      data: (polls) {
        if (polls.isEmpty) {
          return _EmptyState(
            icon: PhosphorIcons.chartBar(PhosphorIconsStyle.duotone),
            title: l10n.noPolls,
            subtitle: l10n.noPollsDesc,
            buttonLabel: l10n.createPoll,
            onTap: () => _openPollEditor(context),
            isDark: isDark,
          );
        }

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async => ref.invalidate(pollsProvider),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                itemCount: polls.length,
                itemBuilder: (context, index) {
                  return _PollCard(
                    poll: polls[index],
                    isDark: isDark,
                  ).animate(delay: (index * 60).ms).fadeIn().slideY(begin: 0.1);
                },
              ),
            ),
            Positioned(
              bottom: 24,
              right: 20,
              left: 20,
              child: _GradientButton(
                label: l10n.createPoll,
                icon: PhosphorIcons.plus(PhosphorIconsStyle.bold),
                onTap: () => _openPollEditor(context),
              ).animate().slideY(begin: 1, curve: Curves.elasticOut),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _openPollEditor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditPollSheet()),
    );
  }
}

class _PollCard extends ConsumerWidget {
  final Poll poll;
  final bool isDark;

  const _PollCard({required this.poll, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isActive = poll.isActive;
    final statusColor = isActive
        ? AppTheme.accentColor
        : (isDark ? Colors.white38 : Colors.black38);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
        border: Border.all(
          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Styled Header Block
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  statusColor.withValues(alpha: 0.15),
                  statusColor.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Badge & Menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isActive
                                ? PhosphorIcons.sealCheck(
                                    PhosphorIconsStyle.fill,
                                  )
                                : PhosphorIcons.clockCountdown(
                                    PhosphorIconsStyle.fill,
                                  ),
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isActive ? l10n.active : l10n.ended,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: PopupMenuButton<String>(
                        icon: Icon(
                          PhosphorIcons.dotsThreeVertical(),
                          color: isDark ? Colors.white70 : Colors.black54,
                          size: 20,
                        ),
                        onSelected: (v) async {
                          if (v == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditPollSheet(poll: poll),
                              ),
                            );
                          } else if (v == 'end' && poll.isActive) {
                            await endPoll(poll.id, ref);
                          } else if (v == 'delete') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: Text(l10n.deletePoll),
                                content: Text(l10n.deletePollConfirm),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: Text(l10n.cancel),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: Text(
                                      l10n.delete,
                                      style: const TextStyle(
                                        color: AppTheme.errorColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) await deletePoll(poll.id, ref);
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                          if (poll.isActive)
                            PopupMenuItem(
                              value: 'end',
                              child: Text(l10n.endPoll),
                            ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              l10n.delete,
                              style: const TextStyle(
                                color: AppTheme.errorColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Question
                Text(
                  poll.question,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (poll.description != null &&
                    poll.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    poll.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Body (Options & Footer)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatChip(
                      icon: PhosphorIcons.users(),
                      label: '${poll.totalVotes} ${l10n.votes}',
                      isDark: isDark,
                    ),
                    if (poll.allowMultiple) ...[
                      const SizedBox(width: 12),
                      _StatChip(
                        icon: PhosphorIcons.checks(),
                        label: l10n.multipleChoice,
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Options with results
                ...poll.options.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final option = entry.value;
                  final pct = poll.votePercentage(idx);
                  final count = poll.voteCounts[idx] ?? 0;
                  final isWinner =
                      poll.isEnded &&
                      idx == poll.winningOptionIndex &&
                      poll.totalVotes > 0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusSm,
                        ),
                        border: Border.all(
                          color: isWinner
                              ? AppTheme.successColor
                              : (isDark
                                    ? AppTheme.darkDivider
                                    : AppTheme.lightDivider),
                          width: isWinner ? 2 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusSm - 1,
                        ),
                        child: Stack(
                          children: [
                            // Progress fill
                            FractionallySizedBox(
                              widthFactor: pct,
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isWinner
                                      ? AppTheme.successColor.withValues(
                                          alpha: 0.15,
                                        )
                                      : AppTheme.accentColor.withValues(
                                          alpha: 0.08,
                                        ),
                                ),
                              ),
                            ),
                            // Label
                            Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Row(
                                children: [
                                  if (isWinner) ...[
                                    const Icon(
                                      Icons.emoji_events,
                                      size: 16,
                                      color: AppTheme.successColor,
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isWinner
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '$count (${(pct * 100).toStringAsFixed(0)}%)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════
//  SHARED WIDGETS
// ════════════════════════════════════════════

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: isDark ? Colors.white38 : Colors.black38),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.primaryDark],
          ),
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;
  final bool isDark;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
            ),
            const SizedBox(height: 32),
            _GradientButton(
              label: buttonLabel,
              icon: PhosphorIcons.plus(PhosphorIconsStyle.bold),
              onTap: onTap,
            ),
          ],
        ).animate().fadeIn().slideY(begin: 0.2),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget _child;
  _SliverAppBarDelegate(this._child);

  @override
  double get minExtent => 76.0;
  @override
  double get maxExtent => 76.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return _child;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
