import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_theme.dart';

class GoogleImageSearchSheet extends StatefulWidget {
  final String initialQuery;

  const GoogleImageSearchSheet({super.key, this.initialQuery = ''});

  @override
  State<GoogleImageSearchSheet> createState() => _GoogleImageSearchSheetState();
}

class _GoogleImageSearchSheetState extends State<GoogleImageSearchSheet> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final query = Uri.encodeComponent(widget.initialQuery);
    final url =
        'https://www.google.com/search?tbm=isch&q=$query&tbs=isz:l'; // isz:l forces large images if possible

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'ImagePicker',
        onMessageReceived: (JavaScriptMessage message) {
          final src = message.message;
          if (src.startsWith('http')) {
            _showSelectionDialog(src);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            // Inject Javascript to intercept long presses on images
            _controller.runJavaScript('''
              document.addEventListener('contextmenu', function(e) {
                if (e.target.tagName === 'IMG') {
                  e.preventDefault();
                  ImagePicker.postMessage(e.target.src);
                }
              });
              
              // Also add a floating hint
              var div = document.createElement('div');
              div.style.position = 'fixed';
              div.style.bottom = '20px';
              div.style.left = '50%';
              div.style.transform = 'translateX(-50%)';
              div.style.backgroundColor = 'rgba(0,0,0,0.8)';
              div.style.color = '#fff';
              div.style.padding = '10px 20px';
              div.style.borderRadius = '20px';
              div.style.fontSize = '14px';
              div.style.zIndex = '999999';
              div.style.pointerEvents = 'none';
              div.innerText = 'Long press any image to select it';
              document.body.appendChild(div);
            ''');
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  void _showSelectionDialog(String url) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(PhosphorIcons.image(), color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            const Text('Use this Image?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                url,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                  height: 100,
                  child: Center(child: Text('Preview not available')),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Do you want to use this image link?',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context, url); // Close bottom sheet and return URL
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Use Image'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIcons.googleLogo(PhosphorIconsStyle.fill),
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Google Images',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Long press an image to select it',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
              ],
            ),
          ),

          // Manual Paste Fallback
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkCard.withValues(alpha: 0.5)
                          : AppTheme.lightCard.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    child: Text(
                      'If long-press fails, manually copy the URL in the browser and tap Paste & Use:',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data != null &&
                        data.text != null &&
                        data.text!.startsWith('http')) {
                      if (context.mounted) {
                        Navigator.pop(context, data.text!);
                      }
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No valid link found in clipboard'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.content_paste, size: 16),
                  label: const Text('Paste'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // WebView
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
