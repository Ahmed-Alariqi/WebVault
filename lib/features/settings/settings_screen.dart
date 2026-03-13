import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:restart_app/restart_app.dart';
import '../../core/supabase_config.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/providers.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../presentation/providers/chat_providers.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final themeMode = settings['themeMode'] as String? ?? 'system';

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings)),
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
                                AppLocalizations.of(context)!.adminDashboard,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                AppLocalizations.of(
                                  context,
                                )!.manageContentAndUsers,
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

          // Clipboard & Copy section
          _buildSectionHeader(
            AppLocalizations.of(context)!.clipboardSettings,
            PhosphorIcons.clipboardText(),
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
                  color: const Color(0xFF009688).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  PhosphorIcons.clipboardText(PhosphorIconsStyle.fill),
                  color: const Color(0xFF009688),
                ),
              ),
              title: Text(
                AppLocalizations.of(context)!.clipboardSettings,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
              subtitle: Text(
                AppLocalizations.of(context)!.clipboardSettingsSubtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
              trailing: Icon(PhosphorIcons.caretRight()),
              onTap: () => context.push('/clipboard-settings'),
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
                  onTap: () async {
                    final success = await ref
                        .read(backupServiceProvider)
                        .exportData();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? AppLocalizations.of(context)!.backupSuccessful
                                : AppLocalizations.of(context)!.backupFailed,
                          ),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
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
                  onTap: () async {
                    final success = await ref
                        .read(backupServiceProvider)
                        .importData();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? AppLocalizations.of(context)!.importSuccessful
                                : AppLocalizations.of(context)!.importFailed,
                          ),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );

                      // Refresh providers to reflect new data
                      if (success) {
                        ref.read(pagesProvider.notifier).refresh();
                        ref.read(foldersProvider.notifier).refresh();
                        ref.read(clipboardItemsProvider.notifier).refresh();
                      }
                    }
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
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    isDark
                        ? 'assets/onboarding/welcome_image_dark.png'
                        : 'assets/onboarding/welcome_image_light.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              title: Text(
                AppLocalizations.of(context)!.appName,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
              subtitle: Text(
                '${AppLocalizations.of(context)!.version} $kAppVersion',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
              trailing: Icon(
                PhosphorIcons.caretRight(),
                size: 18,
                color: isDark ? Colors.white38 : Colors.black26,
              ),
              onTap: () => context.push('/about'),
            ),
          ),
          const SizedBox(height: 28),

          // Support section
          _buildSectionHeader(
            AppLocalizations.of(context)!.support,
            PhosphorIcons.headset(),
            isDark,
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (ctx) {
              final unreadCount =
                  ref.watch(userUnreadCountStreamProvider).valueOrNull ?? 0;

              return _buildCard(
                isDark: isDark,
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Center(
                          child: Icon(
                            PhosphorIcons.chatCircleDots(
                              PhosphorIconsStyle.fill,
                            ),
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? AppTheme.darkCard
                                      : AppTheme.lightCard,
                                  width: 2,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 12,
                                minHeight: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.contactSupport,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!.getHelpFromAdmin,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  trailing: Icon(
                    PhosphorIcons.caretRight(),
                    size: 18,
                    color: isDark ? Colors.white38 : Colors.black26,
                  ),
                  onTap: () => context.push('/chat'),
                ),
              );
            },
          ),
          const SizedBox(height: 28),

          // Fix Notifications (VPN Required) section
          _buildSectionHeader(
            AppLocalizations.of(context)!.pushNotificationsTitle,
            PhosphorIcons.bell(),
            isDark,
          ),
          const SizedBox(height: 12),
          _buildCard(
            isDark: isDark,
            child: StatefulBuilder(
              builder: (context, setLocalState) {
                // Check OneSignal registration status
                String? playerId;
                bool isRegistered = false;
                try {
                  playerId = OneSignal.User.pushSubscription.id;
                  isRegistered = playerId != null && playerId.isNotEmpty;
                } catch (_) {
                  isRegistered = false;
                }

                final statusColor = isRegistered
                    ? Colors.green
                    : Colors.redAccent;
                final statusIcon = isRegistered
                    ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                    : PhosphorIcons.warningCircle(PhosphorIconsStyle.fill);

                return ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Icon(statusIcon, color: statusColor)),
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.settingsFixNotifications,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  subtitle: Text(
                    isRegistered
                        ? AppLocalizations.of(context)!.notifStatusRegistered
                        : AppLocalizations.of(
                            context,
                          )!.notifStatusNotRegistered,
                    style: TextStyle(fontSize: 12, color: statusColor),
                  ),
                  trailing: isRegistered
                      ? Icon(
                          PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                          size: 22,
                          color: Colors.green,
                        )
                      : Icon(
                          PhosphorIcons.arrowClockwise(),
                          size: 18,
                          color: isDark ? Colors.white38 : Colors.black26,
                        ),
                  onTap: () async {
                    if (isRegistered) {
                      // Already registered — send a test notification
                      final scaffoldMsg = ScaffoldMessenger.of(context);
                      try {
                        await SupabaseConfig.client.functions.invoke(
                          'self-test-notification',
                          body: {'player_id': playerId},
                        );
                        scaffoldMsg.showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)!.notifTestSent,
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        scaffoldMsg.showSnackBar(
                          SnackBar(
                            content: Text(
                              '${AppLocalizations.of(context)!.notifTestFailed}: $e',
                            ),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                      }
                    } else {
                      // Not registered — show confirmation dialog
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: isDark
                              ? AppTheme.darkCard
                              : AppTheme.lightCard,
                          icon: Icon(
                            PhosphorIcons.wifiHigh(PhosphorIconsStyle.fill),
                            color: AppTheme.primaryColor,
                            size: 40,
                          ),
                          title: Text(
                            AppLocalizations.of(context)!.notifFixDialogTitle,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          content: Text(
                            AppLocalizations.of(context)!.notifFixDialogBody,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(
                                AppLocalizations.of(context)!.notifCancel,
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: () => Navigator.pop(ctx, true),
                              icon: Icon(
                                PhosphorIcons.arrowClockwise(),
                                size: 16,
                              ),
                              label: Text(
                                AppLocalizations.of(context)!.notifRestartNow,
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        Restart.restartApp();
                      }
                    }
                  },
                );
              },
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
