import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/admin_providers.dart';
import '../../core/services/imagekit_service.dart';
import '../../l10n/app_localizations.dart';

class SendNotificationScreen extends ConsumerStatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  ConsumerState<SendNotificationScreen> createState() =>
      _SendNotificationScreenState();
}

class _SendNotificationScreenState
    extends ConsumerState<SendNotificationScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  String _type = 'general';
  bool _loading = false;
  bool _sent = false;
  bool _isUploading = false;
  double _uploadProgress = 0;
  bool _personalizeWithName = false;

  final _types = ['general', 'announcement', 'update', 'alert'];

  String _getTypeLabel(BuildContext context, String t) {
    switch (t) {
      case 'general':
        return AppLocalizations.of(context)!.notifTypeGeneral;
      case 'announcement':
        return AppLocalizations.of(context)!.notifTypeAnnouncement;
      case 'update':
        return AppLocalizations.of(context)!.notifTypeUpdate;
      case 'alert':
        return AppLocalizations.of(context)!.notifAlert;
      default:
        return AppLocalizations.of(context)!.notifTypeGeneral;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _urlCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);

    try {
      await adminSendNotification({
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'type': _type,
        'target_url': _urlCtrl.text.trim().isEmpty
            ? null
            : _urlCtrl.text.trim(),
        'image_url': _imageUrlCtrl.text.trim().isEmpty
            ? null
            : _imageUrlCtrl.text.trim(),
        'personalize_name': _personalizeWithName,
      });
      setState(() {
        _sent = true;
        _titleCtrl.clear();
        _bodyCtrl.clear();
        _urlCtrl.clear();
        _imageUrlCtrl.clear();
        _type = 'general';
        _personalizeWithName = false;
      });
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
                  ? AppLocalizations.of(context)!.formOfflineError
                  : AppLocalizations.of(context)!.notifFailed(e.toString()),
            ),
            backgroundColor: isOffline ? Colors.orange : Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notifSend),
        forceMaterialTransparency: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sent success
            if (_sent)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(context)!.notifSent,
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _sent = false),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.1),

            // Form Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    PhosphorIcons.bellRinging(PhosphorIconsStyle.fill),
                    size: 40,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.notifNew,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.notifDesc,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _field(
                    _titleCtrl,
                    AppLocalizations.of(context)!.notifTitle,
                    isDark,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    _bodyCtrl,
                    AppLocalizations.of(context)!.notifBody,
                    isDark,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    _urlCtrl,
                    AppLocalizations.of(context)!.notifUrl,
                    isDark,
                  ),
                  const SizedBox(height: 16),

                  Text(
                    AppLocalizations.of(context)!.notifImage,
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
                                            folder: '/notifications',
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
                                          const SnackBar(
                                            content: Text(
                                              'Image uploaded successfully!',
                                            ),
                                            backgroundColor: Colors.green,
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
                                : Icon(PhosphorIcons.uploadSimple(), size: 18),
                            label: Text(
                              _isUploading
                                  ? AppLocalizations.of(context)!.notifUploading
                                  : AppLocalizations.of(
                                      context,
                                    )!.notifUploadImg,
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
                        child: _field(
                          _imageUrlCtrl,
                          AppLocalizations.of(context)!.notifOrImgUrl,
                          isDark,
                        ),
                      ),
                    ],
                  ),

                  // Live Image Preview
                  if (_imageUrlCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: _imageUrlCtrl.text,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                PhosphorIcons.imageBroken(),
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context)!.notifInvalidImg,
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
                      ),
                    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
                  ],
                  const SizedBox(height: 20),

                  // Type selector
                  Text(
                    AppLocalizations.of(context)!.notifType,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _types.map((t) {
                      final active = t == _type;
                      return GestureDetector(
                        onTap: () => setState(() => _type = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? AppTheme.primaryColor
                                : (isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.04)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _getTypeLabel(context, t),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: active
                                  ? Colors.white
                                  : (isDark ? Colors.white60 : Colors.black54),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

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
                          final text = _bodyCtrl.text;
                          final selection = _bodyCtrl.selection;
                          const placeholder = '{user_name}';
                          if (selection.isValid &&
                              selection.start >= 0 &&
                              selection.start <= text.length) {
                            final newText = text.replaceRange(
                              selection.start,
                              selection.end,
                              placeholder,
                            );
                            _bodyCtrl.text = newText;
                            _bodyCtrl.selection = TextSelection.collapsed(
                              offset: selection.start + placeholder.length,
                            );
                          } else {
                            _bodyCtrl.text = '$text$placeholder';
                            _bodyCtrl.selection = TextSelection.collapsed(
                              offset: _bodyCtrl.text.length,
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
                            color: AppTheme.primaryColor.withValues(alpha: 0.4),
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

                  const SizedBox(height: 28),

                  Container(
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, Color(0xFF7C4DFF)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _loading ? null : _send,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  PhosphorIcons.paperPlaneTilt(),
                                  size: 20,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context)!.notifSend,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),
          ],
        ),
      ),
    );
  }

  Widget _field(
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
        labelStyle: TextStyle(
          color: isDark ? Colors.white38 : Colors.black38,
          fontSize: 14,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppTheme.primaryColor,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }
}
