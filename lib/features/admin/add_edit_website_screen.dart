import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/imagekit_service.dart';
import '../../data/models/website_model.dart';
import '../../presentation/providers/admin_providers.dart';
import '../../presentation/providers/discover_providers.dart';
import '../../presentation/widgets/offline_warning_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  late final TextEditingController _videoUrlCtrl;
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
  bool _isUploading = false;
  double _uploadProgress = 0;
  bool _showVideoSection = false;
  bool _isUploadingVideo = false;
  double _videoUploadProgress = 0;

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
    _videoUrlCtrl = TextEditingController(
      text: widget.existing?.videoUrl ?? '',
    );
    _showVideoSection = widget.existing?.hasVideo ?? false;

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
    _videoUrlCtrl.dispose();
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
        'video_url': _videoUrlCtrl.text.trim().isEmpty
            ? null
            : _videoUrlCtrl.text.trim(),
      };

      String? newItemId;
      if (widget.existing == null) {
        newItemId = await adminAddWebsite(data);
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
            'type': 'new_item',
            'target_url': newItemId != null
                ? 'app://discover/item/$newItemId'
                : 'app://discover',
            'image_url': _imgCtrl.text.trim().isEmpty
                ? null
                : _imgCtrl.text.trim(),
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
                          // ── Cover Image Section ──
                          _buildSectionHeader(
                            'Cover Image',
                            PhosphorIcons.image(),
                            isDark,
                          ),
                          const SizedBox(height: 8),
                          // Upload button row
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 44,
                                  child: ElevatedButton.icon(
                                    onPressed: _isUploading
                                        ? null
                                        : () async {
                                            setState(() {
                                              _isUploading = true;
                                              _uploadProgress = 0;
                                            });
                                            try {
                                              final url =
                                                  await ImageKitService.pickAndUpload(
                                                    folder: '/discover',
                                                    onProgress: (p) {
                                                      if (mounted) {
                                                        setState(
                                                          () =>
                                                              _uploadProgress =
                                                                  p,
                                                        );
                                                      }
                                                    },
                                                  );
                                              if (url != null &&
                                                  context.mounted) {
                                                setState(() {
                                                  _imgCtrl.text = url;
                                                });
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Image uploaded successfully!',
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                              } else if (context.mounted &&
                                                  _uploadProgress > 0) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Upload failed. Try again.',
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            } finally {
                                              if (mounted) {
                                                setState(() {
                                                  _isUploading = false;
                                                  _uploadProgress = 0;
                                                });
                                              }
                                            }
                                          },
                                    icon: _isUploading
                                        ? SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              value: _uploadProgress > 0
                                                  ? _uploadProgress
                                                  : null,
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(
                                            PhosphorIcons.uploadSimple(),
                                            size: 18,
                                          ),
                                    label: Text(
                                      _isUploading
                                          ? 'Uploading...'
                                          : 'Upload from Device',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.black12,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      PhosphorIcons.link(),
                                      size: 16,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black45,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'or paste URL',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildTextField(
                            controller: _imgCtrl,
                            label: 'Image URL',
                            prefixIcon: PhosphorIcons.link(),
                            isDark: isDark,
                            helperText: _contentType == 'prompt'
                                ? 'Add an image showing the prompt result'
                                : null,
                          ),
                          // ── Image Preview ──
                          if (_imgCtrl.text.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: _imgCtrl.text.trim(),
                                      height: 160,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (ctx, url) => Container(
                                        height: 160,
                                        color: isDark
                                            ? Colors.white10
                                            : Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                      errorWidget: (ctx, url, err) => Container(
                                        height: 160,
                                        color: isDark
                                            ? Colors.white10
                                            : Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                PhosphorIcons.imageBroken(),
                                                color: Colors.red.withValues(
                                                  alpha: 0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Invalid URL',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.red.withValues(
                                                    alpha: 0.7,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Remove button
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () =>
                                            setState(() => _imgCtrl.clear()),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
                            ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1),

                    // ── Video Section (Toggle) ──
                    _buildCard(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                PhosphorIcons.videoCamera(),
                                size: 18,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tutorial Video',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppTheme.darkTextPrimary
                                        : AppTheme.lightTextPrimary,
                                  ),
                                ),
                              ),
                              Switch.adaptive(
                                value: _showVideoSection,
                                activeTrackColor: AppTheme.primaryColor,
                                onChanged: (v) {
                                  setState(() {
                                    _showVideoSection = v;
                                    if (!v) _videoUrlCtrl.clear();
                                  });
                                },
                              ),
                            ],
                          ),
                          if (_showVideoSection) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Add a tutorial or explainer video (max 50MB)',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Upload video button
                            SizedBox(
                              height: 44,
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isUploadingVideo
                                    ? null
                                    : () async {
                                        setState(() {
                                          _isUploadingVideo = true;
                                          _videoUploadProgress = 0;
                                        });
                                        try {
                                          final url =
                                              await ImageKitService.pickAndUploadVideo(
                                                folder: '/discover/videos',
                                                onProgress: (p) {
                                                  if (mounted) {
                                                    setState(
                                                      () =>
                                                          _videoUploadProgress =
                                                              p,
                                                    );
                                                  }
                                                },
                                              );
                                          if (url != null && context.mounted) {
                                            setState(() {
                                              _videoUrlCtrl.text = url;
                                            });
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Video uploaded!',
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          } else if (context.mounted &&
                                              _videoUploadProgress > 0) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Upload failed or video too large (max 50MB).',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        } finally {
                                          if (mounted) {
                                            setState(() {
                                              _isUploadingVideo = false;
                                              _videoUploadProgress = 0;
                                            });
                                          }
                                        }
                                      },
                                icon: _isUploadingVideo
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          value: _videoUploadProgress > 0
                                              ? _videoUploadProgress
                                              : null,
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(
                                        PhosphorIcons.uploadSimple(),
                                        size: 18,
                                      ),
                                label: Text(
                                  _isUploadingVideo
                                      ? 'Uploading Video...'
                                      : 'Upload Video from Device',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7C3AED),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            // Progress bar
                            if (_isUploadingVideo && _videoUploadProgress > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: _videoUploadProgress,
                                    backgroundColor: isDark
                                        ? Colors.white10
                                        : Colors.black12,
                                    color: const Color(0xFF7C3AED),
                                    minHeight: 4,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 10),
                            _buildTextField(
                              controller: _videoUrlCtrl,
                              label: 'Video URL (or paste link)',
                              prefixIcon: PhosphorIcons.link(),
                              isDark: isDark,
                            ),
                            // Video URL preview
                            if (_videoUrlCtrl.text.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF7C3AED,
                                    ).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF7C3AED,
                                      ).withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        PhosphorIcons.filmSlate(
                                          PhosphorIconsStyle.fill,
                                        ),
                                        color: const Color(0xFF7C3AED),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _videoUrlCtrl.text.trim(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontFamily: 'monospace',
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black54,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => setState(
                                          () => _videoUrlCtrl.clear(),
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          size: 18,
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.black38,
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
