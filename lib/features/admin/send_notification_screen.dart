import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/admin_providers.dart';
import '../../core/services/imagekit_service.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/admin_ui_utils.dart';
import '../../data/models/notification_model.dart';
import 'widgets/discover_item_picker_sheet.dart';
import '../../data/models/website_model.dart';
import 'widgets/google_image_search_sheet.dart';

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

  String _destinationType = 'none'; // 'none', 'item', 'url'
  WebsiteModel? _selectedDiscoverItem;

  bool _loading = false;
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

  Future<void> _showDiscoverItemPicker(
    BuildContext context,
    bool isDark,
  ) async {
    final WebsiteModel? selectedItem =
        await showModalBottomSheet<WebsiteModel?>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => const DiscoverItemPickerSheet(),
        );

    if (selectedItem != null) {
      setState(() {
        _selectedDiscoverItem = selectedItem;
        if (_titleCtrl.text.isEmpty) {
          _titleCtrl.text = selectedItem.title;
        }
        if (_imageUrlCtrl.text.isEmpty && selectedItem.imageUrl != null) {
          _imageUrlCtrl.text = selectedItem.imageUrl!;
        }
      });
    }
  }

  Future<void> _send() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);

    try {
      String? finalUrl;
      if (_destinationType == 'item' && _selectedDiscoverItem != null) {
        finalUrl = 'app://discover/item/${_selectedDiscoverItem!.id}';
      } else if (_destinationType == 'url' && _urlCtrl.text.trim().isNotEmpty) {
        finalUrl = _urlCtrl.text.trim();
      }

      final result = await adminSendNotification({
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'type': _type,
        'target_url': finalUrl,
        'image_url': _imageUrlCtrl.text.trim().isEmpty
            ? null
            : _imageUrlCtrl.text.trim(),
        'personalize_name': _personalizeWithName,
      });

      setState(() {
        _titleCtrl.clear();
        _bodyCtrl.clear();
        _urlCtrl.clear();
        _imageUrlCtrl.clear();
        _type = 'general';
        _destinationType = 'none';
        _selectedDiscoverItem = null;
        _personalizeWithName = false;
      });

      if (mounted) {
        ref.read(adminNotificationsPaginatedProvider.notifier).reset();
        _showStatsDialog(result);
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
            AppLocalizations.of(context)!.notifFailed(e.toString()),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showStatsDialog(Map<String, dynamic> stats) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                  color: Colors.green,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                loc.notifStatsTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loc.notifStatsSuccessMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDialogStatItem(
                      loc.notifStatsTargeted,
                      stats['total_targeted'].toString(),
                      Colors.blueAccent,
                      PhosphorIcons.users(),
                      isDark,
                    ),
                    Container(width: 1, height: 40, color: isDark ? Colors.white10 : Colors.black12),
                    _buildDialogStatItem(
                      loc.notifStatsSent,
                      stats['sent_count'].toString(),
                      Colors.green,
                      PhosphorIcons.checks(),
                      isDark,
                    ),
                    Container(width: 1, height: 40, color: isDark ? Colors.white10 : Colors.black12),
                    _buildDialogStatItem(
                      loc.notifStatsFailed,
                      stats['failed_count'].toString(),
                      Colors.redAccent,
                      PhosphorIcons.warningCircle(),
                      isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogStatItem(String label, String value, Color color, IconData iconData, bool isDark) {
    return Column(
      children: [
        Icon(iconData, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
      ],
    );
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
      bottomNavigationBar: _buildBottomBar(isDark),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopStatsBanner(isDark).animate().fadeIn().slideY(begin: 0.05),
            const SizedBox(height: 20),
            
            _buildMessageCard(isDark).animate().fadeIn(delay: 50.ms).slideY(begin: 0.05),
            const SizedBox(height: 20),

            _buildMediaDestinationCard(
              isDark,
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),
            const SizedBox(height: 20),

            _buildSettingsCard(
              isDark,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),
            const SizedBox(height: 32),

            _buildRecentNotifications(context, ref, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    bool isDark, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMessageCard(bool isDark) {
    return _buildCard(
      isDark,
      title: AppLocalizations.of(context)!.notifMessageContent,
      icon: PhosphorIcons.chatText(PhosphorIconsStyle.fill),
      children: [
        _field(_titleCtrl, AppLocalizations.of(context)!.notifTitle, isDark),
        const SizedBox(height: 14),
        _field(
          _bodyCtrl,
          AppLocalizations.of(context)!.notifBody,
          isDark,
          maxLines: 4,
        ),
        const SizedBox(height: 16),
        _buildPersonalizationToggle(isDark),
      ],
    );
  }

  Widget _buildPersonalizationToggle(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                Icon(PhosphorIcons.info(), size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(
                      context,
                    )!.personalizeNameHint('{user_name}'),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.blue[200] : Colors.blue[700],
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
                AppLocalizations.of(context)!.insertUserName('{user_name}'),
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
      ],
    );
  }

  Widget _buildMediaDestinationCard(bool isDark) {
    return _buildCard(
      isDark,
      title: AppLocalizations.of(context)!.notifMediaDestination,
      icon: PhosphorIcons.paperPlaneTilt(PhosphorIconsStyle.fill),
      children: [
        Text(
          AppLocalizations.of(context)!.notifActionDestination,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        _buildDestinationSelector(isDark),
        const SizedBox(height: 16),
        if (_destinationType == 'item') ...[
          _buildItemPickerUI(isDark),
          const SizedBox(height: 16),
        ] else if (_destinationType == 'url') ...[
          _field(_urlCtrl, AppLocalizations.of(context)!.notifUrl, isDark),
          const SizedBox(height: 16),
        ],
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
                            final url = await ImageKitService.pickAndUpload(
                              folder: '/notifications',
                              onProgress: (p) {
                                if (mounted) {
                                  setState(() => _uploadProgress = p);
                                }
                              },
                            );
                            if (!mounted) return;
                            if (url != null) {
                              setState(() {
                                _imageUrlCtrl.text = url;
                              });
                              AdminUIUtils.showSuccess(
                                context,
                                AppLocalizations.of(context)!.notifImgUploadSuccess,
                              );
                            } else if (_uploadProgress > 0) {
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
                  icon: _isUploading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            value: _uploadProgress > 0 ? _uploadProgress : null,
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(PhosphorIcons.uploadSimple(), size: 18),
                  label: Text(
                    _isUploading
                        ? AppLocalizations.of(context)!.notifUploading
                        : AppLocalizations.of(context)!.notifUploadImg,
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                      builder: (ctx) =>
                          GoogleImageSearchSheet(initialQuery: _titleCtrl.text),
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
                    foregroundColor: isDark ? Colors.white70 : Colors.black87,
                    side: BorderSide(
                      color: isDark ? Colors.white10 : Colors.black12,
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
        const SizedBox(height: 12),
        _field(
          _imageUrlCtrl,
          AppLocalizations.of(context)!.notifOrImgUrl,
          isDark,
        ),
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
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
        ],
      ],
    );
  }

  Widget _buildDestinationSelector(bool isDark) {
    final opts = [
      {'val': 'none', 'label': AppLocalizations.of(context)!.notifNoLink, 'icon': PhosphorIcons.prohibit()},
      {
        'val': 'item',
        'label': AppLocalizations.of(context)!.notifDiscoverItem,
        'icon': PhosphorIcons.appWindow(),
      },
      {'val': 'url', 'label': AppLocalizations.of(context)!.notifExternalUrl, 'icon': PhosphorIcons.link()},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: opts.map((opt) {
        final val = opt['val'] as String;
        final label = opt['label'] as String;
        final icon = opt['icon'] as IconData;
        final active = _destinationType == val;

        return GestureDetector(
          onTap: () {
            setState(() {
              _destinationType = val;
              if (val == 'none') {
                _urlCtrl.clear();
                _selectedDiscoverItem = null;
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: active
                  ? AppTheme.primaryColor
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active
                    ? AppTheme.primaryColor
                    : (isDark ? Colors.white12 : Colors.black12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: active
                      ? Colors.white
                      : (isDark ? Colors.white60 : Colors.black54),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active
                        ? Colors.white
                        : (isDark ? Colors.white60 : Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildItemPickerUI(bool isDark) {
    if (_selectedDiscoverItem == null) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: () => _showDiscoverItemPicker(context, isDark),
          icon: Icon(PhosphorIcons.magnifyingGlass(), size: 18),
          label: Text(AppLocalizations.of(context)!.notifSelectDiscoverItem),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            side: BorderSide(
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: _selectedDiscoverItem!.imageUrl != null
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(
                        _selectedDiscoverItem!.imageUrl!,
                      ),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: isDark ? Colors.white10 : Colors.black12,
            ),
            child: _selectedDiscoverItem!.imageUrl == null
                ? Icon(
                    PhosphorIcons.image(),
                    size: 20,
                    color: isDark ? Colors.white54 : Colors.black54,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedDiscoverItem!.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _selectedDiscoverItem!.contentType,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              PhosphorIcons.pencilSimple(),
              size: 20,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            onPressed: () => _showDiscoverItemPicker(context, isDark),
          ),
          IconButton(
            icon: Icon(PhosphorIcons.x(), size: 20, color: Colors.redAccent),
            onPressed: () => setState(() => _selectedDiscoverItem = null),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(bool isDark) {
    return _buildCard(
      isDark,
      title: AppLocalizations.of(context)!.notifConfiguration,
      icon: PhosphorIcons.sliders(PhosphorIconsStyle.fill),
      children: [
        Text(
          AppLocalizations.of(context)!.notifType,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
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
      ],
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Container(
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

  Widget _buildRecentNotifications(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    final state = ref.watch(adminNotificationsPaginatedProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.notifRecentNotifications,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            if (state.items.isNotEmpty)
              TextButton.icon(
                onPressed: () => _confirmDeleteAll(context, ref),
                icon: Icon(PhosphorIcons.trash(), size: 16, color: Colors.red),
                label: Text(
                  AppLocalizations.of(context)!.notifDeleteAll,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (state.isLoading && state.isInitialLoad)
          const Center(child: CircularProgressIndicator())
        else if (state.items.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                AppLocalizations.of(context)!.notifNoRecent,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.items.length + (state.hasMore ? 1 : 0),
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index >= state.items.length) {
                return Center(
                  child: TextButton(
                    onPressed: () => ref
                        .read(adminNotificationsPaginatedProvider.notifier)
                        .loadMore(),
                    child: Text(AppLocalizations.of(context)!.notifLoadMore),
                  ),
                );
              }
              final notif = state.items[index];
              return _buildNotificationItem(context, ref, notif, isDark);
            },
          ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildNotificationItem(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notif,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIcons.bellRinging(),
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (notif.body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(PhosphorIcons.users(), size: 14, color: isDark ? Colors.white54 : Colors.black54),
                    const SizedBox(width: 4),
                    Text(notif.totalTargeted.toString(), style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Text('|', style: TextStyle(fontSize: 12, color: isDark ? Colors.white24 : Colors.black26)),
                    const SizedBox(width: 12),
                    Icon(PhosphorIcons.checks(), size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(notif.sentCount.toString(), style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Text('|', style: TextStyle(fontSize: 12, color: isDark ? Colors.white24 : Colors.black26)),
                    const SizedBox(width: 12),
                    Icon(PhosphorIcons.warningCircle(), size: 14, color: Colors.redAccent),
                    const SizedBox(width: 4),
                    Text(notif.failedCount.toString(), style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat(
                    'MMM d, yyyy • h:mm a',
                  ).format(notif.createdAt.toLocal()),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              PhosphorIcons.trash(),
              color: Colors.redAccent,
              size: 20,
            ),
            onPressed: () => _confirmDelete(context, ref, notif.id),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        title: Text(AppLocalizations.of(context)!.notifDeleteTitle),
        content: Text(AppLocalizations.of(context)!.notifDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.notifCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppLocalizations.of(context)!.notifDelete,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await adminDeleteNotification(id);
      if (context.mounted) {
        ref.read(adminNotificationsPaginatedProvider.notifier).reset();
      }
    }
  }

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        title: Text(AppLocalizations.of(context)!.notifDeleteAllTitle),
        content: Text(
          AppLocalizations.of(context)!.notifDeleteAllConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.notifCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppLocalizations.of(context)!.notifDeleteAll,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await adminDeleteAllNotifications();
      if (context.mounted) {
        ref.read(adminNotificationsPaginatedProvider.notifier).reset();
      }
    }
  }

  Widget _buildTopStatsBanner(bool isDark) {
    final statsAsync = ref.watch(adminFCMStatsProvider);
    final loc = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.notifUsersProgress,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          statsAsync.when(
            data: (stats) {
              final total = stats['total'] ?? 0;
              final active = stats['active'] ?? 0;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBannerStatItem(loc.notifUsersTotal, total.toString(), isDark),
                  Container(width: 1, height: 30, color: isDark ? Colors.white24 : Colors.black12),
                  _buildBannerStatItem(loc.notifUsersActive, active.toString(), isDark, isHighlight: true),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Text(loc.somethingWentWrong),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerStatItem(String label, String value, bool isDark, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isHighlight ? AppTheme.primaryColor : (isDark ? Colors.white : Colors.black87),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
      ],
    );
  }
}
