import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/google_image_search_sheet.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/imagekit_service.dart';
import '../../presentation/providers/admin_providers.dart';
import '../../presentation/widgets/offline_warning_widget.dart';
import '../../l10n/app_localizations.dart';

class ManageInAppMessagesScreen extends ConsumerStatefulWidget {
  const ManageInAppMessagesScreen({super.key});

  @override
  ConsumerState<ManageInAppMessagesScreen> createState() =>
      _ManageInAppMessagesScreenState();
}

class _ManageInAppMessagesScreenState
    extends ConsumerState<ManageInAppMessagesScreen> {
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _actionUrlCtrl = TextEditingController();
  final _actionTextCtrl = TextEditingController();
  final _targetVersionCtrl = TextEditingController();
  int _campaignMode = 0;
  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0;
  bool _personalizeWithName = false;
  String? _editingId; // null = create mode, non-null = editing existing message

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    _imageUrlCtrl.dispose();
    _actionUrlCtrl.dispose();
    _actionTextCtrl.dispose();
    _targetVersionCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveMessage() async {
    if (_titleCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.titleMessageRequired),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'title': _titleCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        'image_url': _imageUrlCtrl.text.trim().isEmpty
            ? null
            : _imageUrlCtrl.text.trim(),
        'action_url': _actionUrlCtrl.text.trim().isEmpty
            ? null
            : _actionUrlCtrl.text.trim(),
        'action_text': _actionTextCtrl.text.trim().isEmpty
            ? null
            : _actionTextCtrl.text.trim(),
        'is_dismissible': _campaignMode != 2,
        'show_every_time': _campaignMode != 0,
        'target_version':
            (_campaignMode == 2 && _targetVersionCtrl.text.trim().isNotEmpty)
            ? _targetVersionCtrl.text.trim()
            : null,
        'personalize_name': _personalizeWithName,
      };

      if (_editingId != null) {
        // Update existing message
        await adminUpdateInAppMessage(_editingId!, data);
      } else {
        // Create new message
        data['is_active'] = false;
        await adminCreateInAppMessage(data);
      }

      _clearForm();
      ref.invalidate(adminInAppMessagesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editingId != null
                  ? AppLocalizations.of(context)!.campaignUpdated
                  : AppLocalizations.of(context)!.campaignCreated,
            ),
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
                  ? AppLocalizations.of(context)!.offlineWarningDetails
                  : AppLocalizations.of(context)!.failedWarning(e.toString()),
            ),
            backgroundColor: isOffline ? Colors.orange : Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _titleCtrl.clear();
    _messageCtrl.clear();
    _imageUrlCtrl.clear();
    _actionUrlCtrl.clear();
    _actionTextCtrl.clear();
    _targetVersionCtrl.clear();
    setState(() {
      _campaignMode = 0;
      _personalizeWithName = false;
      _editingId = null;
    });
  }

  void _loadMessageForEdit(Map<String, dynamic> msg) {
    _titleCtrl.text = msg['title'] ?? '';
    _messageCtrl.text = msg['message'] ?? '';
    _imageUrlCtrl.text = msg['image_url'] ?? '';
    _actionUrlCtrl.text = msg['action_url'] ?? '';
    _actionTextCtrl.text = msg['action_text'] ?? '';
    _targetVersionCtrl.text = msg['target_version'] ?? '';

    int mode = 0;
    if (msg['is_dismissible'] == false) {
      mode = 2; // Hard Block
    } else if (msg['show_every_time'] == true) {
      mode = 1; // Recurring
    }

    setState(() {
      _campaignMode = mode;
      _personalizeWithName = msg['personalize_name'] == true;
      _editingId = msg['id'];
    });

    // Scroll to top to show the form
    // The form is at the top of the CustomScrollView
  }

  void _previewMessage(Map<String, dynamic> msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String title = msg['title'] as String? ?? '';
    String message = msg['message'] as String? ?? '';
    // Replace {user_name} with example name for preview
    if (msg['personalize_name'] == true) {
      title = title.replaceAll('{user_name}', 'Ahmed');
      message = message.replaceAll('{user_name}', 'Ahmed');
    }
    final imageUrl = msg['image_url'] as String?;
    final actionUrl = msg['action_url'] as String?;
    final actionText = msg['action_text'] as String?;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Preview badge
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.visibility,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context)!.previewBadge,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.orange,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              // Image
              if (imageUrl != null && imageUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 180,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 180,
                    color: isDark ? Colors.white10 : Colors.black12,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 140,
                    color: isDark ? Colors.white10 : Colors.black12,
                    child: Icon(
                      PhosphorIcons.imageBroken(),
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                )
              else
                Container(
                  height: 120,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.accentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      PhosphorIcons.megaphone(PhosphorIconsStyle.fill),
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (actionUrl != null &&
                        actionUrl.isNotEmpty &&
                        actionText != null)
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () async {
                            final uri = Uri.tryParse(actionUrl);
                            if (uri != null && await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            actionText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark
                              ? Colors.white54
                              : Colors.black54,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.closePreview,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Future<void> _toggleStatus(String id, bool currentStatus) async {
    try {
      await adminToggleInAppMessage(id, !currentStatus);
      ref.invalidate(adminInAppMessagesProvider);
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
                  ? AppLocalizations.of(context)!.offlineWarningDetails
                  : AppLocalizations.of(
                      context,
                    )!.failedToUpdateStatus(e.toString()),
            ),
            backgroundColor: isOffline ? Colors.orange : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMessage(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteMessageTitle),
        content: Text(AppLocalizations.of(context)!.deleteMessageContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: Text(AppLocalizations.of(context)!.deleteLabel),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await adminDeleteInAppMessage(id);
        ref.invalidate(adminInAppMessagesProvider);
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
                    ? AppLocalizations.of(context)!.offlineWarningDetails
                    : AppLocalizations.of(
                        context,
                      )!.deleteFailedWarning(e.toString()),
              ),
              backgroundColor: isOffline ? Colors.orange : Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messagesAsync = ref.watch(adminInAppMessagesProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.inAppMessagesTitle),
        forceMaterialTransparency: true,
      ),
      body: CustomScrollView(
        slivers: [
          // Build Form
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          PhosphorIcons.megaphone(PhosphorIconsStyle.fill),
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _editingId != null
                              ? AppLocalizations.of(context)!.editCampaign
                              : AppLocalizations.of(context)!.newCampaign,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_editingId != null)
                          TextButton(
                            onPressed: _clearForm,
                            child: Text(
                              AppLocalizations.of(context)!.cancelEdit,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      _titleCtrl,
                      AppLocalizations.of(context)!.titleLabel,
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _messageCtrl,
                      AppLocalizations.of(context)!.messageLabel,
                      isDark,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.campaignImageOptional,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
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
                                              folder: '/campaigns',
                                              onProgress: (p) {
                                                if (mounted) {
                                                  setState(
                                                    () => _uploadProgress = p,
                                                  );
                                                }
                                              },
                                            );
                                        if (url != null && context.mounted) {
                                          setState(() {
                                            _imageUrlCtrl.text = url;
                                          });
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.imageUploadedSuccessfully,
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } else if (context.mounted &&
                                            _uploadProgress > 0) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.uploadFailed,
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
                                    ? AppLocalizations.of(context)!.uploading
                                    : AppLocalizations.of(
                                        context,
                                      )!.uploadFromDevice,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
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
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final url = await showModalBottomSheet<String>(
                                  context: context,
                                  isScrollControlled: true,
                                  enableDrag: false,
                                  backgroundColor: Colors.transparent,
                                  builder: (ctx) => GoogleImageSearchSheet(
                                    initialQuery: _titleCtrl.text,
                                  ),
                                );
                                if (url != null && mounted) {
                                  setState(() {
                                    _imageUrlCtrl.text = url;
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
                      _imageUrlCtrl,
                      AppLocalizations.of(context)!.imageUrlLabel,
                      isDark,
                    ),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _imageUrlCtrl,
                      builder: (context, value, child) {
                        if (value.text.trim().isEmpty) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                CachedNetworkImage(
                                  imageUrl: value.text.trim(),
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
                                            AppLocalizations.of(
                                              context,
                                            )!.invalidUrl,
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
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => _imageUrlCtrl.clear(),
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
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _actionUrlCtrl,
                      AppLocalizations.of(context)!.buttonUrlOptional,
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _actionTextCtrl,
                      AppLocalizations.of(context)!.buttonTextOptional,
                      isDark,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.campaignModeLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<int>(
                      segments: [
                        ButtonSegment(
                          value: 0,
                          icon: const Icon(Icons.looks_one_outlined),
                          label: Text(
                            AppLocalizations.of(context)!.modeStandard,
                          ),
                        ),
                        ButtonSegment(
                          value: 1,
                          icon: const Icon(Icons.repeat),
                          label: Text(
                            AppLocalizations.of(context)!.modeRecurring,
                          ),
                        ),
                        ButtonSegment(
                          value: 2,
                          icon: const Icon(Icons.block),
                          label: Text(
                            AppLocalizations.of(context)!.modeHardBlock,
                          ),
                        ),
                      ],
                      selected: {_campaignMode},
                      onSelectionChanged: (Set<int> newSelection) {
                        setState(() {
                          _campaignMode = newSelection.first;
                        });
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppTheme.primaryColor.withValues(
                                alpha: 0.2,
                              );
                            }
                            return Colors.transparent;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _campaignMode == 0
                          ? AppLocalizations.of(context)!.modeStandardDesc
                          : _campaignMode == 1
                          ? AppLocalizations.of(context)!.modeRecurringDesc
                          : AppLocalizations.of(context)!.modeHardBlockDesc,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_campaignMode == 2) ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        _targetVersionCtrl,
                        AppLocalizations.of(context)!.targetVersionOptional,
                        isDark,
                      ),
                    ],
                    const SizedBox(height: 16),
                    // --- Personalize with user name ---
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _personalizeWithName
                            ? AppTheme.primaryColor.withValues(alpha: 0.08)
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.03)
                                  : Colors.black.withValues(alpha: 0.02)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _personalizeWithName
                              ? AppTheme.primaryColor.withValues(alpha: 0.3)
                              : (isDark ? Colors.white10 : Colors.black12),
                        ),
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          AppLocalizations.of(context)!.personalizeNameToggle,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        value: _personalizeWithName,
                        activeThumbColor: AppTheme.primaryColor,
                        onChanged: (val) {
                          setState(() => _personalizeWithName = val);
                        },
                      ),
                    ),
                    if (_personalizeWithName) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.blue.withValues(alpha: 0.08)
                              : Colors.blue.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              PhosphorIcons.info(),
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                )!.personalizeNameHint('{user_name}'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.blue[200]
                                      : Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final text = _messageCtrl.text;
                            final selection = _messageCtrl.selection;
                            const placeholder = '{user_name}';
                            if (selection.isValid &&
                                selection.start >= 0 &&
                                selection.start <= text.length) {
                              final newText = text.replaceRange(
                                selection.start,
                                selection.end,
                                placeholder,
                              );
                              _messageCtrl.text = newText;
                              _messageCtrl.selection = TextSelection.collapsed(
                                offset: selection.start + placeholder.length,
                              );
                            } else {
                              _messageCtrl.text = '$text$placeholder';
                              _messageCtrl.selection = TextSelection.collapsed(
                                offset: _messageCtrl.text.length,
                              );
                            }
                          },
                          icon: Icon(PhosphorIcons.userCirclePlus(), size: 16),
                          label: Text(
                            AppLocalizations.of(
                              context,
                            )!.insertUserName('{user_name}'),
                            style: const TextStyle(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            side: BorderSide(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.4,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _editingId != null
                                  ? AppLocalizations.of(context)!.updateCampaign
                                  : AppLocalizations.of(
                                      context,
                                    )!.createCampaign,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.1),
            ),
          ),

          // Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Text(
                AppLocalizations.of(context)!.existingCampaigns,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2,
                  color: Colors.grey,
                ),
              ),
            ),
          ),

          // Message List
          messagesAsync.when(
            data: (messages) {
              if (messages.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.noCampaignsYet,
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final msg = messages[index];
                  final isActive = msg['is_active'] == true;
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? AppTheme.primaryColor
                            : (isDark ? Colors.white10 : Colors.black12),
                      ),
                    ),
                    child: GestureDetector(
                      onTap: () => _previewMessage(msg),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (isActive)
                                      Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.activeBadge,
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    if (msg['is_dismissible'] == false)
                                      Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          msg['target_version'] != null
                                              ? AppLocalizations.of(
                                                  context,
                                                )!.updateBadge(
                                                  msg['target_version']
                                                      .toString(),
                                                )
                                              : AppLocalizations.of(
                                                  context,
                                                )!.hardBlockBadge,
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    else if (msg['show_every_time'] == true)
                                      Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.recurringBadge,
                                          style: const TextStyle(
                                            color: Colors.purple,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    Expanded(
                                      child: Text(
                                        msg['title'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  msg['message'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            children: [
                              Switch(
                                value: isActive,
                                activeThumbColor: AppTheme.primaryColor,
                                onChanged: (val) =>
                                    _toggleStatus(msg['id'], isActive),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      PhosphorIcons.pencilSimple(),
                                      color: AppTheme.primaryColor,
                                      size: 18,
                                    ),
                                    onPressed: () => _loadMessageForEdit(msg),
                                    tooltip: AppLocalizations.of(
                                      context,
                                    )!.editTooltip,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      PhosphorIcons.trash(),
                                      color: AppTheme.errorColor,
                                      size: 18,
                                    ),
                                    onPressed: () => _deleteMessage(msg['id']),
                                    tooltip: AppLocalizations.of(
                                      context,
                                    )!.deleteTooltip,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.1);
                }, childCount: messages.length),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, s) =>
                SliverToBoxAdapter(child: OfflineWarningWidget(error: e)),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    bool isDark, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
