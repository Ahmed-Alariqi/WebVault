import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:ui';
import '../../../data/models/collection_model.dart';
import '../../../data/models/website_model.dart';
import '../../../presentation/providers/referral_providers.dart';

/// A premium, high-end bottom sheet designed to inform users about exclusive features.
/// Uses Glassmorphism and modern aesthetics to create a premium feel.
///
/// Now "smart" — it auto-detects the user's access path:
///   1. Active campaign referral → shows campaign CTA
///   2. Default invite threshold → shows invite progress bar
///   3. Membership request → shows request button (if enabled)
class PremiumFeatureSheet extends ConsumerWidget {
  final String title;
  final String description;
  final String? teaserText;
  final IconData icon;
  final VoidCallback onAction;
  final String actionLabel;
  final Color themeColor;
  final bool isDark;
  final CollectionModel? collection;

  const PremiumFeatureSheet({
    super.key,
    required this.title,
    required this.description,
    this.teaserText,
    required this.icon,
    required this.onAction,
    this.actionLabel = 'فتح الميزة الآن',
    this.themeColor = const Color(0xFF4F46E5),
    required this.isDark,
    this.collection,
  });

  /// Factory constructor to create from a Website/Collection pair
  factory PremiumFeatureSheet.fromWebsite({
    required WebsiteModel site,
    required CollectionModel? collection,
    required bool isDark,
    required VoidCallback onAction,
  }) {
    return PremiumFeatureSheet(
      title: 'محتوى حصري 🔒',
      description: 'هذا المحتوى متاح حصرياً لأعضاء مجموعة "${collection?.title ?? 'المميزة'}".\nادعُ أصدقاءك للحصول على هذا المحتوى المميز وغيره الكثير!',
      teaserText: '«${site.title}»',
      icon: PhosphorIcons.crown(PhosphorIconsStyle.fill),
      onAction: onAction,
      actionLabel: 'ادعُ أصدقاءك لفتح المحتوى',
      themeColor: collection != null ? Color(collection.colorValue) : const Color(0xFFF59E0B),
      isDark: isDark,
      collection: collection,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final confirmedAsync = ref.watch(myTotalConfirmedReferralsProvider);
    final requiredAsync = ref.watch(defaultRequiredInvitesProvider);
    final membershipReqAsync = ref.watch(myMembershipRequestProvider);
    final membershipEnabledAsync = ref.watch(membershipRequestsEnabledProvider);
    final campaignAsync = ref.watch(activeReferralCampaignProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      width: 45, height: 5,
                      margin: const EdgeInsets.only(bottom: 32),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),

                    // Icon with Glow
                    _buildIcon(),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        height: 1.2,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                    if (teaserText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        teaserText!,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: themeColor),
                      ).animate().fadeIn(delay: 300.ms),
                    ],

                    const SizedBox(height: 16),

                    // Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white70 : const Color(0xFF64748B),
                          height: 1.6, fontWeight: FontWeight.w500,
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 24),

                    // ── Smart Progress Section ──
                    _buildProgressSection(
                      confirmed: confirmedAsync.valueOrNull ?? 0,
                      required: requiredAsync.valueOrNull ?? 3,
                      hasCampaign: campaignAsync.valueOrNull != null,
                    ),

                    const SizedBox(height: 20),

                    // Collection Card
                    if (collection != null) ...[
                      _buildCollectionInfo(context, collection!),
                      const SizedBox(height: 20),
                    ],

                    // Action Button
                    _buildActionButton(context),

                    // ── Membership Request Section ──
                    _buildMembershipRequestSection(
                      context: context,
                      ref: ref,
                      enabled: membershipEnabledAsync.valueOrNull ?? false,
                      existingRequest: membershipReqAsync.valueOrNull,
                    ),

                    const SizedBox(height: 8),

                    // Dismiss
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? Colors.white38 : Colors.black38,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('ليس الآن', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ).animate().fadeIn(delay: 600.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [themeColor.withValues(alpha: 0.3), themeColor.withValues(alpha: 0)]),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
          begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2000.ms,
        ),
        Container(
          width: 76, height: 76,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [themeColor, themeColor.withValues(alpha: 0.7)]),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: themeColor.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Icon(icon, size: 32, color: Colors.white),
        ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
      ],
    );
  }

  /// Shows invite progress bar with counts
  Widget _buildProgressSection({required int confirmed, required int required, required bool hasCampaign}) {
    final progress = (confirmed / required).clamp(0.0, 1.0);
    final remaining = (required - confirmed).clamp(0, required);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : themeColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(PhosphorIcons.usersThree(PhosphorIconsStyle.fill), color: themeColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasCampaign ? 'تقدم الدعوات (حملة نشطة)' : 'تقدم الدعوات',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                    ),
                    Text(
                      remaining > 0 ? 'باقي $remaining دعوة لفتح المحتوى' : 'أنت مؤهل! 🎉',
                      style: TextStyle(fontSize: 11, color: remaining > 0 ? (isDark ? Colors.white54 : Colors.black45) : const Color(0xFF10B981), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Text(
                '$confirmed/$required',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: themeColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? const Color(0xFF10B981) : themeColor,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 420.ms).slideY(begin: 0.1);
  }

  Widget _buildActionButton(BuildContext context) {
    return Container(
      width: double.infinity, height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: [themeColor, themeColor.withValues(alpha: 0.8)]),
        boxShadow: [BoxShadow(color: themeColor.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          onAction();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill), size: 20, color: Colors.white),
            const SizedBox(width: 12),
            Text(actionLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3, end: 0);
  }

  /// Shows membership request section if enabled
  Widget _buildMembershipRequestSection({
    required BuildContext context,
    required WidgetRef ref,
    required bool enabled,
    required dynamic existingRequest,
  }) {
    if (!enabled) return const SizedBox.shrink();

    // Already has a request
    if (existingRequest != null) {
      final status = existingRequest.status as String;
      final isPending = status == 'pending';
      final isApproved = status == 'approved';
      final color = isPending ? Colors.amber : isApproved ? const Color(0xFF10B981) : Colors.red;
      final label = isPending ? 'طلبك قيد المراجعة ⏳' : isApproved ? 'تم قبول طلبك ✅' : 'تم رفض طلبك';

      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isPending ? PhosphorIcons.clock() : PhosphorIcons.checkCircle(), size: 16, color: color),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      ).animate().fadeIn(delay: 550.ms);
    }

    // Show request button
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Divider(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('أو', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white38 : Colors.black38)),
              ),
              Expanded(child: Divider(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06))),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  PhosphorIcons.info(),
                  size: 13,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'تفعيل العضوية عبر الطلب قد يتأخر للمراجعة. لفتح المحتوى لحظياً، ادعُ أصدقاءك ⚡',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showRequestDialog(context, ref),
              icon: Icon(PhosphorIcons.envelopeSimple(), size: 18),
              label: const Text('طلب تفعيل عضوية '),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white70 : Colors.black54,
                side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 550.ms);
  }

  void _showRequestDialog(BuildContext context, WidgetRef ref) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('طلب تفعيل العضوية', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('اكتب سبب طلبك للعضوية (اختياري)', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'مثال: أنا مهتم بالمحتوى التقني...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await submitMembershipRequest(
                ref: ref,
                requestType: 'premium_content',
                targetId: collection?.id,
                reason: reasonCtrl.text.trim().isNotEmpty ? reasonCtrl.text.trim() : null,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إرسال طلبك بنجاح ✅'), behavior: SnackBarBehavior.floating),
                );
              }
            },
            child: const Text('إرسال الطلب'),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionInfo(BuildContext context, CollectionModel col) {
    final color = Color(col.colorValue);
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        context.push('/collection-items', extra: col);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
              child: Icon(PhosphorIcons.crown(PhosphorIconsStyle.fill), color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(col.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  Text('${col.itemCount} عنصر حصري في هذه المجموعة', style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black45, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Icon(PhosphorIcons.caretLeft(), size: 20, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 450.ms);
  }
}
