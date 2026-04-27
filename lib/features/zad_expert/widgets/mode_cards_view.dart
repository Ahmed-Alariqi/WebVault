import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/ai_persona_mode.dart';
import '../../../data/models/ai_persona_model.dart';
import '../zad_expert_screen.dart' show hexToColor, personaIconFromName;

/// Welcome screen variant shown when a persona declares specialised modes.
///
/// Lays out one card per visible mode. Tapping a card invokes [onSelect] —
/// the parent screen is responsible for activating the mode (writing to the
/// `selectedModeProvider`) and starting a fresh chat session.
class ModeCardsView extends StatelessWidget {
  final AiPersonaModel persona;
  final Color personaColor;
  final bool isDark;
  final ValueChanged<AiPersonaMode> onSelect;

  const ModeCardsView({
    super.key,
    required this.persona,
    required this.personaColor,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final modes = persona.visibleModes;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Persona header ────────────────────────────────────────
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [personaColor, personaColor.withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: personaColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(personaIconFromName(persona.icon),
                  color: Colors.white, size: 36),
            )
                .animate()
                .scale(
                    begin: const Offset(0.7, 0.7),
                    curve: Curves.easeOutBack,
                    duration: 400.ms)
                .fadeIn(),
          ),
          const SizedBox(height: 14),
          Text(
            persona.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
              fontFamily: 'Cairo',
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 4),
          Text(
            persona.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black45,
              fontFamily: 'Cairo',
            ),
          ).animate().fadeIn(delay: 180.ms),

          const SizedBox(height: 22),

          // ── Section title ─────────────────────────────────────────
          Row(
            children: [
              Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                  size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'اختر تخصصاً للبدء',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                  fontFamily: 'Cairo',
                ),
              ),
              const Spacer(),
              Text(
                '${modes.length} أوضاع',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ).animate().fadeIn(delay: 240.ms),
          const SizedBox(height: 10),

          // ── Mode cards grid (2 columns) ───────────────────────────
          LayoutBuilder(
            builder: (ctx, c) {
              final isWide = c.maxWidth >= 520;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (int i = 0; i < modes.length; i++)
                    SizedBox(
                      width: isWide
                          ? (c.maxWidth - 10) / 2
                          : c.maxWidth,
                      child: _ModeCard(
                        mode: modes[i],
                        isDark: isDark,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onSelect(modes[i]);
                        },
                      )
                          .animate()
                          .fadeIn(delay: (300 + i * 70).ms, duration: 280.ms)
                          .slideY(begin: 0.08, delay: (300 + i * 70).ms),
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 22),

          // ── Hint footer ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: Row(
              children: [
                Icon(PhosphorIcons.info(),
                    size: 16,
                    color: isDark ? Colors.white54 : Colors.black54),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'كل وضع يمنح الخبير منهجية متخصصة وقالب إخراج خاص. يمكنك تغيير الوضع لاحقاً من شريط المحادثة.',
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.5,
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (300 + modes.length * 70 + 120).ms),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final AiPersonaMode mode;
  final bool isDark;
  final VoidCallback onTap;

  const _ModeCard({
    required this.mode,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final modeColor = hexToColor(mode.color);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? modeColor.withValues(alpha: 0.10)
                : modeColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: modeColor.withValues(alpha: 0.25),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [modeColor, modeColor.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(personaIconFromName(mode.icon),
                        color: Colors.white, size: 20),
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black87,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                            if (mode.isDefault) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: modeColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'موصى به',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: modeColor,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(PhosphorIcons.arrowLeft(),
                      size: 16,
                      color: isDark ? Colors.white38 : Colors.black26),
                ],
              ),
              if (mode.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  mode.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.5,
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
