import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/ai_stats_model.dart';
import '../../presentation/providers/zad_expert_providers.dart';
import '../zad_expert/zad_expert_screen.dart' show personaIconFromName;

// ═══════════════════════════════════════════════════════════════════════════
// Stats tab — admin-only AI usage dashboard.
//
// Six self-contained sections, each backed by its own auto-disposing
// FutureProvider so a slow/failing query never blocks the rest of the page:
//   1) Period selector (today / 7d / 15d)
//   2) Overview cards (total, success%, avg latency, errors)
//   3) Top personas (horizontal bar list)
//   4) Top providers (horizontal bar list with success%)
//   5) Top users (Top 10 heaviest consumers)
//   6) Per-key health (per-provider grouping, masked suffixes)
//   7) Recent errors (last 10 across all providers)
// ═══════════════════════════════════════════════════════════════════════════

class AdminAiStatsTab extends ConsumerWidget {
  final bool isDark;
  const AdminAiStatsTab({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(aiOverviewProvider);
        ref.invalidate(aiTopPersonasProvider);
        ref.invalidate(aiTopProvidersProvider);
        ref.invalidate(aiTopUsersProvider);
        ref.invalidate(aiKeyHealthProvider);
        ref.invalidate(aiRecentErrorsProvider);
        // Wait briefly so the spinner doesn't disappear instantly.
        await Future<void>.delayed(const Duration(milliseconds: 300));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _PeriodSelector(isDark: isDark),
          const SizedBox(height: 16),
          _OverviewSection(isDark: isDark),
          const SizedBox(height: 20),
          _SectionHeader(
            isDark: isDark,
            icon: PhosphorIcons.robot(PhosphorIconsStyle.fill),
            title: 'الأكثر استخداماً — الشخصيات',
          ),
          const SizedBox(height: 8),
          _TopPersonasSection(isDark: isDark),
          const SizedBox(height: 20),
          _SectionHeader(
            isDark: isDark,
            icon: PhosphorIcons.plugs(PhosphorIconsStyle.fill),
            title: 'توزيع الطلبات على المزودين',
          ),
          const SizedBox(height: 8),
          _TopProvidersSection(isDark: isDark),
          const SizedBox(height: 20),
          _SectionHeader(
            isDark: isDark,
            icon: PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
            title: 'أكثر المستخدمين استخداماً (Top 10)',
          ),
          const SizedBox(height: 8),
          _TopUsersSection(isDark: isDark),
          const SizedBox(height: 20),
          _SectionHeader(
            isDark: isDark,
            icon: PhosphorIcons.key(PhosphorIconsStyle.fill),
            title: 'صحة المفاتيح',
          ),
          const SizedBox(height: 8),
          _KeyHealthSection(isDark: isDark),
          const SizedBox(height: 20),
          _SectionHeader(
            isDark: isDark,
            icon: PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
            title: 'آخر الأخطاء',
          ),
          const SizedBox(height: 8),
          _RecentErrorsSection(isDark: isDark),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Period selector
// ═══════════════════════════════════════════════════════════════════════════

class _PeriodSelector extends ConsumerWidget {
  final bool isDark;
  const _PeriodSelector({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(aiStatsPeriodProvider);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
        ),
      ),
      child: Row(
        children: AiStatsPeriod.values.map((p) {
          final isActive = p == current;
          return Expanded(
            child: GestureDetector(
              onTap: () => ref.read(aiStatsPeriodProvider.notifier).state = p,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF8B5CF6)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    p.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? Colors.white
                          : (isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Section header
// ═══════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  const _SectionHeader({
    required this.isDark,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF8B5CF6)),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Overview cards
// ═══════════════════════════════════════════════════════════════════════════

class _OverviewSection extends ConsumerWidget {
  final bool isDark;
  const _OverviewSection({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(aiOverviewProvider);
    return asyncStats.when(
      loading: () => const _OverviewSkeleton(),
      error: (e, _) => _ErrorBox(message: 'تعذّر جلب النظرة العامة', isDark: isDark),
      data: (s) => Row(
        children: [
          Expanded(
            child: _StatCard(
              isDark: isDark,
              icon: PhosphorIcons.chatCircleDots(PhosphorIconsStyle.fill),
              color: const Color(0xFF8B5CF6),
              value: _fmtCount(s.total),
              label: 'الطلبات',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              isDark: isDark,
              icon: PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
              color: const Color(0xFF10B981),
              value: '${s.successPct.toStringAsFixed(0)}%',
              label: 'نسبة النجاح',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              isDark: isDark,
              icon: PhosphorIcons.timer(PhosphorIconsStyle.fill),
              color: const Color(0xFF3B82F6),
              value: _fmtMs(s.avgMs),
              label: 'متوسط الردّ',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              isDark: isDark,
              icon: PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
              color: const Color(0xFFEF4444),
              value: _fmtCount(s.errorCount),
              label: 'الأخطاء',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _StatCard({
    required this.isDark,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.15, end: 0);
  }
}

class _OverviewSkeleton extends StatelessWidget {
  const _OverviewSkeleton();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Row(
        children: List.generate(
          4,
          (_) => Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1100.ms,
          color: Colors.white.withValues(alpha: 0.2),
        );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Top personas / providers / users — share the same horizontal-bar visual
// ═══════════════════════════════════════════════════════════════════════════

class _TopPersonasSection extends ConsumerWidget {
  final bool isDark;
  const _TopPersonasSection({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(aiTopPersonasProvider);
    return asyncList.when(
      loading: () => _ListSkeleton(isDark: isDark),
      error: (e, _) => _ErrorBox(message: 'تعذّر جلب الشخصيات', isDark: isDark),
      data: (list) {
        if (list.isEmpty) return _EmptyBox(isDark: isDark, label: 'لا توجد طلبات في هذه الفترة');
        final maxCount = list.first.count;
        return _SectionCard(
          isDark: isDark,
          children: [
            for (var i = 0; i < list.length; i++) ...[
              _BarRow(
                isDark: isDark,
                leading: _PersonaAvatar(icon: list[i].icon),
                label: list[i].name,
                count: list[i].count,
                ratio: maxCount > 0 ? list[i].count / maxCount : 0,
                color: const Color(0xFF8B5CF6),
              ),
              if (i < list.length - 1) const Divider(height: 14),
            ],
          ],
        );
      },
    );
  }
}

class _PersonaAvatar extends StatelessWidget {
  final String icon;
  const _PersonaAvatar({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(personaIconFromName(icon),
          size: 16, color: const Color(0xFF8B5CF6)),
    );
  }
}

class _TopProvidersSection extends ConsumerWidget {
  final bool isDark;
  const _TopProvidersSection({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(aiTopProvidersProvider);
    return asyncList.when(
      loading: () => _ListSkeleton(isDark: isDark),
      error: (e, _) => _ErrorBox(message: 'تعذّر جلب المزودين', isDark: isDark),
      data: (list) {
        if (list.isEmpty) return _EmptyBox(isDark: isDark, label: 'لا توجد طلبات في هذه الفترة');
        final maxCount = list.first.count;
        return _SectionCard(
          isDark: isDark,
          children: [
            for (var i = 0; i < list.length; i++) ...[
              _BarRow(
                isDark: isDark,
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.cable_rounded,
                      size: 16, color: Color(0xFF3B82F6)),
                ),
                label: list[i].name,
                trailingNote: '${list[i].successPct.toStringAsFixed(0)}% نجاح',
                count: list[i].count,
                ratio: maxCount > 0 ? list[i].count / maxCount : 0,
                color: const Color(0xFF3B82F6),
              ),
              if (i < list.length - 1) const Divider(height: 14),
            ],
          ],
        );
      },
    );
  }
}

class _TopUsersSection extends ConsumerWidget {
  final bool isDark;
  const _TopUsersSection({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(aiTopUsersProvider);
    return asyncList.when(
      loading: () => _ListSkeleton(isDark: isDark),
      error: (e, _) => _ErrorBox(message: 'تعذّر جلب المستخدمين', isDark: isDark),
      data: (list) {
        if (list.isEmpty) return _EmptyBox(isDark: isDark, label: 'لا توجد طلبات في هذه الفترة');
        final maxCount = list.first.count;
        return _SectionCard(
          isDark: isDark,
          children: [
            for (var i = 0; i < list.length; i++) ...[
              _BarRow(
                isDark: isDark,
                leading: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                label: list[i].displayLabel,
                trailingNote: list[i].fullName.isNotEmpty
                    ? list[i].fullName
                    : null,
                count: list[i].count,
                ratio: maxCount > 0 ? list[i].count / maxCount : 0,
                color: const Color(0xFF10B981),
              ),
              if (i < list.length - 1) const Divider(height: 14),
            ],
          ],
        );
      },
    );
  }
}

class _BarRow extends StatelessWidget {
  final bool isDark;
  final Widget leading;
  final String label;
  final String? trailingNote;
  final int count;
  final double ratio;
  final Color color;
  const _BarRow({
    required this.isDark,
    required this.leading,
    required this.label,
    this.trailingNote,
    required this.count,
    required this.ratio,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        leading,
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.05, 1.0),
                  minHeight: 6,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              if (trailingNote != null) ...[
                const SizedBox(height: 4),
                Text(
                  trailingNote!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Per-key health
// ═══════════════════════════════════════════════════════════════════════════

class _KeyHealthSection extends ConsumerWidget {
  final bool isDark;
  const _KeyHealthSection({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(aiKeyHealthProvider);
    return asyncList.when(
      loading: () => _ListSkeleton(isDark: isDark),
      error: (e, _) =>
          _ErrorBox(message: 'تعذّر جلب صحة المفاتيح', isDark: isDark),
      data: (list) {
        if (list.isEmpty) {
          return _EmptyBox(
              isDark: isDark, label: 'لم يُسجّل استخدام أي مفتاح بعد');
        }
        // Group rows by provider name so the admin sees them clustered.
        final byProvider = <String, List<AiKeyHealth>>{};
        for (final k in list) {
          byProvider.putIfAbsent(k.providerName, () => []).add(k);
        }
        return _SectionCard(
          isDark: isDark,
          children: [
            for (final entry in byProvider.entries) ...[
              Text(
                entry.key,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              for (final k in entry.value) _KeyHealthRow(isDark: isDark, k: k),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _KeyHealthRow extends StatelessWidget {
  final bool isDark;
  final AiKeyHealth k;
  const _KeyHealthRow({required this.isDark, required this.k});

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = switch (k.level) {
      AiKeyHealthLevel.healthy => (
          const Color(0xFF10B981),
          'صحّي',
          PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
        ),
      AiKeyHealthLevel.warning => (
          const Color(0xFFF59E0B),
          'تحذير',
          PhosphorIcons.warning(PhosphorIconsStyle.fill),
        ),
      AiKeyHealthLevel.broken => (
          const Color(0xFFEF4444),
          'معطّل',
          PhosphorIcons.xCircle(PhosphorIconsStyle.fill),
        ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            '...${k.keySuffix}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const Spacer(),
          Text(
            '${k.success} نجاح / ${k.fail} فشل${k.lastStatus != null ? ' (${k.lastStatus})' : ''}',
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Recent errors
// ═══════════════════════════════════════════════════════════════════════════

class _RecentErrorsSection extends ConsumerWidget {
  final bool isDark;
  const _RecentErrorsSection({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(aiRecentErrorsProvider);
    return asyncList.when(
      loading: () => _ListSkeleton(isDark: isDark),
      error: (e, _) =>
          _ErrorBox(message: 'تعذّر جلب الأخطاء الأخيرة', isDark: isDark),
      data: (list) {
        if (list.isEmpty) {
          return _EmptyBox(
              isDark: isDark,
              label: 'لا توجد أخطاء — كل شيء يعمل بسلاسة! ✨');
        }
        return _SectionCard(
          isDark: isDark,
          children: [
            for (var i = 0; i < list.length; i++) ...[
              _ErrorRow(isDark: isDark, e: list[i]),
              if (i < list.length - 1) const Divider(height: 14),
            ],
          ],
        );
      },
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final bool isDark;
  final AiErrorEntry e;
  const _ErrorRow({required this.isDark, required this.e});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFFEF4444),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${e.statusCode}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    e.providerName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (e.keySuffix != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      '...${e.keySuffix}',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    _fmtRelative(e.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              if (e.errorMessage != null && e.errorMessage!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  e.errorMessage!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared little helpers
// ═══════════════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;
  const _SectionCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ).animate().fadeIn(duration: 220.ms);
  }
}

class _ListSkeleton extends StatelessWidget {
  final bool isDark;
  const _ListSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1100.ms,
          color: Colors.white.withValues(alpha: 0.18),
        );
  }
}

class _EmptyBox extends StatelessWidget {
  final bool isDark;
  final String label;
  const _EmptyBox({required this.isDark, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
        ),
      ),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final bool isDark;
  const _ErrorBox({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
              size: 18, color: const Color(0xFFEF4444)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Formatting helpers
// ═══════════════════════════════════════════════════════════════════════════

String _fmtCount(int n) {
  if (n < 1000) return n.toString();
  if (n < 1000000) return '${(n / 1000).toStringAsFixed(n < 10000 ? 1 : 0)}k';
  return '${(n / 1000000).toStringAsFixed(1)}m';
}

String _fmtMs(double ms) {
  if (ms < 1000) return '${ms.toInt()}ms';
  return '${(ms / 1000).toStringAsFixed(1)}s';
}

String _fmtRelative(DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inSeconds < 60) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes}د';
  if (diff.inHours < 24) return 'منذ ${diff.inHours}س';
  return 'منذ ${diff.inDays}ي';
}
