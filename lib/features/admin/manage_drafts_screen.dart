import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/draft_model.dart';
import '../../data/models/ai_content_result.dart';
import '../../presentation/providers/admin_providers.dart';
import '../../presentation/widgets/modern_fab.dart';
import '../../core/utils/admin_ui_utils.dart';
import 'widgets/quick_draft_sheet.dart';
import 'widgets/ai_content_prep_sheet.dart';

class ManageDraftsScreen extends ConsumerStatefulWidget {
  const ManageDraftsScreen({super.key});

  @override
  ConsumerState<ManageDraftsScreen> createState() => _ManageDraftsScreenState();
}

class _ManageDraftsScreenState extends ConsumerState<ManageDraftsScreen> {
  String? _statusFilter; // null = all

  static const _contentTypeValues = [
    'website', 'tool', 'course', 'prompt', 'offer', 'announcement', 'tutorial',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final draftsAsync = ref.watch(adminDraftsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.notepad(PhosphorIconsStyle.fill),
              size: 22,
              color: const Color(0xFFF59E0B),
            ),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.draftsTitle),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Status filter chips
          Container(
            height: 56,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _filterChip(
                  label: AppLocalizations.of(context)!.filterAll,
                  icon: PhosphorIcons.squaresFour(),
                  isSelected: _statusFilter == null,
                  onTap: () => setState(() => _statusFilter = null),
                  isDark: isDark,
                  color: AppTheme.primaryColor,
                ),
                _filterChip(
                  label: AppLocalizations.of(context)!.draftsFilterIdeas,
                  icon: PhosphorIcons.lightbulb(),
                  isSelected: _statusFilter == 'idea',
                  onTap: () => setState(() => _statusFilter = 'idea'),
                  isDark: isDark,
                  color: const Color(0xFFF59E0B),
                ),
                _filterChip(
                  label: AppLocalizations.of(context)!.draftsFilterInProgress,
                  icon: PhosphorIcons.clockClockwise(),
                  isSelected: _statusFilter == 'in_progress',
                  onTap: () => setState(() => _statusFilter = 'in_progress'),
                  isDark: isDark,
                  color: const Color(0xFF3B82F6),
                ),
                _filterChip(
                  label: AppLocalizations.of(context)!.draftsFilterReady,
                  icon: PhosphorIcons.checkCircle(),
                  isSelected: _statusFilter == 'ready',
                  onTap: () => setState(() => _statusFilter = 'ready'),
                  isDark: isDark,
                  color: AppTheme.successColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Draft list
          Expanded(
            child: draftsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(AppLocalizations.of(context)!.errorMessage(e.toString()),
                    style: TextStyle(color: AppTheme.errorColor)),
              ),
              data: (drafts) {
                // Apply filter
                final filtered = _statusFilter != null
                    ? drafts
                        .where((d) =>
                            d.status == _statusFilter && !d.isPublished)
                        .toList()
                    : drafts.where((d) => !d.isPublished).toList();

                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async => ref.refresh(adminDraftsProvider),
                    child: Stack(
                      children: [
                        ListView(), // To make RefreshIndicator work
                        _buildEmptyState(isDark),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(adminDraftsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _buildDraftCard(
                      context,
                      filtered[i],
                      isDark,
                      i,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: ModernFab.extended(
        onPressed: () => _showQuickDraftSheet(context),
        icon: Icon(PhosphorIcons.lightbulb(PhosphorIconsStyle.fill)),
        label: Text(AppLocalizations.of(context)!.draftsNewDraft),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  const Color(0xFFEF4444).withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIcons.notepad(PhosphorIconsStyle.duotone),
              size: 56,
              color: const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.draftsEmptyTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.draftsEmptySub,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black45,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildDraftCard(
    BuildContext context,
    DraftModel draft,
    bool isDark,
    int index,
  ) {
    final statusColor = _statusColor(draft.status);
    final priorityColor = _priorityColor(draft.priority);
    final completion = draft.completionPercentage;

    return Dismissible(
      key: ValueKey(draft.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.only(left: 20, right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(PhosphorIcons.trash(), color: Colors.red, size: 24),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.draftsDeleteTitle),
            content: Text(AppLocalizations.of(context)!.draftsDeleteConfirm(draft.displayTitle)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(AppLocalizations.of(context)!.delete,
                    style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        await adminDeleteDraft(draft.id);
        if (context.mounted) {
          AdminUIUtils.showSuccess(context, AppLocalizations.of(context)!.draftsDeleted);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.03),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            if (!isDark)
              BoxShadow(
                color: Colors.white,
                blurRadius: 0,
                offset: const Offset(0, 0),
                spreadRadius: -1,
              ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status + Priority row
                  Row(
                    children: [
                      // Status badge
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
                            Icon(
                              _statusIcon(draft.status),
                              size: 12,
                              color: statusColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _statusLabel(context, draft.status),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Priority badge
                      if (draft.priority != 'normal')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _priorityIcon(draft.priority),
                                size: 11,
                                color: priorityColor,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _priorityLabel(context, draft.priority),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: priorityColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const Spacer(),

                      // Content type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _typeIcon(draft.contentType),
                              size: 11,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _typeLabel(context, draft.contentType),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    draft.displayTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // URL preview
                  if (draft.url != null && draft.url!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            PhosphorIcons.link(),
                            size: 14,
                            color: AppTheme.accentColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              draft.url!,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Tags
                  if (draft.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 24,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: draft.tags.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 6),
                        itemBuilder: (ctx, i) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '#${draft.tags[i]}',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? Colors.white38 : Colors.black38,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Progress bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.draftsReadiness,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                            Text(
                              '${(completion * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: completion >= 0.8
                                    ? AppTheme.successColor
                                    : completion >= 0.5
                                        ? AppTheme.primaryColor
                                        : const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Stack(
                          children: [
                            // Progress track
                            Container(
                              height: 8,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            // Progress fill
                            FractionallySizedBox(
                              widthFactor: completion,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 800),
                                height: 8,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: completion >= 0.8
                                        ? [AppTheme.successColor, const Color(0xFF10B981)]
                                        : completion >= 0.5
                                            ? [AppTheme.primaryColor, const Color(0xFF6366F1)]
                                            : [const Color(0xFFF59E0B), const Color(0xFFF97316)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (completion >= 0.8
                                              ? AppTheme.successColor
                                              : completion >= 0.5
                                                  ? AppTheme.primaryColor
                                                  : const Color(0xFFF59E0B))
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Time info
                  Row(
                    children: [
                      Icon(
                        PhosphorIcons.calendarBlank(),
                        size: 12,
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(context, draft.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                      ),
                      const Spacer(),
                      if (draft.notes != null && draft.notes!.isNotEmpty)
                        Icon(
                          PhosphorIcons.note(),
                          size: 12,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Action buttons
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.02),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // AI convert button
                  Expanded(
                    flex: 2,
                    child: _actionButton(
                      label: draft.status == 'idea' 
                          ? AppLocalizations.of(context)!.draftsPrepAi 
                          : AppLocalizations.of(context)!.draftsImproveAi,
                      icon: PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                      color: const Color(0xFF8B5CF6),
                      isDark: isDark,
                      onTap: () => _convertWithAI(draft),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Publish button (only if ready)
                  if (draft.isReadyToPublish) ...[
                    Expanded(
                      flex: 1,
                      child: _actionButton(
                        label: AppLocalizations.of(context)!.publish,
                        icon: PhosphorIcons.paperPlaneTilt(
                            PhosphorIconsStyle.fill),
                        color: AppTheme.successColor,
                        isDark: isDark,
                        onTap: () => _publishDraft(draft),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Edit quick icon (Primary way to edit manually)
                  SizedBox(
                    width: 40,
                    height: 36,
                    child: IconButton(
                      onPressed: () => _showQuickDraftSheet(context, draft),
                      icon: Icon(PhosphorIcons.pencilLine(), size: 18),
                      padding: EdgeInsets.zero,
                      tooltip: AppLocalizations.of(context)!.draftsManualEdit,
                      style: IconButton.styleFrom(
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 60).ms).fadeIn().slideY(begin: 0.05);
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      color,
                      color.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected
                ? null
                : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03)),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
            border: Border.all(
              color: isSelected
                  ? Colors.white24
                  : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08)),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white38 : Colors.black45),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Actions ──

  void _showQuickDraftSheet(BuildContext context, [DraftModel? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickDraftSheet(existing: existing),
    );
  }

  Future<void> _convertWithAI(DraftModel draft) async {
    final categories = ref.read(adminCategoriesProvider).valueOrNull ?? [];

    // Build AI input from draft data
    final parts = <String>[];
    if (draft.title != null && draft.title!.isNotEmpty) parts.add(draft.title!);
    if (draft.url != null && draft.url!.isNotEmpty) parts.add(draft.url!);
    if (draft.notes != null && draft.notes!.isNotEmpty) parts.add(draft.notes!);
    final aiInput = parts.join('\n');

    final result = await showModalBottomSheet<AiContentResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.8,
        maxChildSize: 0.8,
        builder: (_, scrollCtrl) => AiContentPrepSheet(
          categories: categories,
          contentTypes: _contentTypeValues,
          initialInput: aiInput,
        ),
      ),
    );

    if (result != null && mounted) {
      // Update draft with AI results
      final updateData = <String, dynamic>{
        'title': result.title,
        'description': result.description,
        'content_type': result.contentType,
        'tags': result.tags,
        'status': 'ready',
      };

      // Match category by name
      final matched = categories.where((c) => c.name == result.categoryName);
      if (matched.isNotEmpty) {
        updateData['category_id'] = matched.first.id;
      }

      if (result.sourceUrl.isNotEmpty) {
        updateData['url'] = result.sourceUrl;
      }

      await adminUpdateDraft(draft.id, updateData);

      if (mounted) {
        AdminUIUtils.showSuccess(context, 'تم تجهيز المسودة بنجاح ✨');
      }
    }
  }

  void _publishDraft(DraftModel draft) {
    // Navigate to AddEditWebsite with draft data pre-filled
    context.push('/admin/websites/edit', extra: {
      'draft': draft,
    });
  }


  // ── Helpers ──

  String _statusLabel(BuildContext context, String s) {
    final l10n = AppLocalizations.of(context)!;
    switch (s) {
      case 'idea':
        return l10n.draftsFilterIdeas;
      case 'in_progress':
        return l10n.draftsFilterInProgress;
      case 'ready':
        return l10n.draftsFilterReady;
      default:
        return s;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'idea':
        return PhosphorIcons.lightbulb(PhosphorIconsStyle.fill);
      case 'in_progress':
        return PhosphorIcons.circleNotch();
      case 'ready':
        return PhosphorIcons.checkCircle(PhosphorIconsStyle.fill);
      default:
        return PhosphorIcons.circle();
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'idea':
        return const Color(0xFFF59E0B);
      case 'in_progress':
        return const Color(0xFF3B82F6);
      case 'ready':
        return AppTheme.successColor;
      default:
        return Colors.grey;
    }
  }

  String _priorityLabel(BuildContext context, String p) {
    final l10n = AppLocalizations.of(context)!;
    switch (p) {
      case 'low':
        return l10n.draftsPriorityLow;
      case 'high':
        return l10n.draftsPriorityHigh;
      case 'urgent':
        return l10n.draftsPriorityUrgent;
      default:
        return l10n.draftsPriorityNormal;
    }
  }

  IconData _priorityIcon(String p) {
    switch (p) {
      case 'low':
        return PhosphorIcons.arrowDown();
      case 'high':
        return PhosphorIcons.arrowUp();
      case 'urgent':
        return PhosphorIcons.lightning();
      default:
        return PhosphorIcons.minus();
    }
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'low':
        return Colors.grey;
      case 'high':
        return AppTheme.warningColor;
      case 'urgent':
        return AppTheme.errorColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _typeLabel(BuildContext context, String t) {
    final l10n = AppLocalizations.of(context)!;
    switch (t) {
      case 'tool':
        return l10n.typeTool;
      case 'course':
        return l10n.typeCourse;
      case 'prompt':
        return l10n.typePrompt;
      case 'offer':
        return l10n.typeOffer;
      case 'announcement':
        return l10n.typeAnnouncement;
      case 'tutorial':
        return l10n.typeTutorial;
      default:
        return l10n.typeWebsite;
    }
  }

  IconData _typeIcon(String t) {
    switch (t) {
      case 'tool':
        return PhosphorIcons.wrench();
      case 'course':
        return PhosphorIcons.graduationCap();
      case 'prompt':
        return PhosphorIcons.sparkle();
      case 'offer':
        return PhosphorIcons.tag();
      case 'announcement':
        return PhosphorIcons.megaphone();
      case 'tutorial':
        return PhosphorIcons.chalkboardTeacher();
      default:
        return PhosphorIcons.globe();
    }
  }

  String _formatDate(BuildContext context, DateTime dt) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return l10n.timeJustNow;
    if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.timeDaysAgo(diff.inDays);
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
