import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/admin_ui_utils.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../presentation/providers/notification_settings_providers.dart';

import '../../presentation/widgets/tutorial_overlay.dart';
import '../../presentation/widgets/responsive_layout.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  final GlobalKey _discoverKey = GlobalKey();
  final GlobalKey _communityKey = GlobalKey();
  bool _tutorialTriggered = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _checkTutorial() async {
    if (await TutorialManager.shouldShowSection(TutorialSection.notifications)) {
      // Small delay to ensure the ListView items are fully attached to the render tree
      await Future.delayed(const Duration(milliseconds: 150));
      
      if (mounted) {
        TutorialOverlay.show(
          context,
          section: TutorialSection.notifications,
          steps: TutorialManager.getNotificationsSteps(_discoverKey, _communityKey),
          onComplete: () {},
        );
      }
    }
  }

  Future<void> _setAllContent(bool value) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      await SupabaseConfig.client
          .from('profiles')
          .update({'notif_all_new_content': value})
          .eq('id', user.id);
      ref.invalidate(notificationPrefsProvider);
    } catch (_) {
      if (mounted) {
        AdminUIUtils.showError(
          context,
          AppLocalizations.of(context)!.notifSettingsSaveError,
        );
      }
    }
  }

  Future<void> _setCommunityPosts(bool value) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      await SupabaseConfig.client
          .from('profiles')
          .update({'notif_community_posts': value})
          .eq('id', user.id);
      ref.invalidate(notificationPrefsProvider);
    } catch (_) {
      if (mounted) {
        AdminUIUtils.showError(
          context,
          AppLocalizations.of(context)!.notifSettingsSaveError,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;
    final prefsAsync = ref.watch(notificationPrefsProvider);

    return ResponsiveLayout(
      maxWidth: 520,
      child: Scaffold(
      appBar: AppBar(title: Text(loc.notifSettingsTitle)),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('$e')),
        data: (prefs) {
          final allContent =
              prefs['notif_all_new_content'] as bool? ?? false;
          final communityPosts =
              prefs['notif_community_posts'] as bool? ?? false;

          if (!_tutorialTriggered) {
            _tutorialTriggered = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _checkTutorial();
            });
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildToggleCard(
                key: _discoverKey,
                isDark: isDark,
                icon: PhosphorIcons.compass(PhosphorIconsStyle.fill),
                iconColor: Colors.teal,
                title: loc.notifSettingsAllContent,
                subtitle: loc.notifSettingsAllContentSub,
                value: allContent,
                onChanged: _setAllContent,
              ),
              const SizedBox(height: 16),
              _buildToggleCard(
                key: _communityKey,
                isDark: isDark,
                icon: PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
                iconColor: AppTheme.primaryColor,
                title: loc.notifSettingsCommunity,
                subtitle: loc.notifSettingsCommunitySub,
                value: communityPosts,
                onChanged: _setCommunityPosts,
              ),
            ],
          );
        },
      ),
    ),
  );
}

  Widget _buildToggleCard({
    Key? key,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppTheme.darkDivider.withValues(alpha: 0.5)
              : AppTheme.lightDivider.withValues(alpha: 0.5),
        ),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        secondary: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ),
        value: value,
        activeThumbColor: AppTheme.primaryColor,
        onChanged: onChanged,
      ),
    );
  }
}
