import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/referral_providers.dart';
import '../../presentation/providers/chat_providers.dart';
import '../../data/models/referral_model.dart';
import '../../data/models/collection_model.dart';
import '../../core/supabase_config.dart';
import '../../l10n/app_localizations.dart';

// ═══════════════════════════════════════════
//  REFERRAL SHARE SCREEN — User facing
// ═══════════════════════════════════════════

class ReferralShareScreen extends ConsumerStatefulWidget {
  const ReferralShareScreen({super.key});

  @override
  ConsumerState<ReferralShareScreen> createState() =>
      _ReferralShareScreenState();
}

class _ReferralShareScreenState extends ConsumerState<ReferralShareScreen> {
  bool _codeLoading = true;
  ReferralCode? _myCode;

  @override
  void initState() {
    super.initState();
    _loadCode();
  }

  Future<void> _loadCode() async {
    try {
      final code = await ensureReferralCode(ref);
      if (mounted) {
        setState(() {
          _myCode = code;
          _codeLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _codeLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final campaignAsync = ref.watch(activeReferralCampaignProvider);
    final referralsAsync = ref.watch(myReferralsProvider);
    final rewardStatusAsync = ref.watch(myReferralRewardStatusProvider);
    final referredRewardAsync = ref.watch(myReferredRewardProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(l10n.referralShareTitle),
        backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
        elevation: 0,
      ),
      body: campaignAsync.when(
        data: (campaign) {
          if (campaign == null) {
            return Center(
              child: Text(
                l10n.referralCodeNoCampaign,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Reward Status Card (earned) ──
                rewardStatusAsync.when(
                  data: (status) {
                    if (status['earned'] == true) {
                      return _buildRewardEarnedCard(
                        context,
                        status,
                        campaign,
                        isDark,
                      );
                    }
                    return const SizedBox();
                  },
                  loading: () => const SizedBox(),
                  error: (_, _) => const SizedBox(),
                ),

                // ── Referred User Reward Card ──
                referredRewardAsync.when(
                  data: (reward) {
                    if (reward != null) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildReferredRewardCard(
                          context,
                          reward,
                          isDark,
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                  loading: () => const SizedBox(),
                  error: (_, _) => const SizedBox(),
                ),

                // ── Progress ──
                referralsAsync.when(
                  data: (referrals) {
                    final confirmed = referrals
                        .where((r) => r.isConfirmed)
                        .length;
                    final progress = confirmed / campaign.requiredReferrals;
                    return _buildProgressCard(
                      context,
                      confirmed: confirmed,
                      total: campaign.requiredReferrals,
                      progress: progress.clamp(0.0, 1.0),
                      isDark: isDark,
                      l10n: l10n,
                    );
                  },
                  loading: () => const SizedBox(height: 80),
                  error: (_, _) => const SizedBox(),
                ),
                const SizedBox(height: 20),

                // ── Code Card ──
                _buildCodeCard(isDark, l10n, campaign),
                const SizedBox(height: 20),

                // ── Rewards Description ──
                Builder(
                  builder: (context) {
                    String myRewardDesc = '';
                    switch (campaign.rewardType) {
                      case 'giveaway_entry':
                        myRewardDesc =
                            'الحصول على تذكرة مجانية في السحب عند اكتمال متطلبات الإحالة.';
                        break;
                      case 'giveaway_boost':
                        myRewardDesc =
                            'تعزيز فرصتك بـ 3 مشاركات إضافية في السحب.';
                        break;
                      case 'collection_access':
                        myRewardDesc =
                            'صلاحية فتح المجموعات المميزة للمحتوى الحصري.';
                        break;
                      case 'custom':
                      default:
                        myRewardDesc = campaign.rewardDescription ?? '';
                    }

                    String friendRewardDesc = '';
                    switch (campaign.referredRewardType) {
                      case 'giveaway_entry':
                        friendRewardDesc =
                            'الحصول على تذكرة سحب مجانية عند الانضمام.';
                        break;
                      case 'giveaway_boost':
                        friendRewardDesc =
                            'الحصول على 3 مشاركات إضافية في السحب فور الانضمام.';
                        break;
                      case 'collection_access':
                        friendRewardDesc = 'الوصول للمجموعات المميزة الحصرية.';
                        break;
                      case 'custom':
                      default:
                        friendRewardDesc =
                            campaign.referredRewardDescription ?? '';
                    }

                    return Column(
                      children: [
                        if (myRewardDesc.isNotEmpty)
                          _buildRewardDescCard(
                            icon: PhosphorIcons.gift(PhosphorIconsStyle.fill),
                            title: l10n.referralYourReward,
                            description: myRewardDesc,
                            color: AppTheme.primaryColor,
                            isDark: isDark,
                          ),
                        if (friendRewardDesc.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildRewardDescCard(
                            icon: PhosphorIcons.userPlus(
                              PhosphorIconsStyle.fill,
                            ),
                            title: l10n.referralFriendReward,
                            description: friendRewardDesc,
                            color: AppTheme.accentColor,
                            isDark: isDark,
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // ── Referrals List ──
                Text(
                  l10n.referralYourReferrals,
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
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.black.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            l10n.referralNoReferrals,
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: referrals.asMap().entries.map((e) {
                        final r = e.value;
                        return _buildReferralItem(r, isDark)
                            .animate(delay: (e.key * 50).ms)
                            .fadeIn()
                            .slideX(begin: 0.05);
                      }).toList(),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const SizedBox(),
                ),
                const SizedBox(height: 30),

                // ── How it Works ──
                _buildHowItWorks(campaign, isDark, l10n),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const SizedBox(),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  REWARD EARNED CARD (REFERRER)
  // ═══════════════════════════════════════════

  Widget _buildRewardEarnedCard(
    BuildContext context,
    Map<String, dynamic> status,
    ReferralCampaign campaign,
    bool isDark,
  ) {
    final rewardType = status['rewardType'] as String? ?? 'none';
    final giveawayName = status['giveawayName'] as String?;

    IconData icon;
    String title;
    String subtitle;
    Color color;
    Widget? actionButton;

    switch (rewardType) {
      case 'giveaway_entry':
        icon = PhosphorIcons.ticket(PhosphorIconsStyle.fill);
        title = '🎉 تهانينا! تم تسجيلك في السحب';
        subtitle = giveawayName != null
            ? 'تم إدخالك تلقائياً في سحب "$giveawayName"'
            : 'تم تسجيل مشاركتك في السحب بنجاح';
        color = AppTheme.successColor;
        break;

      case 'giveaway_boost':
        icon = PhosphorIcons.lightning(PhosphorIconsStyle.fill);
        title = '⚡ تم تعزيز فرصتك!';
        subtitle = giveawayName != null
            ? 'تمت إضافة 3 مشاركات إضافية في "$giveawayName"'
            : 'تمت إضافة 3 مشاركات إضافية في السحب';
        color = Colors.amber.shade700;
        break;

      case 'collection_access':
        icon = PhosphorIcons.lockOpen(PhosphorIconsStyle.fill);
        title = '🔓 تم فتح المجموعة المميزة!';
        subtitle = 'يمكنك الآن الوصول إلى المحتوى الحصري';
        color = AppTheme.primaryColor;
        actionButton = TextButton.icon(
          onPressed: () async {
            final colId = status['rewardValue'] as String?;
            if (colId != null) {
              try {
                final response = await SupabaseConfig.client
                    .from('collections')
                    .select()
                    .eq('id', colId)
                    .single();
                final col = CollectionModel.fromJson(response);
                if (!context.mounted) return;
                context.push('/collection-items', extra: col);
              } catch (e) {
                // Fallback to discover on error
                if (!context.mounted) return;
                context.go('/discover');
              }
            } else {
              context.go('/discover');
            }
          },
          icon: Icon(PhosphorIcons.arrowRight(), size: 16),
          label: const Text('فتح المجموعة'),
          style: TextButton.styleFrom(foregroundColor: Colors.white),
        );
        break;

      case 'custom':
        icon = PhosphorIcons.envelope(PhosphorIconsStyle.fill);
        title = '🎁 جائزتك جاهزة!';
        subtitle =
            status['rewardDescription'] as String? ??
            'تواصل مع الدعم لاستلام جائزتك';
        color = const Color(0xFF7C4DFF);
        actionButton = TextButton.icon(
          onPressed: () async {
            final l10n = AppLocalizations.of(context)!;
            final rewardDesc =
                status['rewardDescription'] as String? ?? 'جائزة مخصصة';

            // 1. Get/Create conversation
            final conv = await ref.read(userConversationProvider.future);
            if (conv != null) {
              // 2. Send automated claim message
              final message = l10n.referralClaimMessage(rewardDesc);
              await userSendMessage(conv.id, message);
            }

            // 3. Navigate to chat
            if (!mounted) return;
            context.push('/chat');
          },
          icon: Icon(PhosphorIcons.chatCircle(), size: 16),
          label: const Text('مراسلة الدعم'),
          style: TextButton.styleFrom(foregroundColor: Colors.white),
        );
        break;

      default:
        return const SizedBox();
    }

    return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.2),
                color.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.4,
                ),
              ),
              if (actionButton != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: actionButton,
                ),
              ],
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: -0.1)
        .shimmer(
          delay: 300.ms,
          duration: 1200.ms,
          color: Colors.white.withValues(alpha: 0.1),
        );
  }

  // ═══════════════════════════════════════════
  //  REFERRED USER REWARD CARD
  // ═══════════════════════════════════════════

  Widget _buildReferredRewardCard(
    BuildContext context,
    Map<String, dynamic> reward,
    bool isDark,
  ) {
    final rewardType = reward['rewardType'] as String? ?? 'none';
    final giveawayName = reward['giveawayName'] as String?;
    final description = reward['rewardDescription'] as String?;

    String subtitle;
    switch (rewardType) {
      case 'giveaway_entry':
        subtitle = giveawayName != null
            ? 'تم تسجيلك في سحب "$giveawayName" كهدية انضمام 🎉'
            : description ?? 'تم تسجيل مشاركتك في السحب';
        break;
      default:
        subtitle = description ?? 'تم الحصول على جائزة الانضمام';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIcons.gift(PhosphorIconsStyle.fill),
              color: AppTheme.accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎁 جائزة الانضمام',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
            color: AppTheme.successColor,
            size: 22,
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.05);
  }

  // ═══════════════════════════════════════════
  //  PROGRESS CARD
  // ═══════════════════════════════════════════

  Widget _buildProgressCard(
    BuildContext context, {
    required int confirmed,
    required int total,
    required double progress,
    required bool isDark,
    required AppLocalizations l10n,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.15),
            AppTheme.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.referralYourProgress,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(
                progress >= 1.0 ? AppTheme.successColor : AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.referralSuccessful(confirmed, total),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          if (progress >= 1.0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                  size: 18,
                  color: AppTheme.successColor,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.referralCompleted,
                  style: const TextStyle(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  // ═══════════════════════════════════════════
  //  CODE CARD + VIRAL SHARE
  // ═══════════════════════════════════════════

  Widget _buildCodeCard(
    bool isDark,
    AppLocalizations l10n,
    ReferralCampaign campaign,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(20),
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
          Text(
            l10n.referralYourCode,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(height: 10),
          if (_codeLoading)
            const Center(child: CircularProgressIndicator())
          else if (_myCode != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Center(
                child: Text(
                  _myCode!.code,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                // Copy Code button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _myCode!.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.referralCodeCopied)),
                      );
                    },
                    icon: Icon(PhosphorIcons.copy(), size: 18),
                    label: Text(l10n.referralCopyCode),
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
                const SizedBox(width: 12),
                // Viral Share button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareViralMessage(campaign),
                    icon: Icon(PhosphorIcons.shareFat(), size: 18),
                    label: Text(l10n.referralShareCode),
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
          ],
        ],
      ),
    ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1);
  }

  /// Compose and share a creative, viral message
  void _shareViralMessage(ReferralCampaign campaign) {
    final code = _myCode?.code ?? '';
    // TODO: Replace with real download link when app is published
    const appLink = 'https://webvault.app/download';

    // Build the reward mention for the referred user
    String rewardMention = '';
    if (campaign.referredRewardDescription != null &&
        campaign.referredRewardDescription!.isNotEmpty) {
      rewardMention =
          '\n🎁 وعند انضمامك، ستحصل على: ${campaign.referredRewardDescription}';
    }

    // Creative, natural Arabic share message
    final message =
        '''
أهلاً! 👋

اكتشفت تطبيق WebVault وصراحةً غيّر طريقتي بحفظ الروابط والملاحظات — كل شي منظّم ومرتّب بمكان واحد 🔖✨
$rewardMention
جرّبه بنفسك وادخل كود الدعوة:
📌 $code

حمّل التطبيق من هنا:
$appLink

أعدك ما بتندم! 🚀''';

    Share.share(message);
  }

  // ═══════════════════════════════════════════
  //  REWARD DESCRIPTION CARD
  // ═══════════════════════════════════════════

  Widget _buildRewardDescCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  REFERRAL ITEM
  // ═══════════════════════════════════════════

  Widget _buildReferralItem(Referral r, bool isDark) {
    final statusIcon = r.isConfirmed
        ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
        : r.isRejected
        ? PhosphorIcons.xCircle(PhosphorIconsStyle.fill)
        : r.isExpired
        ? PhosphorIcons.clockCountdown(PhosphorIconsStyle.fill)
        : PhosphorIcons.clock(PhosphorIconsStyle.fill);
    final statusColor = r.isConfirmed
        ? AppTheme.successColor
        : r.isRejected
        ? AppTheme.errorColor
        : r.isExpired
        ? Colors.grey
        : Colors.amber;
    final statusText = r.isConfirmed
        ? AppLocalizations.of(context)!.referralStatusConfirmed
        : r.isRejected
        ? AppLocalizations.of(context)!.referralStatusRejected
        : r.isExpired
        ? 'منتهية'
        : AppLocalizations.of(context)!.referralStatusPending;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(statusIcon, size: 20, color: statusColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '@${r.referredUsername ?? r.referredName ?? '?'}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  HOW IT WORKS
  // ═══════════════════════════════════════════

  Widget _buildHowItWorks(
    ReferralCampaign campaign,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final steps = [
      (PhosphorIcons.share(), l10n.referralStep1),
      (PhosphorIcons.userPlus(), l10n.referralStep2),
      (PhosphorIcons.sealCheck(), l10n.referralStep3),
      (PhosphorIcons.gift(), l10n.referralStep4(campaign.requiredReferrals)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.referralHowItWorks,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...steps.asMap().entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      e.value.$1,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${e.key + 1}. ${e.value.$2}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.referralValidationWarning,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.orange[200] : Colors.orange[800],
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
