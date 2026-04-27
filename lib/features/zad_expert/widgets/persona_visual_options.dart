import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../zad_expert_screen.dart' show personaIconFromName;

/// A single icon choice surfaced in admin pickers.
class PersonaIconOption {
  final String key;
  final String label;
  const PersonaIconOption(this.key, this.label);
  IconData get icon => personaIconFromName(key);
}

/// A single colour choice surfaced in admin pickers.
class PersonaColorOption {
  final String hex;
  final String label;
  const PersonaColorOption(this.hex, this.label);
  Color get color {
    var v = hex.replaceAll('#', '');
    if (v.length == 6) v = 'FF$v';
    return Color(int.parse(v, radix: 16));
  }
}

/// Curated set of icons used across personas + sub-modes. Ordered roughly
/// by category so the picker reads naturally.
const List<PersonaIconOption> kPersonaIconOptions = [
  // — Generic / smart —
  PersonaIconOption('sparkle', 'بريق'),
  PersonaIconOption('robot', 'روبوت'),
  PersonaIconOption('brain', 'دماغ'),
  PersonaIconOption('lightbulb', 'فكرة'),
  PersonaIconOption('magic', 'سحر'),
  PersonaIconOption('atom', 'ذرة'),
  // — Diagrams —
  PersonaIconOption('treeStructure', 'هيكل شجري'),
  PersonaIconOption('flowArrow', 'تدفق'),
  PersonaIconOption('database', 'قاعدة بيانات'),
  PersonaIconOption('sequence', 'تسلسل'),
  PersonaIconOption('class', 'فئات'),
  PersonaIconOption('architecture', 'معمارية'),
  PersonaIconOption('stack', 'طبقات'),
  PersonaIconOption('chart', 'مخطط'),
  // — Code / dev —
  PersonaIconOption('code', 'كود'),
  PersonaIconOption('terminal', 'طرفية'),
  PersonaIconOption('gitBranch', 'فرع'),
  PersonaIconOption('package', 'حزمة'),
  PersonaIconOption('cloud', 'سحابة'),
  PersonaIconOption('bug', 'خطأ'),
  PersonaIconOption('gear', 'ترس'),
  PersonaIconOption('hammer', 'مطرقة'),
  // — Creative —
  PersonaIconOption('paintBrush', 'فرشاة'),
  PersonaIconOption('palette', 'لوحة ألوان'),
  PersonaIconOption('pencilLine', 'قلم'),
  PersonaIconOption('image', 'صورة'),
  PersonaIconOption('video', 'فيديو'),
  // — Knowledge / business —
  PersonaIconOption('graduationCap', 'تعليم'),
  PersonaIconOption('book', 'كتاب'),
  PersonaIconOption('briefcase', 'حقيبة'),
  PersonaIconOption('chatCircle', 'محادثة'),
  PersonaIconOption('megaphone', 'مكبر صوت'),
  // — Symbols —
  PersonaIconOption('shield', 'درع'),
  PersonaIconOption('key', 'مفتاح'),
  PersonaIconOption('rocket', 'صاروخ'),
  PersonaIconOption('rocketLaunch', 'إطلاق'),
  PersonaIconOption('target', 'هدف'),
  PersonaIconOption('compass', 'بوصلة'),
  PersonaIconOption('globe', 'كرة أرضية'),
  PersonaIconOption('crown', 'تاج'),
  PersonaIconOption('trophy', 'كأس'),
  PersonaIconOption('fire', 'نار'),
  PersonaIconOption('flask', 'قارورة'),
  PersonaIconOption('microscope', 'مجهر'),
];

/// Curated palette — vibrant, accessible, distinct hues.
const List<PersonaColorOption> kPersonaColorOptions = [
  PersonaColorOption('#6366F1', 'بنفسجي'),
  PersonaColorOption('#8B5CF6', 'أرجواني'),
  PersonaColorOption('#A855F7', 'ليلكي'),
  PersonaColorOption('#EC4899', 'وردي'),
  PersonaColorOption('#F43F5E', 'وردي حار'),
  PersonaColorOption('#EF4444', 'أحمر'),
  PersonaColorOption('#F97316', 'برتقالي'),
  PersonaColorOption('#F59E0B', 'ذهبي'),
  PersonaColorOption('#EAB308', 'أصفر'),
  PersonaColorOption('#84CC16', 'ليموني'),
  PersonaColorOption('#22C55E', 'أخضر فاتح'),
  PersonaColorOption('#10B981', 'أخضر'),
  PersonaColorOption('#14B8A6', 'تركواز'),
  PersonaColorOption('#06B6D4', 'سماوي'),
  PersonaColorOption('#0EA5E9', 'أزرق فاتح'),
  PersonaColorOption('#3B82F6', 'أزرق'),
  PersonaColorOption('#6B7280', 'رمادي'),
  PersonaColorOption('#1F2937', 'فحمي'),
];

// ────────────────────────────────────────────────────────────────────────────
// Reusable visual icon picker — wraps all available icons, single tap to pick.
// ────────────────────────────────────────────────────────────────────────────
class PersonaIconPicker extends StatelessWidget {
  final String selected;
  final Color highlight;
  final bool isDark;
  final ValueChanged<String> onPick;

  const PersonaIconPicker({
    super.key,
    required this.selected,
    required this.highlight,
    required this.isDark,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final opt in kPersonaIconOptions)
          _IconChip(
            opt: opt,
            isSelected: opt.key == selected,
            highlight: highlight,
            isDark: isDark,
            onTap: () => onPick(opt.key),
          ),
      ],
    );
  }
}

class _IconChip extends StatelessWidget {
  final PersonaIconOption opt;
  final bool isSelected;
  final Color highlight;
  final bool isDark;
  final VoidCallback onTap;

  const _IconChip({
    required this.opt,
    required this.isSelected,
    required this.highlight,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: opt.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        highlight,
                        highlight.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected
                  ? null
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? highlight
                    : (isDark
                        ? AppTheme.darkDivider
                        : AppTheme.lightDivider),
                width: isSelected ? 1.6 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: highlight.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              opt.icon,
              size: 21,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Reusable visual color palette — circular swatches with check on selection.
// ────────────────────────────────────────────────────────────────────────────
class PersonaColorPalette extends StatelessWidget {
  final String selected;
  final bool isDark;
  final ValueChanged<String> onPick;

  const PersonaColorPalette({
    super.key,
    required this.selected,
    required this.isDark,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final opt in kPersonaColorOptions)
          _ColorDot(
            opt: opt,
            isSelected: opt.hex == selected,
            isDark: isDark,
            onTap: () => onPick(opt.hex),
          ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  final PersonaColorOption opt;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ColorDot({
    required this.opt,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${opt.label}  •  ${opt.hex}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [opt.color, opt.color.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? (isDark ? Colors.white : Colors.black87)
                  : Colors.transparent,
              width: 2.4,
            ),
            boxShadow: [
              BoxShadow(
                color: opt.color
                    .withValues(alpha: isSelected ? 0.55 : 0.25),
                blurRadius: isSelected ? 14 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: isSelected
              ? const Center(
                  child: Icon(Icons.check, size: 18, color: Colors.white),
                )
              : null,
        ),
      ),
    );
  }
}
