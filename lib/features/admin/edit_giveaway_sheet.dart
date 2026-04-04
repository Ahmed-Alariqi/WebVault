import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/imagekit_service.dart';
import '../../data/models/giveaway_model.dart';
import '../../presentation/providers/events_providers.dart';
import '../../presentation/providers/admin_providers.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/google_image_search_sheet.dart';

class EditGiveawaySheet extends ConsumerStatefulWidget {
  final Giveaway? giveaway;
  const EditGiveawaySheet({super.key, this.giveaway});

  @override
  ConsumerState<EditGiveawaySheet> createState() => _EditGiveawaySheetState();
}

class _EditGiveawaySheetState extends ConsumerState<EditGiveawaySheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _maxEntriesCtrl = TextEditingController();
  final _entryFieldCtrl = TextEditingController();
  final _winnerCountCtrl = TextEditingController(text: '1');
  String _prizeType = 'other';
  DateTime? _endsAt;
  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0;
  bool _sendNotification = false;
  bool _requestEntryData = false;

  @override
  void initState() {
    super.initState();
    final g = widget.giveaway;
    if (g != null) {
      _titleCtrl.text = g.title;
      _descCtrl.text = g.description ?? '';
      _imageCtrl.text = g.imageUrl ?? '';
      _prizeType = g.prizeType;
      _endsAt = g.endsAt;
      if (g.maxEntries != null) _maxEntriesCtrl.text = g.maxEntries.toString();
      if (g.entryFieldLabel != null && g.entryFieldLabel!.isNotEmpty) {
        _requestEntryData = true;
        _entryFieldCtrl.text = g.entryFieldLabel!;
      }
      _winnerCountCtrl.text = g.winnerCount.toString();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _imageCtrl.dispose();
    _maxEntriesCtrl.dispose();
    _entryFieldCtrl.dispose();
    _winnerCountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _endsAt == null) {
      if (_endsAt == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.selectEndDate)),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final data = {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        'image_url': _imageCtrl.text.trim().isEmpty
            ? null
            : _imageCtrl.text.trim(),
        'prize_type': _prizeType,
        'ends_at': _endsAt!.toUtc().toIso8601String(),
        'max_entries': _maxEntriesCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(_maxEntriesCtrl.text.trim()),
        'entry_field_label':
            _requestEntryData && _entryFieldCtrl.text.trim().isNotEmpty
            ? _entryFieldCtrl.text.trim()
            : null,
        'winner_count': int.tryParse(_winnerCountCtrl.text.trim()) ?? 1,
      };

      if (widget.giveaway == null) {
        final newId = await createGiveaway(data, ref);

        // Send notification if toggled on
        if (_sendNotification) {
          try {
            await adminSendNotification({
              'title': '🎁 ${_titleCtrl.text.trim()}',
              'body': l10n.notifBodyGiveaway,
              'type': 'giveaway',
              'target_url': 'app://events/giveaway/$newId',
              'image_url': _imageCtrl.text.trim().isEmpty
                  ? null
                  : _imageCtrl.text.trim(),
            });
          } catch (_) {
            // Notification failure shouldn't block save
          }
        }
      } else {
        await updateGiveaway(widget.giveaway!.id, data, ref);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endsAt ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endsAt ?? DateTime.now()),
    );
    if (time != null) {
      setState(() {
        _endsAt = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.giveaway != null;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(
          isEdit ? l10n.editGiveaway : l10n.createGiveaway,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        forceMaterialTransparency: true,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // General Info Section
              _buildSectionTitle(
                'General Information',
                PhosphorIcons.info(),
                isDark,
              ),
              _buildCard(
                isDark: isDark,
                child: Column(
                  children: [
                    _buildField(
                      controller: _titleCtrl,
                      label: l10n.giveawayTitle,
                      icon: PhosphorIcons.textT(),
                      isDark: isDark,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? l10n.required : null,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _descCtrl,
                      label: l10n.giveawayDescription,
                      icon: PhosphorIcons.textAa(),
                      isDark: isDark,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Prize Details Section
              _buildSectionTitle('Prize Details', PhosphorIcons.gift(), isDark),
              _buildCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.prizeType,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['account', 'subscription', 'code', 'other']
                          .map(
                            (type) => ChoiceChip(
                              label: Text(_prizeLabel(type, l10n)),
                              selected: _prizeType == type,
                              onSelected: (_) =>
                                  setState(() => _prizeType = type),
                              selectedColor: AppTheme.primaryColor.withValues(
                                alpha: 0.15,
                              ),
                              elevation: 0,
                              pressElevation: 0,
                              backgroundColor: isDark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.04),
                              side: BorderSide(
                                color: _prizeType == type
                                    ? AppTheme.primaryColor.withValues(
                                        alpha: 0.5,
                                      )
                                    : Colors.transparent,
                              ),
                              labelStyle: TextStyle(
                                color: _prizeType == type
                                    ? AppTheme.primaryColor
                                    : (isDark
                                          ? Colors.white70
                                          : Colors.black54),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const Divider(height: 32),
                    Text(
                      l10n.prizeImage,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
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
                                              folder: '/giveaways',
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
                                            _imageCtrl.text = url;
                                            _isUploading = false;
                                          });
                                        } else {
                                          setState(() => _isUploading = false);
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          setState(() => _isUploading = false);
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
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.cloud_upload_outlined,
                                      size: 20,
                                    ),
                              label: Text(
                                l10n.upload,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                                  builder: (_) => GoogleImageSearchSheet(
                                    initialQuery: _titleCtrl.text,
                                  ),
                                );
                                if (url != null && mounted) {
                                  setState(() => _imageCtrl.text = url);
                                }
                              },
                              icon: Icon(
                                PhosphorIcons.magnifyingGlass(),
                                size: 20,
                              ),
                              label: Text(
                                l10n.searchImage,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark
                                    ? Colors.white70
                                    : Colors.black87,
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.white24
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
                    if (_imageCtrl.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Image.network(
                                _imageCtrl.text,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const SizedBox(),
                              ),
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                onPressed: () =>
                                    setState(() => _imageCtrl.clear()),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Settings Section
              _buildSectionTitle(
                'Event Settings',
                PhosphorIcons.slidersHorizontal(),
                isDark,
              ),
              _buildCard(
                isDark: isDark,
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          PhosphorIcons.calendarBlank(PhosphorIconsStyle.fill),
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        _endsAt != null
                            ? DateFormat(
                                'MMM d, yyyy • h:mm a',
                              ).format(_endsAt!)
                            : l10n.selectEndDate,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: _endsAt != null
                              ? (isDark ? Colors.white : Colors.black87)
                              : (isDark ? Colors.white54 : Colors.black54),
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          l10n.endDateDesc,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _pickEndDate,
                    ),
                    const Divider(height: 32),
                    _buildField(
                      controller: _maxEntriesCtrl,
                      label: l10n.maxEntries,
                      icon: PhosphorIcons.usersThree(),
                      isDark: isDark,
                      keyboardType: TextInputType.number,
                      helperText: l10n.maxEntriesHint,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _winnerCountCtrl,
                      label: l10n.winnerCount,
                      icon: PhosphorIcons.trophy(),
                      isDark: isDark,
                      keyboardType: TextInputType.number,
                      helperText: l10n.winnerCountHint,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = int.tryParse(v.trim());
                        if (n == null || n < 1) return l10n.invalidNumber;
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Interactive Entry Section
              _buildSectionTitle(
                'Interactive Entry',
                PhosphorIcons.chatTeardropText(),
                isDark,
              ),
              _buildCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _requestEntryData
                              ? AppTheme.primaryColor.withValues(alpha: 0.1)
                              : (isDark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.04)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          PhosphorIcons.textbox(PhosphorIconsStyle.fill),
                          color: _requestEntryData
                              ? AppTheme.primaryColor
                              : (isDark ? Colors.white54 : Colors.black54),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        l10n.requestEntryData,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          l10n.requestEntryDataSub,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ),
                      value: _requestEntryData,
                      onChanged: (v) => setState(() => _requestEntryData = v),
                      activeColor: Colors.white,
                      activeTrackColor: AppTheme.primaryColor,
                    ),
                    if (_requestEntryData) ...[
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _entryFieldCtrl,
                        label: l10n.entryFieldLabel,
                        icon: PhosphorIcons.question(),
                        isDark: isDark,
                        helperText: l10n.entryFieldLabelHint,
                        validator: (v) {
                          if (_requestEntryData &&
                              (v == null || v.trim().isEmpty)) {
                            return l10n.required;
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
              ),

              if (!isEdit) ...[
                const SizedBox(height: 28),
                _buildSectionTitle(
                  'Notifications',
                  PhosphorIcons.bell(),
                  isDark,
                ),
                _buildCard(
                  isDark: isDark,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _sendNotification
                            ? AppTheme.primaryColor.withValues(alpha: 0.1)
                            : (isDark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.04)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        PhosphorIcons.bellRinging(PhosphorIconsStyle.fill),
                        color: _sendNotification
                            ? AppTheme.primaryColor
                            : (isDark ? Colors.white54 : Colors.black54),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      l10n.eventSendNotif,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.eventSendNotifSub,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ),
                    value: _sendNotification,
                    onChanged: (v) => setState(() => _sendNotification = v),
                    activeColor: Colors.white,
                    activeTrackColor: AppTheme.primaryColor,
                  ),
                ),
              ],

              const SizedBox(height: 48),

              // Save button
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEdit ? l10n.save : l10n.createGiveaway,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  String _prizeLabel(String type, AppLocalizations l10n) {
    switch (type) {
      case 'account':
        return l10n.prizeAccount;
      case 'subscription':
        return l10n.prizeSubscription;
      case 'code':
        return l10n.prizeCode;
      default:
        return l10n.prizeOther;
    }
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 0.5,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
    String? helperText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: AppTheme.primaryColor,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.white54 : Colors.black54,
          fontWeight: FontWeight.w500,
        ),
        helperText: helperText,
        helperStyle: TextStyle(
          color: isDark ? Colors.white38 : Colors.black38,
          fontSize: 12,
        ),
        prefixIcon: Icon(
          icon,
          size: 20,
          color: AppTheme.primaryColor.withValues(alpha: 0.8),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
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
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.errorColor, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard.withValues(alpha: 0.6) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: child,
    );
  }
}
