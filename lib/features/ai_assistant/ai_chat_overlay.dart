import 'package:flutter/material.dart';
import '../../data/models/website_model.dart';
import 'ai_chat_screen.dart';

class AiChatOverlay {
  static OverlayEntry? _entry;

  static void show(
    BuildContext context,
    WebsiteModel site, {
    OverlayEntry? above,
  }) {
    if (_entry != null) return;

    _entry = OverlayEntry(
      builder: (context) => DraggableAiChatWidget(site: site, onClose: hide),
    );

    final overlay = Navigator.of(context, rootNavigator: true).overlay;
    if (overlay != null) {
      if (above != null) {
        overlay.insert(_entry!, above: above);
      } else {
        overlay.insert(_entry!);
      }
    } else {
      Overlay.of(context, rootOverlay: true).insert(_entry!);
    }
  }

  static void showWithOverlay(OverlayState overlay, WebsiteModel site) {
    if (_entry != null) return;

    _entry = OverlayEntry(
      builder: (context) => DraggableAiChatWidget(site: site, onClose: hide),
    );

    overlay.insert(_entry!);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}

class DraggableAiChatWidget extends StatefulWidget {
  final WebsiteModel site;
  final VoidCallback onClose;

  const DraggableAiChatWidget({
    super.key,
    required this.site,
    required this.onClose,
  });

  @override
  State<DraggableAiChatWidget> createState() => _DraggableAiChatWidgetState();
}

class _DraggableAiChatWidgetState extends State<DraggableAiChatWidget>
    with SingleTickerProviderStateMixin {
  bool _isFullScreen = true;
  // Fallback initial offset for PIP mode, we will update this in didChangeDependencies
  Offset _bottomRightOffset = const Offset(20, 100);
  bool _hasInitializedOffset = false;

  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutQuart,
    );
    _animController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedOffset) {
      final size = MediaQuery.of(context).size;
      // Position bottom right initially: offset distance from right and bottom
      final padding = MediaQuery.of(context).padding;
      _bottomRightOffset = Offset(
        size.width - 320 - 16, // Assuming 320 is pip width, 16 is padding
        size.height - 450 - padding.bottom - 16,
      ); // 450 pip height
      _hasInitializedOffset = true;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  void _handleClose() {
    _animController.reverse().then((_) {
      widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final viewInsets = MediaQuery.of(context).viewInsets;

    // Define PIP size
    const double pipWidth = 320;
    const double pipHeight = 450;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Positioned(
          left: _isFullScreen ? 0 : _bottomRightOffset.dx,
          top: _isFullScreen
              ? 0
              : _bottomRightOffset.dy -
                    (viewInsets.bottom > 0 ? viewInsets.bottom / 2 : 0),
          width: _isFullScreen ? size.width : pipWidth,
          height: _isFullScreen ? size.height : pipHeight,
          child: child!,
        );
      },
      child: Transform.scale(
        scale: _scaleAnimation.value,
        alignment: Alignment.bottomRight,
        child: Opacity(
          opacity: _scaleAnimation.value,
          child: GestureDetector(
            onPanUpdate: _isFullScreen
                ? null
                : (details) {
                    setState(() {
                      _bottomRightOffset += details.delta;

                      // Clamp offset to screen boundaries
                      final double maxX = size.width - pipWidth;
                      final double maxY =
                          size.height - pipHeight - viewInsets.bottom;

                      _bottomRightOffset = Offset(
                        _bottomRightOffset.dx.clamp(0, maxX),
                        _bottomRightOffset.dy.clamp(0, maxY),
                      );
                    });
                  },
            child: Material(
              elevation: _isFullScreen ? 0 : 20,
              type: MaterialType.transparency,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_isFullScreen ? 0 : 24),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: _isFullScreen
                        ? null
                        : Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                    borderRadius: BorderRadius.circular(_isFullScreen ? 0 : 24),
                    boxShadow: _isFullScreen
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                  ),
                  child: AiChatScreen(
                    site: widget.site,
                    isPipMode: !_isFullScreen,
                    onToggleScrn: _toggleFullScreen,
                    onClose: _handleClose,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
