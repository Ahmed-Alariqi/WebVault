import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_theme.dart';
import '../supabase_config.dart';
import '../constants.dart';

class InAppMessageService {
  static const String _dismissedKey = 'dismissed_in_app_messages';

  /// Check for active in-app messages from Supabase and show them if not dismissed
  static Future<void> checkAndShowMessage(BuildContext context) async {
    try {
      final response = await SupabaseConfig.client
          .from('in_app_messages')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return;

      final messageId = response['id'] as String;

      // Check if user already dismissed this specific message ID
      final box = Hive.box(kSettingsBox);
      final List<String> dismissedIds = List<String>.from(
        box.get(_dismissedKey) ?? [],
      );

      if (dismissedIds.contains(messageId)) {
        return; // Already seen and dismissed
      }

      if (context.mounted) {
        _showCampaignDialog(context, response, messageId, box, dismissedIds);
      }
    } catch (e) {
      debugPrint('Error loading in-app messages: $e');
    }
  }

  static void _showCampaignDialog(
    BuildContext context,
    Map<String, dynamic> data,
    String messageId,
    Box box,
    List<String> dismissedIds,
  ) {
    final title = data['title'] as String;
    final message = data['message'] as String;
    final imageUrl = data['image_url'] as String?;
    final actionUrl = data['action_url'] as String?;
    final actionText = data['action_text'] as String?;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false, // Force them to explicitly dismiss it
      builder: (ctx) {
        return Dialog(
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
                        child: const Center(child: CircularProgressIndicator()),
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
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: isDark ? Colors.white70 : Colors.black87,
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
                              // Mark as dismissed and close
                              dismissedIds.add(messageId);
                              await box.put(_dismissedKey, dismissedIds);
                              if (ctx.mounted) Navigator.pop(ctx);
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
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: TextButton(
                          onPressed: () async {
                            dismissedIds.add(messageId);
                            await box.put(_dismissedKey, dismissedIds);
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
                          child: const Text(
                            'Dismiss',
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
              ],
            ),
          ),
        );
      },
    );
  }
}
