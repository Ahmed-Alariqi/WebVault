import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/poll_model.dart';
import '../../presentation/providers/events_providers.dart';
import '../../presentation/providers/admin_providers.dart';
import '../../l10n/app_localizations.dart';

class EditPollSheet extends ConsumerStatefulWidget {
  final Poll? poll;
  const EditPollSheet({super.key, this.poll});

  @override
  ConsumerState<EditPollSheet> createState() => _EditPollSheetState();
}

class _EditPollSheetState extends ConsumerState<EditPollSheet> {
  final _formKey = GlobalKey<FormState>();
  final _questionCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final List<TextEditingController> _optionCtrls = [];
  DateTime? _endsAt;
  bool _allowMultiple = false;
  bool _isLoading = false;
  bool _sendNotification = false;

  @override
  void initState() {
    super.initState();
    final p = widget.poll;
    if (p != null) {
      _questionCtrl.text = p.question;
      _descCtrl.text = p.description ?? '';
      _endsAt = p.endsAt;
      _allowMultiple = p.allowMultiple;
      for (final opt in p.options) {
        _optionCtrls.add(TextEditingController(text: opt));
      }
    }
    // Ensure at least 2 options
    while (_optionCtrls.length < 2) {
      _optionCtrls.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _descCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionCtrls.length >= 6) return;
    setState(() => _optionCtrls.add(TextEditingController()));
  }

  void _removeOption(int index) {
    if (_optionCtrls.length <= 2) return;
    setState(() {
      _optionCtrls[index].dispose();
      _optionCtrls.removeAt(index);
    });
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

    final options = _optionCtrls
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.minTwoOptions)),
      );
      return;
    }

    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final data = {
        'question': _questionCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        'options': options,
        'ends_at': _endsAt!.toIso8601String(),
        'allow_multiple': _allowMultiple,
      };

      if (widget.poll == null) {
        final newId = await createPoll(data, ref);

        // Send notification if toggled on
        if (_sendNotification) {
          try {
            await adminSendNotification({
              'title': '📊 ${_questionCtrl.text.trim()}',
              'body': l10n.notifBodyPoll,
              'type': 'poll',
              'target_url': 'app://events/poll/$newId',
            });
          } catch (_) {
            // Notification failure shouldn't block save
          }
        }
      } else {
        await updatePoll(widget.poll!.id, data, ref);
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
      initialDate: _endsAt ?? DateTime.now().add(const Duration(days: 3)),
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
    final isEdit = widget.poll != null;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(
          isEdit ? l10n.editPoll : l10n.createPoll,
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
              // Question
              _buildField(
                controller: _questionCtrl,
                label: l10n.pollQuestion,
                icon: PhosphorIcons.question(),
                isDark: isDark,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? l10n.required : null,
              ),
              const SizedBox(height: 16),

              // Description
              _buildField(
                controller: _descCtrl,
                label: l10n.pollDescription,
                icon: PhosphorIcons.textAa(),
                isDark: isDark,
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Options
              _buildCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          PhosphorIcons.listBullets(),
                          size: 20,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.pollOptions,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_optionCtrls.length}/6',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    ..._optionCtrls.asMap().entries.map((entry) {
                      final i = entry.key;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF7C3AED,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF7C3AED),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: entry.value,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: '${l10n.option} ${i + 1}',
                                  hintStyle: TextStyle(
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.black26,
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : Colors.black.withValues(alpha: 0.02),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                ),
                                validator: (v) {
                                  if (i < 2 &&
                                      (v == null || v.trim().isEmpty)) {
                                    return l10n.required;
                                  }
                                  return null;
                                },
                              ),
                            ),
                            if (_optionCtrls.length > 2)
                              IconButton(
                                icon: Icon(
                                  PhosphorIcons.xCircle(),
                                  size: 20,
                                  color: AppTheme.errorColor.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                onPressed: () => _removeOption(i),
                              ),
                          ],
                        ),
                      );
                    }),

                    if (_optionCtrls.length < 6)
                      TextButton.icon(
                        onPressed: _addOption,
                        icon: Icon(PhosphorIcons.plus(), size: 18),
                        label: Text(l10n.addOption),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF7C3AED),
                        ),
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
                  subtitle: Text(l10n.pollEndDateDesc),
                  trailing: Icon(PhosphorIcons.caretRight(), size: 18),
                  onTap: _pickEndDate,
                ),
              ),
              const SizedBox(height: 16),

              // Allow multiple
              _buildCard(
                isDark: isDark,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.allowMultiple,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(l10n.allowMultipleDesc),
                  value: _allowMultiple,
                  onChanged: (v) => setState(() => _allowMultiple = v),
                  activeThumbColor: const Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(height: 16),

              // Notification toggle (only for new polls)
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

              // Save
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
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
                        isEdit ? l10n.save : l10n.createPoll,
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
