import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/providers.dart';
import '../../presentation/providers/auth_providers.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final themeMode = settings['themeMode'] as String? ?? 'system';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Account section
          _buildSectionHeader(
            AppLocalizations.of(context)!.account,
            PhosphorIcons.userCircle(),
            isDark,
          ),
          const SizedBox(height: 12),
          _buildCard(
            isDark: isDark,
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      PhosphorIcons.user(PhosphorIconsStyle.fill),
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.myProfile,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!.viewAndEditProfile,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  trailing: Icon(
                    PhosphorIcons.caretRight(),
                    size: 18,
                    color: isDark ? Colors.white38 : Colors.black26,
                  ),
                  onTap: () => context.push('/profile'),
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                ),
                Consumer(
                  builder: (ctx, ref, _) {
                    final isAdmin = ref.watch(isAdminProvider);
                    return isAdmin.when(
                      data: (admin) => admin
                          ? ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  PhosphorIcons.crown(PhosphorIconsStyle.fill),
                                  color: Colors.amber.shade700,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                'Admin Dashboard',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                'Manage content and users',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black45,
                                ),
                              ),
                              trailing: Icon(
                                PhosphorIcons.caretRight(),
                                size: 18,
                                color: isDark ? Colors.white38 : Colors.black26,
                              ),
                              onTap: () => context.push('/admin'),
                            )
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (e, st) => const SizedBox.shrink(),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Appearance section
          _buildSectionHeader(
            AppLocalizations.of(context)!.appearance,
            PhosphorIcons.paintBrush(),
            isDark,
          ),
          const SizedBox(height: 12),
          _buildCard(
            isDark: isDark,
            child: Column(
              children: [
                _buildThemeOption(
                  isDark: isDark,
                  icon: PhosphorIcons.deviceMobile(),
                  title: AppLocalizations.of(context)!.system,
                  isSelected: themeMode == 'system',
                  onTap: () => settingsNotifier.setThemeMode('system'),
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                ),
                _buildThemeOption(
                  isDark: isDark,
                  icon: PhosphorIcons.sun(),
                  title: AppLocalizations.of(context)!.light,
                  isSelected: themeMode == 'light',
                  onTap: () => settingsNotifier.setThemeMode('light'),
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                ),
                _buildThemeOption(
                  isDark: isDark,
                  icon: PhosphorIcons.moon(),
                  title: AppLocalizations.of(context)!.dark,
                  isSelected: themeMode == 'dark',
                  onTap: () => settingsNotifier.setThemeMode('dark'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Language section
          _buildSectionHeader(
            AppLocalizations.of(context)!.language,
            PhosphorIcons.globe(),
            isDark,
          ),
          const SizedBox(height: 12),
          Consumer(
            builder: (context, ref, _) {
              final locale = ref.watch(localeProvider);
              return _buildCard(
                isDark: isDark,
                child: Column(
                  children: [
                    _buildThemeOption(
                      isDark: isDark,
                      icon: PhosphorIcons.translate(),
                      title: AppLocalizations.of(context)!.english,
                      isSelected: locale.languageCode == 'en',
                      onTap: () => settingsNotifier.setLocale('en'),
                    ),
                    Divider(
                      height: 1,
                      color: isDark
                          ? AppTheme.darkDivider
                          : AppTheme.lightDivider,
                    ),
                    _buildThemeOption(
                      isDark: isDark,
                      icon: PhosphorIcons.translate(),
                      title: AppLocalizations.of(context)!.arabic,
                      isSelected: locale.languageCode == 'ar',
                      onTap: () => settingsNotifier.setLocale('ar'),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 28),

          // Security section
          _buildSectionHeader(
            AppLocalizations.of(context)!.securityAndPrivacy,
            PhosphorIcons.shield(),
            isDark,
          ),
          const SizedBox(height: 12),
          _buildCard(
            isDark: isDark,
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  PhosphorIcons.lockKey(),
                  color: AppTheme.primaryColor,
                ),
              ),
              title: Text(
                AppLocalizations.of(context)!.securitySettings,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
              subtitle: Text(
                AppLocalizations.of(context)!.securitySubtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
              trailing: Icon(PhosphorIcons.caretRight()),
              onTap: () => context.push('/security-settings'),
            ),
          ),

          const SizedBox(height: 28),

          // Data section
          _buildSectionHeader(
            AppLocalizations.of(context)!.data,
            PhosphorIcons.hardDrives(),
            isDark,
          ),
          const SizedBox(height: 12),
          _buildCard(
            isDark: isDark,
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      PhosphorIcons.upload(),
                      color: AppTheme.accentColor,
                    ),
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.exportBackup,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!.saveAllDataAsJson,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.exportFeatureComingSoon,
                        ),
                      ),
                    );
                  },
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                ),
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      PhosphorIcons.download(),
                      color: AppTheme.warningColor,
                    ),
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.importBackup,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!.restoreFromJson,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.importFeatureComingSoon,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // About
          _buildSectionHeader(
            AppLocalizations.of(context)!.about,
            PhosphorIcons.info(),
            isDark,
          ),
          const SizedBox(height: 12),
          _buildCard(
            isDark: isDark,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.accentColor],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      PhosphorIcons.briefcase(PhosphorIconsStyle.duotone),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.appName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                      Text(
                        '${AppLocalizations.of(context)!.version} ${kAppVersion}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
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

  Widget _buildCard({required bool isDark, required Widget child}) {
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
      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: child),
    );
  }

  Widget _buildThemeOption({
    required bool isDark,
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? AppTheme.primaryColor
            : (isDark ? Colors.white54 : Colors.black45),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
        ),
      ),
      trailing: isSelected
          ? Icon(
              PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
              color: AppTheme.primaryColor,
              size: 22,
            )
          : null,
      onTap: onTap,
    );
  }
}
