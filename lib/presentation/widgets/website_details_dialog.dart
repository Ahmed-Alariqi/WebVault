import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/website_model.dart';
import '../../presentation/providers/discover_providers.dart';
import '../../utils/clipboard_helper.dart';
import '../../utils/text_utils.dart';

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
                                if (site.contentType != 'website')
                                  _badge(
                                    _typeLabel(site.contentType),
                                    _typeColor(site.contentType),
                                    isDark,
                                  ),
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
                                if (site.expiresAt != null)
                                  _badge(
                                    _formatTimeLeft(site.expiresAt!),
                                    Colors.orange,
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
                            Builder(
                              builder: (context) {
                                Document doc;
                                bool isRichText = false;
                                try {
                                  if (site.description.isNotEmpty) {
                                    final decoded = jsonDecode(
                                      site.description,
                                    );
                                    doc = Document.fromJson(decoded);
                                    isRichText = true;
                                  } else {
                                    doc = Document();
                                  }
                                } catch (_) {
                                  // Fallback for older plain text strings
                                  doc = Document()..insert(0, site.description);
                                }

                                if (isRichText) {
                                  final quillController = QuillController(
                                    document: doc,
                                    selection: const TextSelection.collapsed(
                                      offset: 0,
                                    ),
                                    readOnly: true,
                                  );

                                  return GestureDetector(
                                    onLongPress: () =>
                                        ClipboardHelper.copyAndPrompt(
                                          context,
                                          ref,
                                          TextUtils.getPlainTextFromDescription(
                                            site.description,
                                          ),
                                        ),
                                    child: DefaultTextStyle(
                                      style: TextStyle(
                                        fontSize: 15,
                                        height: 1.6,
                                        color: isDark
                                            ? AppTheme.darkTextSecondary
                                            : AppTheme.lightTextSecondary,
                                      ),
                                      child: QuillEditor.basic(
                                        controller: quillController,
                                        config: const QuillEditorConfig(
                                          showCursor: false,
                                          scrollable: false,
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  return GestureDetector(
                                    onLongPress: () =>
                                        ClipboardHelper.copyAndPrompt(
                                          context,
                                          ref,
                                          site.description,
                                        ),
                                    child: Text(
                                      site.description,
                                      style: TextStyle(
                                        fontSize: 15,
                                        height: 1.6,
                                        color: isDark
                                            ? AppTheme.darkTextSecondary
                                            : AppTheme.lightTextSecondary,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 24),

                            // Copyable Content (prompts, offers)
                            if (site.hasCopyableValue) ...[
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : Colors.black.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.black12,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          PhosphorIcons.clipboardText(),
                                          size: 14,
                                          color: _typeColor(site.contentType),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          site.contentType == 'prompt'
                                              ? 'Prompt Text'
                                              : 'Code / Key',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _typeColor(site.contentType),
                                          ),
                                        ),
                                        const Spacer(),
                                        GestureDetector(
                                          onTap: () {
                                            Clipboard.setData(
                                              ClipboardData(
                                                text: site.actionValue,
                                              ),
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: const Row(
                                                  children: [
                                                    Icon(
                                                      Icons.check_circle,
                                                      color: Colors.white,
                                                      size: 18,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text('Copied!'),
                                                  ],
                                                ),
                                                backgroundColor:
                                                    Colors.green.shade600,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _typeColor(
                                                site.contentType,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.copy,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Copy',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    SelectableText(
                                      site.actionValue,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontFamily: 'monospace',
                                        height: 1.5,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Video Player Section
                            if (site.hasVideo) ...[
                              _VideoSection(
                                videoUrl: site.videoUrl!,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Action Buttons — dynamic per content type
                            _buildDialogActions(context, ref, site, isDark),
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

  Widget _buildDialogActions(
    BuildContext context,
    WidgetRef ref,
    WebsiteModel site,
    bool isDark,
  ) {
    switch (site.contentType) {
      case 'prompt':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: site.actionValue));
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text('Prompt copied!'),
                        ],
                      ),
                      backgroundColor: Colors.green.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C27B0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                icon: Icon(PhosphorIcons.copy(), size: 20),
                label: const Text(
                  'Copy Prompt',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            if (site.hasUrl) ...[
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/discover-browser', extra: site);
                  },
                  icon: Icon(PhosphorIcons.arrowSquareOut(), size: 22),
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                  tooltip: 'Try It',
                ),
              ),
            ],
          ],
        );

      case 'offer':
        return Row(
          children: [
            if (site.hasCopyableValue)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: site.actionValue));
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text('Code copied!'),
                          ],
                        ),
                        backgroundColor: Colors.green.shade600,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  icon: Icon(PhosphorIcons.key(), size: 20),
                  label: const Text(
                    'Copy Code',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            if (site.hasUrl) ...[
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/discover-browser', extra: site);
                  },
                  icon: Icon(PhosphorIcons.globe(), size: 22),
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                  tooltip: 'Visit',
                ),
              ),
            ],
          ],
        );

      case 'announcement':
        if (site.hasUrl) {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/discover-browser', extra: site);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              icon: Icon(PhosphorIcons.globe(), size: 20),
              label: const Text(
                'Visit Link',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          );
        }
        return const SizedBox();

      default: // website
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/discover-browser', extra: site);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                icon: Icon(
                  PhosphorIcons.rocketLaunch(PhosphorIconsStyle.fill),
                  size: 20,
                ),
                label: const Text(
                  'Open App',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
                onPressed: () => _openUrl(site.url, inApp: false),
                icon: Icon(PhosphorIcons.browser(), size: 22),
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
                tooltip: 'Open in Browser',
              ),
            ),
          ],
        );
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'prompt':
        return 'Prompt';
      case 'offer':
        return 'Offer';
      case 'announcement':
        return 'News';
      default:
        return 'Website';
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'prompt':
        return const Color(0xFF9C27B0);
      case 'offer':
        return const Color(0xFFFF9800);
      case 'announcement':
        return const Color(0xFF2196F3);
      default:
        return AppTheme.primaryColor;
    }
  }

  String _formatTimeLeft(DateTime expiresAt) {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inDays > 0) return '${diff.inDays}d left';
    if (diff.inHours > 0) return '${diff.inHours}h left';
    return '${diff.inMinutes}m left';
  }
}

/// Stateful widget for the video section (manages controller lifecycle)
class _VideoSection extends StatefulWidget {
  final String videoUrl;
  final bool isDark;

  const _VideoSection({required this.videoUrl, required this.isDark});

  @override
  State<_VideoSection> createState() => _VideoSectionState();
}

class _VideoSectionState extends State<_VideoSection> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;

  /// Check if the URL is an external video platform (YouTube, Vimeo, etc.)
  bool get _isExternalVideo {
    final url = widget.videoUrl.toLowerCase();
    return url.contains('youtube.com') ||
        url.contains('youtu.be') ||
        url.contains('vimeo.com') ||
        url.contains('dailymotion.com') ||
        url.contains('tiktok.com') ||
        // Not a direct video file
        (!url.endsWith('.mp4') &&
            !url.endsWith('.mov') &&
            !url.endsWith('.webm') &&
            !url.endsWith('.avi') &&
            !url.contains('imagekit.io'));
  }

  @override
  void initState() {
    super.initState();
    if (!_isExternalVideo) {
      _initDirectVideo();
    }
  }

  Future<void> _initDirectVideo() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      // Listen for errors
      _videoController!.addListener(() {
        if (_videoController!.value.hasError && mounted) {
          setState(() => _hasError = true);
          debugPrint(
            'Video error: ${_videoController!.value.errorDescription}',
          );
        }
      });

      await _videoController!.initialize();
      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIcons.warning(),
                    color: Colors.white38,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Video playback error',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _openExternally(),
                    icon: const Icon(
                      Icons.open_in_new,
                      size: 14,
                      color: Colors.white70,
                    ),
                    label: const Text(
                      'Open Externally',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.primaryColor,
          handleColor: AppTheme.primaryColor,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
      );
      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Video init error: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  Future<void> _openExternally() async {
    final uri = Uri.parse(widget.videoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          color: widget.isDark
              ? Colors.white10
              : Colors.black.withValues(alpha: 0.05),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              PhosphorIcons.videoCamera(PhosphorIconsStyle.fill),
              size: 16,
              color: const Color(0xFF7C3AED),
            ),
            const SizedBox(width: 8),
            Text(
              'Watch Tutorial',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF7C3AED),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // External video (YouTube, Vimeo, etc.) — open button
        if (_isExternalVideo)
          GestureDetector(
            onTap: _openExternally,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Watch Video',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getExternalLabel(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          )
        // Direct video — inline player
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(14),
              ),
              child: _hasError
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIcons.warning(),
                              color: Colors.white38,
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Could not load video',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _openExternally,
                              icon: const Icon(
                                Icons.open_in_new,
                                size: 14,
                                color: Color(0xFF7C3AED),
                              ),
                              label: const Text(
                                'Open in Browser',
                                style: TextStyle(
                                  color: Color(0xFF7C3AED),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : !_isInitialized
                  ? const SizedBox(
                      height: 180,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    )
                  : Chewie(controller: _chewieController!),
            ),
          ),
        const SizedBox(height: 4),
      ],
    );
  }

  String _getExternalLabel() {
    final url = widget.videoUrl.toLowerCase();
    if (url.contains('youtube') || url.contains('youtu.be')) {
      return 'Opens on YouTube';
    } else if (url.contains('vimeo')) {
      return 'Opens on Vimeo';
    }
    return 'Opens in browser';
  }
}
