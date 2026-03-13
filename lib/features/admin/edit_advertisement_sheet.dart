import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/imagekit_service.dart';
import '../../domain/models/advertisement.dart';
import '../../data/models/website_model.dart';
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
  final _searchController = TextEditingController();

  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0;
  bool _isActive = true;
  bool _showRemainingTime = false;
  String _targetScreen = 'both';
  DateTime? _adEndDate;
  bool _isInternalLink = false;

  Timer? _debounce;
  bool _isSearching = false;
  List<WebsiteModel>? _searchResults;
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
    _searchController.dispose();
    _debounce?.cancel();
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

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isEmpty) {
        setState(() {
          _searchResults = null;
          _isSearching = false;
        });
        return;
      }
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    try {
      final response = await SupabaseConfig.client
          .from('websites')
          .select()
          .ilike('title', '%$query%')
          .limit(5);

      final results = (response as List)
          .map((e) => WebsiteModel.fromJson(e))
          .toList();
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
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
                        Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.white10 : Colors.black12,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIcons.link(),
                                size: 16,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(context)!.orPasteUrl,
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
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(AppLocalizations.of(context)!.adLinkInternal),
                      subtitle: Text(
                        AppLocalizations.of(context)!.adLinkInternalSub,
                      ),
                      value: _isInternalLink,
                      onChanged: (v) => setState(() => _isInternalLink = v),
                      activeThumbColor: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 16),
                    if (_isInternalLink)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            controller: _searchController,
                            label: AppLocalizations.of(
                              context,
                            )!.adSearchInternal,
                            prefixIcon: PhosphorIcons.magnifyingGlass(),
                            isDark: isDark,
                            onChanged: _onSearchChanged,
                          ),
                          if (_isSearching)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          if (_searchResults != null && !_isSearching)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              constraints: const BoxConstraints(maxHeight: 200),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppTheme.darkCard
                                    : AppTheme.lightCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black12,
                                ),
                              ),
                              child: _searchResults!.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.adNoMatchingItems,
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: _searchResults!.length,
                                      itemBuilder: (context, index) {
                                        final site = _searchResults![index];
                                        return ListTile(
                                          leading:
                                              site.imageUrl != null &&
                                                  site.imageUrl!.isNotEmpty
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  child: CachedNetworkImage(
                                                    imageUrl: site.imageUrl!,
                                                    width: 32,
                                                    height: 32,
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                              : const Icon(Icons.language),
                                          title: Text(site.title, maxLines: 1),
                                          subtitle: Text(
                                            site.description,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          onTap: () {
                                            setState(() {
                                              _selectedWebsite = site;
                                              _linkedWebsiteIdController.text =
                                                  site.id;
                                              _searchController.clear();
                                              _searchResults = null;
                                            });
                                          },
                                        );
                                      },
                                    ),
                            ),
                        ],
                      )
                    else
                      _buildTextField(
                        controller: _linkUrlController,
                        label: AppLocalizations.of(context)!.adExternalUrl,
                        prefixIcon: PhosphorIcons.browser(),
                        isDark: isDark,
                        helperText: AppLocalizations.of(
                          context,
                        )!.adExternalUrlHelper,
                      ),
                    const SizedBox(height: 16),
                    if (_selectedWebsite != null && _isInternalLink)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.darkCard
                              : AppTheme.lightCard,
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
                                child: const Icon(
                                  Icons.language,
                                  color: Colors.grey,
                                ),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedWebsite!.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
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
