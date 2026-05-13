import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/ai_persona_model.dart';
import '../../presentation/providers/referral_providers.dart';
import '../discover/widgets/premium_unlock_sheet.dart';
import 'zad_expert_screen.dart' show hexToColor, personaIconFromName;
import '../../presentation/providers/membership_providers.dart';

/// Bottom sheet for choosing a persona — card grid layout.
class PersonaSelectorSheet extends ConsumerWidget {
  final List<AiPersonaModel> personas;
  final String? selectedSlug;
  final ValueChanged<AiPersonaModel> onSelect;

  const PersonaSelectorSheet({
    super.key,
    required this.personas,
    required this.selectedSlug,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(12),
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                      size: 20,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'اختر شخصية الخبير',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),

              const SizedBox(height: 4),

              // Grid
              Flexible(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.05,
                  ),
                  itemCount: personas.length,
                  itemBuilder: (ctx, i) {
                    final p = personas[i];
                    final color = hexToColor(p.color);
                    final isSelected = p.slug == selectedSlug;
                    final isPremium = p.isPremium;
                    final memStatus = ref.watch(membershipStatusProvider);
                    final hasAccess = !isPremium || memStatus.hasAccessTo(type: 'persona', id: p.id);
                    final isAdmin = memStatus.isAdmin;

                    return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          // In the selector, we always allow admins to enter, but we show the sheet if they aren't admin and don't have access.
                          if (!hasAccess && !isAdmin) {
                            _showPremiumLock(context, ref, isDark, p);
                            return;
                          }
                          onSelect(p);
                        },
                      child: Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: double.infinity,
                            height: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [
                                        color.withValues(alpha: 0.2),
                                        color.withValues(alpha: 0.08),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isSelected
                                  ? null
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : Colors.black.withValues(alpha: 0.02)),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? color.withValues(alpha: 0.5)
                                    : (isPremium && !hasAccess
                                        ? Colors.amber.withValues(alpha: 0.3)
                                        : (isDark
                                            ? Colors.white.withValues(alpha: 0.06)
                                            : Colors.black.withValues(alpha: 0.05))),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.2),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    personaIconFromName(p.icon),
                                    color: color,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  p.name,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontFamily: 'Cairo',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          
                          // Pro Badge
                          if (isPremium)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      PhosphorIcons.crown(PhosphorIconsStyle.fill),
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 2),
                                    const Text(
                                      'PRO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                          // Lock Icon for gated content
                          if (isPremium && (!hasAccess || isAdmin))
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Icon(
                                isAdmin && hasAccess 
                                  ? PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill) // Admin sees a shield instead of a lock if they have access
                                  : PhosphorIcons.lockSimple(PhosphorIconsStyle.fill),
                                size: 16,
                                color: isAdmin 
                                  ? AppTheme.primaryColor.withValues(alpha: 0.5)
                                  : (isDark ? Colors.white24 : Colors.black12),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPremiumLock(BuildContext context, WidgetRef ref, bool isDark, AiPersonaModel persona) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PremiumFeatureSheet(
        title: 'شخصيات خبير زاد PRO 👑',
        description: 'الوصول إلى شخصية "${persona.name}" يتطلب تفعيل العضوية. يمكنك فتحها الآن من خلال دعوة أصدقائك للتطبيق.',
        icon: PhosphorIcons.brain(PhosphorIconsStyle.fill),
        onAction: () async {
          HapticFeedback.lightImpact();
          await shareViralInvitation(ref);
        },
        actionLabel: 'ادعُ أصدقاءك لفتح الميزة',
        themeColor: const Color(0xFFF59E0B),
        isDark: isDark,
      ),
    );
  }
}
