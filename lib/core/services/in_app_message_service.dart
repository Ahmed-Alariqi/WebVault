import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../theme/app_theme.dart';
import '../supabase_config.dart';
import '../constants.dart';

class InAppMessageService {
  static const String _dismissedKey = 'dismissed_in_app_messages';

  /// Check for active in-app messages from Supabase and show each eligible
  /// message sequentially (a professional "campaign queue"). Prior to this,
  /// only a single most-recent message was ever fetched via `.limit(1)`,
  /// which meant that e.g. a "please update" banner and a "welcome to v1.5"
  /// welcome card could never coexist — whichever was newest silently hid
  /// the other. Now the admin can schedule several simultaneous campaigns,
  /// each with its own audience (`target_version_mode`) and importance
  /// (`priority`); they are presented one after another, in priority order,
  /// with each subsequent dialog opening only after the previous one has
  /// been dismissed.
  static Future<void> checkAndShowMessage(BuildContext context) async {
    try {
      // Fetch ALL active messages (no limit). Server-side ordering is by
      // priority DESC, then created_at DESC so the admin's explicit urgency
      // wins, with newest-first as the tie-breaker.
      final raw = await SupabaseConfig.client
          .from('in_app_messages')
          .select()
          .eq('is_active', true)
          .order('priority', ascending: false)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> candidates = (raw as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (candidates.isEmpty) return;

      // ── Shared context (fetched once — avoids N round-trips in the loop).
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final currentUser = SupabaseConfig.client.auth.currentUser;
      bool? userIsAdmin;
      String? userFullName;

      Future<bool> isAdmin() async {
        if (userIsAdmin != null) return userIsAdmin!;
        if (currentUser == null) {
          userIsAdmin = false;
          return false;
        }
        try {
          final profile = await SupabaseConfig.client
              .from('profiles')
              .select('role')
              .eq('id', currentUser.id)
              .maybeSingle();
          userIsAdmin = profile != null && profile['role'] == 'admin';
        } catch (_) {
          userIsAdmin = false;
        }
        return userIsAdmin!;
      }

      Future<String> userName(BuildContext ctx) async {
        if (userFullName != null) return userFullName!;
        if (currentUser == null) {
          userFullName = ctx.mounted
              ? AppLocalizations.of(ctx)!.defaultUserFallback
              : 'User';
          return userFullName!;
        }
        try {
          final profile = await SupabaseConfig.client
              .from('profiles')
              .select('full_name')
              .eq('id', currentUser.id)
              .maybeSingle();
          final name = profile?['full_name'] as String?;
          userFullName = (name != null && name.isNotEmpty)
              ? name
              : (ctx.mounted
                  ? AppLocalizations.of(ctx)!.defaultUserFallback
                  : 'User');
        } catch (_) {
          userFullName = ctx.mounted
              ? AppLocalizations.of(ctx)!.defaultUserFallback
              : 'User';
        }
        return userFullName!;
      }

      // Dismissed-IDs live in Hive. A message with `show_every_time=true`
      // ignores this list so recurring reminders keep firing every launch.
      final box = Hive.box(kSettingsBox);
      final List<String> dismissedIds = List<String>.from(
        box.get(_dismissedKey) ?? [],
      );

      // ── Filter the candidates down to what this user should actually see.
      final List<Map<String, dynamic>> eligible = [];
      for (final msg in candidates) {
        final messageId = msg['id'] as String;
        final bool showEveryTime = msg['show_every_time'] == true;
        if (!showEveryTime && dismissedIds.contains(messageId)) continue;

        // Audience: version mode gate.
        if (!_matchesAudience(msg, currentVersion)) continue;

        eligible.add(msg);
      }
      if (eligible.isEmpty) return;

      // ── Present the eligible messages sequentially. We await each dialog
      // so the next one only appears after the user has dismissed / acted
      // on the previous — no stacked modals, no surprise chains.
      for (final msg in eligible) {
        if (!context.mounted) return;
        final messageId = msg['id'] as String;
        final bool showEveryTime = msg['show_every_time'] == true;
        bool isDismissible = msg['is_dismissible'] ?? true;

        // Admin override: never lock an admin out with a non-dismissible
        // "hard block" campaign (prevents self-inflicted lockouts).
        if (!isDismissible && await isAdmin()) {
          isDismissible = true;
        }

        // Personalisation: replace `{user_name}` in title/body with the
        // profile's full_name (or a localised fallback). We mutate a local
        // copy so we don't disturb the map we iterate over.
        if (msg['personalize_name'] == true && context.mounted) {
          final name = await userName(context);
          msg['title'] =
              (msg['title'] as String).replaceAll('{user_name}', name);
          msg['message'] =
              (msg['message'] as String).replaceAll('{user_name}', name);
        }

        if (!context.mounted) return;
        await _showCampaignDialog(
          context,
          msg,
          messageId,
          box,
          dismissedIds,
          isDismissible,
          showEveryTime,
        );

        // A short gap between dialogs gives the user a moment to realise
        // one ended before the next appears — feels like a conversation
        // rather than a barrage.
        if (context.mounted) {
          await Future.delayed(const Duration(milliseconds: 250));
        }
      }
    } catch (e) {
      debugPrint('Error loading in-app messages: $e');
    }
  }

  /// Returns true when [msg]'s audience targeting rules admit the given
  /// [currentVersion]. Three modes (see migration comments):
  ///   * any           → always matches (default for broadcast messages)
  ///   * below         → matches users *older* than target_version (legacy
  ///                     "update required / available" semantic)
  ///   * at_or_above   → matches users on target_version or newer (welcome
  ///                     cards, "what's new in v1.5", release notes, etc.)
  static bool _matchesAudience(
    Map<String, dynamic> msg,
    String currentVersion,
  ) {
    final String mode = (msg['target_version_mode'] as String?) ?? 'any';
    final String? target = msg['target_version'] as String?;

    if (mode == 'any') return true;
    if (target == null || target.isEmpty) {
      // Admin picked a version-targeted mode but forgot the version — fall
      // back to "show to everyone" to avoid silently hiding the message.
      return true;
    }
    final isLower = _isVersionLower(currentVersion, target);
    switch (mode) {
      case 'below':
        return isLower;
      case 'at_or_above':
        return !isLower;
      default:
        return true;
    }
  }

  static bool _isVersionLower(String current, String target) {
    try {
      final currentParts = current.split('.');
      final targetParts = target.split('.');

      for (int i = 0; i < currentParts.length && i < targetParts.length; i++) {
        final c = int.tryParse(currentParts[i]) ?? 0;
        final t = int.tryParse(targetParts[i]) ?? 0;
        if (c < t) return true;
        if (c > t) return false;
      }
      return currentParts.length < targetParts.length;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _showCampaignDialog(
    BuildContext context,
    Map<String, dynamic> data,
    String messageId,
    Box box,
    List<String> dismissedIds,
    bool isDismissible,
    bool showEveryTime,
  ) {
    final title = data['title'] as String;
    final message = data['message'] as String;
    final imageUrl = data['image_url'] as String?;
    final actionUrl = data['action_url'] as String?;
    final actionText = data['action_text'] as String?;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<void>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (ctx) {
        return PopScope(
          canPop: isDismissible,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Image Header
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        height: 180,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 180,
                          color: isDark ? Colors.white10 : Colors.black12,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 140,
                          color: isDark ? Colors.white10 : Colors.black12,
                          child: Icon(
                            PhosphorIcons.imageBroken(),
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    // Fallback colored header if no image
                    Container(
                      height: 120,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.accentColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          PhosphorIcons.megaphone(PhosphorIconsStyle.fill),
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),

                  // Content
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    title,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    message,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      height: 1.5,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Action Buttons
                          if (actionUrl != null &&
                              actionUrl.isNotEmpty &&
                              actionText != null)
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final uri = Uri.tryParse(actionUrl);
                                  if (uri != null && await canLaunchUrl(uri)) {
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                  if (isDismissible) {
                                    dismissedIds.add(messageId);
                                    await box.put(_dismissedKey, dismissedIds);
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  actionText,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                          const SizedBox(height: 12),

                          // Dismiss Button
                          if (isDismissible)
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: TextButton(
                                onPressed: () async {
                                  if (!showEveryTime) {
                                    dismissedIds.add(messageId);
                                    await box.put(_dismissedKey, dismissedIds);
                                  }
                                  if (ctx.mounted) Navigator.pop(ctx);
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: isDark
                                      ? Colors.white54
                                      : Colors.black54,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.dismissButton,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
