import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/supabase_config.dart';
import '../../presentation/providers/referral_providers.dart';
import '../../data/models/referral_model.dart';
import '../../l10n/app_localizations.dart';
import 'edit_referral_campaign_sheet.dart';

// ═══════════════════════════════════════════
//  ADMIN REFERRALS TAB
// ═══════════════════════════════════════════

class AdminReferralsTab extends ConsumerWidget {
  final bool isDark;
  const AdminReferralsTab({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignsAsync = ref.watch(referralCampaignsProvider);
    final l10n = AppLocalizations.of(context)!;

    return campaignsAsync.when(
      data: (campaigns) {
        if (campaigns.isEmpty) {
          return _EmptyState(
            isDark: isDark,
            onTap: () => _openCampaignEditor(context),
          );
        }
        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async => ref.invalidate(referralCampaignsProvider),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                itemCount: campaigns.length,
                itemBuilder: (context, index) {
                  return _CampaignCard(
                    campaign: campaigns[index],
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
                label: l10n.referralCreateCampaign,
                icon: PhosphorIcons.plus(PhosphorIconsStyle.bold),
                onTap: () => _openCampaignEditor(context),
              ).animate().slideY(begin: 1, curve: Curves.elasticOut),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _openCampaignEditor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditReferralCampaignSheet()),
    );
  }
}

// ═══════════════════════════════════════════
//  CAMPAIGN CARD
// ═══════════════════════════════════════════

class _CampaignCard extends ConsumerWidget {
  final ReferralCampaign campaign;
  final bool isDark;
  const _CampaignCard({required this.campaign, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(campaignStatsProvider(campaign.id));

    final statusColor = campaign.isRunning
        ? AppTheme.successColor
        : campaign.isExpired
        ? Colors.orange
        : (isDark ? Colors.white38 : Colors.black38);

    final statusLabel = campaign.isRunning
        ? l10n.referralActiveCampaign
        : campaign.isExpired
        ? l10n.referralExpiredCampaign
        : l10n.referralInactiveCampaign;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
        border: Border.all(
          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
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
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (campaign.isVisible) ...[
                  const SizedBox(width: 8),
                  Icon(
                    PhosphorIcons.eye(),
                    size: 16,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ],
                const Spacer(),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 20,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                  onSelected: (v) => _handleMenuAction(v, context, ref),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(
                        campaign.isActive
                            ? l10n.referralInactiveCampaign
                            : l10n.referralActiveCampaign,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        l10n.delete,
                        style: const TextStyle(color: AppTheme.errorColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  campaign.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (campaign.description != null &&
                    campaign.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    campaign.description!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 12),

                // Info chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: PhosphorIcons.usersThree(),
                      label:
                          '${campaign.requiredReferrals} ${l10n.referralRequiredCount}',
                      isDark: isDark,
                    ),
                    _InfoChip(
                      icon: PhosphorIcons.gift(),
                      label: _rewardLabel(campaign.rewardType, l10n),
                      isDark: isDark,
                    ),
                    if (campaign.endsAt != null)
                      _InfoChip(
                        icon: PhosphorIcons.calendar(),
                        label: DateFormat('MMM d').format(campaign.endsAt!),
                        isDark: isDark,
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                // Stats row
                statsAsync.when(
                  data: (stats) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatBox(
                        value: stats['total']!,
                        label: l10n.referralStatsTotal,
                        color: AppTheme.primaryColor,
                        isDark: isDark,
                      ),
                      _StatBox(
                        value: stats['confirmed']!,
                        label: l10n.referralStatsConfirmed,
                        color: AppTheme.successColor,
                        isDark: isDark,
                      ),
                      _StatBox(
                        value: stats['pending']!,
                        label: l10n.referralStatsPending,
                        color: Colors.amber,
                        isDark: isDark,
                      ),
                      _StatBox(
                        value: stats['expired'] ?? 0,
                        label: 'منتهية',
                        color: Colors.grey,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  loading: () => const SizedBox(height: 40),
                  error: (_, _) => const SizedBox(),
                ),

                const SizedBox(height: 12),

                // Details button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showDetails(context, ref),
                    icon: Icon(PhosphorIcons.listBullets(), size: 18),
                    label: Text(l10n.referralCampaignDetails),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white70 : Colors.black87,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _rewardLabel(String type, AppLocalizations l10n) {
    switch (type) {
      case 'giveaway_entry':
        return l10n.referralRewardGiveawayEntry;
      case 'giveaway_boost':
        return l10n.referralRewardGiveawayBoost;
      case 'collection_access':
        return l10n.referralRewardCollectionAccess;
      case 'custom':
        return l10n.referralRewardCustom;
      default:
        return l10n.referralRewardNone;
    }
  }

  void _handleMenuAction(
    String action,
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditReferralCampaignSheet(campaign: campaign),
          ),
        );
        break;
      case 'toggle':
        await updateReferralCampaign(campaign.id, {
          'is_active': !campaign.isActive,
        }, ref);
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(l10n.delete),
            content: Text(l10n.referralDeleteCampaignConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: Text(
                  l10n.delete,
                  style: const TextStyle(color: AppTheme.errorColor),
                ),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await deleteReferralCampaign(campaign.id, ref);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.referralCampaignDeleted)),
            );
          }
        }
        break;
    }
  }

  void _showDetails(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CampaignDetailsSheet(campaign: campaign, isDark: isDark),
    );
  }
}

// ═══════════════════════════════════════════
//  CAMPAIGN DETAILS BOTTOM SHEET
// ═══════════════════════════════════════════

class _CampaignDetailsSheet extends ConsumerWidget {
  final ReferralCampaign campaign;
  final bool isDark;
  const _CampaignDetailsSheet({required this.campaign, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final referralsAsync = ref.watch(campaignReferralsProvider(campaign.id));
    final topRefAsync = ref.watch(topReferrersProvider(campaign.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              '${l10n.referralCampaignDetails}: ${campaign.title}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // Top Referrers
            Text(
              l10n.referralTopReferrers,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            topRefAsync.when(
              data: (topRefs) {
                if (topRefs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      l10n.referralNoReferrals,
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  );
                }
                return Column(
                  children: topRefs.asMap().entries.map((e) {
                    final idx = e.key;
                    final r = e.value;
                    final completed =
                        (r['confirmed'] as int) >= campaign.requiredReferrals;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: completed
                            ? AppTheme.successColor.withValues(alpha: 0.08)
                            : isDark
                            ? Colors.white.withValues(alpha: 0.03)
                            : Colors.black.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(12),
                        border: completed
                            ? Border.all(
                                color: AppTheme.successColor.withValues(
                                  alpha: 0.3,
                                ),
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${idx + 1}.',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '@${r['username']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                Text(
                                  r['name'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${r['confirmed']}/${campaign.requiredReferrals}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: completed
                                  ? AppTheme.successColor
                                  : isDark
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                          ),
                          if (completed) ...[
                            const SizedBox(width: 6),
                            Icon(
                              PhosphorIcons.checkCircle(
                                PhosphorIconsStyle.fill,
                              ),
                              size: 18,
                              color: AppTheme.successColor,
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const SizedBox(),
            ),

            const SizedBox(height: 24),

            // All referrals
            Text(
              l10n.referralAllReferrals,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            referralsAsync.when(
              data: (referrals) {
                if (referrals.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      l10n.referralNoReferrals,
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  );
                }

                // Group by referrer
                final Map<String, List<Referral>> grouped = {};
                for (final r in referrals) {
                  grouped.putIfAbsent(r.referrerId, () => []).add(r);
                }

                return Column(
                  children: grouped.entries.map((entry) {
                    final referrerRefs = entry.value;
                    final referrerName =
                        referrerRefs.first.referrerUsername ??
                        referrerRefs.first.referrerName ??
                        '?';
                    final confirmedCount = referrerRefs
                        .where((r) => r.isConfirmed)
                        .length;
                    final pendingCount = referrerRefs
                        .where((r) => r.isPending)
                        .length;
                    final expiredCount = referrerRefs
                        .where((r) => r.isExpired)
                        .length;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.03)
                            : Colors.black.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            14,
                            0,
                            14,
                            12,
                          ),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${referrerRefs.length}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryColor,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            '@$referrerName',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              if (confirmedCount > 0)
                                _MiniStatChip(
                                  count: confirmedCount,
                                  color: AppTheme.successColor,
                                  icon: PhosphorIcons.check(),
                                ),
                              if (pendingCount > 0)
                                _MiniStatChip(
                                  count: pendingCount,
                                  color: Colors.amber,
                                  icon: PhosphorIcons.clock(),
                                ),
                              if (expiredCount > 0)
                                _MiniStatChip(
                                  count: expiredCount,
                                  color: Colors.grey,
                                  icon: PhosphorIcons.clockCountdown(),
                                ),
                            ],
                          ),
                          children: referrerRefs.map((r) {
                            final statusIcon = r.isConfirmed
                                ? PhosphorIcons.checkCircle(
                                    PhosphorIconsStyle.fill,
                                  )
                                : r.isRejected
                                ? PhosphorIcons.xCircle(PhosphorIconsStyle.fill)
                                : r.isExpired
                                ? PhosphorIcons.clockCountdown(
                                    PhosphorIconsStyle.fill,
                                  )
                                : PhosphorIcons.clock(PhosphorIconsStyle.fill);
                            final statusColor = r.isConfirmed
                                ? AppTheme.successColor
                                : r.isRejected
                                ? AppTheme.errorColor
                                : r.isExpired
                                ? Colors.grey
                                : Colors.amber;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.03)
                                    : Colors.black.withValues(alpha: 0.02),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        statusIcon,
                                        size: 18,
                                        color: statusColor,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '@${r.referredUsername ?? '?'}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black87,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              r.referredName ?? '',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark
                                                    ? Colors.white38
                                                    : Colors.black38,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Show approve/reject for pending AND expired
                                      if (r.isPending || r.isExpired) ...[
                                        IconButton(
                                          onPressed: () async {
                                            await approveReferral(r.id, ref);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    l10n.referralConfirmed,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          icon: Icon(
                                            PhosphorIcons.check(),
                                            color: AppTheme.successColor,
                                            size: 20,
                                          ),
                                          tooltip: l10n.referralConfirm,
                                          constraints: const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                        IconButton(
                                          onPressed: () async {
                                            await rejectReferral(r.id, ref);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    l10n.referralRejected,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          icon: Icon(
                                            PhosphorIcons.x(),
                                            color: AppTheme.errorColor,
                                            size: 20,
                                          ),
                                          tooltip: l10n.referralReject,
                                          constraints: const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ],
                                    ],
                                  ),
                                  // Activity indicators for pending/expired referrals
                                  if (r.isPending || r.isExpired)
                                    _ReferralActivityIndicator(
                                      referredId: r.referredId,
                                      referralCreatedAt: r.createdAt,
                                      isDark: isDark,
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
//  SHARED WIDGETS
// ═══════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _EmptyState({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.usersThree(PhosphorIconsStyle.duotone),
              size: 64,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.referralNoCampaigns,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add),
              label: Text(l10n.referralCreateCampaign),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isDark ? Colors.white54 : Colors.black45),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final bool isDark;
  const _StatBox({
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 75,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.black45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mini stat chip for the per-referrer grouped view
class _MiniStatChip extends StatelessWidget {
  final int count;
  final Color color;
  final IconData icon;
  const _MiniStatChip({
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Activity indicator widget that shows referred user's activity status
class _ReferralActivityIndicator extends StatefulWidget {
  final String referredId;
  final DateTime referralCreatedAt;
  final bool isDark;
  const _ReferralActivityIndicator({
    required this.referredId,
    required this.referralCreatedAt,
    required this.isDark,
  });

  @override
  State<_ReferralActivityIndicator> createState() =>
      _ReferralActivityIndicatorState();
}

class _ReferralActivityIndicatorState
    extends State<_ReferralActivityIndicator> {
  Map<String, dynamic>? _activityData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    try {
      final supabase = SupabaseConfig.client;

      // Profile check
      final profile = await supabase
          .from('profiles')
          .select('full_name, username')
          .eq('id', widget.referredId)
          .single();
      final hasProfile =
          (profile['full_name'] as String?)?.isNotEmpty == true &&
          (profile['username'] as String?)?.isNotEmpty == true;

      // App opens
      final appOpens = await supabase
          .from('user_activity')
          .select('id')
          .eq('user_id', widget.referredId)
          .eq('activity_type', 'app_open')
          .gte('created_at', widget.referralCreatedAt.toIso8601String());
      final loginCount = (appOpens as List).length;

      // Content activity
      final contentActs = await supabase
          .from('user_activity')
          .select('id')
          .eq('user_id', widget.referredId)
          .inFilter('activity_type', [
            'item_view',
            'clipboard_add',
            'page_add',
            'search',
            'bookmark',
          ])
          .gte('created_at', widget.referralCreatedAt.toIso8601String())
          .limit(1);
      final hasContent = (contentActs as List).isNotEmpty;

      if (mounted) {
        setState(() {
          _activityData = {
            'hasProfile': hasProfile,
            'loginCount': loginCount,
            'hasContent': hasContent,
          };
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      );
    }
    if (_activityData == null) return const SizedBox();

    final hasProfile = _activityData!['hasProfile'] as bool;
    final loginCount = _activityData!['loginCount'] as int;
    final hasContent = _activityData!['hasContent'] as bool;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          _ActivityDot(
            label: 'ملف شخصي',
            done: hasProfile,
            isDark: widget.isDark,
          ),
          const SizedBox(width: 10),
          _ActivityDot(
            label: 'دخول $loginCount/3',
            done: loginCount >= 3,
            isDark: widget.isDark,
          ),
          const SizedBox(width: 10),
          _ActivityDot(label: 'نشاط', done: hasContent, isDark: widget.isDark),
        ],
      ),
    );
  }
}

class _ActivityDot extends StatelessWidget {
  final String label;
  final bool done;
  final bool isDark;
  const _ActivityDot({
    required this.label,
    required this.done,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: done ? AppTheme.successColor : Colors.orange.shade300,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: done
                ? AppTheme.successColor
                : (isDark ? Colors.white38 : Colors.black38),
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
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.primaryDark],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
