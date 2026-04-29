import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../presentation/widgets/custom_quill_editor.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/imagekit_service.dart';
import 'widgets/google_image_search_sheet.dart';
import '../../data/models/website_model.dart';
import '../../data/models/suggestion_model.dart';
import '../../data/repositories/suggestion_repository.dart';
import '../../core/supabase_config.dart';
import '../../presentation/providers/admin_providers.dart';
import '../../presentation/providers/discover_providers.dart';
import '../../presentation/widgets/offline_warning_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/admin_ui_utils.dart';
import '../../data/models/ai_content_result.dart';
import '../../data/models/category_model.dart';
import '../../data/models/draft_model.dart';
import 'widgets/ai_content_prep_sheet.dart';

class AddEditWebsiteScreen extends ConsumerStatefulWidget {
  final WebsiteModel? existing;
  final SuggestionModel? suggestion;
  final DraftModel? draft;

  const AddEditWebsiteScreen({super.key, this.existing, this.suggestion, this.draft});

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
  late final TextEditingController _tagsCtrl;
  late final QuillController _quillController;

  bool _isTrending = false;
  bool _isPopular = false;
  bool _isFeatured = false;
  bool _isActive = true;
  String? _selectedCategoryId;
  String _contentType = 'website';
  String _pricingModel = 'free';
  Set<String> _selectedCollectionIds = {};
  DateTime? _expiresAt;
  bool _sendNotification = false;
  bool _isSaving = false;
  bool _isUploading = false;
  double _uploadProgress = 0;
  bool _showVideoSection = false;
  bool _isUploadingVideo = false;
  double _videoUploadProgress = 0;
  bool _isSavingDraft = false;

  // ── AI Content Prep ──
  Future<void> _openAiContentPrep(List<CategoryModel> categories) async {
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
          contentTypes: _contentTypeValues.toList(),
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _titleCtrl.text = result.title;
        _tagsCtrl.text = result.tags.join(', ');
        if (_contentTypeValues.contains(result.contentType)) {
          _contentType = result.contentType;
        }
        // Match category by name
        final matched = categories.where((c) => c.name == result.categoryName);
        if (matched.isNotEmpty) {
          _selectedCategoryId = matched.first.id;
        }
        // Auto-fill URL if extracted
        if (result.sourceUrl.isNotEmpty && _urlCtrl.text.isEmpty) {
          _urlCtrl.text = result.sourceUrl;
        }
        // Set rich description in Quill
        if (result.description.isNotEmpty) {
          final doc = Document();
          final lines = result.description.split('\n');
          int offset = 0;
          for (int i = 0; i < lines.length; i++) {
            final line = lines[i];
            if (line.trim().isEmpty) {
              doc.insert(offset, '\n');
              offset += 1;
              continue;
            }
            // Section headers (lines ending with :) → insert as bold
            if (line.trim().endsWith(':') && !line.trim().startsWith('•')) {
              doc.insert(offset, '${line.trim()}\n');
              doc.format(offset, line.trim().length, Attribute.bold);
              offset += line.trim().length + 1;
            } else {
              doc.insert(offset, '${line.trim()}\n');
              offset += line.trim().length + 1;
            }
          }
          _quillController.document = doc;
        }
      });
    }
  }

  static const _contentTypeValues = [
    'website',
    'tool',
    'course',
    'prompt',
    'offer',
    'announcement',
    'tutorial',
  ];
  static const _contentTypeColors = [
    Color(0xFF4A8FE7), // Resources - blue
    Color(0xFF607D8B), // Tools - blue-grey
    Color(0xFF4CAF50), // Courses - green
    Color(0xFF9C27B0), // Prompts - purple
    Color(0xFFFF9800), // Offers - orange
    Color(0xFF2196F3), // News - light blue
    Color(0xFFE91E63), // Tutorials - pink
  ];

  Future<void> _loadExistingCollections(String websiteId) async {
    final response = await SupabaseConfig.client
        .from('collection_items')
        .select('collection_id')
        .eq('website_id', websiteId);

    setState(() {
      _selectedCollectionIds = (response as List)
          .map((item) => item['collection_id'] as String)
          .toSet();
    });
  }

  IconData _contentTypeIcon(String type) {
    switch (type) {
      case 'prompt':
        return PhosphorIcons.sparkle();
      case 'offer':
        return PhosphorIcons.tag();
      case 'announcement':
        return PhosphorIcons.megaphone();
      case 'tutorial':
        return PhosphorIcons.chalkboardTeacher();
      case 'tool':
        return PhosphorIcons.wrench();
      case 'course':
        return PhosphorIcons.graduationCap();
      default:
        return PhosphorIcons.globe();
    }
  }

  String _contentTypeLabel(BuildContext context, String type) {
    switch (type) {
      case 'tool':
        return AppLocalizations.of(context)!.formTypeTools;
      case 'course':
        return AppLocalizations.of(context)!.formTypeCourses;
      case 'website':
        return AppLocalizations.of(context)!.formTypeResources;
      case 'prompt':
        return AppLocalizations.of(context)!.formTypePrompts;
      case 'offer':
        return AppLocalizations.of(context)!.formTypeOffers;
      case 'announcement':
        return AppLocalizations.of(context)!.formTypeNews;
      case 'tutorial':
        return AppLocalizations.of(context)!.formTypeTutorials;
      default:
        return type.toUpperCase();
    }
  }

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(
      text: widget.existing?.title ?? widget.suggestion?.pageTitle ?? widget.draft?.title ?? '',
    );
    _urlCtrl = TextEditingController(
      text: widget.existing?.url ?? widget.suggestion?.pageUrl ?? widget.draft?.url ?? '',
    );
    _imgCtrl = TextEditingController(text: widget.existing?.imageUrl ?? widget.draft?.imageUrl ?? '');
    _actionValueCtrl = TextEditingController(
      text: widget.existing?.actionValue ?? widget.draft?.actionValue ?? '',
    );
    _videoUrlCtrl = TextEditingController(
      text: widget.existing?.videoUrl ?? '',
    );
    _tagsCtrl = TextEditingController(
      text: widget.existing?.tags.join(', ') ?? widget.draft?.tags.join(', ') ?? '',
    );
    _showVideoSection = widget.existing?.hasVideo ?? false;

    _isTrending = widget.existing?.isTrending ?? false;
    _isPopular = widget.existing?.isPopular ?? false;
    _isFeatured = widget.existing?.isFeatured ?? false;
    _isActive = widget.existing?.isActive ?? true;
    _selectedCategoryId = widget.existing?.categoryId ?? widget.draft?.categoryId;
    _contentType = widget.existing?.contentType ?? widget.draft?.contentType ?? 'website';
    _pricingModel = widget.existing?.pricingModel ?? widget.draft?.pricingModel ?? 'free';
    _expiresAt = widget.existing?.expiresAt;

    Document doc;
    try {
      if (widget.existing != null && widget.existing!.description.isNotEmpty) {
        final decoded = jsonDecode(widget.existing!.description);
        doc = Document.fromJson(decoded);
      } else if (widget.draft != null &&
          widget.draft!.description != null &&
          widget.draft!.description!.isNotEmpty) {
        // Try to parse as Quill Delta JSON, otherwise as plain text
        try {
          final decoded = jsonDecode(widget.draft!.description!);
          doc = Document.fromJson(decoded);
        } catch (_) {
          doc = Document()..insert(0, widget.draft!.description!);
        }
      } else if (widget.suggestion != null &&
          widget.suggestion!.pageDescription != null &&
          widget.suggestion!.pageDescription!.isNotEmpty) {
        doc = Document()..insert(0, widget.suggestion!.pageDescription!);
      } else {
        doc = Document();
      }
    } catch (_) {
      doc = Document()
        ..insert(
          0,
          widget.existing?.description ??
              widget.draft?.description ??
              widget.suggestion?.pageDescription ??
              '',
        );
    }

    if (widget.existing != null) {
      _loadExistingCollections(widget.existing!.id);
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
    _tagsCtrl.dispose();
    _quillController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      AdminUIUtils.showWarning(
        context,
        AppLocalizations.of(context)!.formTitleRequired,
      );
      return;
    }

    if (_contentType == 'website' && _urlCtrl.text.trim().isEmpty) {
      AdminUIUtils.showWarning(
        context,
        AppLocalizations.of(context)!.formUrlRequired,
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
        'tags': _tagsCtrl.text.trim().isEmpty
            ? <String>[]
            : _tagsCtrl.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList(),
        'pricing_model': _pricingModel,
      };

      // Notification translation strings
      final notifOffer = AppLocalizations.of(context)!.notifBodyOffer;
      final notifPrompt = AppLocalizations.of(context)!.notifBodyPrompt;
      final notifAnnouncement = AppLocalizations.of(
        context,
      )!.notifBodyAnnouncement;
      final notifDefault = AppLocalizations.of(context)!.notifBodyDefault;

      String? newItemId;
      if (widget.existing == null) {
        newItemId = await adminAddWebsite(data);
        if (widget.suggestion != null) {
          await SuggestionRepository().markSuggestionAsApproved(
            widget.suggestion!.id,
          );
          ref.invalidate(adminSuggestionsProvider);
        }
      } else {
        await adminUpdateWebsite(widget.existing!.id, data);
        newItemId = widget.existing!.id;
      }

      // Sync collections
      if (newItemId != null) {
        await SupabaseConfig.client
            .from('collection_items')
            .delete()
            .eq('website_id', newItemId);

        if (_selectedCollectionIds.isNotEmpty) {
          final inserts = _selectedCollectionIds
              .map((cid) => {'collection_id': cid, 'website_id': newItemId})
              .toList();
          await SupabaseConfig.client.from('collection_items').insert(inserts);
        }
      }

      // Link draft if applicable
      if (newItemId != null && widget.draft != null) {
        await adminMarkDraftPublished(widget.draft!.id, newItemId);
      }

      // Notifications for newly created items only.
      if (widget.existing == null) {
        final notifTitle = '✨ ${_titleCtrl.text.trim()}';
        final notifBody = _contentType == 'offer'
            ? notifOffer
            : _contentType == 'prompt'
            ? notifPrompt
            : _contentType == 'announcement'
            ? notifAnnouncement
            : notifDefault;
        final notifTargetUrl = newItemId != null
            ? 'app://discover/item/$newItemId'
            : 'app://discover';
        final notifImageUrl = _imgCtrl.text.trim().isEmpty
            ? null
            : _imgCtrl.text.trim();

        if (_sendNotification) {
          // Admin opted to broadcast to everyone — also creates a DB notification record.
          try {
            await adminSendNotification({
              'title': notifTitle,
              'body': notifBody,
              'type': 'new_item',
              'target_url': notifTargetUrl,
              'image_url': notifImageUrl,
            });
          } catch (_) {
            // Notification failure shouldn't block save
          }
        } else {
          // Admin DID NOT broadcast: still push silently to users who opted-in
          // to receive every new explorer item (notif_all_new_content = true).
          // No DB row inserted — these are silent opt-in deliveries.
          try {
            await SupabaseConfig.client.functions.invoke(
              'send-notification',
              body: {
                'mode': 'auto_content_only',
                'title': notifTitle,
                'body': notifBody,
                'type': 'content_auto',
                'target_url': notifTargetUrl,
                'image_url': notifImageUrl,
              },
            );
          } catch (_) {
            // Silent — opt-in push is best-effort.
          }
        }
      }

      ref.invalidate(adminWebsitesProvider);
      ref.invalidate(discoverWebsitesProvider);
      ref.invalidate(trendingWebsitesProvider);
      ref.invalidate(popularWebsitesProvider);
      ref.invalidate(featuredWebsitesProvider);

      if (mounted) {
        context.pop();
        AdminUIUtils.showSuccess(
          context,
          widget.existing == null
              ? AppLocalizations.of(context)!.formPublishedSuccess
              : AppLocalizations.of(context)!.formUpdatedSuccess,
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

        if (isOffline) {
          AdminUIUtils.showWarning(
            context,
            AppLocalizations.of(context)!.formOfflineError,
          );
        } else {
          AdminUIUtils.showError(
            context,
            AppLocalizations.of(context)!.formSaveError(e.toString()),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Save current form state as a draft
  Future<void> _saveAsDraft() async {
    if (_titleCtrl.text.trim().isEmpty &&
        _urlCtrl.text.trim().isEmpty) {
      AdminUIUtils.showWarning(context, 'يجب ملء العنوان أو الرابط على الأقل');
      return;
    }

    setState(() => _isSavingDraft = true);

    try {
      final deltaJson = jsonEncode(
        _quillController.document.toDelta().toJson(),
      );

      final data = {
        'title': _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
        'url': _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
        'description': deltaJson,
        'category_id': _selectedCategoryId,
        'image_url': _imgCtrl.text.trim().isEmpty ? null : _imgCtrl.text.trim(),
        'content_type': _contentType,
        'action_value': _actionValueCtrl.text.trim(),
        'tags': _tagsCtrl.text.trim().isEmpty
            ? <String>[]
            : _tagsCtrl.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList(),
        'pricing_model': _pricingModel,
        'status': 'in_progress',
        'priority': 'normal',
      };

      if (widget.draft != null) {
        await adminUpdateDraft(widget.draft!.id, data);
      } else {
        await adminAddDraft(data);
      }

      if (mounted) {
        context.pop();
        AdminUIUtils.showSuccess(context, 'تم حفظ المسودة بنجاح 💾');
      }
    } catch (e) {
      if (mounted) {
        AdminUIUtils.showError(context, 'خطأ في حفظ المسودة: $e');
      }
    } finally {
      if (mounted) setState(() => _isSavingDraft = false);
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
  String _typeLabel(BuildContext context) {
    switch (_contentType) {
      case 'prompt':
        return AppLocalizations.of(context)!.promptBadge;
      case 'offer':
        return AppLocalizations.of(context)!.offerBadge;
      case 'announcement':
        return AppLocalizations.of(context)!.newsBadge;
      case 'tutorial':
        return AppLocalizations.of(context)!.tutorialBadge;
      case 'tool':
        return 'Tool';
      case 'course':
        return 'Course';
      default:
        return AppLocalizations.of(context)!.websiteBadge;
    }
  }

  /// Dynamic URL field label based on content type
  String _urlLabel(BuildContext context) {
    switch (_contentType) {
      case 'tool':
        return AppLocalizations.of(context)!.formUrlRequiredTool;
      case 'course':
        return AppLocalizations.of(context)!.formUrlRequiredCourse;
      case 'prompt':
        return AppLocalizations.of(context)!.formUrlPromptRef;
      case 'offer':
        return AppLocalizations.of(context)!.formUrlOfferRef;
      case 'announcement':
        return AppLocalizations.of(context)!.formUrlNewsRef;
      case 'tutorial':
        return AppLocalizations.of(context)!.formUrlTutorialRef;
      default:
        return AppLocalizations.of(context)!.formUrlRequiredWeb;
    }
  }

  /// Dynamic action value label
  String _actionLabel(BuildContext context) {
    switch (_contentType) {
      case 'prompt':
        return AppLocalizations.of(context)!.formActionPromptLabel;
      case 'offer':
        return AppLocalizations.of(context)!.formActionOfferLabel;
      case 'tool':
        return AppLocalizations.of(context)!.formActionToolLabel;
      case 'course':
        return AppLocalizations.of(context)!.formActionCourseLabel;
      case 'announcement':
        return AppLocalizations.of(context)!.formActionNewsLabel;
      case 'tutorial':
        return AppLocalizations.of(context)!.formActionTutorialLabel;
      default:
        return AppLocalizations.of(context)!.formActionDefaultLabel;
    }
  }

  /// Dynamic action section header
  String _actionSectionHeader(BuildContext context) {
    switch (_contentType) {
      case 'prompt':
        return AppLocalizations.of(context)!.formActionPromptHeader;
      case 'offer':
        return AppLocalizations.of(context)!.formActionOfferHeader;
      case 'tool':
        return AppLocalizations.of(context)!.formActionToolHeader;
      case 'course':
        return AppLocalizations.of(context)!.formActionCourseHeader;
      case 'announcement':
        return AppLocalizations.of(context)!.formActionNewsHeader;
      case 'tutorial':
        return AppLocalizations.of(context)!.formActionTutorialHeader;
      default:
        return AppLocalizations.of(context)!.formActionDefaultHeader;
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
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        alignLabelWithHint: maxLines > 1,
        floatingLabelStyle: TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        helperStyle: TextStyle(
          color: isDark ? Colors.white38 : Colors.black45,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: TextStyle(
          color: isDark ? Colors.white60 : Colors.black54,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : const Color(0xFFF9FAFB),
        prefixIcon: prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    prefixIcon,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                ),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppTheme.primaryColor.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white54 : AppTheme.primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
          ),
        ),
      ],
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
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.03),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Widget _buildCollectionsSection(BuildContext context, bool isDark) {
    final collectionsAsync = ref.watch(adminCollectionsProvider);
    final loc = AppLocalizations.of(context)!;

    return _buildCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            loc.addToCollections,
            Icons.folder_special,
            isDark,
          ),
          const SizedBox(height: 16),
          collectionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Text('Error: $e', style: const TextStyle(color: Colors.red)),
            data: (collections) {
              if (collections.isEmpty) {
                return Text(
                  loc.collectionsEmpty,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: collections.map((col) {
                  final isSelected = _selectedCollectionIds.contains(col.id);
                  return FilterChip(
                    label: Text(col.title),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCollectionIds.add(col.id);
                        } else {
                          _selectedCollectionIds.remove(col.id);
                        }
                      });
                    },
                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primaryColor,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? AppLocalizations.of(context)!.formNewItem(_typeLabel(context))
              : AppLocalizations.of(context)!.formEditItem(_typeLabel(context)),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        forceMaterialTransparency: true,
        leading: IconButton(
          icon: Icon(PhosphorIcons.x()),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (widget.existing == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _isSavingDraft
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  : Tooltip(
                      message: 'حفظ كمسودة',
                      child: IconButton(
                        onPressed: _isSaving ? null : _saveAsDraft,
                        icon: Icon(
                          PhosphorIcons.notepad(),
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
            ),
        ],
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
                            AppLocalizations.of(context)!.formContentType,
                            PhosphorIcons.squaresFour(),
                            isDark,
                          ),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: 1.3,
                                ),
                            itemCount: _contentTypeValues.length,
                            itemBuilder: (ctx, i) {
                              final isSelected =
                                  _contentType == _contentTypeValues[i];
                              final typeColor = _contentTypeColors[i];
                              return GestureDetector(
                                onTap: () => setState(
                                  () => _contentType = _contentTypeValues[i],
                                ),
                                child: AnimatedContainer(
                                  duration: 200.ms,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? typeColor
                                        : (isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.04,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.02,
                                                )),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? typeColor
                                          : (isDark
                                                ? Colors.white12
                                                : Colors.black12),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: typeColor.withValues(
                                                alpha: 0.3,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _contentTypeIcon(_contentTypeValues[i]),
                                        size: 24,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark
                                                  ? Colors.white60
                                                  : Colors.black54),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _contentTypeLabel(
                                          context,
                                          _contentTypeValues[i],
                                        ),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? Colors.white
                                              : (isDark
                                                    ? Colors.white60
                                                    : Colors.black54),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

                    // ── AI Content Prep Button ──
                    if (widget.existing == null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GestureDetector(
                          onTap: () {
                            final categoriesAsync = ref.read(
                              adminCategoriesProvider,
                            );
                            categoriesAsync.whenData((cats) {
                              _openAiContentPrep(cats);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(
                                    0xFF7C3AED,
                                  ).withValues(alpha: 0.12),
                                  const Color(
                                    0xFF3B82F6,
                                  ).withValues(alpha: 0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(
                                  0xFF7C3AED,
                                ).withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF7C3AED),
                                        Color(0xFF3B82F6),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    PhosphorIcons.sparkle(
                                      PhosphorIconsStyle.fill,
                                    ),
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'مساعد تجهيز المحتوى',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? AppTheme.darkTextPrimary
                                              : AppTheme.lightTextPrimary,
                                        ),
                                      ),
                                      Text(
                                        'أدخل رابط أو نص وسيُعبّئ النموذج تلقائياً',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? AppTheme.darkTextSecondary
                                              : AppTheme.lightTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  PhosphorIcons.caretLeft(),
                                  color: const Color(0xFF7C3AED),
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.15),
                      ),

                    // ── Basic Info Section ──
                    _buildCard(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            AppLocalizations.of(context)!.formBasicInfo,
                            PhosphorIcons.info(),
                            isDark,
                          ),
                          _buildTextField(
                            controller: _titleCtrl,
                            label: AppLocalizations.of(
                              context,
                            )!.formTypeTitle(_typeLabel(context)),
                            prefixIcon: PhosphorIcons.textT(),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          // URL field — required for websites, optional for others
                          _buildTextField(
                            controller: _urlCtrl,
                            label: _urlLabel(context),
                            prefixIcon: PhosphorIcons.link(),
                            isDark: isDark,
                            helperText: _contentType == 'website'
                                ? null
                                : _contentType == 'tool'
                                ? AppLocalizations.of(
                                    context,
                                  )!.formUrlToolHelper
                                : _contentType == 'course'
                                ? AppLocalizations.of(
                                    context,
                                  )!.formUrlCourseHelper
                                : AppLocalizations.of(
                                    context,
                                  )!.formUrlOptionalHelper,
                          ),
                          const SizedBox(height: 16),
                          // ── Cover Image Section ──
                          _buildSectionHeader(
                            AppLocalizations.of(context)!.formCoverImage,
                            PhosphorIcons.image(),
                            isDark,
                          ),
                          const SizedBox(height: 8),
                          // Upload button row
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: _isUploading
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
                                                            _uploadProgress = p,
                                                      );
                                                    }
                                                  },
                                                );
                                            if (url != null &&
                                                context.mounted) {
                                              setState(() {
                                                _imgCtrl.text = url;
                                              });
                                              AdminUIUtils.showSuccess(
                                                context,
                                                AppLocalizations.of(context)!.notifImgUploadSuccess,
                                              );
                                            } else if (context.mounted &&
                                                _uploadProgress > 0) {
                                              AdminUIUtils.showError(
                                                context,
                                                AppLocalizations.of(context)!.notifImgUploadFail,
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
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppTheme.primaryColor.withValues(
                                              alpha: 0.1,
                                            )
                                          : AppTheme.primaryColor.withValues(
                                              alpha: 0.05,
                                            ),
                                      border: Border.all(
                                        color: AppTheme.primaryColor.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: _isUploading
                                          ? SizedBox(
                                              height: 32,
                                              width: 32,
                                              child: CircularProgressIndicator(
                                                value: _uploadProgress > 0
                                                    ? _uploadProgress
                                                    : null,
                                                strokeWidth: 3,
                                                color: AppTheme.primaryColor,
                                              ),
                                            )
                                          : Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  PhosphorIcons.uploadSimple(),
                                                  size: 28,
                                                  color: AppTheme.primaryColor,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.formUploadDevice,
                                                  style: TextStyle(
                                                    color:
                                                        AppTheme.primaryColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final url =
                                        await showModalBottomSheet<String>(
                                          context: context,
                                          isScrollControlled: true,
                                          enableDrag: false,
                                          backgroundColor: Colors.transparent,
                                          builder: (ctx) =>
                                              GoogleImageSearchSheet(
                                                initialQuery: _titleCtrl.text,
                                              ),
                                        );
                                    if (url != null && context.mounted) {
                                      setState(() {
                                        _imgCtrl.text = url;
                                      });
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.03)
                                          : Colors.black.withValues(
                                              alpha: 0.02,
                                            ),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white10
                                            : Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            PhosphorIcons.googleLogo(),
                                            size: 28,
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black54,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Search Web',
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black87,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildTextField(
                            controller: _imgCtrl,
                            label: AppLocalizations.of(context)!.formImageUrl,
                            prefixIcon: PhosphorIcons.link(),
                            isDark: isDark,
                            helperText: _contentType == 'prompt'
                                ? AppLocalizations.of(
                                    context,
                                  )!.formPromptImgHelper
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
                                                AppLocalizations.of(
                                                  context,
                                                )!.formInvalidUrl,
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
                                      AppLocalizations.of(
                                        context,
                                      )!.formTutorialVideo,
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
                                  AppLocalizations.of(context)!.formVideoHelper,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                // Upload video button
                                InkWell(
                                  onTap: _isUploadingVideo
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
                                            if (url != null &&
                                                context.mounted) {
                                              setState(() {
                                                _videoUrlCtrl.text = url;
                                              });
                                              AdminUIUtils.showSuccess(
                                                context,
                                                AppLocalizations.of(context)!.formVideoUploaded,
                                              );
                                            } else if (context.mounted &&
                                                _videoUploadProgress > 0) {
                                              AdminUIUtils.showError(
                                                context,
                                                AppLocalizations.of(context)!.formVideoUploadError,
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
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    height: 100,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(
                                              0xFF7C3AED,
                                            ).withValues(alpha: 0.1)
                                          : const Color(
                                              0xFF7C3AED,
                                            ).withValues(alpha: 0.05),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF7C3AED,
                                        ).withValues(alpha: 0.3),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: _isUploadingVideo
                                          ? SizedBox(
                                              height: 32,
                                              width: 32,
                                              child: CircularProgressIndicator(
                                                value: _videoUploadProgress > 0
                                                    ? _videoUploadProgress
                                                    : null,
                                                strokeWidth: 3,
                                                color: const Color(0xFF7C3AED),
                                              ),
                                            )
                                          : Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  PhosphorIcons.uploadSimple(),
                                                  size: 28,
                                                  color: const Color(
                                                    0xFF7C3AED,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.formUploadVideoDevice,
                                                  style: const TextStyle(
                                                    color: Color(0xFF7C3AED),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                                // Progress bar
                                if (_isUploadingVideo &&
                                    _videoUploadProgress > 0)
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
                                  label: AppLocalizations.of(
                                    context,
                                  )!.formVideoUrlLabel,
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
                        )
                        .animate()
                        .fadeIn(delay: 150.ms, duration: 400.ms)
                        .slideY(begin: 0.1),

                    // ── Collections Section (Independent) ──
                    _buildCollectionsSection(context, isDark)
                        .animate()
                        .fadeIn(delay: 150.ms, duration: 400.ms)
                        .slideY(begin: 0.1),

                    // ── Copyable Content (all non-website types) ──
                    if (_contentType != 'website')
                      _buildCard(
                            isDark: isDark,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(
                                  _actionSectionHeader(context),
                                  _contentType == 'prompt'
                                      ? PhosphorIcons.sparkle()
                                      : _contentType == 'offer'
                                      ? PhosphorIcons.key()
                                      : _contentType == 'tool'
                                      ? PhosphorIcons.wrench()
                                      : _contentType == 'course'
                                      ? PhosphorIcons.graduationCap()
                                      : PhosphorIcons.megaphone(),
                                  isDark,
                                ),
                                _buildTextField(
                                  controller: _actionValueCtrl,
                                  label: _actionLabel(context),
                                  prefixIcon: PhosphorIcons.clipboardText(),
                                  isDark: isDark,
                                  maxLines: _contentType == 'prompt' ? 6 : 3,
                                  helperText: AppLocalizations.of(
                                    context,
                                  )!.formCopyHelper,
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
                                            ? Colors.white.withValues(
                                                alpha: 0.04,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.02,
                                              ),
                                        borderRadius: BorderRadius.circular(16),
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
                                                  ? AppLocalizations.of(
                                                      context,
                                                    )!.formExpires(
                                                      '${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year} ${_expiresAt!.hour.toString().padLeft(2, '0')}:${_expiresAt!.minute.toString().padLeft(2, '0')}',
                                                    )
                                                  : AppLocalizations.of(
                                                      context,
                                                    )!.formSetExpiry,
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
                                              onTap: () => setState(
                                                () => _expiresAt = null,
                                              ),
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
                          )
                          .animate()
                          .fadeIn(delay: 150.ms, duration: 400.ms)
                          .slideY(begin: 0.1),

                    // ── Categorization Section ──
                    _buildCard(
                          isDark: isDark,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader(
                                AppLocalizations.of(
                                  context,
                                )!.formCategorization,
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
                                      final filteredCats = cats
                                          .where(
                                            (c) =>
                                                c.contentTypes == null ||
                                                c.contentTypes!.isEmpty ||
                                                c.contentTypes!.contains(
                                                  _contentType,
                                                ),
                                          )
                                          .toList();

                                      // Auto-clear selection if it is no longer valid
                                      if (_selectedCategoryId != null &&
                                          !filteredCats.any(
                                            (c) => c.id == _selectedCategoryId,
                                          )) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              if (mounted) {
                                                setState(
                                                  () => _selectedCategoryId =
                                                      null,
                                                );
                                              }
                                            });
                                      }

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
                                              AppLocalizations.of(
                                                context,
                                              )!.formSelectCategory,
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white54
                                                    : Colors.black54,
                                                fontSize: 16,
                                              ),
                                            ),
                                            items: [
                                              DropdownMenuItem<String?>(
                                                value: null,
                                                child: Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.uncategorized,
                                                ),
                                              ),
                                              ...filteredCats.map(
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
                              const SizedBox(height: 16),
                              // ── Tags ──
                              _buildTextField(
                                controller: _tagsCtrl,
                                label: AppLocalizations.of(
                                  context,
                                )!.formTagsPlaceholder,
                                prefixIcon: PhosphorIcons.tag(),
                                isDark: isDark,
                              ),
                              const SizedBox(height: 16),
                              // ── Pricing Model ──
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.filterPricingModel,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : Colors.black.withValues(alpha: 0.02),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.05),
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    dropdownColor: isDark
                                        ? AppTheme.darkCard
                                        : Colors.white,
                                    value: _pricingModel,
                                    icon: Icon(
                                      PhosphorIcons.caretDown(),
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black54,
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        value: 'free',
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.pricingFree,
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'freemium',
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.pricingFreemium,
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'paid',
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.pricingPaid,
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _pricingModel = val);
                                      }
                                    },
                                  ),
                                ),
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
                                AppLocalizations.of(context)!.formDescContent,
                                PhosphorIcons.article(),
                                isDark,
                              ),
                              CustomQuillEditor(
                                controller: _quillController,
                                label: '',
                                helperText: AppLocalizations.of(
                                  context,
                                )!.formDescPlaceholder,
                                height: 250.0,
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
                                AppLocalizations.of(context)!.formDisplayVis,
                                PhosphorIcons.tag(),
                                isDark,
                              ),
                              SwitchListTile(
                                title: Text(
                                  AppLocalizations.of(context)!.formActive,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  AppLocalizations.of(context)!.formActiveSub,
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
                                title: Text(
                                  AppLocalizations.of(context)!.formTrending,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  AppLocalizations.of(context)!.formTrendingSub,
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
                                title: Text(
                                  AppLocalizations.of(context)!.formPopular,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  AppLocalizations.of(context)!.formPopularSub,
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
                                title: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.formFeaturedStatus,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  AppLocalizations.of(context)!.formFeaturedSub,
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
                                  AppLocalizations.of(
                                    context,
                                  )!.formNotification,
                                  PhosphorIcons.bellRinging(),
                                  isDark,
                                ),
                                SwitchListTile(
                                  title: Text(
                                    AppLocalizations.of(context)!.formSendNotif,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.formSendNotifSub,
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
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: true,
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isSaving ? null : () => context.pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.cancel,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF4F46E5,
                              ).withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
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
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      widget.existing == null
                                          ? PhosphorIcons.rocketLaunch()
                                          : PhosphorIcons.checkCircle(),
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.existing == null
                                          ? AppLocalizations.of(
                                              context,
                                            )!.formPublishItem(
                                              _typeLabel(context),
                                            )
                                          : AppLocalizations.of(
                                              context,
                                            )!.formSaveChanges,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
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
      ),
    );
  }
}
