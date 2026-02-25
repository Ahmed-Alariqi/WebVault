import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/website_model.dart';
import '../../presentation/providers/admin_providers.dart';
import '../../presentation/providers/discover_providers.dart';
import '../../presentation/widgets/offline_warning_widget.dart';

class AddEditWebsiteScreen extends ConsumerStatefulWidget {
  final WebsiteModel? existing;

  const AddEditWebsiteScreen({super.key, this.existing});

  @override
  ConsumerState<AddEditWebsiteScreen> createState() =>
      _AddEditWebsiteScreenState();
}

class _AddEditWebsiteScreenState extends ConsumerState<AddEditWebsiteScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _urlCtrl;
  late final TextEditingController _imgCtrl;
  late final QuillController _quillController;

  bool _isTrending = false;
  bool _isPopular = false;
  bool _isFeatured = false;
  String? _selectedCategoryId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
    _urlCtrl = TextEditingController(text: widget.existing?.url ?? '');
    _imgCtrl = TextEditingController(text: widget.existing?.imageUrl ?? '');

    _isTrending = widget.existing?.isTrending ?? false;
    _isPopular = widget.existing?.isPopular ?? false;
    _isFeatured = widget.existing?.isFeatured ?? false;
    _selectedCategoryId = widget.existing?.categoryId;

    Document doc;
    try {
      if (widget.existing != null && widget.existing!.description.isNotEmpty) {
        final decoded = jsonDecode(widget.existing!.description);
        doc = Document.fromJson(decoded);
      } else {
        doc = Document();
      }
    } catch (_) {
      doc = Document()..insert(0, widget.existing?.description ?? '');
    }

    _quillController = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    _imgCtrl.dispose();
    _quillController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty || _urlCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and URL are required.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final deltaJson = jsonEncode(
        _quillController.document.toDelta().toJson(),
      );

      final data = {
        'title': _titleCtrl.text.trim(),
        'url': _urlCtrl.text.trim(),
        'description': deltaJson,
        'category_id': _selectedCategoryId,
        'image_url': _imgCtrl.text.trim().isEmpty ? null : _imgCtrl.text.trim(),
        'is_trending': _isTrending,
        'is_popular': _isPopular,
        'is_featured': _isFeatured,
      };

      if (widget.existing == null) {
        await adminAddWebsite(data);
      } else {
        await adminUpdateWebsite(widget.existing!.id, data);
      }

      ref.invalidate(adminWebsitesProvider);
      ref.invalidate(discoverWebsitesProvider);
      ref.invalidate(trendingWebsitesProvider);
      ref.invalidate(popularWebsitesProvider);
      ref.invalidate(featuredWebsitesProvider);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existing == null
                  ? 'Website added successfully!'
                  : 'Website updated successfully!',
            ),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errStr = e.toString().toLowerCase();
        final isOffline =
            errStr.contains('socketexception') ||
            errStr.contains('failed host lookup') ||
            errStr.contains('connection refused') ||
            errStr.contains('clientexception') ||
            errStr.contains('network is unreachable');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOffline
                  ? 'You are offline. Please check your internet connection.'
                  : 'Error saving: $e',
            ),
            backgroundColor: isOffline ? Colors.orange : Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool isDark,
    IconData? prefixIcon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.white54 : Colors.black54,
          fontSize: 14,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.02),
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                color: isDark ? Colors.white54 : Colors.black54,
                size: 20,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child, required bool isDark}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'New Website' : 'Edit Website',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        forceMaterialTransparency: true,
        leading: IconButton(
          icon: Icon(PhosphorIcons.x()),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Basic Info Section
                    _buildCard(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            'Basic Information',
                            PhosphorIcons.info(),
                            isDark,
                          ),
                          _buildTextField(
                            controller: _titleCtrl,
                            label: 'Website Title',
                            prefixIcon: PhosphorIcons.textT(),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _urlCtrl,
                            label: 'URL (https://...)',
                            prefixIcon: PhosphorIcons.link(),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _imgCtrl,
                            label: 'Cover Image URL (Optional)',
                            prefixIcon: PhosphorIcons.image(),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

                    // Categorization Section
                    _buildCard(
                          isDark: isDark,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader(
                                'Categorization',
                                PhosphorIcons.folder(),
                                isDark,
                              ),
                              Consumer(
                                builder: (context, ref, _) {
                                  final categoriesAsync = ref.watch(
                                    adminCategoriesProvider,
                                  );
                                  return categoriesAsync.when(
                                    data: (cats) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.04,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.02,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.05,
                                                  )
                                                : Colors.black.withValues(
                                                    alpha: 0.05,
                                                  ),
                                          ),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String?>(
                                            isExpanded: true,
                                            dropdownColor: isDark
                                                ? AppTheme.darkCard
                                                : Colors.white,
                                            value: _selectedCategoryId,
                                            icon: Icon(
                                              PhosphorIcons.caretDown(),
                                              color: isDark
                                                  ? Colors.white54
                                                  : Colors.black54,
                                            ),
                                            hint: Text(
                                              'Select Reference Category',
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white54
                                                    : Colors.black54,
                                                fontSize: 16,
                                              ),
                                            ),
                                            items: [
                                              const DropdownMenuItem<String?>(
                                                value: null,
                                                child: Text('Uncategorized'),
                                              ),
                                              ...cats.map(
                                                (c) => DropdownMenuItem(
                                                  value: c.id,
                                                  child: Text(
                                                    c.name,
                                                    style: TextStyle(
                                                      color: isDark
                                                          ? Colors.white
                                                          : Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                            onChanged: (val) {
                                              setState(
                                                () => _selectedCategoryId = val,
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    loading: () => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    error: (e, _) =>
                                        OfflineWarningWidget(error: e),
                                  );
                                },
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 400.ms)
                        .slideY(begin: 0.1),

                    // Rich Text Description Section
                    _buildCard(
                          isDark: isDark,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildSectionHeader(
                                'Description & Content',
                                PhosphorIcons.article(),
                                isDark,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey[850]
                                      : Colors.grey[100],
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.05),
                                  ),
                                ),
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    canvasColor: isDark
                                        ? Colors.grey[850]
                                        : Colors.grey[200],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    child: QuillSimpleToolbar(
                                      controller: _quillController,
                                      config: const QuillSimpleToolbarConfig(
                                        showFontFamily: false,
                                        showFontSize: false,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                height: 250,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.02)
                                      : Colors.white,
                                  borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(16),
                                  ),
                                  border: Border(
                                    left: BorderSide(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                    ),
                                    right: BorderSide(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                    ),
                                    bottom: BorderSide(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                    ),
                                  ),
                                ),
                                child: QuillEditor.basic(
                                  controller: _quillController,
                                  config: const QuillEditorConfig(
                                    padding: EdgeInsets.zero,
                                    placeholder:
                                        'Write a highly detailed beautiful description...',
                                    scrollable: true,
                                    expands: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 400.ms)
                        .slideY(begin: 0.1),

                    // Status Flags Section
                    _buildCard(
                          isDark: isDark,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader(
                                'Display Flags',
                                PhosphorIcons.tag(),
                                isDark,
                              ),
                              SwitchListTile(
                                title: const Text(
                                  'Show in Trending',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  'Highlight this website in the trending slider',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                                value: _isTrending,
                                activeTrackColor: AppTheme.primaryColor
                                    .withValues(alpha: 0.5),
                                activeThumbColor: AppTheme.primaryColor,
                                onChanged: (v) =>
                                    setState(() => _isTrending = v),
                                contentPadding: EdgeInsets.zero,
                              ),
                              SwitchListTile(
                                title: const Text(
                                  'Mark as Popular',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  'List this website in the popular section',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                                value: _isPopular,
                                activeTrackColor: AppTheme.primaryColor
                                    .withValues(alpha: 0.5),
                                activeThumbColor: AppTheme.primaryColor,
                                onChanged: (v) =>
                                    setState(() => _isPopular = v),
                                contentPadding: EdgeInsets.zero,
                              ),
                              SwitchListTile(
                                title: const Text(
                                  'Feature Status',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  'Flag this website as a featured discovery',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                                value: _isFeatured,
                                activeTrackColor: AppTheme.primaryColor
                                    .withValues(alpha: 0.5),
                                activeThumbColor: AppTheme.primaryColor,
                                onChanged: (v) =>
                                    setState(() => _isFeatured = v),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 400.ms)
                        .slideY(begin: 0.1),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // Fixed Bottom Save/Cancel Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Text(
                              widget.existing == null
                                  ? 'Publish Website'
                                  : 'Save Changes',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
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
