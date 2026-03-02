import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/providers.dart';
import '../../data/models/clipboard_item_model.dart';

class FloatingClipboard extends ConsumerStatefulWidget {
  final WebViewController? webViewController;

  const FloatingClipboard({super.key, this.webViewController});

  @override
  ConsumerState<FloatingClipboard> createState() => _FloatingClipboardState();
}

class _FloatingClipboardState extends ConsumerState<FloatingClipboard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  double _xPos = 20;
  double _yPos = 100;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  Timer? _inactivityTimer;
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _resetInactivityTimer();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    if (_opacity != 1.0) {
      if (mounted) setState(() => _opacity = 1.0);
    }
    _inactivityTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      if (_isExpanded) {
        _toggle();
      }
      setState(() {
        _opacity = 0.4;
      });
    });
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    _resetInactivityTimer();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allItems = ref.watch(clipboardItemsProvider);
    final groups = ref.watch(clipboardGroupsProvider);
    final activeGroupId = ref.watch(selectedClipboardGroupProvider);
    final isVisible = ref.watch(clipboardVisibilityProvider);
    final screenSize = MediaQuery.of(context).size;

    // Filter items based on active group
    final items = activeGroupId == null
        ? allItems
        : activeGroupId == 'uncategorized'
        ? allItems.where((i) => i.groupId == null).toList()
        : allItems.where((i) => i.groupId == activeGroupId).toList();

    if (!isVisible) {
      // If the clipboard tool is globally hidden, reset expansion and return empty box
      if (_isExpanded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _isExpanded = false);
        });
      }
      return const SizedBox.shrink();
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: _opacity,
      child: Listener(
        onPointerDown: (_) => _resetInactivityTimer(),
        child: Stack(
          children: [
            // Expanded panel
            if (_isExpanded)
              Positioned(
                right: 16,
                bottom: 100,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  alignment: Alignment.bottomRight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        width: 280,
                        constraints: BoxConstraints(
                          maxHeight: screenSize.height * 0.45,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.06),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppTheme.primaryColor,
                                          AppTheme.accentColor,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.content_paste_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Quick Clipboard',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : AppTheme.lightTextPrimary,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: _toggle,
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 20,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Divider(
                              height: 1,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.06),
                            ),
                            // Groups Filter Row
                            if (groups.isNotEmpty)
                              Container(
                                height: 40,
                                margin: const EdgeInsets.only(top: 8),
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  children: [
                                    _FloatingGroupChip(
                                      label: 'All',
                                      isSelected: activeGroupId == null,
                                      onTap: () =>
                                          ref
                                                  .read(
                                                    selectedClipboardGroupProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              null,
                                      isDark: isDark,
                                    ),
                                    _FloatingGroupChip(
                                      label: 'Uncategorized',
                                      isSelected:
                                          activeGroupId == 'uncategorized',
                                      onTap: () =>
                                          ref
                                                  .read(
                                                    selectedClipboardGroupProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              'uncategorized',
                                      isDark: isDark,
                                    ),
                                    ...groups.map(
                                      (g) => _FloatingGroupChip(
                                        label: g.name,
                                        isSelected: activeGroupId == g.id,
                                        color: Color(
                                          int.parse(
                                            g.colorHex.replaceFirst(
                                              '#',
                                              '0xFF',
                                            ),
                                          ),
                                        ),
                                        onTap: () =>
                                            ref
                                                .read(
                                                  selectedClipboardGroupProvider
                                                      .notifier,
                                                )
                                                .state = g
                                                .id,
                                        isDark: isDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Items list
                            if (items.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  'No clipboard items.\nAdd values from the Clipboard tab.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black45,
                                  ),
                                ),
                              )
                            else
                              Flexible(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  itemCount: items.length,
                                  itemBuilder: (context, i) {
                                    final item = items[i];
                                    return _buildClipItem(item, isDark);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // FAB
            Positioned(
              left: _xPos,
              top: _yPos,
              child: GestureDetector(
                onPanUpdate: (details) {
                  _resetInactivityTimer();
                  setState(() {
                    _xPos += details.delta.dx;
                    _yPos += details.delta.dy;
                    // Keep within bounds
                    _xPos = _xPos.clamp(0, screenSize.width - 56);
                    _yPos = _yPos.clamp(0, screenSize.height - 150);
                  });
                },
                onTap: _toggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isExpanded
                          ? [AppTheme.accentColor, AppTheme.primaryColor]
                          : [AppTheme.primaryColor, AppTheme.accentColor],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isExpanded
                        ? Icons.content_paste_go_rounded
                        : Icons.content_paste_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClipItem(ClipboardItemModel item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: item.isPinned
            ? Border.all(color: AppTheme.accentColor.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          if (item.isPinned)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                Icons.push_pin_rounded,
                size: 12,
                color: AppTheme.accentColor,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (widget.webViewController != null)
            GestureDetector(
              onTap: () {
                final jsCode =
                    '''
                  (function() {
                    const val = ${jsonEncode(item.value)};
                    const el = document.activeElement;
                    if (el && (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA' || el.isContentEditable)) {
                      if (el.isContentEditable) {
                        el.innerText += val;
                      } else {
                        const start = el.selectionStart || 0;
                        const end = el.selectionEnd || 0;
                        const text = el.value || '';
                        el.value = text.substring(0, start) + val + text.substring(end, text.length);
                        el.selectionStart = el.selectionEnd = start + val.length;
                        el.dispatchEvent(new Event('input', { bubbles: true }));
                        el.dispatchEvent(new Event('change', { bubbles: true }));
                      }
                      return true;
                    }
                    return false;
                  })();
                  ''';
                widget.webViewController!
                    .runJavaScriptReturningResult(jsCode)
                    .then((result) {
                      if (result == true || result == 'true') {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Injected "${item.label}"'),
                              backgroundColor: AppTheme.successColor,
                              duration: const Duration(milliseconds: 800),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please select a text field first.',
                              ),
                              duration: Duration(milliseconds: 1500),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    });
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  size: 16,
                  color: AppTheme.accentColor,
                ),
              ),
            ),
          if (item.value.trim().startsWith('http'))
            GestureDetector(
              onTap: () => launchUrl(
                Uri.parse(item.value),
                mode: LaunchMode.externalApplication,
              ),
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(
                  PhosphorIcons.arrowSquareOut(),
                  size: 18,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            )
          else if (item.type == ClipboardItemType.email)
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('mailto:${item.value}')),
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(
                  PhosphorIcons.envelopeSimple(),
                  size: 18,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: item.value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied "${item.label}"'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppTheme.successColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  duration: const Duration(milliseconds: 800),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(
                Icons.copy_rounded,
                size: 16,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 150.ms);
  }
}

class _FloatingGroupChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;
  final bool isDark;

  const _FloatingGroupChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = color ?? AppTheme.primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? primary
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? primary : Colors.transparent),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }
}
