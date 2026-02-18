import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/providers.dart';
import '../../presentation/widgets/suggestion_dialog.dart';
import '../../data/models/page_model.dart';
import '../../l10n/app_localizations.dart';
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
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.error)),
        body: Center(child: Text(AppLocalizations.of(context)!.pageNotFound)),
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
            tooltip: AppLocalizations.of(context)!.back,
          ),
          IconButton(
            icon: Icon(PhosphorIcons.caretRight(), size: 20),
            onPressed: () => _controller.goForward(),
            tooltip: AppLocalizations.of(context)!.forward,
          ),
          IconButton(
            icon: Icon(PhosphorIcons.arrowClockwise(), size: 20),
            onPressed: () => _controller.reload(),
            tooltip: AppLocalizations.of(context)!.refresh,
          ),
          IconButton(
            icon: Icon(PhosphorIcons.folderPlus(), size: 20),
            onPressed: () => _showAddToFolder(context, widget.pageId),
            tooltip: AppLocalizations.of(context)!.addToFolder,
          ),
          IconButton(
            icon: Icon(PhosphorIcons.paperPlaneTilt(), size: 20),
            onPressed: () => showSuggestionDialog(
              context,
              ref,
              title: currentPage.title,
              url: currentPage.url,
            ),
            tooltip: AppLocalizations.of(context)!.suggestToAdmin,
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
            tooltip: AppLocalizations.of(context)!.openInBrowser,
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

  void _showAddToFolder(BuildContext context, String pageId) {
    final folders = ref.read(foldersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context)!.addToFolder,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (folders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  AppLocalizations.of(context)!.noFoldersYet,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              )
            else
              ...folders.map(
                (folder) => ListTile(
                  leading: Icon(
                    PhosphorIcons.folder(),
                    color: Color(folder.colorValue),
                  ),
                  title: Text(
                    folder.name,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  onTap: () {
                    ref
                        .read(pagesProvider.notifier)
                        .addToFolder(pageId, folder.id);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.addedTo(folder.name),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
