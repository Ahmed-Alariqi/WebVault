import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/supabase_config.dart';
import '../../data/repositories/settings_repository.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

/// Fetches the active campaign from the database.
final activeCampaignProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    return await SupabaseConfig.client
        .from('app_campaigns')
        .select()
        .eq('is_active', true)
        .gt('end_at', DateTime.now().toUtc().toIso8601String())
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
  } catch (_) {
    return null;
  }
});

/// Tracks if we've already shown the dialog this session.
/// Once set to true it stays true for the entire app lifecycle.
final campaignDialogShownProvider = StateProvider<bool>((ref) => false);

/// Tracks if the user has collapsed the top banner.
final campaignBannerCollapsedProvider = StateProvider<bool>((ref) => false);

// ─── Dialog Trigger ───────────────────────────────────────────────────────────

class CampaignOverlay {
  /// Call this once from DashboardScreen.initState via addPostFrameCallback.
  /// It will show the dialog exactly once per app session.
  static Future<void> showGiftDialogIfNeeded(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final campaign = await ref.read(activeCampaignProvider.future);
    if (campaign == null) return;
    if (!context.mounted) return;

    // Check persistence to see if user has already seen THIS specific campaign.
    final settings = SettingsRepository();
    final lastShownId = settings.getLastShownCampaignId();
    final currentId = campaign['id']?.toString() ?? '';

    if (lastShownId == currentId) return;

    // Mark as shown in persistence AND session.
    await settings.setLastShownCampaignId(currentId);
    ref.read(campaignDialogShownProvider.notifier).state = true;

    if (!context.mounted) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'CampaignGift',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (ctx, _, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curved,
          child: FadeTransition(
            opacity: anim,
            child: _CampaignGiftDialog(campaign: campaign),
          ),
        );
      },
    );
  }

  /// Re-shows the dialog (e.g. when user taps the banner "view offer" button).
  static void showGiftDialog(BuildContext context, Map<String, dynamic> campaign) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'CampaignGift',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (ctx, _, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curved,
          child: FadeTransition(
            opacity: anim,
            child: _CampaignGiftDialog(campaign: campaign),
          ),
        );
      },
    );
  }
}

// ─── Gift Dialog ─────────────────────────────────────────────────────────────

class _CampaignGiftDialog extends StatelessWidget {
  final Map<String, dynamic> campaign;
  const _CampaignGiftDialog({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final endAt = DateTime.tryParse(campaign['end_at'] ?? '');
    final daysLeft = endAt != null ? endAt.difference(DateTime.now()).inDays : 0;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.25),
              blurRadius: 50,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF1E1B4B).withValues(alpha: 0.95),
                          const Color(0xFF0F172A).withValues(alpha: 0.98),
                        ]
                      : [
                          const Color(0xFFFFFFFF).withValues(alpha: 0.9),
                          const Color(0xFFF1F5F9).withValues(alpha: 0.95),
                        ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.25),
                  width: 2,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated sparkle icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFA855F7).withValues(alpha: 0.25),
                            const Color(0xFFA855F7).withValues(alpha: 0.05),
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xFFA855F7).withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        PhosphorIconsFill.gift,
                        color: Color(0xFFA855F7),
                        size: 38,
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 2400.ms, color: const Color(0xFFA855F7).withValues(alpha: 0.2)),
                    const SizedBox(height: 20),

                    // Days left badge
                    if (daysLeft > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, color: Color(0xFFEF4444), size: 12),
                            const SizedBox(width: 5),
                            Text(
                              'ينتهي خلال $daysLeft يوم',
                              style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 14),

                    // Title
                    Text(
                      campaign['title'] ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.8,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Description
                    Text(
                      campaign['promo_text'] ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white60 : Colors.black54,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // CTA button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFA855F7),
                              Color(0xFF8B5CF6),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFA855F7).withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text(
                            'استفد من العرض الآن 🎁',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? Colors.white30 : Colors.black38,
                      ),
                      child: const Text(
                        'لاحقاً',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Collapsible Campaign Banner ──────────────────────────────────────────────

/// A collapsible pill-shaped banner that sits at the very top of a screen.
/// Tap the chevron to collapse it into a slim strip, tap again to expand.
class CampaignTopBanner extends ConsumerWidget {
  const CampaignTopBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignAsync = ref.watch(activeCampaignProvider);
    final isCollapsed = ref.watch(campaignBannerCollapsedProvider);

    return campaignAsync.when(
      data: (campaign) {
        if (campaign == null) return const SizedBox.shrink();
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AnimatedSize(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
          child: isCollapsed
              ? _CollapsedStrip(isDark: isDark, campaign: campaign)
              : _ExpandedBanner(isDark: isDark, campaign: campaign),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.3);
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }
}

/// Slim collapsed version — just a thin pill with a gift icon and "اضغط لرؤية العرض"
class _CollapsedStrip extends ConsumerWidget {
  final bool isDark;
  final Map<String, dynamic> campaign;
  const _CollapsedStrip({required this.isDark, required this.campaign});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(campaignBannerCollapsedProvider.notifier).state = false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    AppTheme.primaryColor.withValues(alpha: 0.25),
                    AppTheme.primaryColor.withValues(alpha: 0.1),
                  ]
                : [
                    AppTheme.primaryColor.withValues(alpha: 0.12),
                    AppTheme.primaryColor.withValues(alpha: 0.05),
                  ],
          ),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.45 : 0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIconsFill.gift, color: AppTheme.primaryColor, size: 14),
            const SizedBox(width: 8),
            Text(
              'عرض حصري • اضغط للتوسيع',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryColor, size: 16),
          ],
        ),
      ),
    );
  }
}

/// Full expanded banner with all campaign details.
class _ExpandedBanner extends ConsumerWidget {
  final bool isDark;
  final Map<String, dynamic> campaign;
  const _ExpandedBanner({required this.isDark, required this.campaign});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final endAt = DateTime.tryParse(campaign['end_at'] ?? '');
    final daysLeft = endAt != null ? endAt.difference(DateTime.now()).inDays : 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF110E2E)]
              : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
        ),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.5 : 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Decorative background blobs
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              left: -10,
              bottom: -10,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withValues(alpha: 0.06),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  // Gift icon with glow
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFA855F7).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFA855F7).withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      PhosphorIconsFill.gift,
                      color: Color(0xFFA855F7),
                      size: 24,
                    ).animate(onPlay: (c) => c.repeat())
                     .shimmer(duration: 3.seconds, color: const Color(0xFFA855F7).withValues(alpha: 0.3)),
                  ),
                  const SizedBox(width: 12),
                  // Text
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (daysLeft > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '⏳ ينتهي خلال $daysLeft يوم',
                              style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        Text(
                          campaign['title'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          campaign['promo_text'] ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.black54,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => CampaignOverlay.showGiftDialog(context, campaign),
                          child: const Text(
                            'عرض التفاصيل ←',
                            style: TextStyle(
                              color: Color(0xFFA855F7),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Collapse button
                  GestureDetector(
                    onTap: () => ref.read(campaignBannerCollapsedProvider.notifier).state = true,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: isDark ? Colors.white38 : Colors.black38,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
