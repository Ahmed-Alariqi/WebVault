import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/providers.dart';
import '../../data/models/clipboard_item_model.dart';

class FloatingClipboard extends ConsumerStatefulWidget {
  const FloatingClipboard({super.key});

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
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
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
    final items = ref.watch(clipboardItemsProvider);
    final screenSize = MediaQuery.of(context).size;

    return Stack(
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
                        // Items list
                        if (items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No clipboard items.\nAdd values from the Clipboard tab.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white54 : Colors.black45,
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
    );
  }

  Widget _buildClipItem(ClipboardItemModel item, bool isDark) {
    return GestureDetector(
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
      child: Container(
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
            Icon(
              Icons.copy_rounded,
              size: 14,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 150.ms);
  }
}
