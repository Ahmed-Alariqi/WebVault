import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/pages')) return 1;
    if (location.startsWith('/discover')) return 2;
    if (location.startsWith('/clipboard')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/pages');
        break;
      case 2:
        context.go('/discover');
        break;
      case 3:
        context.go('/clipboard');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      extendBody: true, // Important for floating effect
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        decoration: BoxDecoration(
          color: (isDark ? AppTheme.darkSurface : AppTheme.lightSurface)
              .withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(
                    context,
                    icon: PhosphorIcons.squaresFour(PhosphorIconsStyle.fill),
                    inactiveIcon: PhosphorIcons.squaresFour(),
                    label: AppLocalizations.of(context)!.home,
                    index: 0,
                    selectedIndex: selectedIndex,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    context,
                    icon: PhosphorIcons.browsers(PhosphorIconsStyle.fill),
                    inactiveIcon: PhosphorIcons.browsers(),
                    label: AppLocalizations.of(context)!.folders,
                    index: 1,
                    selectedIndex: selectedIndex,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    context,
                    icon: PhosphorIcons.compass(PhosphorIconsStyle.fill),
                    inactiveIcon: PhosphorIcons.compass(),
                    label: AppLocalizations.of(context)!.discover,
                    index: 2,
                    selectedIndex: selectedIndex,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    context,
                    icon: PhosphorIcons.clipboardText(PhosphorIconsStyle.fill),
                    inactiveIcon: PhosphorIcons.clipboardText(),
                    label: AppLocalizations.of(context)!.clipboard,
                    index: 3,
                    selectedIndex: selectedIndex,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    context,
                    icon: PhosphorIcons.gear(PhosphorIconsStyle.fill),
                    inactiveIcon: PhosphorIcons.gear(),
                    label: AppLocalizations.of(context)!.settings,
                    index: 4,
                    selectedIndex: selectedIndex,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData inactiveIcon,
    required String label,
    required int index,
    required int selectedIndex,
    required bool isDark,
  }) {
    final isSelected = index == selectedIndex;
    return GestureDetector(
      onTap: () => _onItemTapped(context, index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? icon : inactiveIcon,
              size: 22,
              color: isSelected
                  ? AppTheme.primaryColor
                  : (isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary),
            ),
            if (isSelected) ...[
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
