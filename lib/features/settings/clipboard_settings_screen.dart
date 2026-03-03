import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../presentation/providers/providers.dart';

class ClipboardSettingsScreen extends ConsumerStatefulWidget {
  const ClipboardSettingsScreen({super.key});

  @override
  ConsumerState<ClipboardSettingsScreen> createState() =>
      _ClipboardSettingsScreenState();
}

class _ClipboardSettingsScreenState
    extends ConsumerState<ClipboardSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final isAdvancedCopyEnabled =
        settings['isAdvancedCopyEnabled'] as bool? ?? false;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Premium header ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  PhosphorIcons.caretLeft(),
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Clipboard & Copy',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF009688),
                      Color(0xFF3F51B5),
                      Color(0xFF1A237E),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.04),
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child:
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                PhosphorIcons.clipboardText(
                                  PhosphorIconsStyle.fill,
                                ),
                                color: Colors.white,
                                size: 32,
                              ),
                            ).animate().scale(
                              duration: 500.ms,
                              curve: Curves.elasticOut,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Quick Access ──────────────────────────────────────
                _buildSectionHeader(
                  'Quick Access',
                  PhosphorIcons.lightning(),
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildCard(
                  isDark: isDark,
                  children: [
                    // How to add QS tile
                    _buildInstructionsTile(isDark),
                    _buildDivider(isDark),
                    // Usage tips
                    _buildUsageTipsTile(isDark),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Smart Clipboard ────────────────────────────────────
                _buildSectionHeader(
                  'Smart Clipboard',
                  PhosphorIcons.brain(),
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildCard(
                  isDark: isDark,
                  children: [
                    _buildSwitchTile(
                      icon: PhosphorIcons.clipboard(PhosphorIconsStyle.fill),
                      iconColor: const Color(0xFF3F51B5),
                      title: 'Smart Background Copy',
                      subtitle: isAdvancedCopyEnabled
                          ? 'Enabled — Saves everything you copy'
                          : 'Off — Manual save only',
                      value: isAdvancedCopyEnabled,
                      onChanged: (val) =>
                          settingsNotifier.setAdvancedCopyEnabled(val),
                    ),
                    _buildDivider(isDark),
                    _buildInfoTile(
                      isDark: isDark,
                      icon: PhosphorIcons.info(),
                      iconColor: const Color(0xFF3F51B5),
                      title: 'How Smart Copy works',
                      content:
                          'When enabled, any text you copy on your device '
                          '(outside of WebVault) is automatically detected and '
                          'saved to your WebVault clipboard in the background. '
                          'This requires the overlay permission to be granted.',
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Usage Tips ─────────────────────────────────────────
                _buildSectionHeader(
                  'How to Use',
                  PhosphorIcons.lightbulb(),
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildTipsCard(isDark),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── How to add QS tile ─────────────────────────────────────────────
  Widget _buildInstructionsTile(bool isDark) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF009688).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.widgets_rounded,
          color: Color(0xFF009688),
          size: 22,
        ),
      ),
      title: Text(
        'How to add the Quick Tile',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
        ),
      ),
      subtitle: Text(
        'Access clipboard from any screen',
        style: TextStyle(
          fontSize: 12,
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              _step(
                '1',
                'Swipe down twice to open Quick Settings panel',
                isDark,
              ),
              _step(
                '2',
                'Tap the pencil / edit icon to enter edit mode',
                isDark,
              ),
              _step(
                '3',
                'Find "WebVault Clipboard" and drag it into your tiles',
                isDark,
              ),
              _step(
                '4',
                'Tap the tile anytime to instantly open your clipboard!',
                isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Usage tips tile ───────────────────────────────────────────────
  Widget _buildUsageTipsTile(bool isDark) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          PhosphorIcons.lightbulb(PhosphorIconsStyle.fill),
          color: Colors.amber.shade700,
          size: 22,
        ),
      ),
      title: Text(
        'Tips for Quick Clipboard',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
        ),
      ),
      subtitle: Text(
        'Get the most out of it',
        style: TextStyle(
          fontSize: 12,
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              _tip(
                PhosphorIcons.handTap(),
                'Tap any item to instantly copy it to your clipboard',
                isDark,
              ),
              _tip(
                PhosphorIcons.plus(),
                'Tap + to quickly add a new item',
                isDark,
              ),
              _tip(
                PhosphorIcons.tag(),
                'Use categories to filter your items',
                isDark,
              ),
              _tip(
                PhosphorIcons.arrowClockwise(),
                'Tap refresh to reload the latest saved items',
                isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Info tile ─────────────────────────────────────────────────────
  Widget _buildInfoTile({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // ── Full tips card ────────────────────────────────────────────────
  Widget _buildTipsCard(bool isDark) {
    final tips = [
      (
        PhosphorIcons.clipboardText(PhosphorIconsStyle.fill),
        'Tap any clipboard item to instantly copy it',
        'Works instantly within the clipboard screen',
      ),
      (
        PhosphorIcons.pushPin(PhosphorIconsStyle.fill),
        'Pin important items to the top',
        'Long press any item in the clipboard screen to pin it',
      ),
      (
        PhosphorIcons.folders(),
        'Organise with Groups',
        'Create groups/categories to keep your clipboard tidy and filterable',
      ),
      (
        PhosphorIcons.shareNetwork(),
        'Share directly to WebVault',
        'In any app, select text → Share → WebVault Clipboard to save it',
      ),
      (
        PhosphorIcons.arrowsCounterClockwise(),
        'Pull-to-refresh',
        'Swipe down in the clipboard list to reload items from storage',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppTheme.darkDivider.withValues(alpha: 0.5)
              : AppTheme.lightDivider.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: tips.asMap().entries.map((entry) {
          final i = entry.key;
          final (icon, title, subtitle) = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: AppTheme.accentColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(
                delay: Duration(milliseconds: 60 * i),
                duration: 300.ms,
              ),
              if (i < tips.length - 1) _buildDivider(isDark),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required bool isDark, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppTheme.darkDivider.withValues(alpha: 0.5)
              : AppTheme.lightDivider.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    void Function(bool)? onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
      ),
    );
  }

  Widget _step(String num, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFF009688).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              num,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF009688),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tip(IconData icon, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.amber.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
