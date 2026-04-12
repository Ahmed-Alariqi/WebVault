import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/ai_content_result.dart';
import '../../../data/models/category_model.dart';
import '../../../data/services/ai_content_prep_service.dart';

/// BottomSheet with 3 states: Input → Loading → Result
class AiContentPrepSheet extends StatefulWidget {
  final List<CategoryModel> categories;
  final List<String> contentTypes;

  const AiContentPrepSheet({
    super.key,
    required this.categories,
    required this.contentTypes,
  });

  @override
  State<AiContentPrepSheet> createState() => _AiContentPrepSheetState();
}

enum _SheetState { input, loading, result }

class _AiContentPrepSheetState extends State<AiContentPrepSheet> {
  final _inputCtrl = TextEditingController();
  _SheetState _state = _SheetState.input;
  String? _error;
  String _originalInput = '';

  // Editable result fields
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  String _selectedCategoryName = '';
  String _selectedSubcategory = '';
  String _selectedContentType = 'website';
  List<String> _tags = [];
  String _sourceUrl = '';
  final _tagInputCtrl = TextEditingController();

  // Model selection
  String _selectedModel = 'gemini-3-flash-preview:cloud';
  static const _availableModels = [
    'gemini-3-flash-preview:cloud',
    'gpt-oss:120b-cloud',
    'glm-5.1:cloud',
    'qwen3.5:cloud',
    'minimax-m2.7:cloud',
    'gemma4:31b-cloud',
  ];

  // Per-field regeneration state
  String? _regeneratingField;

  // Subcategory lists
  static const _generalSubcategories = [
    'ذكاء اصطناعي',
    'برمجة',
    'بحث',
    'انتاجية',
    'تصميم',
    'امن سيبراني',
    'اعمال وتسويق',
    'تعليم',
    'عام',
  ];
  static const _promptSubcategories = [
    'توليد صور',
    'تعديل صور',
    'توليد فيديو',
    'كتابة',
    'برمجة',
    'تحليل',
    'أتمتة',
    'أسلوب وتحكم',
    'عام',
  ];

  List<String> get _currentSubcategories {
    if (_selectedContentType == 'prompt') return _promptSubcategories;
    return _generalSubcategories;
  }

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _descCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _tagInputCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _currentDataMap => {
    'title': _titleCtrl.text,
    'description': _descCtrl.text,
    'category_name': _selectedCategoryName,
    'subcategory': _selectedSubcategory,
    'content_type': _selectedContentType,
    'tags': _tags,
  };

  Future<void> _generate() async {
    if (_inputCtrl.text.trim().isEmpty) return;

    setState(() {
      _state = _SheetState.loading;
      _error = null;
      _originalInput = _inputCtrl.text.trim();
    });

    try {
      final categoryNames = widget.categories.map((c) => c.name).toList();

      final result = await AiContentPrepService.generate(
        input: _originalInput,
        categories: categoryNames,
        contentTypes: widget.contentTypes,
        model: _selectedModel,
      );

      setState(() {
        _titleCtrl.text = result.title;
        _descCtrl.text = result.description;
        _selectedCategoryName = result.categoryName;
        _selectedSubcategory = result.subcategory;
        _selectedContentType = result.contentType;
        _tags = List<String>.from(result.tags);
        _sourceUrl = result.sourceUrl;
        _state = _SheetState.result;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _state = _SheetState.input;
      });
    }
  }

  Future<void> _regenerateField(String fieldName) async {
    setState(() => _regeneratingField = fieldName);
    try {
      final newValue = await AiContentPrepService.regenerateField(
        fieldName: fieldName,
        currentData: _currentDataMap,
        originalInput: _originalInput,
        model: _selectedModel,
      );

      if (!mounted) return;
      setState(() {
        switch (fieldName) {
          case 'title':
            _titleCtrl.text = newValue;
            break;
          case 'description':
            _descCtrl.text = newValue;
            break;
          case 'tags':
            _tags = newValue
                .split(',')
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .toList();
            break;
        }
        _regeneratingField = null;
      });
    } catch (_) {
      if (mounted) setState(() => _regeneratingField = null);
    }
  }

  void _approve() {
    final result = AiContentResult(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      categoryName: _selectedCategoryName,
      subcategory: _selectedSubcategory,
      contentType: _selectedContentType,
      tags: _tags,
      sourceUrl: _sourceUrl,
    );
    Navigator.of(context).pop(result);
  }

  void _retry() {
    setState(() => _state = _SheetState.input);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                      colors: [AppTheme.primaryColor, AppTheme.accentColor],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
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
                        'مساعد تجهيز المحتوى',
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
                        'أدخل رابط أو نص لتوليد بيانات منظمة',
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
                Theme(
                  data: Theme.of(context).copyWith(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    dividerColor: Colors.transparent,
                  ),
                  child: PopupMenuButton<String>(
                    initialValue: _selectedModel,
                    tooltip: 'تغيير نموذج الذكاء الاصطناعي',
                    onSelected: (String newValue) {
                      setState(() {
                        _selectedModel = newValue;
                      });
                    },
                    color: isDark ? const Color(0xFF1E1E3A) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                    offset: const Offset(0, 40),
                    itemBuilder: (BuildContext context) {
                      return _availableModels.map((String value) {
                        return PopupMenuItem<String>(
                          value: value,
                          height: 48,
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: _selectedModel == value
                                    ? AppTheme.primaryColor
                                    : Colors.transparent,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    color: _selectedModel == value
                                        ? AppTheme.primaryColor
                                        : (isDark
                                              ? Colors.white70
                                              : Colors.black87),
                                    fontSize: 13,
                                    fontWeight: _selectedModel == value
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIcons.cpu(),
                            size: 14,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _selectedModel.split(':').first.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
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
          const SizedBox(height: 4),
          Divider(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
            height: 1,
          ),
          // Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: _buildBody(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    switch (_state) {
      case _SheetState.input:
        return _buildInputState(isDark);
      case _SheetState.loading:
        return _buildLoadingState(isDark);
      case _SheetState.result:
        return _buildResultState(isDark);
    }
  }

  // ── INPUT STATE ──
  Widget _buildInputState(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Input field
        TextField(
          controller: _inputCtrl,
          maxLines: 5,
          minLines: 3,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: 'الصق رابط أو اكتب وصف المحتوى...',
            hintStyle: TextStyle(
              color: isDark ? Colors.white30 : Colors.black26,
              fontSize: 14,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.primaryColor.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 16),
        // Generate button
        GestureDetector(
          onTap: _generate,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.accentColor],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'توليد المحتوى',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),
      ],
    );
  }

  // ── LOADING STATE ──
  Widget _buildLoadingState(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'جاري تحليل المحتوى...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ..._buildShimmerFields(isDark),
      ],
    );
  }

  List<Widget> _buildShimmerFields(bool isDark) {
    final fields = [
      'العنوان',
      'الوصف',
      'التصنيف الرئيسي',
      'التصنيف الفرعي',
      'النوع',
      'التاجات',
    ];
    return fields.map((label) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Shimmer.fromColors(
          baseColor: isDark ? Colors.white10 : Colors.grey.shade200,
          highlightColor: isDark ? Colors.white24 : Colors.grey.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: label == 'الوصف' ? 80 : 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  // ── RESULT STATE ──
  Widget _buildResultState(bool isDark) {
    final categoryNames = widget.categories.map((c) => c.name).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Source URL info bar
        if (_sourceUrl.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.accentColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.link(PhosphorIconsStyle.bold),
                  size: 16,
                  color: AppTheme.accentColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _sourceUrl,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: Colors.green.shade400,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Title with regen button
        _buildResultFieldWithRegen(
          label: 'العنوان',
          fieldName: 'title',
          icon: PhosphorIcons.textT(),
          isDark: isDark,
          child: TextField(
            controller: _titleCtrl,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: _resultInputDecoration(isDark),
          ),
        ),
        const SizedBox(height: 14),

        // Description with regen button
        _buildResultFieldWithRegen(
          label: 'الوصف',
          fieldName: 'description',
          icon: PhosphorIcons.textAlignLeft(),
          isDark: isDark,
          child: TextField(
            controller: _descCtrl,
            maxLines: 8,
            minLines: 4,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.6,
            ),
            decoration: _resultInputDecoration(isDark),
          ),
        ),
        const SizedBox(height: 14),

        // Category dropdown
        _buildResultField(
          label: 'التصنيف الرئيسي',
          icon: PhosphorIcons.folders(),
          isDark: isDark,
          child: _buildDropdown(
            value: categoryNames.contains(_selectedCategoryName)
                ? _selectedCategoryName
                : null,
            hint: _selectedCategoryName.isNotEmpty
                ? _selectedCategoryName
                : 'اختر التصنيف',
            items: categoryNames,
            isDark: isDark,
            onChanged: (val) => setState(() => _selectedCategoryName = val!),
          ),
        ),
        const SizedBox(height: 14),

        // Subcategory dropdown
        _buildResultField(
          label: 'التصنيف الفرعي',
          icon: PhosphorIcons.treeStructure(),
          isDark: isDark,
          child: _buildDropdown(
            value: _currentSubcategories.contains(_selectedSubcategory)
                ? _selectedSubcategory
                : null,
            hint: _selectedSubcategory.isNotEmpty
                ? _selectedSubcategory
                : 'اختر التصنيف الفرعي',
            items: _currentSubcategories,
            isDark: isDark,
            onChanged: (val) => setState(() => _selectedSubcategory = val!),
          ),
        ),
        const SizedBox(height: 14),

        // Content type dropdown
        _buildResultField(
          label: 'نوع المحتوى',
          icon: PhosphorIcons.squaresFour(),
          isDark: isDark,
          child: _buildDropdown(
            value: widget.contentTypes.contains(_selectedContentType)
                ? _selectedContentType
                : widget.contentTypes.first,
            hint: 'اختر النوع',
            items: widget.contentTypes,
            isDark: isDark,
            onChanged: (val) => setState(() => _selectedContentType = val!),
          ),
        ),
        const SizedBox(height: 14),

        // Tags with regen button
        _buildResultFieldWithRegen(
          label: 'التاجات',
          fieldName: 'tags',
          icon: PhosphorIcons.tag(),
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _tags.map((tag) {
                  return InputChip(
                    label: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    deleteIconColor: isDark ? Colors.white54 : Colors.black45,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                    onDeleted: () => setState(() => _tags.remove(tag)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagInputCtrl,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'أضف تاج...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white30 : Colors.black26,
                          fontSize: 13,
                        ),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          setState(() {
                            _tags.add(val.trim());
                            _tagInputCtrl.clear();
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (_tagInputCtrl.text.trim().isNotEmpty) {
                        setState(() {
                          _tags.add(_tagInputCtrl.text.trim());
                          _tagInputCtrl.clear();
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Action buttons
        Row(
          children: [
            // Retry button
            Expanded(
              child: GestureDetector(
                onTap: _retry,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        PhosphorIcons.arrowCounterClockwise(),
                        size: 18,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'إعادة التوليد',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Approve button
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: _approve,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.accentColor],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 6),
                      Text(
                        'اعتماد وتعبئة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  // ── Reusable Dropdown ──
  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required bool isDark,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black45,
              fontSize: 14,
            ),
          ),
          isExpanded: true,
          dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
          items: items.map((name) {
            return DropdownMenuItem(value: name, child: Text(name));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ── Field with Regen Button ──
  Widget _buildResultFieldWithRegen({
    required String label,
    required String fieldName,
    required IconData icon,
    required bool isDark,
    required Widget child,
  }) {
    final isRegenerating = _regeneratingField == fieldName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const Spacer(),
            // Regenerate button
            GestureDetector(
              onTap: isRegenerating ? null : () => _regenerateField(fieldName),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isRegenerating)
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppTheme.primaryColor,
                        ),
                      )
                    else
                      Icon(
                        PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                        size: 12,
                        color: AppTheme.primaryColor,
                      ),
                    const SizedBox(width: 4),
                    Text(
                      isRegenerating ? 'جاري...' : 'تحسين',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  // ── Simple Field (no regen) ──
  Widget _buildResultField({
    required String label,
    required IconData icon,
    required bool isDark,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _resultInputDecoration(bool isDark) {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.03),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppTheme.primaryColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
