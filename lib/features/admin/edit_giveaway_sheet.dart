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
  String _prizeType = 'other';
  DateTime? _endsAt;
  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0;
  bool _sendNotification = false;

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
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _imageCtrl.dispose();
    _maxEntriesCtrl.dispose();
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
        'ends_at': _endsAt!.toIso8601String(),
        'max_entries': _maxEntriesCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(_maxEntriesCtrl.text.trim()),
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
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        forceMaterialTransparency: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              _buildField(
                controller: _titleCtrl,
                label: l10n.giveawayTitle,
                icon: PhosphorIcons.textT(),
                isDark: isDark,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? l10n.required : null,
              ),
              const SizedBox(height: 16),

              // Description
              _buildField(
                controller: _descCtrl,
                label: l10n.giveawayDescription,
                icon: PhosphorIcons.textAa(),
                isDark: isDark,
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Image
              _buildCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.prizeImage,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
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
                                              folder: '/giveaways',
                                              onProgress: (p) {
                                                if (mounted)
                                                  setState(
                                                    () => _uploadProgress = p,
                                                  );
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
                                        if (mounted)
                                          setState(() => _isUploading = false);
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
                                      ),
                                    )
                                  : const Icon(Icons.upload, size: 18),
                              label: Text(l10n.upload),
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
                                size: 18,
                              ),
                              label: Text(l10n.searchImage),
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
                        padding: const EdgeInsets.only(top: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _imageCtrl.text,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Prize Type
              _buildCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.prizeType,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: ['account', 'subscription', 'code', 'other']
                          .map(
                            (type) => ChoiceChip(
                              label: Text(_prizeLabel(type, l10n)),
                              selected: _prizeType == type,
                              onSelected: (_) =>
                                  setState(() => _prizeType = type),
                              selectedColor: AppTheme.primaryColor.withValues(
                                alpha: 0.2,
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
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // End date
              _buildCard(
                isDark: isDark,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    PhosphorIcons.calendarBlank(),
                    color: AppTheme.primaryColor,
                  ),
                  title: Text(
                    _endsAt != null
                        ? DateFormat('MMM d, yyyy • h:mm a').format(_endsAt!)
                        : l10n.selectEndDate,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _endsAt != null
                          ? (isDark ? Colors.white : Colors.black87)
                          : (isDark ? Colors.white38 : Colors.black38),
                    ),
                  ),
                  subtitle: Text(l10n.endDateDesc),
                  trailing: Icon(PhosphorIcons.caretRight(), size: 18),
                  onTap: _pickEndDate,
                ),
              ),
              const SizedBox(height: 16),

              // Max entries
              _buildField(
                controller: _maxEntriesCtrl,
                label: l10n.maxEntries,
                icon: PhosphorIcons.usersThree(),
                isDark: isDark,
                keyboardType: TextInputType.number,
                helperText: l10n.maxEntriesHint,
              ),
              const SizedBox(height: 16),

              // Notification toggle (only for new giveaways)
              if (!isEdit)
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        PhosphorIcons.bellRinging(),
                        color: _sendNotification
                            ? AppTheme.primaryColor
                            : (isDark ? Colors.white38 : Colors.black38),
                        size: 22,
                      ),
                    ),
                    title: Text(
                      l10n.eventSendNotif,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      l10n.eventSendNotifSub,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black45,
                      ),
                    ),
                    value: _sendNotification,
                    onChanged: (v) => setState(() => _sendNotification = v),
                    activeColor: AppTheme.primaryColor,
                  ),
                ),

              const SizedBox(height: 32),

              // Save button
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE11D48),
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
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEdit ? l10n.save : l10n.createGiveaway,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        helperStyle: TextStyle(
          color: isDark ? Colors.white38 : Colors.black38,
          fontSize: 11,
        ),
        prefixIcon: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white54 : Colors.black54,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.04)
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
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
