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
  late final TextEditingController _actionValueCtrl;
  late final QuillController _quillController;

  bool _isTrending = false;
  bool _isPopular = false;
  bool _isFeatured = false;
  bool _isActive = true;
  String? _selectedCategoryId;
  String _contentType = 'website';
  DateTime? _expiresAt;
  bool _sendNotification = false;
  bool _isSaving = false;

  static const _contentTypeValues = [
    'website',
    'prompt',
    'offer',
    'announcement',
  ];
  static const _contentTypeLabels = ['Website', 'Prompt', 'Offer', 'Announce'];

  IconData _contentTypeIcon(String type) {
    switch (type) {
      case 'prompt':
        return PhosphorIcons.sparkle();
      case 'offer':
        return PhosphorIcons.tag();
      case 'announcement':
        return PhosphorIcons.megaphone();
      default:
        return PhosphorIcons.globe();
    }
  }

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
    _urlCtrl = TextEditingController(text: widget.existing?.url ?? '');
    _imgCtrl = TextEditingController(text: widget.existing?.imageUrl ?? '');
    _actionValueCtrl = TextEditingController(
      text: widget.existing?.actionValue ?? '',
    );

    _isTrending = widget.existing?.isTrending ?? false;
    _isPopular = widget.existing?.isPopular ?? false;
    _isFeatured = widget.existing?.isFeatured ?? false;
    _isActive = widget.existing?.isActive ?? true;
    _selectedCategoryId = widget.existing?.categoryId;
    _contentType = widget.existing?.contentType ?? 'website';
    _expiresAt = widget.existing?.expiresAt;

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
    _actionValueCtrl.dispose();
    _quillController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required.')));
      return;
    }

    if (_contentType == 'website' && _urlCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL is required for websites.')),
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
        'content_type': _contentType,
        'action_value': _actionValueCtrl.text.trim(),
        'expires_at': _expiresAt?.toUtc().toIso8601String(),
        'is_active': _isActive,
      };

      if (widget.existing == null) {
        await adminAddWebsite(data);
      } else {
        await adminUpdateWebsite(widget.existing!.id, data);
      }

      // Send notification if toggled on (only for new items)
      if (_sendNotification && widget.existing == null) {
        try {
          await adminSendNotification({
            'title': '✨ ${_titleCtrl.text.trim()}',
            'body': _contentType == 'offer'
                ? '🔥 New offer available! Check it out now.'
                : _contentType == 'prompt'
                ? '💡 New prompt added! Tap to explore.'
                : _contentType == 'announcement'
                ? '📢 New announcement! Tap to read.'
                : '🌐 New content just added! Tap to discover.',
            'type': 'announcement',
            'target_url': null,
          });
        } catch (_) {
          // Notification failure shouldn't block save
        }
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
                  ? 'Published successfully!'
                  : 'Updated successfully!',
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

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_expiresAt ?? now),
      );
      setState(() {
        _expiresAt = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time?.hour ?? 23,
          time?.minute ?? 59,
        );
      });
    }
  }

  // ── Helper label for content type ──
  String get _typeLabel {
    switch (_contentType) {
      case 'prompt':
        return 'Prompt';
      case 'offer':
        return 'Offer';
      case 'announcement':
        return 'Announcement';
      default:
        return 'Website';
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool isDark,
    IconData? prefixIcon,
    int maxLines = 1,
    String? helperText,
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
        helperText: helperText,
        helperStyle: TextStyle(
          color: isDark ? Colors.white38 : Colors.black38,
          fontSize: 11,
        ),
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
          widget.existing == null ? 'New $_typeLabel' : 'Edit $_typeLabel',
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
                    // ── Content Type Selector ──
                    _buildCard(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            'Content Type',
                            PhosphorIcons.squaresFour(),
                            isDark,
                          ),
                          Row(
                            children: [
                              for (
                                int i = 0;
                                i < _contentTypeValues.length;
                                i++
                              ) ...[
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () =>
                                          _contentType = _contentTypeValues[i],
                                    ),
                                    child: AnimatedContainer(
                                      duration: 200.ms,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            _contentType ==
                                                _contentTypeValues[i]
                                            ? AppTheme.primaryColor
                                            : (isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.04,
                                                    )
                                                  : Colors.black.withValues(
                                                      alpha: 0.02,
                                                    )),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color:
                                              _contentType ==
                                                  _contentTypeValues[i]
                                              ? AppTheme.primaryColor
                                              : (isDark
                                                    ? Colors.white12
                                                    : Colors.black12),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            _contentTypeIcon(
                                              _contentTypeValues[i],
                                            ),
                                            size: 22,
                                            color:
                                                _contentType ==
                                                    _contentTypeValues[i]
                                                ? Colors.white
                                                : (isDark
                                                      ? Colors.white60
                                                      : Colors.black54),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _contentTypeLabels[i],
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  _contentType ==
                                                      _contentTypeValues[i]
                                                  ? Colors.white
                                                  : (isDark
                                                        ? Colors.white60
                                                        : Colors.black54),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (i < _contentTypeValues.length - 1)
                                  const SizedBox(width: 8),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

                    // ── Basic Info Section ──
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
                                label: '$_typeLabel Title',
                                prefixIcon: PhosphorIcons.textT(),
                                isDark: isDark,
                              ),
                              const SizedBox(height: 16),
                              // URL field — required for websites, optional for others
                              _buildTextField(
                                controller: _urlCtrl,
                                label: _contentType == 'website'
                                    ? 'URL (https://...)'
                                    : 'Link URL (Optional)',
                                prefixIcon: PhosphorIcons.link(),
                                isDark: isDark,
                                helperText: _contentType != 'website'
                                    ? 'Optional: add a link for users to visit'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _imgCtrl,
                                label: 'Cover Image URL (Optional)',
                                prefixIcon: PhosphorIcons.image(),
                                isDark: isDark,
                                helperText: _contentType == 'prompt'
                                    ? 'Add an image showing the prompt result'
                                    : null,
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 400.ms)
                        .slideY(begin: 0.1),

                    // ── Copyable Content (Prompt / Offer / Announcement) ──
                    if (_contentType != 'website')
                      _buildCard(
                        isDark: isDark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              _contentType == 'prompt'
                                  ? 'Prompt Text'
                                  : _contentType == 'offer'
                                  ? 'Offer Code / Key'
                                  : 'Announcement Text',
                              _contentType == 'prompt'
                                  ? PhosphorIcons.sparkle()
                                  : _contentType == 'offer'
                                  ? PhosphorIcons.key()
                                  : PhosphorIcons.megaphone(),
                              isDark,
                            ),
                            _buildTextField(
                              controller: _actionValueCtrl,
                              label: _contentType == 'prompt'
                                  ? 'Enter the prompt text (users can copy this)'
                                  : _contentType == 'offer'
                                  ? 'Enter code, key, or offer details'
                                  : 'Announcement details (optional)',
                              prefixIcon: PhosphorIcons.clipboardText(),
                              isDark: isDark,
                              maxLines: _contentType == 'prompt' ? 6 : 3,
                              helperText:
                                  'Users will see a Copy button for this content',
                            ),
                            // Expiry date for offers
                            if (_contentType == 'offer') ...[
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: _pickExpiryDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.04)
                                        : Colors.black.withValues(alpha: 0.02),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        PhosphorIcons.clock(),
                                        color: _expiresAt != null
                                            ? AppTheme.primaryColor
                                            : (isDark
                                                  ? Colors.white54
                                                  : Colors.black54),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _expiresAt != null
                                              ? 'Expires: ${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year} ${_expiresAt!.hour.toString().padLeft(2, '0')}:${_expiresAt!.minute.toString().padLeft(2, '0')}'
                                              : 'Set Expiry Date (Optional)',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _expiresAt != null
                                                ? (isDark
                                                      ? Colors.white
                                                      : Colors.black87)
                                                : (isDark
                                                      ? Colors.white54
                                                      : Colors.black54),
                                          ),
                                        ),
                                      ),
                                      if (_expiresAt != null)
                                        GestureDetector(
                                          onTap: () =>
                                              setState(() => _expiresAt = null),
                                          child: Icon(
                                            PhosphorIcons.x(),
                                            size: 18,
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.black54,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.1),

                    // ── Categorization Section ──
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
                                              'Select Category',
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
                        .fadeIn(delay: 200.ms, duration: 400.ms)
                        .slideY(begin: 0.1),

                    // ── Rich Text Description Section ──
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
                                        'Write a detailed description...',
                                    scrollable: true,
                                    expands: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 400.ms)
                        .slideY(begin: 0.1),

                    // ── Status Flags Section ──
                    _buildCard(
                          isDark: isDark,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader(
                                'Display & Visibility',
                                PhosphorIcons.tag(),
                                isDark,
                              ),
                              SwitchListTile(
                                title: const Text(
                                  'Active',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  'Show this item in Discover',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                                value: _isActive,
                                activeTrackColor: Colors.green.withValues(
                                  alpha: 0.5,
                                ),
                                activeThumbColor: Colors.green,
                                onChanged: (v) => setState(() => _isActive = v),
                                contentPadding: EdgeInsets.zero,
                              ),
                              const Divider(height: 8),
                              SwitchListTile(
                                title: const Text(
                                  'Show in Trending',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  'Highlight in the trending slider',
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
                                  'Show in the popular section',
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
                                  'Flag as a featured discovery',
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
                        .fadeIn(delay: 400.ms, duration: 400.ms)
                        .slideY(begin: 0.1),

                    // ── Notification Toggle (only for new items) ──
                    if (widget.existing == null)
                      _buildCard(
                            isDark: isDark,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(
                                  'Notification',
                                  PhosphorIcons.bellRinging(),
                                  isDark,
                                ),
                                SwitchListTile(
                                  title: const Text(
                                    'Send Notification on Publish',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Notify all users about this new item',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  value: _sendNotification,
                                  activeTrackColor: const Color(
                                    0xFFFF6B6B,
                                  ).withValues(alpha: 0.5),
                                  activeThumbColor: const Color(0xFFFF6B6B),
                                  onChanged: (v) =>
                                      setState(() => _sendNotification = v),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 500.ms, duration: 400.ms)
                          .slideY(begin: 0.1),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // ── Fixed Bottom Save/Cancel Bar ──
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
                                  ? 'Publish $_typeLabel'
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
