import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../l10n/app_localizations.dart';
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
      // extendBody: false, // Default is false, ensuring body doesn't go under nav bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
