import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
      error: (_, _) => const SizedBox.shrink(),
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

  Future<void> _submitEntry([String? value]) async {
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.mediumImpact();
    setState(() => _entering = true);
    try {
      await enterGiveaway(widget.giveaway.id, ref, entryValue: value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.enteredGiveaway} 🎉'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _entering = false);
      }
    }
  }

  void _showEntryDataModal() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE11D48).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      PhosphorIconsRegular.paperPlaneRight,
                      color: Color(0xFFE11D48),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.giveaway.entryFieldLabel!,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: ctrl,
                autofocus: true,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: const Color(0xFFE11D48),
                decoration: InputDecoration(
                  hintText: l10n.enterGiveaway,
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontWeight: FontWeight.w400,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFE11D48),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final val = ctrl.text.trim();
                  if (val.isEmpty) return;
                  Navigator.pop(context);
                  _submitEntry(val);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE11D48),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.enterGiveaway,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

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
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE11D48).withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Background: image or gradient
                Positioned.fill(
                  child: g.imageUrl != null && g.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: g.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFE11D48), Color(0xFFBE185D)],
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFE11D48), Color(0xFFBE185D)],
                              ),
                            ),
                          ),
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFE11D48), Color(0xFFBE185D)],
                            ),
                          ),
                        ),
                ),
                // Gradient overlay for text readability
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(
                            alpha: g.imageUrl != null ? 0.3 : 0,
                          ),
                          Colors.black.withValues(
                            alpha: g.imageUrl != null ? 0.7 : 0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Decorative icon (only when no image)
                if (g.imageUrl == null || g.imageUrl!.isEmpty)
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
                Positioned.directional(
                  textDirection: Directionality.of(context),
                  end: 8,
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
                              : () {
                                  if (g.entryFieldLabel != null &&
                                      g.entryFieldLabel!.isNotEmpty) {
                                    _showEntryDataModal();
                                  } else {
                                    _submitEntry();
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
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15);
  }

  String _formatTime(Duration d, AppLocalizations l10n) {
    if (d.isNegative) return l10n.ended;
    if (d.inDays > 0) return l10n.daysLeft(d.inDays.toString());
    if (d.inHours > 0) return l10n.hoursLeft(d.inHours.toString());
    return '${d.inMinutes} ${l10n.minutesLeftLabel}';
  }
}
