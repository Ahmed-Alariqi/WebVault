import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/providers.dart';
import '../../data/models/website_model.dart';
import '../../data/models/page_model.dart';
import '../../core/utils/text_utils.dart';
import '../../l10n/app_localizations.dart';
import '../clipboard/floating_clipboard.dart';
import 'package:uuid/uuid.dart';

class DiscoverBrowserScreen extends ConsumerStatefulWidget {
  final WebsiteModel site;

  const DiscoverBrowserScreen({super.key, required this.site});

  @override
  ConsumerState<DiscoverBrowserScreen> createState() =>
      _DiscoverBrowserScreenState();
}

class _DiscoverBrowserScreenState extends ConsumerState<DiscoverBrowserScreen> {
  late WebViewController _controller;
  double _progress = 0;
  bool _isLoading = true;
  bool _isFullscreen = false; // Toggle for fullscreen mode

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  void _initPage() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            if (mounted) setState(() => _progress = p / 100);
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.site.url));
  }

  void _saveToPages() {
    final newPage = PageModel(
      id: const Uuid().v4(),
      url: widget.site.url,
      title: widget.site.title,
      notes: TextUtils.getPlainTextFromDescription(widget.site.description),
      tags: widget.site.tags,
      createdAt: DateTime.now(),
      lastOpened: DateTime.now(),
    );

    ref.read(pagesProvider.notifier).addPage(newPage);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved to Pages: ${widget.site.title}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isFullscreen
          ? null
          : AppBar(
              leading: IconButton(
                icon: Icon(PhosphorIcons.arrowLeft()),
                onPressed: () => context.pop(),
              ),
              title: Text(
                widget.site.title,
                style: const TextStyle(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  icon: Icon(PhosphorIcons.folderPlus(), size: 20),
                  onPressed: _saveToPages,
                  tooltip: 'Save to Pages',
                ),
                IconButton(
                  icon: Icon(PhosphorIcons.cornersOut(), size: 20),
                  onPressed: () => setState(() => _isFullscreen = true),
                  tooltip: 'Fullscreen',
                ),
                IconButton(
                  icon: Icon(PhosphorIcons.arrowSquareOut(), size: 20),
                  onPressed: () => launchUrl(
                    Uri.parse(widget.site.url),
                    mode: LaunchMode.externalApplication,
                  ),
                  tooltip: AppLocalizations.of(context)!.openInBrowser,
                ),
              ],
            ),
      body: SafeArea(
        top:
            _isFullscreen, // Only apply safe area on top if fullscreen to prevent notch overlap
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),

            // Loading indicator
            if (_isLoading && !_isFullscreen)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(AppTheme.accentColor),
                  minHeight: 3,
                ),
              ),

            // Fullscreen Exit Button Overlay
            if (_isFullscreen)
              Positioned(
                bottom: 30,
                right: 30,
                child: FloatingActionButton(
                  mini: true,
                  heroTag: 'exit_fullscreen',
                  onPressed: () => setState(() => _isFullscreen = false),
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.8),
                  child: Icon(
                    PhosphorIcons.cornersIn(),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),

            // Floating clipboard tool (always active)
            FloatingClipboard(webViewController: _controller),
          ],
        ),
      ),
    );
  }
}
