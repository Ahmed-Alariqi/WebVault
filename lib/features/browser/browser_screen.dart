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
import '../../presentation/widgets/tutorial_overlay.dart';
import '../../utils/clipboard_helper.dart';
import '../../core/utils/page_content_extractor.dart';
import '../ai_assistant/ai_chat_bottom_sheet.dart';
import '../clipboard/floating_clipboard.dart';
import '../../data/models/website_model.dart';

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
  final GlobalKey _suggestKey = GlobalKey();
  final GlobalKey _clipboardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initPage();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTutorial());
  }

  Future<void> _checkTutorial() async {
    final shouldShow = await TutorialManager.shouldShowSection(TutorialSection.browser);
    if (mounted && shouldShow) {
      final l10n = AppLocalizations.of(context)!;
      TutorialOverlay.show(
        context,
        section: TutorialSection.browser,
        steps: TutorialManager.getBrowserSteps(l10n, _clipboardKey, _suggestKey),
        onComplete: () {
          if (mounted) setState(() {});
        },
      );
    }
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
            key: _suggestKey,
            icon: Icon(PhosphorIcons.paperPlaneTilt(), size: 20),
            onPressed: () => showSuggestionDialog(
              context,
              ref,
              title: currentPage.title,
              url: currentPage.url,
            ),
            tooltip: AppLocalizations.of(context)!.suggestToAdmin,
          ),
          Tooltip(
            message: AppLocalizations.of(context)!.browserAiAssistant,
            child: InkWell(
              onTap: () async {
                // Show scanning snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(AppLocalizations.of(context)!.browserAiScanning),
                      ],
                    ),
                    backgroundColor: AppTheme.primaryColor,
                    duration: const Duration(seconds: 2),
                  ),
                );

                try {
                  // Extract dynamic page content
                  final contentData = await PageContentExtractor.extractPageData(_controller);
                  final pageContent = contentData['content'];

                  if (!context.mounted) return;
                  
                  // Store extracted content and open bottom sheet
                  ref.read(extractedBrowserContentProvider.notifier).state = pageContent;
                  ref.read(aiBottomSheetStateProvider.notifier).state = 
                      const AiBottomSheetState(isVisible: true, isExpanded: false);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.browserAiExtractError),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              },
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                  size: 20,
                  color: const Color(0xFF8A2BE2),
                ),
              ),
            ),
          ),
          Tooltip(
            message: 'Toggle Clipboard (Long press to Quick-Add)',
            child: InkWell(
              key: _clipboardKey,
              onTap: () {
                ref
                    .read(clipboardVisibilityProvider.notifier)
                    .update((s) => !s);
              },
              onLongPress: () {
                ClipboardHelper.showManualEntrySheet(context, ref);
              },
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  ref.watch(clipboardVisibilityProvider)
                      ? PhosphorIcons.clipboardText(PhosphorIconsStyle.fill)
                      : PhosphorIcons.clipboardText(),
                  size: 20,
                ),
              ),
            ),
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
          if (_isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.transparent,
                color: AppTheme.primaryColor,
              ),
            ),
          // Floating Clipboard Integration
          FloatingClipboard(webViewController: _controller),
          // AI Chat Bottom Sheet Area
          if (_page != null)
            AiChatBottomSheet(
              site: WebsiteModel(
                id: _page!.id,
                title: _page!.title,
                url: _page!.url,
                description: _page!.notes,
                contentType: 'website',
                categoryId: _page!.folderId ?? '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ),
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
