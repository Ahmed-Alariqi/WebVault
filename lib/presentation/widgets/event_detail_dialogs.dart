import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/giveaway_model.dart';
import '../../data/models/poll_model.dart';
import '../../presentation/providers/events_providers.dart';
import '../../l10n/app_localizations.dart';

// ════════════════════════════════════════
//  GIVEAWAY DETAIL DIALOG
// ════════════════════════════════════════

class GiveawayDetailDialog extends ConsumerStatefulWidget {
  final Giveaway giveaway;
  const GiveawayDetailDialog({super.key, required this.giveaway});

  @override
  ConsumerState<GiveawayDetailDialog> createState() =>
      _GiveawayDetailDialogState();
}

class _GiveawayDetailDialogState extends ConsumerState<GiveawayDetailDialog> {
  final _entryCtrl = TextEditingController();
  bool _isEntering = false;

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final giveaway = widget.giveaway;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final isActive = giveaway.isActive;
    final isDrawn = giveaway.isDrawn;
    final color = isDrawn
        ? AppTheme.successColor
        : isActive
        ? AppTheme.primaryColor
        : Colors.grey;

    final statusLabel = isDrawn
        ? l10n.drawn
        : isActive
        ? l10n.active
        : l10n.ended;

    return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: -5,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      child:
                          giveaway.imageUrl != null &&
                              giveaway.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: giveaway.imageUrl!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => Container(
                                height: 200,
                                color: color.withValues(alpha: 0.1),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (_, _, _) => _iconHeader(color),
                            )
                          : _iconHeader(color),
                    ),

                    // Content Body
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              giveaway.title,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _badge(statusLabel, color, isDark),
                                const SizedBox(width: 8),
                                _badge(
                                  _prizeLabel(giveaway.prizeType, l10n),
                                  AppTheme.accentColor,
                                  isDark,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (giveaway.description != null &&
                                giveaway.description!.isNotEmpty) ...[
                              Divider(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.06),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                giveaway.description!,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.6,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Stats Row
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
                                  _stat(
                                    PhosphorIcons.users(),
                                    '${giveaway.entryCount}',
                                    l10n.entries,
                                    isDark,
                                  ),
                                  Container(
                                    width: 1,
                                    height: 32,
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.black12,
                                  ),
                                  _stat(
                                    PhosphorIcons.clockCountdown(),
                                    _timeValue(giveaway.endsAt),
                                    isActive ? l10n.timeLeft : l10n.ended,
                                    isDark,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Entry value field
                            if (isActive &&
                                giveaway.hasEntryField &&
                                !giveaway.hasEntered) ...[
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 4,
                                  bottom: 8,
                                ),
                                child: Text(
                                  giveaway.entryFieldLabel!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : Colors.black.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: TextField(
                                  controller: _entryCtrl,
                                  onChanged: (_) => setState(() {}),
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  cursorColor: AppTheme.primaryColor,
                                  decoration: InputDecoration(
                                    hintText: l10n.enterYourValue,
                                    hintStyle: TextStyle(
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black38,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: AppTheme.primaryColor,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Icon(
                                        PhosphorIcons.textbox(),
                                        size: 20,
                                        color: AppTheme.primaryColor.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            // Enter button
                            if (isActive)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: giveaway.hasEntered || _isEntering
                                      ? null
                                      : (giveaway.hasEntryField &&
                                            _entryCtrl.text.trim().isEmpty)
                                      ? null
                                      : () async {
                                          setState(() => _isEntering = true);
                                          try {
                                            await enterGiveaway(
                                              giveaway.id,
                                              ref,
                                              entryValue: giveaway.hasEntryField
                                                  ? _entryCtrl.text.trim()
                                                  : null,
                                            );
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    )!.enteredGiveawaySuccess,
                                                  ),
                                                  backgroundColor:
                                                      AppTheme.successColor,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  duration: const Duration(
                                                    seconds: 2,
                                                  ),
                                                ),
                                              );
                                              Navigator.of(context).pop();
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              final eStr = e.toString();
                                              if (eStr.contains(
                                                'referrals_required_',
                                              )) {
                                                final countStr = eStr
                                                    .split(
                                                      'referrals_required_',
                                                    )
                                                    .last
                                                    .replaceAll(
                                                      RegExp(r'[^0-9]'),
                                                      '',
                                                    );
                                                final count =
                                                    int.tryParse(countStr) ?? 0;
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'عذراً، يتطلب الدخول إكمال ($count) إحالة ناجحة أولاً.',
                                                    ),
                                                    backgroundColor:
                                                        AppTheme.errorColor,
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    duration: const Duration(
                                                      seconds: 4,
                                                    ),
                                                    action: SnackBarAction(
                                                      label: 'الذهاب للإحالات',
                                                      textColor: Colors.white,
                                                      onPressed: () {
                                                        if (context.mounted) {
                                                          Navigator.pop(
                                                            context,
                                                          );
                                                          context.push(
                                                            '/profile',
                                                          );
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      AppLocalizations.of(
                                                            context,
                                                          )!.failedToEnterGiveaway ??
                                                          'Failed to enter.',
                                                    ),
                                                    backgroundColor:
                                                        AppTheme.errorColor,
                                                  ),
                                                );
                                              }
                                            }
                                            setState(() => _isEntering = false);
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: giveaway.hasEntered
                                        ? (isDark
                                              ? Colors.white10
                                              : Colors.black12)
                                        : AppTheme.primaryColor,
                                    foregroundColor: giveaway.hasEntered
                                        ? (isDark
                                              ? Colors.white38
                                              : Colors.black38)
                                        : Colors.white,
                                    disabledBackgroundColor: isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : Colors.black.withValues(alpha: 0.06),
                                    disabledForegroundColor: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  icon: _isEntering
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Icon(
                                          giveaway.hasEntered
                                              ? PhosphorIcons.checkCircle(
                                                  PhosphorIconsStyle.fill,
                                                )
                                              : PhosphorIcons.ticket(
                                                  PhosphorIconsStyle.fill,
                                                ),
                                          size: 20,
                                        ),
                                  label: Text(
                                    giveaway.hasEntered
                                        ? l10n.alreadyEntered
                                        : l10n.enterGiveaway,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),

                            // Winners (multiple)
                            if (isDrawn && giveaway.winnerIds.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.successColor.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme.successColor.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          PhosphorIcons.trophy(
                                            PhosphorIconsStyle.fill,
                                          ),
                                          color: AppTheme.successColor,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '${l10n.winners} (${giveaway.winnerIds.length})',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.successColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ...giveaway.winnerIds.map(
                                      (wId) => Consumer(
                                        builder: (ctx, cRef, _) {
                                          final nameAsync = cRef.watch(
                                            winnerNameProvider(wId),
                                          );
                                          return nameAsync.when(
                                            data: (name) => Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 3,
                                                  ),
                                              child: Text(
                                                '\u2022 $name',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isDark
                                                      ? Colors.white60
                                                      : Colors.black54,
                                                ),
                                              ),
                                            ),
                                            loading: () => const SizedBox(
                                              height: 14,
                                              width: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 1.5,
                                              ),
                                            ),
                                            error: (_, _) =>
                                                const SizedBox.shrink(),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Close button
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack);
  }

  Widget _iconHeader(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            PhosphorIcons.gift(PhosphorIconsStyle.fill),
            size: 56,
            color: color,
          ),
        ),
      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _badge(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: isDark ? Colors.white38 : Colors.black38),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black45,
            ),
          ),
        ],
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

  String _timeValue(DateTime endsAt) {
    final diff = endsAt.difference(DateTime.now());
    if (diff.isNegative) return '—';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    return '${diff.inMinutes}m';
  }
}

// ════════════════════════════════════════
//  POLL DETAIL DIALOG
// ════════════════════════════════════════

class PollDetailDialog extends ConsumerStatefulWidget {
  final Poll poll;
  const PollDetailDialog({super.key, required this.poll});

  @override
  ConsumerState<PollDetailDialog> createState() => _PollDetailDialogState();
}

class _PollDetailDialogState extends ConsumerState<PollDetailDialog> {
  Set<int> _selectedIndexes = {};
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final updatedPoll = ref.watch(pollByIdProvider(widget.poll.id)).value;
    final poll = updatedPoll ?? widget.poll;

    final isActive = poll.isActive;
    final color = isActive ? AppTheme.accentColor : Colors.grey;
    final statusLabel = isActive ? l10n.active : l10n.ended;
    final totalVotes = poll.totalVotes;

    return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: -5,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Gradient header
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color.withValues(alpha: 0.2),
                              color.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child:
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.2),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  PhosphorIcons.chartBar(
                                    PhosphorIconsStyle.fill,
                                  ),
                                  size: 56,
                                  color: color,
                                ),
                              ),
                            ).animate().scale(
                              duration: 400.ms,
                              curve: Curves.easeOutBack,
                            ),
                      ),
                    ),

                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              poll.question,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _badge(statusLabel, color, isDark),
                                const SizedBox(width: 8),
                                Text(
                                  '$totalVotes ${l10n.votes}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (poll.description != null &&
                                poll.description!.isNotEmpty) ...[
                              Text(
                                poll.description!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            Divider(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.06),
                            ),
                            const SizedBox(height: 12),

                            // Interactive Options List
                            ...poll.options.asMap().entries.map((entry) {
                              final i = entry.key;
                              final option = entry.value;
                              final count = poll.voteCounts[i] ?? 0;
                              final pct = poll.votePercentage(i);
                              final isSelected =
                                  poll.userVotes.contains(i) ||
                                  (!poll.hasVoted &&
                                      _selectedIndexes.contains(i));
                              final showResults =
                                  poll.hasVoted ||
                                  poll.isEnded ||
                                  !isActive ||
                                  (!poll.hasVoted &&
                                      _selectedIndexes.isNotEmpty);
                              final isUpdating =
                                  _selectedIndexes.contains(i) && _isSubmitting;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: GestureDetector(
                                  onTap:
                                      (poll.hasVoted && !poll.allowMultiple) ||
                                          !isActive ||
                                          _isSubmitting
                                      ? null
                                      : () {
                                          setState(() {
                                            if (poll.allowMultiple) {
                                              if (_selectedIndexes.contains(
                                                i,
                                              )) {
                                                _selectedIndexes.remove(i);
                                              } else {
                                                _selectedIndexes.add(i);
                                              }
                                            } else {
                                              _selectedIndexes = {i};
                                            }
                                          });
                                        },
                                  child: AnimatedContainer(
                                    duration: 400.ms,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppTheme.accentColor
                                            : (isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.08,
                                                    )
                                                  : Colors.black.withValues(
                                                      alpha: 0.06,
                                                    )),
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
                                              height: 52,
                                              width:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width *
                                                  pct *
                                                  (isDark ? 0.8 : 0.85),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? AppTheme.accentColor
                                                          .withValues(
                                                            alpha: 0.15,
                                                          )
                                                    : (isDark
                                                          ? Colors.white
                                                                .withValues(
                                                                  alpha: 0.05,
                                                                )
                                                          : AppTheme
                                                                .primaryColor
                                                                .withValues(
                                                                  alpha: 0.05,
                                                                )),
                                              ),
                                            ),
                                          // Content
                                          Container(
                                            height: 52,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: Row(
                                              children: [
                                                if (!showResults)
                                                  Icon(
                                                    isSelected
                                                        ? Icons
                                                              .radio_button_checked
                                                        : Icons
                                                              .radio_button_off,
                                                    size: 20,
                                                    color: isSelected
                                                        ? AppTheme.accentColor
                                                        : (isDark
                                                              ? Colors.white24
                                                              : Colors.black26),
                                                  )
                                                else if (isSelected)
                                                  const Icon(
                                                    PhosphorIconsRegular
                                                        .checkCircle,
                                                    size: 18,
                                                    color: AppTheme.accentColor,
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
                                                          ? AppTheme.accentColor
                                                          : (isDark
                                                                ? Colors.white
                                                                : Colors
                                                                      .black87),
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (isUpdating) ...[
                                                  const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                                ] else if (showResults) ...[
                                                  Text(
                                                    '${(pct * 100).toStringAsFixed(0)}%',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: isSelected
                                                          ? AppTheme.accentColor
                                                          : (isDark
                                                                ? Colors.white70
                                                                : Colors
                                                                      .black54),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '($count)',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
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

                            // Vote Button
                            if (_selectedIndexes.isNotEmpty &&
                                !poll.hasVoted &&
                                isActive) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () async {
                                          setState(() {
                                            _isSubmitting = true;
                                          });
                                          try {
                                            for (final idx
                                                in _selectedIndexes) {
                                              await votePoll(poll.id, idx, ref);
                                            }
                                            if (mounted && context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    )!.votedPollSuccess,
                                                  ),
                                                  backgroundColor:
                                                      AppTheme.successColor,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  duration: const Duration(
                                                    seconds: 2,
                                                  ),
                                                ),
                                              );
                                              Future.delayed(
                                                const Duration(
                                                  milliseconds: 1200,
                                                ),
                                                () {
                                                  if (mounted &&
                                                      context.mounted) {
                                                    Navigator.of(context).pop();
                                                  }
                                                },
                                              );
                                            }
                                          } catch (_) {}
                                          if (mounted) {
                                            setState(() {
                                              _isSubmitting = false;
                                              // keeping selectedIndexes so user can see their vote while delayed
                                            });
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accentColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          l10n.pollLabel,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Close button
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack);
  }

  Widget _badge(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
