import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/imagekit_service.dart';
// Note: Fallback to Flutter's native TextField and InputDecoration to avoid missing CustomTextField
import '../../presentation/providers/community_providers.dart';
import '../../l10n/app_localizations.dart';

class CommunityNewPostSheet extends ConsumerStatefulWidget {
  const CommunityNewPostSheet({super.key});

  @override
  ConsumerState<CommunityNewPostSheet> createState() =>
      _CommunityNewPostSheetState();
}

class _CommunityNewPostSheetState extends ConsumerState<CommunityNewPostSheet> {
  final _contentCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();

  String _category = 'general';
  bool _isSubmitting = false;

  // Image upload state
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploading = false;
  final double _uploadProgress = 0;

  @override
  void dispose() {
    _contentCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1024,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _isUploading = true;
      });

      try {
        final bytes = await pickedFile.readAsBytes();
        final fileName = pickedFile.name;

        final url = await ImageKitService.uploadImage(
          fileBytes: bytes,
          fileName: fileName,
          folder: 'community',
        );
        setState(() {
          _uploadedImageUrl = url;
          _isUploading = false;
        });
      } catch (e) {
        setState(() {
          _isUploading = false;
          _selectedImage = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _submit() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      await CommunityActions.createPost(
        content: content,
        category: _category,
        imageUrl: _uploadedImageUrl,
        linkUrl: _linkCtrl.text.trim().isNotEmpty
            ? _linkCtrl.text.trim()
            : null,
      );

      if (mounted) {
        context.pop(); // close sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.postPublished),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Create Post',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
              IconButton(
                onPressed: _isSubmitting ? null : () => context.pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Categories
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CategoryChip(
                  label: AppLocalizations.of(context)!.categoryGeneral,
                  category: 'general',
                  selected: _category == 'general',
                  icon: PhosphorIcons.chatTeardrop(PhosphorIconsStyle.fill),
                  onSelect: () => setState(() => _category = 'general'),
                ),
                _CategoryChip(
                  label: AppLocalizations.of(context)!.categoryQuestion,
                  category: 'question',
                  selected: _category == 'question',
                  icon: PhosphorIcons.question(PhosphorIconsStyle.fill),
                  color: const Color(0xFFF59E0B),
                  onSelect: () => setState(() => _category = 'question'),
                ),
                _CategoryChip(
                  label: AppLocalizations.of(context)!.categoryTip,
                  category: 'tip',
                  selected: _category == 'tip',
                  icon: PhosphorIcons.lightbulb(PhosphorIconsStyle.fill),
                  color: const Color(0xFF10B981),
                  onSelect: () => setState(() => _category = 'tip'),
                ),
                _CategoryChip(
                  label: AppLocalizations.of(context)!.categoryResource,
                  category: 'resource',
                  selected: _category == 'resource',
                  icon: PhosphorIcons.folderStar(PhosphorIconsStyle.fill),
                  color: const Color(0xFF6366F1),
                  onSelect: () => setState(() => _category = 'resource'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Image Preview
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      _selectedImage!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (_isUploading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                value: _uploadProgress,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (!_isUploading)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedImage = null;
                          _uploadedImageUrl = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Main Text Input
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                ),
              ),
              child: TextField(
                controller: _contentCtrl,
                maxLines: null,
                expands: true,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.whatToShare,
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppTheme.darkTextSecondary.withValues(alpha: 0.4)
                        : AppTheme.lightTextSecondary.withValues(alpha: 0.4),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          // Link Input (Compact)
          if (_category == 'resource' || _linkCtrl.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 16),
              child: TextField(
                controller: _linkCtrl,
                keyboardType: TextInputType.url,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Add a URL (optional)',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  prefixIcon: Icon(
                    PhosphorIcons.link(),
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppTheme.darkDivider
                          : AppTheme.lightDivider,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppTheme.darkDivider
                          : AppTheme.lightDivider,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Bottom Actions
          Row(
            children: [
              IconButton(
                onPressed: _isUploading ? null : _pickAndUploadImage,
                icon: Icon(
                  PhosphorIcons.image(PhosphorIconsStyle.fill),
                  color: AppTheme.accentColor,
                  size: 28,
                ),
                tooltip: 'Add Image',
              ),
              if (_category != 'resource' && _linkCtrl.text.isEmpty)
                IconButton(
                  onPressed: () => setState(
                    () => _category = 'resource',
                  ), // Forces link input to show
                  icon: Icon(
                    PhosphorIcons.link(PhosphorIconsStyle.bold),
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  tooltip: 'Add Link',
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isSubmitting || _isUploading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context)!.post,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final String category;
  final bool selected;
  final IconData icon;
  final Color? color;
  final VoidCallback onSelect;

  const _CategoryChip({
    required this.label,
    required this.category,
    required this.selected,
    required this.icon,
    required this.onSelect,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor = color ?? AppTheme.primaryColor;

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? themeColor
              : (isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? themeColor : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
