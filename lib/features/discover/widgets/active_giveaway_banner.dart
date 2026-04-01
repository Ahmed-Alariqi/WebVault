import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/giveaway_model.dart';
import '../../../presentation/providers/events_providers.dart';
import '../../../l10n/app_localizations.dart';

class ActiveGiveawayBanner extends ConsumerWidget {
  const ActiveGiveawayBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final giveawayAsync = ref.watch(activeGiveawayProvider);
    final hiddenEvents = ref.watch(hiddenEventsProvider);
    return giveawayAsync.when(
      data: (giveaway) {
        if (giveaway == null || hiddenEvents.contains(giveaway.id)) {
          return const SizedBox.shrink();
        }
        return _BannerContent(giveaway: giveaway);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _BannerContent extends ConsumerStatefulWidget {
  final Giveaway giveaway;
  const _BannerContent({required this.giveaway});

  @override
  ConsumerState<_BannerContent> createState() => _BannerContentState();
}

class _BannerContentState extends ConsumerState<_BannerContent> {
  bool _entering = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final g = widget.giveaway;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GestureDetector(
        onTap: () => context.push('/giveaway/${g.id}'),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE11D48), Color(0xFFBE185D)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE11D48).withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background decoration
              Positioned(
                right: -20,
                top: -15,
                child: Icon(
                  PhosphorIcons.gift(PhosphorIconsStyle.fill),
                  size: 100,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              // Close button
              Positioned(
                right: 8,
                top: 8,
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white54,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    ref
                        .read(hiddenEventsProvider.notifier)
                        .update((state) => {...state, g.id});
                  },
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.giveawayLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Title
                    Text(
                      g.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Stats row
                    Row(
                      children: [
                        Icon(
                          PhosphorIcons.clockCountdown(),
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(g.timeRemaining, l10n),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          PhosphorIcons.users(),
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${g.entryCount} ${l10n.entries}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Action button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: g.hasEntered || g.isFull || _entering
                            ? null
                            : () async {
                                HapticFeedback.mediumImpact();
                                setState(() => _entering = true);
                                try {
                                  await enterGiveaway(g.id, ref);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${l10n.enteredGiveaway} 🎉',
                                        ),
                                        backgroundColor: const Color(
                                          0xFF10B981,
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                } finally {
                                  if (mounted)
                                    setState(() => _entering = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFE11D48),
                          disabledBackgroundColor: Colors.white.withValues(
                            alpha: 0.6,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _entering
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    g.hasEntered
                                        ? PhosphorIcons.checkCircle(
                                            PhosphorIconsStyle.fill,
                                          )
                                        : PhosphorIcons.sparkle(
                                            PhosphorIconsStyle.fill,
                                          ),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    g.hasEntered
                                        ? l10n.alreadyEntered
                                        : l10n.enterGiveaway,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15);
  }

  String _formatTime(Duration d, AppLocalizations l10n) {
    if (d.isNegative) return l10n.ended;
    if (d.inDays > 0) return l10n.daysLeft(d.inDays.toString());
    if (d.inHours > 0) return l10n.hoursLeft(d.inHours.toString());
    return '${d.inMinutes} ${l10n.minutesLeft}';
  }
}
