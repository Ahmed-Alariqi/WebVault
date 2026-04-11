import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class GoogleImageSearchSheet extends StatefulWidget {
  final String initialQuery;

  const GoogleImageSearchSheet({super.key, this.initialQuery = ''});

  @override
  State<GoogleImageSearchSheet> createState() => _GoogleImageSearchSheetState();
}

class _GoogleImageSearchSheetState extends State<GoogleImageSearchSheet>
    with SingleTickerProviderStateMixin {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isDialogShowing = false;
  String? _selectedImageUrl;
  bool _showSelectedBanner = false;

  // For the pulsing select button animation
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    final query = Uri.encodeComponent(widget.initialQuery);
    final url = 'https://www.google.com/search?tbm=isch&q=$query&tbs=isz:l';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'ImagePicker',
        onMessageReceived: (JavaScriptMessage message) {
          final src = message.message;
          if (src.startsWith('http') && mounted) {
            _onImageSelected(src);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
            _injectImageInterceptor();
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  void _injectImageInterceptor() {
    _controller.runJavaScript('''
      (function() {
        // Prevent duplicate injection
        if (window.__imagePickerInjected) return;
        window.__imagePickerInjected = true;

        var lastSentUrl = '';
        var lastSentTime = 0;

        function sendImageUrl(src) {
          var now = Date.now();
          // Debounce: ignore duplicate sends within 1 second
          if (src === lastSentUrl && (now - lastSentTime) < 1000) return;
          if (!src || !src.startsWith('http')) return;
          // Skip tiny thumbnails and data URIs
          if (src.startsWith('data:')) return;
          lastSentUrl = src;
          lastSentTime = now;
          ImagePicker.postMessage(src);
        }

        // --- Method 1: Intercept taps on images ---
        document.addEventListener('click', function(e) {
          var target = e.target;
          if (target.tagName === 'IMG' && target.src && target.src.startsWith('http')) {
            // Only consider images that are reasonably large (preview panels)
            if (target.naturalWidth > 100 || target.width > 100) {
              sendImageUrl(target.src);
            }
          }
        }, true);

        // --- Method 2: Long-press (contextmenu) on images ---
        document.addEventListener('contextmenu', function(e) {
          var target = e.target;
          if (target.tagName === 'IMG' && target.src && target.src.startsWith('http')) {
            e.preventDefault();
            e.stopPropagation();
            sendImageUrl(target.src);
          }
        }, true);

        // --- Method 3: MutationObserver for full-size image panels ---
        var observer = new MutationObserver(function(mutations) {
          // Look for large images that appear in the preview panel
          var allImgs = document.querySelectorAll('img[src^="http"]');
          for (var i = 0; i < allImgs.length; i++) {
            var img = allImgs[i];
            // If image is large enough, it's likely a preview
            if ((img.naturalWidth > 300 || img.width > 300) && 
                (img.naturalHeight > 200 || img.height > 200)) {
              // Check if this is in a preview/overlay panel
              var parent = img.parentElement;
              var isInPreview = false;
              for (var j = 0; j < 5; j++) {
                if (parent && parent.style && 
                    (parent.style.position === 'fixed' || 
                     parent.style.position === 'absolute' ||
                     parent.getAttribute('role') === 'dialog')) {
                  isInPreview = true;
                  break;
                }
                parent = parent ? parent.parentElement : null;
              }
              // Auto-send large preview images
              if (isInPreview && img.src && !img.src.startsWith('data:')) {
                sendImageUrl(img.src);
              }
            }
          }
        });
        observer.observe(document.body, { childList: true, subtree: true });
      })();
    ''');
  }

  void _onImageSelected(String url) {
    if (_isDialogShowing || !mounted) return;

    setState(() {
      _selectedImageUrl = url;
      _showSelectedBanner = true;
    });

    // Auto-show confirmation dialog
    _showConfirmationDialog(url);
  }

  void _showConfirmationDialog(String url) {
    if (_isDialogShowing || !mounted) return;
    _isDialogShowing = true;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child:
            Container(
                  constraints: const BoxConstraints(maxWidth: 380),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.15),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.4 : 0.08,
                        ),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Image Preview
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                        child: Stack(
                          children: [
                            Image.network(
                              url,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (_, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 200,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.03),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => Container(
                                height: 140,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.03),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        PhosphorIcons.imageSquare(),
                                        size: 36,
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.black26,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        loc.imageSearchPreviewFail,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.black38,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Gradient overlay at bottom
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      (isDark
                                              ? const Color(0xFF1E1E2E)
                                              : Colors.white)
                                          .withValues(alpha: 0.9),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                        child: Column(
                          children: [
                            // Title Row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.primaryColor.withValues(
                                          alpha: 0.15,
                                        ),
                                        AppTheme.primaryColor.withValues(
                                          alpha: 0.05,
                                        ),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    PhosphorIcons.imageSquare(
                                      PhosphorIconsStyle.fill,
                                    ),
                                    color: AppTheme.primaryColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        loc.imageSearchUseThis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 17,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        loc.imageSearchConfirmDesc,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Action Buttons
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: Row(
                          children: [
                            // Cancel
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: isDark
                                          ? Colors.white12
                                          : Colors.black12,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  loc.cancelLabel,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Use Image
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx); // Close dialog
                                  if (mounted) {
                                    Navigator.pop(
                                      context,
                                      url,
                                    ); // Close sheet, return URL
                                  }
                                },
                                icon: Icon(
                                  PhosphorIcons.check(PhosphorIconsStyle.bold),
                                  size: 18,
                                ),
                                label: Text(
                                  loc.imageSearchSelect,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 200.ms)
                .scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1, 1),
                  duration: 200.ms,
                  curve: Curves.easeOutCubic,
                ),
      ),
    ).then((_) {
      _isDialogShowing = false;
    });
  }

  void _pasteFromClipboard() async {
    final loc = AppLocalizations.of(context)!;
    final data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null && data.text!.startsWith('http')) {
      if (mounted) {
        Navigator.pop(context, data.text!);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(PhosphorIcons.warning(), color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(loc.imageSearchNoValidUrl)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          backgroundColor: Colors.orange.shade700,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121218) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // ── Header ──
          _buildHeader(isDark, loc),

          // ── Instruction Banner ──
          _buildInstructionBanner(isDark, loc),

          // ── WebView ──
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: _showSelectedBanner
                      ? BorderRadius.zero
                      : const BorderRadius.vertical(bottom: Radius.circular(0)),
                  child: WebViewWidget(controller: _controller),
                ),
                // Loading overlay
                if (_isLoading)
                  Container(
                    color: (isDark ? Colors.black : Colors.white).withValues(
                      alpha: 0.7,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            loc.imageSearchLoading,
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Bottom Action Bar ──
          _buildBottomBar(isDark, loc),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Google Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.15),
                    AppTheme.primaryColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold),
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.imageSearchTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    loc.imageSearchHint,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Paste URL button
            _buildHeaderAction(
              icon: PhosphorIcons.clipboardText(),
              label: loc.imageSearchPasteUrl,
              isDark: isDark,
              onTap: _pasteFromClipboard,
            ),
            const SizedBox(width: 4),
            // Close button
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold), size: 20),
              style: IconButton.styleFrom(
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionBanner(bool isDark, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isDark
          ? AppTheme.primaryColor.withValues(alpha: 0.08)
          : AppTheme.primaryColor.withValues(alpha: 0.04),
      child: Row(
        children: [
          Icon(
            PhosphorIcons.info(PhosphorIconsStyle.fill),
            size: 16,
            color: AppTheme.primaryColor.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              loc.imageSearchInstruction,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark, AppLocalizations loc) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: _showSelectedBanner && _selectedImageUrl != null
          ? _buildSelectedBar(isDark, loc)
          : _buildDefaultBar(isDark, loc),
    );
  }

  Widget _buildDefaultBar(bool isDark, AppLocalizations loc) {
    return Row(
      children: [
        Icon(
          PhosphorIcons.cursorClick(),
          size: 18,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            loc.imageSearchBottomHint,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.black45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedBar(bool isDark, AppLocalizations loc) {
    return Row(
      children: [
        // Thumbnail
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            _selectedImageUrl!,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                PhosphorIcons.imageSquare(),
                size: 20,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.imageSearchImageReady,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                loc.imageSearchTapToConfirm,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Use button
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_pulseController.value * 0.03),
              child: child,
            );
          },
          child: FilledButton.icon(
            onPressed: () {
              if (_selectedImageUrl != null && mounted) {
                Navigator.pop(context, _selectedImageUrl);
              }
            },
            icon: Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: 16),
            label: Text(
              loc.imageSearchSelect,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.3, duration: 300.ms);
  }
}
