import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/draft_model.dart';
import '../../../presentation/providers/admin_providers.dart';
import '../../../presentation/providers/discover_providers.dart';

/// Quick BottomSheet for adding/editing a draft with minimal input
class QuickDraftSheet extends ConsumerStatefulWidget {
  final DraftModel? existing;

  const QuickDraftSheet({super.key, this.existing});

  @override
  ConsumerState<QuickDraftSheet> createState() => _QuickDraftSheetState();
}

class _QuickDraftSheetState extends ConsumerState<QuickDraftSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _urlCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _tagsCtrl;
  String _priority = 'normal';
  String _contentType = 'website';
  String? _categoryId;
  bool _isSaving = false;

  static const _priorityValues = ['low', 'normal', 'high', 'urgent'];
  static const _contentTypeValues = [
    'website',
    'tool',
    'course',
    'prompt',
    'offer',
    'announcement',
    'tutorial',
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
    _urlCtrl = TextEditingController(text: widget.existing?.url ?? '');
    _notesCtrl = TextEditingController(text: widget.existing?.notes ?? '');
    _descCtrl = TextEditingController(text: widget.existing?.description ?? '');
    _tagsCtrl = TextEditingController(
        text: widget.existing?.tags.join(', ') ?? '');
    _priority = widget.existing?.priority ?? 'normal';
    _contentType = widget.existing?.contentType ?? 'website';
    _categoryId = widget.existing?.categoryId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    _notesCtrl.dispose();
    _descCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  bool get _hasContent =>
      _titleCtrl.text.trim().isNotEmpty ||
      _urlCtrl.text.trim().isNotEmpty ||
      _notesCtrl.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_hasContent) return;

    setState(() => _isSaving = true);

    try {
      final data = {
        'title': _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
        'url': _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'priority': _priority,
        'content_type': _contentType,
        'category_id': _categoryId,
        'tags': _tagsCtrl.text.isEmpty
            ? []
            : _tagsCtrl.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList(),
      };

      if (widget.existing != null) {
        await adminUpdateDraft(widget.existing!.id, data);
      } else {
        data['status'] = 'idea';
        await adminAddDraft(data);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.draftsErrorSaving(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _priorityLabel(BuildContext context, String p) {
    final l10n = AppLocalizations.of(context)!;
    switch (p) {
      case 'low':
        return l10n.draftsPriorityLow;
      case 'normal':
        return l10n.draftsPriorityNormal;
      case 'high':
        return l10n.draftsPriorityHigh;
      case 'urgent':
        return l10n.draftsPriorityUrgent;
      default:
        return p;
    }
  }

  IconData _priorityIcon(String p) {
    switch (p) {
      case 'low':
        return PhosphorIcons.arrowDown();
      case 'normal':
        return PhosphorIcons.minus();
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
      case 'normal':
        return AppTheme.primaryColor;
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
      case 'website':
        return l10n.typeWebsite;
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
        return t;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.existing != null;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF6366F1),
                          Color(0xFF7C3AED),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      PhosphorIcons.lightbulb(PhosphorIconsStyle.fill),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing 
                              ? AppLocalizations.of(context)!.draftsEditTitle 
                              : AppLocalizations.of(context)!.draftsNewTitle,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppLocalizations.of(context)!.draftsHeaderSub,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
              height: 1,
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title field
                  _buildField(
                    controller: _titleCtrl,
                    label: AppLocalizations.of(context)!.draftsTitleOrIdea,
                    icon: PhosphorIcons.textT(),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),

                  // Description field (Optional)
                  _buildField(
                    controller: _descCtrl,
                    label: AppLocalizations.of(context)!.draftsDescription,
                    icon: PhosphorIcons.textAlignLeft(),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),

                  // URL field
                  _buildField(
                    controller: _urlCtrl,
                    label: AppLocalizations.of(context)!.draftsUrl,
                    icon: PhosphorIcons.link(),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),

                  // Tags field
                  _buildField(
                    controller: _tagsCtrl,
                    label: AppLocalizations.of(context)!.draftsTags,
                    icon: PhosphorIcons.hash(),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),

                  // Notes field
                  _buildField(
                    controller: _notesCtrl,
                    label: AppLocalizations.of(context)!.draftsNotes,
                    icon: PhosphorIcons.notepad(),
                    isDark: isDark,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Category Selector
                  _buildCategorySelector(isDark),
                  const SizedBox(height: 16),

                  // Priority & Content Type row
                  Row(
                    children: [
                      // Priority
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.draftsPriority,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 42,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.08),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _priority,
                                  isExpanded: true,
                                  borderRadius: BorderRadius.circular(12),
                                  dropdownColor: isDark
                                      ? AppTheme.darkCard
                                      : Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  icon: Icon(
                                    PhosphorIcons.caretDown(),
                                    size: 14,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black45,
                                  ),
                                  items: _priorityValues.map((p) {
                                    return DropdownMenuItem(
                                      value: p,
                                      child: Row(
                                        children: [
                                          Icon(
                                            _priorityIcon(p),
                                            size: 14,
                                            color: _priorityColor(p),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _priorityLabel(context, p),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _priority = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Content type
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.draftsContentType,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 42,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.08),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _contentType,
                                  isExpanded: true,
                                  borderRadius: BorderRadius.circular(12),
                                  dropdownColor: isDark
                                      ? AppTheme.darkCard
                                      : Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  icon: Icon(
                                    PhosphorIcons.caretDown(),
                                    size: 14,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black45,
                                  ),
                                  items: _contentTypeValues.map((t) {
                                    return DropdownMenuItem(
                                      value: t,
                                      child: Row(
                                        children: [
                                          Icon(
                                            _typeIcon(t),
                                            size: 14,
                                            color: AppTheme.primaryColor,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _typeLabel(context, t),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _contentType = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Save button
                  GestureDetector(
                    onTap: _isSaving || !_hasContent ? null : _save,
                    child: AnimatedContainer(
                      duration: 200.ms,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: _hasContent
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFF6366F1),
                                  Color(0xFF7C3AED),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              )
                            : null,
                        color: _hasContent ? null : (isDark ? Colors.white10 : Colors.black12),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _hasContent
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF6366F1)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: _isSaving
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isEditing
                                        ? PhosphorIcons.floppyDisk(
                                            PhosphorIconsStyle.fill)
                                        : PhosphorIcons.lightbulb(
                                            PhosphorIconsStyle.fill),
                                    color: _hasContent
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.white38
                                            : Colors.black26),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isEditing 
                                        ? AppLocalizations.of(context)!.draftsSaveEdits 
                                        : AppLocalizations.of(context)!.draftsSaveAsDraft,
                                    style: TextStyle(
                                      color: _hasContent
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.white38
                                              : Colors.black26),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(bool isDark) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.draftsCategory,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        categoriesAsync.when(
          data: (cats) => Container(
            height: 42,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _categoryId,
                isExpanded: true,
                borderRadius: BorderRadius.circular(12),
                dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                hint: Text(
                  AppLocalizations.of(context)!.draftsSelectCategory,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
                icon: Icon(
                  PhosphorIcons.caretDown(),
                  size: 14,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
                items: cats.map((c) {
                  return DropdownMenuItem(
                    value: c.id,
                    child: Text(
                      c.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _categoryId = val);
                },
              ),
            ),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error loading categories'),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: 1,
      onChanged: (_) => setState(() {}),
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(
          color: isDark ? Colors.white30 : Colors.black26,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Icon(
            icon,
            size: 16,
            color: AppTheme.primaryColor.withValues(alpha: 0.7),
          ),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.primaryColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
      ),
    );
  }
}
