import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/ai_persona_mode.dart';
import '../../data/models/ai_persona_model.dart';
import '../../data/services/zad_expert_service.dart';
import '../../presentation/providers/zad_expert_providers.dart';
import '../zad_expert/zad_expert_screen.dart' show personaIconFromName, hexToColor;
import '../zad_expert/widgets/persona_visual_options.dart';

/// Bottom sheet that lets the admin manage the sub-persona modes attached to
/// an [AiPersonaModel]. Modes are stored as a JSONB array on the persona row;
/// every save here re-writes the whole array.
class AdminPersonaModesSheet extends ConsumerStatefulWidget {
  final AiPersonaModel persona;
  final bool isDark;

  const AdminPersonaModesSheet({
    super.key,
    required this.persona,
    required this.isDark,
  });

  static Future<void> show(
      BuildContext context, AiPersonaModel persona, bool isDark) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdminPersonaModesSheet(persona: persona, isDark: isDark),
    );
  }

  @override
  ConsumerState<AdminPersonaModesSheet> createState() =>
      _AdminPersonaModesSheetState();
}

class _AdminPersonaModesSheetState
    extends ConsumerState<AdminPersonaModesSheet> {
  late List<AiPersonaMode> _modes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _modes = List.of(widget.persona.visibleModes.isEmpty
        ? widget.persona.modes
        : widget.persona.modes); // preserve original order incl. disabled
    _modes.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  bool get _isDark => widget.isDark;

  Future<void> _persist() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final updated = AiPersonaModel(
        id: widget.persona.id,
        name: widget.persona.name,
        slug: widget.persona.slug,
        description: widget.persona.description,
        icon: widget.persona.icon,
        color: widget.persona.color,
        systemInstruction: widget.persona.systemInstruction,
        providerId: widget.persona.providerId,
        modelId: widget.persona.modelId,
        temperature: widget.persona.temperature,
        maxTokens: widget.persona.maxTokens,
        isActive: widget.persona.isActive,
        sortOrder: widget.persona.sortOrder,
        quickActions: widget.persona.quickActions,
        modes: _normalisedModes(),
      );
      await ZadExpertService.savePersona(updated, existingId: widget.persona.id);
      ref.invalidate(adminAllPersonasProvider);
      ref.invalidate(expertPersonasProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم حفظ الأوضاع ✅'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('فشل الحفظ: $e'),
              backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Re-assigns sort_order based on current list position and ensures at most
  /// one default. Called before save to keep DB consistent.
  List<AiPersonaMode> _normalisedModes() {
    bool foundDefault = false;
    return [
      for (int i = 0; i < _modes.length; i++)
        () {
          var m = _modes[i].copyWith(sortOrder: i);
          if (m.isDefault) {
            if (foundDefault) {
              m = m.copyWith(isDefault: false);
            } else {
              foundDefault = true;
            }
          }
          return m;
        }(),
    ];
  }

  void _toggleEnabled(int i) {
    setState(() {
      _modes[i] = _modes[i].copyWith(enabled: !_modes[i].enabled);
    });
  }

  void _setAsDefault(int i) {
    setState(() {
      for (int j = 0; j < _modes.length; j++) {
        _modes[j] = _modes[j].copyWith(isDefault: j == i);
      }
    });
  }

  void _delete(int i) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الوضع؟'),
        content: Text('سيُحذف "${_modes[i].name}" نهائياً من هذه الشخصية.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _modes.removeAt(i));
    }
  }

  void _move(int from, int to) {
    if (to < 0 || to >= _modes.length) return;
    setState(() {
      final m = _modes.removeAt(from);
      _modes.insert(to, m);
    });
  }

  Future<void> _editMode({AiPersonaMode? existing, int? index}) async {
    final result = await showModalBottomSheet<AiPersonaMode>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModeEditorSheet(
        existing: existing,
        usedKeys: [
          for (int i = 0; i < _modes.length; i++)
            if (i != index) _modes[i].key,
        ],
        isDark: _isDark,
      ),
    );
    if (result == null) return;
    setState(() {
      if (index == null) {
        _modes.add(result);
      } else {
        _modes[index] = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final maxH = mq.size.height * 0.92;
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        height: maxH,
        decoration: BoxDecoration(
          color: _isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // ── Drag handle + title row ──────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Row(
                children: [
                  Icon(PhosphorIcons.squaresFour(PhosphorIconsStyle.fill),
                      color: const Color(0xFF8B5CF6), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('أوضاع: ${widget.persona.name}',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color:
                                    _isDark ? Colors.white : Colors.black87)),
                        Text('${_modes.length} أوضاع',
                            style: TextStyle(
                                fontSize: 11,
                                color: _isDark
                                    ? Colors.white54
                                    : Colors.black45)),
                      ],
                    ),
                  ),
                  TextButton(
                      onPressed:
                          _saving ? null : () => Navigator.pop(context),
                      child: const Text('إلغاء')),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: _saving ? null : _persist,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('حفظ'),
                  ),
                ],
              ),
            ),
            const Divider(),

            // ── Modes list ───────────────────────────────────────
            Expanded(
              child: _modes.isEmpty
                  ? _emptyState()
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      itemCount: _modes.length,
                      onReorder: (a, b) {
                        var dest = b;
                        if (dest > a) dest -= 1;
                        _move(a, dest);
                      },
                      itemBuilder: (ctx, i) {
                        final m = _modes[i];
                        return _ModeRow(
                          key: ValueKey('mode-${m.key}-$i'),
                          mode: m,
                          isDark: _isDark,
                          onTap: () => _editMode(existing: m, index: i),
                          onToggle: () => _toggleEnabled(i),
                          onSetDefault: () => _setAsDefault(i),
                          onDelete: () => _delete(i),
                          onDuplicate: () {
                            final dup = m.copyWith(
                              key: '${m.key}_copy',
                              name: '${m.name} (نسخة)',
                              isDefault: false,
                            );
                            setState(() => _modes.insert(i + 1, dup));
                          },
                        );
                      },
                    ),
            ),

            // ── Add button ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : () => _editMode(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(
                        color:
                            const Color(0xFF8B5CF6).withValues(alpha: 0.5)),
                    foregroundColor: const Color(0xFF8B5CF6),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إضافة وضع جديد'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIcons.squaresFour(),
              size: 56, color: _isDark ? Colors.white24 : Colors.black26),
          const SizedBox(height: 10),
          Text('لا توجد أوضاع لهذه الشخصية',
              style: TextStyle(
                  color: _isDark ? Colors.white60 : Colors.black54,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'الشخصية ستعمل بسلوكها العام (التعليمة الأساسية و quickActions). أضف أوضاعاً لتقسيمها إلى تخصصات احترافية.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: _isDark ? Colors.white54 : Colors.black45),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// One row in the modes list
// ────────────────────────────────────────────────────────────────────────────
class _ModeRow extends StatelessWidget {
  final AiPersonaMode mode;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const _ModeRow({
    super.key,
    required this.mode,
    required this.isDark,
    required this.onTap,
    required this.onToggle,
    required this.onSetDefault,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(mode.color);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: mode.isDefault
              ? color.withValues(alpha: 0.55)
              : (isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
          width: mode.isDefault ? 1.4 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
            child: Row(
              children: [
                Icon(PhosphorIcons.dotsSixVertical(),
                    size: 18,
                    color: isDark ? Colors.white38 : Colors.black26),
                const SizedBox(width: 6),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      color,
                      color.withValues(alpha: 0.7),
                    ]),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(personaIconFromName(mode.icon),
                      color: Colors.white, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              mode.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color:
                                    isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          if (mode.isDefault) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('افتراضي',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: color)),
                            ),
                          ],
                          if (!mode.enabled) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.redAccent
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('معطّل',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.redAccent)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mode.key,
                        style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: isDark
                                ? Colors.white38
                                : Colors.black38),
                      ),
                      if (mode.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          mode.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.black54),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(PhosphorIcons.dotsThreeVertical(),
                      color: isDark ? Colors.white54 : Colors.black54,
                      size: 18),
                  color: isDark ? AppTheme.darkCard : Colors.white,
                  onSelected: (v) {
                    switch (v) {
                      case 'default':
                        onSetDefault();
                        break;
                      case 'toggle':
                        onToggle();
                        break;
                      case 'duplicate':
                        onDuplicate();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    if (!mode.isDefault)
                      const PopupMenuItem(
                          value: 'default',
                          child: Text('تعيين افتراضياً')),
                    PopupMenuItem(
                        value: 'toggle',
                        child:
                            Text(mode.enabled ? 'تعطيل' : 'تفعيل')),
                    const PopupMenuItem(
                        value: 'duplicate', child: Text('تكرار')),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('حذف',
                            style: TextStyle(color: Colors.redAccent))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Modal for adding / editing a single mode (visual editor with live preview)
// ────────────────────────────────────────────────────────────────────────────
class _ModeEditorSheet extends StatefulWidget {
  final AiPersonaMode? existing;
  final List<String> usedKeys;
  final bool isDark;

  const _ModeEditorSheet({
    required this.existing,
    required this.usedKeys,
    required this.isDark,
  });

  @override
  State<_ModeEditorSheet> createState() => _ModeEditorSheetState();
}

class _ModeEditorSheetState extends State<_ModeEditorSheet> {
  late TextEditingController _key;
  late TextEditingController _name;
  late TextEditingController _description;
  late TextEditingController _systemPrompt;
  late TextEditingController _outputTemplate;
  // Inline add-action form
  final TextEditingController _newActionLabel = TextEditingController();
  final TextEditingController _newActionPrompt = TextEditingController();

  late String _selectedIcon;
  late String _selectedColor;
  late List<Map<String, String>> _quickActions;
  late bool _isDefault;
  late bool _enabled;

  String? _err;

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _key = TextEditingController(text: m?.key ?? '');
    _name = TextEditingController(text: m?.name ?? '');
    _description = TextEditingController(text: m?.description ?? '');
    _systemPrompt = TextEditingController(text: m?.systemPrompt ?? '');
    _outputTemplate = TextEditingController(text: m?.outputTemplate ?? '');
    _selectedIcon = m?.icon ?? 'sparkle';
    _selectedColor = m?.color ?? '#8B5CF6';
    _quickActions = [
      for (final a in (m?.quickActions ?? const <Map<String, String>>[]))
        {'label': a['label'] ?? '', 'prompt': a['prompt'] ?? ''}
    ];
    _isDefault = m?.isDefault ?? false;
    _enabled = m?.enabled ?? true;

    // Live-preview redraw when name/description change.
    _name.addListener(() => setState(() {}));
    _description.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [
      _key,
      _name,
      _description,
      _systemPrompt,
      _outputTemplate,
      _newActionLabel,
      _newActionPrompt,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isDark => widget.isDark;
  Color get _color => hexToColor(_selectedColor);

  void _save() {
    final key = _key.text.trim();
    final name = _name.text.trim();
    if (key.isEmpty || name.isEmpty) {
      setState(() => _err = 'المفتاح والاسم مطلوبان');
      return;
    }
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(key)) {
      setState(() => _err = 'المفتاح يجب أن يكون a-z, 0-9, _ فقط');
      return;
    }
    if (widget.usedKeys.contains(key)) {
      setState(() => _err = 'هذا المفتاح مستخدم في وضع آخر');
      return;
    }

    final mode = AiPersonaMode(
      key: key,
      name: name,
      icon: _selectedIcon,
      color: _selectedColor,
      description: _description.text.trim(),
      systemPrompt: _systemPrompt.text.trim(),
      outputTemplate: _outputTemplate.text.trim(),
      quickActions: List<Map<String, String>>.from(_quickActions),
      isDefault: _isDefault,
      enabled: _enabled,
      sortOrder: widget.existing?.sortOrder ?? 0,
    );
    Navigator.pop(context, mode);
  }

  void _addAction() {
    final l = _newActionLabel.text.trim();
    final p = _newActionPrompt.text.trim();
    if (l.isEmpty || p.isEmpty) return;
    setState(() {
      _quickActions.add({'label': l, 'prompt': p});
      _newActionLabel.clear();
      _newActionPrompt.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        height: mq.size.height * 0.94,
        decoration: BoxDecoration(
          color: _isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // ── Drag handle ────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // ── Title bar ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Row(
                children: [
                  Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                      color: _color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.existing != null
                          ? 'تعديل وضع'
                          : 'إضافة وضع جديد',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء')),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('حفظ'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (_err != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline,
                      color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(_err!,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 12))),
                ]),
              ),

            // ── Body ───────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                children: [
                  // Live preview card
                  _previewCard(),
                  const SizedBox(height: 18),

                  // Identity (key + name)
                  _section('الهوية', PhosphorIcons.identificationCard()),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        flex: 2,
                        child: _txt('الاسم', _name,
                            hint: 'مثال: تصميم ERD')),
                    const SizedBox(width: 10),
                    Expanded(
                        flex: 2,
                        child: _txt('المفتاح (key)', _key,
                            hint: 'erd / flowchart',
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-z0-9_]')),
                            ])),
                  ]),
                  const SizedBox(height: 10),
                  _txt('الوصف القصير', _description,
                      maxLines: 2,
                      hint: 'وصف مختصر يظهر داخل بطاقة الوضع'),
                  const SizedBox(height: 22),

                  // Visual identity
                  _section('الأيقونة', PhosphorIcons.shapes()),
                  const SizedBox(height: 8),
                  PersonaIconPicker(
                    selected: _selectedIcon,
                    highlight: _color,
                    isDark: _isDark,
                    onPick: (k) => setState(() => _selectedIcon = k),
                  ),
                  const SizedBox(height: 22),

                  _section('اللون', PhosphorIcons.palette()),
                  const SizedBox(height: 8),
                  PersonaColorPalette(
                    selected: _selectedColor,
                    isDark: _isDark,
                    onPick: (h) => setState(() => _selectedColor = h),
                  ),
                  const SizedBox(height: 22),

                  // Behaviour switches
                  _section('السلوك', PhosphorIcons.toggleRight()),
                  const SizedBox(height: 4),
                  Row(children: [
                    Expanded(
                      child: _switchTile(
                        'افتراضي',
                        'يُختار تلقائياً عند فتح الشخصية',
                        _isDefault,
                        (v) => setState(() => _isDefault = v),
                        _color,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _switchTile(
                        'مفعّل',
                        'يظهر للمستخدمين',
                        _enabled,
                        (v) => setState(() => _enabled = v),
                        AppTheme.successColor,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 22),

                  // System prompt
                  _section('تعليمة الوضع', PhosphorIcons.brain(),
                      hint: 'منهجية الوضع التي ستُضاف فوق التعليمة الأم'),
                  const SizedBox(height: 8),
                  _txt('System Prompt', _systemPrompt,
                      maxLines: 9,
                      hint:
                          'منهجية الوضع، المراحل، أسئلة قبل البدء، قواعد المخرج…'),
                  const SizedBox(height: 22),

                  // Output template
                  _section('قالب الإخراج', PhosphorIcons.fileText(),
                      hint: 'هيكل Markdown يلتزم به النموذج'),
                  const SizedBox(height: 8),
                  _txt('Output Template', _outputTemplate,
                      maxLines: 7,
                      hint:
                          'مثال: ## الفهم … ## التحليل … ```mermaid …```'),
                  const SizedBox(height: 22),

                  // Quick actions
                  _section(
                      'الاقتراحات السريعة (${_quickActions.length})',
                      PhosphorIcons.lightning(),
                      hint: 'تظهر كأزرار في الشاشة الفارغة عند تفعيل الوضع'),
                  const SizedBox(height: 8),
                  _quickActionsEditor(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Live preview that mirrors how the mode renders in ModeCardsView ──────
  Widget _previewCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _color.withValues(alpha: _isDark ? 0.18 : 0.10),
            _color.withValues(alpha: _isDark ? 0.06 : 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _color.withValues(alpha: 0.35),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: _color.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_color, _color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(personaIconFromName(_selectedIcon),
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(
                      _name.text.trim().isEmpty
                          ? 'اسم الوضع'
                          : _name.text.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  if (_isDefault) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('موصى به',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: _color)),
                    ),
                  ],
                ]),
                const SizedBox(height: 4),
                Text(
                  _description.text.trim().isEmpty
                      ? 'وصف مختصر يظهر تحت العنوان…'
                      : _description.text.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.5,
                    color: _isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Icon(PhosphorIcons.eye(),
              size: 14,
              color: _isDark ? Colors.white38 : Colors.black26),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  // ── Section heading ──────────────────────────────────────────────────────
  Widget _section(String title, IconData icon, {String? hint}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: _color),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _isDark ? Colors.white : Colors.black87)),
        if (hint != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                color: _isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Pretty switch tile ───────────────────────────────────────────────────
  Widget _switchTile(String title, String subtitle, bool value,
      ValueChanged<bool> onChanged, Color tint) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: value
              ? tint.withValues(alpha: 0.10)
              : (_isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value
                ? tint.withValues(alpha: 0.5)
                : (_isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
          ),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 10.5,
                        color: _isDark ? Colors.white54 : Colors.black54)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: tint,
          ),
        ]),
      ),
    );
  }

  // ── Quick actions visual editor ──────────────────────────────────────────
  Widget _quickActionsEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_quickActions.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: _isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _isDark
                      ? AppTheme.darkDivider
                      : AppTheme.lightDivider),
            ),
            child: Row(children: [
              Icon(PhosphorIcons.info(),
                  size: 14,
                  color: _isDark ? Colors.white54 : Colors.black45),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'لا توجد اقتراحات بعد. أضف اقتراحاً للمستخدم في الأسفل.',
                  style: TextStyle(
                      fontSize: 11,
                      color: _isDark ? Colors.white60 : Colors.black54),
                ),
              ),
            ]),
          )
        else
          for (int i = 0; i < _quickActions.length; i++)
            _actionRow(i, _quickActions[i]),
        const SizedBox(height: 10),
        // Add form
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: _isDark ? 0.06 : 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _color.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('إضافة اقتراح جديد',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: _color)),
              const SizedBox(height: 6),
              _txt('النص الظاهر للمستخدم', _newActionLabel,
                  hint: 'مثال: ابدأ بفكرة مشروع جديد'),
              const SizedBox(height: 8),
              _txt('الـ Prompt الكامل', _newActionPrompt,
                  maxLines: 3,
                  hint: 'النص الذي يُرسل للنموذج عند الضغط على الزر'),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addAction,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('إضافة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionRow(int i, Map<String, String> a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: _isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
      ),
      child: Row(children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('${i + 1}',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: _color)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a['label'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 2),
              Text(a['prompt'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 10.5,
                      color: _isDark ? Colors.white54 : Colors.black45)),
            ],
          ),
        ),
        IconButton(
          icon: Icon(PhosphorIcons.trash(),
              size: 16, color: Colors.redAccent),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'حذف',
          onPressed: () => setState(() => _quickActions.removeAt(i)),
        ),
      ]),
    );
  }

  Widget _txt(String label, TextEditingController c,
      {int maxLines = 1,
      String? hint,
      List<TextInputFormatter>? inputFormatters}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
                color: _isDark ? Colors.white70 : Colors.black54)),
        const SizedBox(height: 4),
        TextField(
          controller: c,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          textDirection: maxLines > 1 ? TextDirection.rtl : null,
          style: TextStyle(
              fontSize: 13,
              color: _isDark ? Colors.white : Colors.black87,
              height: 1.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: _isDark ? Colors.white24 : Colors.black26,
                fontSize: 11.5),
            isDense: true,
            filled: true,
            fillColor: _isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: _isDark
                    ? AppTheme.darkDivider
                    : AppTheme.lightDivider,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _color, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

// Visual icon/color pickers live in `persona_visual_options.dart` and are
// reused by both the persona editor and the modes editor.
