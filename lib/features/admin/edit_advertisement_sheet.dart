import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../presentation/widgets/custom_quill_editor.dart';

import '../../core/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/imagekit_service.dart';
import '../../domain/models/advertisement.dart';
import '../../data/models/website_model.dart';
import 'widgets/google_image_search_sheet.dart';
import 'widgets/discover_item_picker_sheet.dart';
import '../../l10n/app_localizations.dart';

class EditAdvertisementSheet extends ConsumerStatefulWidget {
  final Advertisement? ad; // If null, creating new ad

  const EditAdvertisementSheet({super.key, this.ad});

  @override
  ConsumerState<EditAdvertisementSheet> createState() =>
      _EditAdvertisementSheetState();
}

class _EditAdvertisementSheetState
    extends ConsumerState<EditAdvertisementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  final _imageController = TextEditingController();
  final _durationController = TextEditingController();
  final _linkUrlController = TextEditingController();
  final _linkedWebsiteIdController = TextEditingController();
  late final QuillController _detailInstructionsController;
  final _detailButtonTextController = TextEditingController();
  final _detailActionUrlController = TextEditingController();

  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0;
  bool _isActive = true;
  bool _showRemainingTime = false;
  String _targetScreen = 'both';
  DateTime? _adEndDate;
  bool _isInternalLink = false;
  bool _detailCardEnabled = false;
  String _detailCardActionType = 'support_chat';

  WebsiteModel? _selectedWebsite;

  @override
  void initState() {
    super.initState();
    if (widget.ad != null) {
      _titleController.text = widget.ad!.title;
      _textController.text = widget.ad!.textContent ?? '';
      _durationController.text = widget.ad!.displayDurationSeconds.toString();
      _imageController.text = widget.ad!.imageUrl;
      _linkUrlController.text = widget.ad!.linkUrl ?? '';
      _linkedWebsiteIdController.text = widget.ad!.linkedWebsiteId ?? '';
      _detailCardEnabled = widget.ad!.detailCardEnabled;

      Document doc;
      try {
        if (widget.ad!.detailCardInstructions != null &&
            widget.ad!.detailCardInstructions!.isNotEmpty) {
          final decoded = jsonDecode(widget.ad!.detailCardInstructions!);
          doc = Document.fromJson(decoded);
        } else {
          doc = Document();
        }
      } catch (_) {
        doc = Document()..insert(0, widget.ad!.detailCardInstructions ?? '');
      }
      _detailInstructionsController = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );

      _detailButtonTextController.text = widget.ad!.detailCardButtonText ?? '';
      _detailCardActionType = widget.ad!.detailCardActionType;
      _detailActionUrlController.text = widget.ad!.detailCardActionUrl ?? '';
      if (_linkedWebsiteIdController.text.isNotEmpty) {
        _isInternalLink = true;
        _fetchInitialWebsite(_linkedWebsiteIdController.text);
      } else if (_linkUrlController.text.isNotEmpty) {
        _isInternalLink = false;
      }

      _isActive = widget.ad!.isActive;
      _showRemainingTime = widget.ad!.showRemainingTime;
      _targetScreen = widget.ad!.targetScreen;
      _adEndDate = widget.ad!.adEndDate;
    } else {
      _durationController.text = '5'; // Default 5 seconds
      _detailInstructionsController = QuillController(
        document: Document(),
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _durationController.dispose();
    _imageController.dispose();
    _linkUrlController.dispose();
    _linkedWebsiteIdController.dispose();
    _detailInstructionsController.dispose();
    _detailButtonTextController.dispose();
    _detailActionUrlController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialWebsite(String id) async {
    try {
      final response = await SupabaseConfig.client
          .from('websites')
          .select()
          .eq('id', id)
          .single();
      if (mounted) {
        setState(() {
          _selectedWebsite = WebsiteModel.fromJson(response);
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _pickAdEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _adEndDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_adEndDate ?? DateTime.now()),
      );

      if (time != null) {
        setState(() {
          _adEndDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _save() async {
    if (_imageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.adEnterImageError),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'title': _titleController.text.trim(),
        'image_url': _imageController.text.trim(),
        'text_content': _textController.text.trim(),
        'link_url': _linkUrlController.text.trim().isEmpty
            ? null
            : _linkUrlController.text.trim(),
        'linked_website_id': _linkedWebsiteIdController.text.trim().isEmpty
            ? null
            : _linkedWebsiteIdController.text.trim(),
        'display_duration_seconds':
            int.tryParse(_durationController.text.trim()) ?? 5,
        'ad_end_date': _adEndDate?.toIso8601String(),
        'show_remaining_time': _showRemainingTime,
        'target_screen': _targetScreen,
        'is_active': _isActive,
        'detail_card_enabled': _detailCardEnabled,
        'detail_card_instructions':
            _detailInstructionsController.document.isEmpty()
            ? null
            : jsonEncode(
                _detailInstructionsController.document.toDelta().toJson(),
              ),
        'detail_card_button_text':
            _detailButtonTextController.text.trim().isEmpty
            ? null
            : _detailButtonTextController.text.trim(),
        'detail_card_action_type': _detailCardActionType,
        'detail_card_action_url': _detailActionUrlController.text.trim().isEmpty
            ? null
            : _detailActionUrlController.text.trim(),
      };

      if (widget.ad == null) {
        await SupabaseConfig.client.from('advertisements').insert(data);
      } else {
        await SupabaseConfig.client
            .from('advertisements')
            .update(data)
            .eq('id', widget.ad!.id);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.adSavedSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.adSaveError(e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool isDark,
    IconData? prefixIcon,
    int maxLines = 1,
    String? helperText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
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

  // ── Detail Card Form (shown when detail card is enabled) ──
  Widget _buildDetailCardForm(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // ── Instructions (Rich Text) ──
        CustomQuillEditor(
          controller: _detailInstructionsController,
          label: l10n.adDetailInstructions,
          helperText: l10n.adDetailInstructionsHint,
          height: 150.0,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _detailButtonTextController,
          label: l10n.adDetailButtonText,
          prefixIcon: PhosphorIcons.cursor(),
          isDark: isDark,
          helperText: l10n.adDetailButtonTextHint,
        ),
        const SizedBox(height: 16),
        // Action Type Dropdown
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            l10n.adDetailActionType,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
              value: _detailCardActionType,
              isExpanded: true,
              dropdownColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              icon: Icon(PhosphorIcons.caretDown(), size: 16),
              items: [
                DropdownMenuItem(
                  value: 'support_chat',
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIcons.chatCircleDots(),
                        size: 18,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 10),
                      Text(l10n.adDetailActionSupportChat),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'whatsapp',
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIcons.whatsappLogo(),
                        size: 18,
                        color: const Color(0xFF25D366),
                      ),
                      const SizedBox(width: 10),
                      Text(l10n.adDetailActionWhatsApp),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'telegram',
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIcons.telegramLogo(),
                        size: 18,
                        color: const Color(0xFF0088CC),
                      ),
                      const SizedBox(width: 10),
                      Text(l10n.adDetailActionTelegram),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'external_link',
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIcons.link(),
                        size: 18,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 10),
                      Text(l10n.adDetailActionExternalLink),
                    ],
                  ),
                ),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => _detailCardActionType = v);
                }
              },
            ),
          ),
        ),
        // Action Target
        if (_detailCardActionType != 'support_chat') ...[
          const SizedBox(height: 16),
          _buildTextField(
            controller: _detailActionUrlController,
            label: l10n.adDetailActionUrl,
            prefixIcon: PhosphorIcons.link(),
            isDark: isDark,
            keyboardType: _detailCardActionType == 'whatsapp'
                ? TextInputType.phone
                : TextInputType.url,
            helperText: _detailCardActionType == 'whatsapp'
                ? l10n.adDetailActionWhatsAppHelper
                : _detailCardActionType == 'telegram'
                ? l10n.adDetailActionTelegramHelper
                : l10n.adDetailActionExternalLinkHelper,
          ),
        ],
      ],
    );
  }

  // ── Link Form (shown when detail card is disabled) ──
  Widget _buildLinkForm(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.adLinkInternal),
          subtitle: Text(l10n.adLinkInternalSub),
          value: _isInternalLink,
          onChanged: (v) => setState(() => _isInternalLink = v),
          activeThumbColor: AppTheme.primaryColor,
        ),
        const SizedBox(height: 16),
        if (_isInternalLink)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedWebsite == null)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final selected =
                          await showModalBottomSheet<WebsiteModel?>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const DiscoverItemPickerSheet(),
                          );
                      if (selected != null) {
                        setState(() {
                          _selectedWebsite = selected;
                          _linkedWebsiteIdController.text = selected.id;
                        });
                      }
                    },
                    icon: Icon(PhosphorIcons.magnifyingGlass(), size: 20),
                    label: Text(
                      l10n.adSearchInternal,
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      side: BorderSide(
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
            ],
          )
        else
          _buildTextField(
            controller: _linkUrlController,
            label: l10n.adExternalUrl,
            prefixIcon: PhosphorIcons.browser(),
            isDark: isDark,
            helperText: l10n.adExternalUrlHelper,
          ),
        const SizedBox(height: 16),
        if (_selectedWebsite != null && _isInternalLink)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                if (_selectedWebsite!.imageUrl != null &&
                    _selectedWebsite!.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: _selectedWebsite!.imageUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.language, color: Colors.grey),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedWebsite!.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'ID: ...${_selectedWebsite!.id.substring(_selectedWebsite!.id.length - 6)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _selectedWebsite = null;
                      _linkedWebsiteIdController.clear();
                    });
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(
          widget.ad == null
              ? AppLocalizations.of(context)!.addAd
              : AppLocalizations.of(context)!.editAd,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        forceMaterialTransparency: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Basic Info Section ──
              _buildCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      AppLocalizations.of(context)!.basicInfo,
                      PhosphorIcons.info(),
                      isDark,
                    ),
                    _buildTextField(
                      controller: _titleController,
                      label: AppLocalizations.of(context)!.adTitleLabel,
                      prefixIcon: PhosphorIcons.textT(),
                      isDark: isDark,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _textController,
                      label: AppLocalizations.of(context)!.adContentLabel,
                      prefixIcon: PhosphorIcons.textAa(),
                      isDark: isDark,
                      helperText: AppLocalizations.of(context)!.adContentHint,
                    ),
                  ],
                ),
              ),

              // ── Image Section ──
              _buildCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      AppLocalizations.of(context)!.coverImage,
                      PhosphorIcons.image(),
                      isDark,
                    ),
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
                                              folder: '/ads',
                                              onProgress: (p) {
                                                if (mounted) {
                                                  setState(
                                                    () => _uploadProgress = p,
                                                  );
                                                }
                                              },
                                            );

                                        if (url != null && mounted) {
                                          setState(() {
                                            _imageController.text = url;
                                            _isUploading = false;
                                          });
                                        } else {
                                          setState(() => _isUploading = false);
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          setState(() => _isUploading = false);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.uploadFailed,
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                              icon: _isUploading
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        value: _uploadProgress > 0
                                            ? _uploadProgress
                                            : null,
                                        strokeWidth: 2,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    )
                                  : const Icon(Icons.upload, size: 18),
                              label: Text(
                                _isUploading
                                    ? AppLocalizations.of(context)!.uploading
                                    : AppLocalizations.of(
                                        context,
                                      )!.formUploadDevice,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
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
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final url = await showModalBottomSheet<String>(
                                  context: context,
                                  isScrollControlled: true,
                                  enableDrag: false,
                                  backgroundColor: Colors.transparent,
                                  builder: (ctx) => GoogleImageSearchSheet(
                                    initialQuery: _titleController.text,
                                  ),
                                );
                                if (url != null && mounted) {
                                  setState(() {
                                    _imageController.text = url;
                                  });
                                }
                              },
                              icon: Icon(PhosphorIcons.googleLogo(), size: 18),
                              label: Text(
                                AppLocalizations.of(context)!.orPasteUrl,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark
                                    ? Colors.white70
                                    : Colors.black87,
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      controller: _imageController,
                      label: AppLocalizations.of(context)!.formImageUrl,
                      prefixIcon: PhosphorIcons.link(),
                      isDark: isDark,
                      keyboardType: TextInputType.url,
                      onChanged: (v) {
                        setState(() {}); // Trigger image preview update
                      },
                    ),
                    if (_imageController.text.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              CachedNetworkImage(
                                imageUrl: _imageController.text.trim(),
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (ctx, url) => Container(
                                  height: 160,
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.05),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (ctx, url, err) => Container(
                                  height: 160,
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.05),
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
                                      setState(() => _imageController.clear()),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
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
              ),

              const SizedBox(height: 24),
              // ── Ad Linking Section ──
              _buildCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      AppLocalizations.of(context)!.adLinking,
                      PhosphorIcons.link(),
                      isDark,
                    ),
                    // ── Detail Card Toggle ──
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        AppLocalizations.of(context)!.adDetailCard,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _detailCardEnabled
                              ? AppTheme.primaryColor
                              : null,
                        ),
                      ),
                      subtitle: Text(
                        AppLocalizations.of(context)!.adDetailCardSub,
                      ),
                      value: _detailCardEnabled,
                      onChanged: (v) => setState(() => _detailCardEnabled = v),
                      activeThumbColor: AppTheme.primaryColor,
                    ),
                    // ── Detail Card Expanded Form ──
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 350),
                      crossFadeState: _detailCardEnabled
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      firstChild: _buildDetailCardForm(isDark),
                      secondChild: _buildLinkForm(isDark),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // ── Display Settings Section ──
              _buildCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      AppLocalizations.of(context)!.displaySettings,
                      PhosphorIcons.monitorPlay(),
                      isDark,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _durationController,
                            label: AppLocalizations.of(
                              context,
                            )!.adDurationLabel,
                            prefixIcon: PhosphorIcons.clock(),
                            isDark: isDark,
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v == null || int.tryParse(v) == null
                                ? AppLocalizations.of(context)!.invalid
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 4,
                                  bottom: 8,
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.adTargetScreen,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              Container(
                                height: 48,
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
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _targetScreen,
                                    isExpanded: true,
                                    dropdownColor: isDark
                                        ? AppTheme.darkCard
                                        : AppTheme.lightCard,
                                    icon: Icon(
                                      PhosphorIcons.caretDown(),
                                      size: 16,
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                        value: 'home',
                                        child: Text('Home Only'),
                                      ),
                                      const DropdownMenuItem(
                                        value: 'discover',
                                        child: Text('Discover Only'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'both',
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.adBothScreens,
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() => _targetScreen = v);
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
                    const SizedBox(height: 16),
                    // End Date Picker
                    InkWell(
                      onTap: _pickAdEndDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                PhosphorIcons.calendarBlank(),
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.adEndDate,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _adEndDate != null
                                        ? '${_adEndDate!.day}/${_adEndDate!.month}/${_adEndDate!.year}'
                                        : AppLocalizations.of(
                                            context,
                                          )!.adEndDateSubtitle,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_adEndDate != null)
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () {
                                  setState(() => _adEndDate = null);
                                },
                                color: Colors.red,
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              )
                            else
                              Icon(
                                PhosphorIcons.caretRight(),
                                size: 16,
                                color: isDark ? Colors.white30 : Colors.black26,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Toggles ──
              _buildCard(
                isDark: isDark,
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(AppLocalizations.of(context)!.adShowTimer),
                      subtitle: Text(
                        AppLocalizations.of(context)!.adShowTimerSub,
                      ),
                      value: _showRemainingTime,
                      onChanged: (v) => setState(() => _showRemainingTime = v),
                      activeThumbColor: AppTheme.primaryColor,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(AppLocalizations.of(context)!.adActiveStatus),
                      subtitle: Text(
                        AppLocalizations.of(context)!.adActiveStatusSub,
                      ),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      activeThumbColor: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),

              // ── Save Button ──
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.ad == null
                              ? AppLocalizations.of(context)!.publish
                              : AppLocalizations.of(context)!.saveChanges,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        ),
      ),
    );
  }
}
