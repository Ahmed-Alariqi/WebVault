import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../presentation/providers/referral_providers.dart';
import 'referral_dialog.dart';

class ReferralReminderCard extends ConsumerStatefulWidget {
  const ReferralReminderCard({super.key});

  @override
  ConsumerState<ReferralReminderCard> createState() => _ReferralReminderCardState();
}

class _ReferralReminderCardState extends ConsumerState<ReferralReminderCard> with SingleTickerProviderStateMixin {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rotationController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTime();
    });
  }

  void _updateRemainingTime() async {
    final profileData = await ref.read(userProfileProvider.future);
    if (profileData == null) return;
    
    final profile = profileData;

    final createdAtStr = profile['created_at']?.toString();
    if (createdAtStr == null) return;

    final createdAt = DateTime.tryParse(createdAtStr);
    if (createdAt == null) return;

    final now = DateTime.now();
    final difference = now.difference(createdAt);
    final remaining = const Duration(hours: 24) - difference;

    if (mounted) {
      setState(() {
        _remainingTime = remaining.isNegative ? Duration.zero : remaining;
      });
    }

    if (remaining.isNegative) {
      _timer?.cancel();
    }
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return "انتهت الفرصة";
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (profileData) {
        if (profileData == null) return const SizedBox.shrink();
        final profile = profileData;
        
        if (profile['referred_by'] != null) return const SizedBox.shrink();

        final createdAtStr = profile['created_at']?.toString();
        if (createdAtStr == null) return const SizedBox.shrink();

        final createdAt = DateTime.tryParse(createdAtStr);
        if (createdAt == null) return const SizedBox.shrink();

        final diff = DateTime.now().difference(createdAt);
        if (diff.inHours >= 24) return const SizedBox.shrink();

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryBlue = AppTheme.primaryColor;
        final accentTeal = AppTheme.accentColor;
        
        final cardBg = isDark ? AppTheme.darkSurface : Colors.white;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(2), // The thickness of the animated border
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: SweepGradient(
                    colors: [
                      primaryBlue.withValues(alpha: 0),
                      primaryBlue,
                      accentTeal,
                      primaryBlue.withValues(alpha: 0),
                    ],
                    stops: const [0.0, 0.4, 0.6, 1.0],
                    transform: GradientRotation(_rotationController.value * 2 * 3.14159),
                  ),
                ),
                child: child,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: InkWell(
                onTap: () async {
                  final campaign = await ref.read(activeReferralCampaignProvider.future);
                  if (context.mounted) {
                    showReferralCodeDialog(context, ref, campaign);
                  }
                },
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [primaryBlue, accentTeal],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          PhosphorIconsFill.gift,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'معك كود دعوة؟ استلم هديتك الآن! 🎁',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14, // Slightly smaller for better fit
                                color: isDark ? Colors.white : primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'أدخل كود صديقك لتفعيل ميزات PRO فوراً',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : primaryBlue.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _formatDuration(_remainingTime),
                          style: TextStyle(
                            color: isDark ? accentTeal : primaryBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
