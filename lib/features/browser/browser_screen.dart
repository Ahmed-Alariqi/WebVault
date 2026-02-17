import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/providers.dart';
import '../../data/models/page_model.dart';
import '../clipboard/floating_clipboard.dart';

class BrowserScreen extends ConsumerStatefulWidget {
  final String pageId;

  const BrowserScreen({super.key, required this.pageId});

  @override
  ConsumerState<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends ConsumerState<BrowserScreen> {
  late WebViewController _controller;
  double _progress = 0;
  bool _isLoading = true;
  PageModel? _page;

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  void _initPage() {
    final repo = ref.read(pageRepositoryProvider);
    _page = repo.getById(widget.pageId);
    if (_page == null) return;

    ref.read(pagesProvider.notifier).incrementVisit(widget.pageId);

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
      ..loadRequest(Uri.parse(_page!.url));
  }

  @override
  Widget build(BuildContext context) {
    if (_page == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Page not found')),
      );
    }

    // Re-read page state for favorite toggle
    final pages = ref.watch(pagesProvider);
    final currentPage = pages.firstWhere(
      (p) => p.id == widget.pageId,
      orElse: () => _page!,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft()),
          onPressed: () => context.pop(),
        ),
        title: Text(
          currentPage.title,
          style: const TextStyle(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.caretLeft(), size: 20),
            onPressed: () => _controller.goBack(),
            tooltip: 'Back',
          ),
          IconButton(
            icon: Icon(PhosphorIcons.caretRight(), size: 20),
            onPressed: () => _controller.goForward(),
            tooltip: 'Forward',
          ),
          IconButton(
            icon: Icon(PhosphorIcons.arrowClockwise(), size: 20),
            onPressed: () => _controller.reload(),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(
              currentPage.isFavorite
                  ? PhosphorIcons.heart(PhosphorIconsStyle.fill)
                  : PhosphorIcons.heart(),
              color: currentPage.isFavorite ? AppTheme.errorColor : null,
              size: 20,
            ),
            onPressed: () =>
                ref.read(pagesProvider.notifier).toggleFavorite(widget.pageId),
          ),
          IconButton(
            icon: Icon(PhosphorIcons.arrowSquareOut(), size: 20),
            onPressed: () => launchUrl(
              Uri.parse(currentPage.url),
              mode: LaunchMode.externalApplication,
            ),
            tooltip: 'Open in browser',
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          // Loading indicator
          if (_isLoading)
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
          // Floating clipboard
          const FloatingClipboard(),
        ],
      ),
    );
  }
}
