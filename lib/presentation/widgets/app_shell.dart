import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/in_app_message_service.dart';
import 'dart:ui';

class AppShell extends StatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    // Check for in-app messages globally — fires on first app entry,
    // regardless of which tab the user is on.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        InAppMessageService.checkAndShowMessage(context);
      }
    });
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/pages')) return 1;
    if (location.startsWith('/discover') ||
        location.startsWith('/notifications'))
      return 2;
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
      // extendBody is false by default, which ensures the body ends ABOVE the nav bar
      // instead of flowing underneath and getting covered by it.
      body: widget.child,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.darkSurface.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNavItem(
                        context,
                        icon: PhosphorIcons.squaresFour(
                          PhosphorIconsStyle.fill,
                        ),
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
                        icon: PhosphorIcons.clipboardText(
                          PhosphorIconsStyle.fill,
                        ),
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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Animated Icon
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                isSelected ? icon : inactiveIcon,
                key: ValueKey(isSelected), // Forces swap animation
                size: 24,
                color: isSelected
                    ? AppTheme.primaryColor
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
            ),
            const SizedBox(height: 4),

            /// Persistent label
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 0.2,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? AppTheme.primaryColor
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
            ),

            /// Subtle active indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(top: 4),
              height: 4,
              width: isSelected ? 4 : 0,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
