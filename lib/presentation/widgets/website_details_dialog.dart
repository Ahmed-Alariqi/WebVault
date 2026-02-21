import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/website_model.dart';
import '../../presentation/providers/discover_providers.dart';

class WebsiteDetailsDialog extends ConsumerWidget {
  final WebsiteModel site;

  const WebsiteDetailsDialog({super.key, required this.site});

  Future<void> _openUrl(String url, {bool inApp = true}) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: inApp ? LaunchMode.inAppWebView : LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesProvider);

    // Attempt to find the category name if it exists
    String? categoryName;
    if (site.categoryId != null) {
      categoriesAsync.whenData((categories) {
        try {
          final cat = categories.firstWhere((c) => c.id == site.categoryId);
          categoryName = cat.name;
        } catch (_) {}
      });
    }

    return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: -5,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      child: SizedBox(
                        height: 180,
                        width: double.infinity,
                        child:
                            site.imageUrl != null && site.imageUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: site.imageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (ctx, url) => Container(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.05),
                                  child: Center(
                                    child: Icon(
                                      PhosphorIcons.image(),
                                      color: isDark
                                          ? Colors.white24
                                          : Colors.black12,
                                    ),
                                  ),
                                ),
                                errorWidget: (ctx, url, err) => Container(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.05),
                                  child: Center(
                                    child: Icon(
                                      PhosphorIcons.globe(),
                                      size: 48,
                                      color: isDark
                                          ? Colors.white24
                                          : Colors.black12,
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.05),
                                child: Center(
                                  child: Icon(
                                    PhosphorIcons.globe(),
                                    size: 48,
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.black12,
                                  ),
                                ),
                              ),
                      ),
                    ),

                    // Content Body
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title and Badges
                            Text(
                              site.title,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.lightTextPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Badges row
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (categoryName != null)
                                  _badge(
                                    categoryName!,
                                    AppTheme.primaryColor,
                                    isDark,
                                  ),
                                if (site.isTrending)
                                  _badge(
                                    'Trending',
                                    const Color(0xFFFF6B6B),
                                    isDark,
                                  ),
                                if (site.isPopular)
                                  _badge(
                                    'Popular',
                                    const Color(0xFFFF9800),
                                    isDark,
                                  ),
                                if (site.isFeatured)
                                  _badge(
                                    'Featured',
                                    const Color(0xFF4CAF50),
                                    isDark,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Divider
                            Divider(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.05),
                            ),
                            const SizedBox(height: 16),

                            // Full Description
                            Text(
                              site.description,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _openUrl(site.url, inApp: true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    icon: Icon(
                                      PhosphorIcons.rocketLaunch(
                                        PhosphorIconsStyle.fill,
                                      ),
                                      size: 20,
                                    ),
                                    label: const Text(
                                      'Open App',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: IconButton(
                                    onPressed: () =>
                                        _openUrl(site.url, inApp: false),
                                    icon: Icon(
                                      PhosphorIcons.browser(),
                                      size: 22,
                                    ),
                                    color: isDark
                                        ? AppTheme.darkTextPrimary
                                        : AppTheme.lightTextPrimary,
                                    tooltip: 'Open in Browser',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Close Button Overlay
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack);
  }

  Widget _badge(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
