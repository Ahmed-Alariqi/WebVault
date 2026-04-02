import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/poll_model.dart';
import '../../../presentation/providers/events_providers.dart';
import '../../../l10n/app_localizations.dart';

class ActivePollCard extends ConsumerWidget {
  const ActivePollCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pollAsync = ref.watch(activePollProvider);
    final hiddenEvents = ref.watch(hiddenEventsProvider);
    return pollAsync.when(
      data: (poll) {
        if (poll == null || hiddenEvents.contains(poll.id)) {
          return const SizedBox.shrink();
        }
        return _PollCardContent(poll: poll);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _PollCardContent extends ConsumerStatefulWidget {
  final Poll poll;
  const _PollCardContent({required this.poll});

  @override
  ConsumerState<_PollCardContent> createState() => _PollCardContentState();
}

class _PollCardContentState extends ConsumerState<_PollCardContent> {
  bool _voting = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final poll = widget.poll;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.poll_outlined,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.pollLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    PhosphorIcons.clockCountdown(),
                    size: 14,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(poll.timeRemaining, l10n),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      ref
                          .read(hiddenEventsProvider.notifier)
                          .update((state) => {...state, poll.id});
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Question
              Text(
                poll.question,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              if (poll.description != null && poll.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  poll.description!,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Options
              ...poll.options.asMap().entries.map((entry) {
                final idx = entry.key;
                final option = entry.value;
                final pct = poll.votePercentage(idx);
                final count = poll.voteCounts[idx] ?? 0;
                final isSelected = poll.userVotes.contains(idx);
                final showResults = poll.hasVoted || poll.isEnded;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap:
                        (poll.hasVoted && !poll.allowMultiple) ||
                            poll.isEnded ||
                            _voting
                        ? null
                        : () async {
                            HapticFeedback.selectionClick();
                            setState(() => _voting = true);
                            try {
                              if (isSelected) {
                                await unvotePoll(poll.id, idx, ref);
                              } else {
                                await votePoll(poll.id, idx, ref);
                              }
                            } catch (_) {}
                            if (mounted) setState(() => _voting = false);
                          },
                    child: AnimatedContainer(
                      duration: 400.ms,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF7C3AED)
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.06)),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Stack(
                          children: [
                            // Progress bar
                            if (showResults)
                              AnimatedContainer(
                                duration: 600.ms,
                                curve: Curves.easeOut,
                                height: 50,
                                width:
                                    MediaQuery.of(context).size.width *
                                    pct *
                                    0.75,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(
                                          0xFF7C3AED,
                                        ).withValues(alpha: 0.15)
                                      : (isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.04,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.03,
                                              )),
                                ),
                              ),
                            // Content
                            Container(
                              height: 50,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  if (!showResults)
                                    Icon(
                                      isSelected
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_off,
                                      size: 20,
                                      color: isSelected
                                          ? const Color(0xFF7C3AED)
                                          : (isDark
                                                ? Colors.white24
                                                : Colors.black26),
                                    )
                                  else if (isSelected)
                                    const Icon(
                                      PhosphorIconsRegular.checkCircle,
                                      size: 18,
                                      color: Color(0xFF7C3AED),
                                    ),
                                  if (!showResults || isSelected)
                                    const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? const Color(0xFF7C3AED)
                                            : (isDark
                                                  ? Colors.white
                                                  : Colors.black87),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (showResults) ...[
                                    Text(
                                      '${(pct * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected
                                            ? const Color(0xFF7C3AED)
                                            : (isDark
                                                  ? Colors.white54
                                                  : Colors.black54),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '($count)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.black38,
                                      ),
                                    ),
                                  ],
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

              // Footer
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    PhosphorIcons.users(),
                    size: 14,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${poll.totalVotes} ${l10n.votes}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  if (poll.allowMultiple) ...[
                    const SizedBox(width: 12),
                    Icon(
                      PhosphorIcons.checks(),
                      size: 14,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.multipleChoice,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ],
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
    return '${d.inMinutes} ${l10n.minutesLeftLabel}';
  }
}
