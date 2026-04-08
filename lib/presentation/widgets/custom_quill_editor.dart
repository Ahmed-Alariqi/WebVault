import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../core/theme/app_theme.dart';

class CustomQuillEditor extends StatefulWidget {
  final QuillController controller;
  final String label;
  final String? helperText;
  final double height;

  const CustomQuillEditor({
    super.key,
    required this.controller,
    required this.label,
    this.helperText,
    this.height = 150.0,
  });

  @override
  State<CustomQuillEditor> createState() => _CustomQuillEditorState();
}

class _CustomQuillEditorState extends State<CustomQuillEditor> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Default border color based on theme
    final baseBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);

    // Active border color (when focused)
    final activeBorderColor = AppTheme.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),

        // Editor Container
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: _isFocused ? 0.06 : 0.04)
                : Colors.black.withValues(alpha: _isFocused ? 0.04 : 0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isFocused ? activeBorderColor : baseBorderColor,
              width: _isFocused ? 1.5 : 1.0,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: activeBorderColor.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              // Toolbar
              Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: isDark ? Colors.grey[850] : Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  child: QuillSimpleToolbar(
                    controller: widget.controller,
                    config: const QuillSimpleToolbarConfig(
                      showFontFamily: false,
                      showFontSize: false,
                      showSmallButton: true,
                      showInlineCode: true,
                      showColorButton: true,
                      showBackgroundColorButton: true,
                      showClearFormat: true,
                      showAlignmentButtons: true,
                      showListNumbers: true,
                      showListBullets: true,
                      showListCheck: true,
                      showCodeBlock: true,
                      showQuote: true,
                      showIndent: true,
                      showLink: true,
                      showDividers: true,
                      showDirection: true,
                      showSuperscript: false,
                      multiRowsDisplay: false,
                    ),
                  ),
                ),
              ),

              // Editor Area
              GestureDetector(
                onTap: () {
                  if (!_focusNode.hasFocus) {
                    _focusNode.requestFocus();
                  }
                },
                child: Container(
                  height: widget.height,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.02)
                        : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(15),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.85)
                          : Colors.black87,
                    ),
                    child: QuillEditor.basic(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      config: QuillEditorConfig(
                        padding: EdgeInsets.zero,
                        placeholder: widget.helperText ?? '',
                        scrollable: true,
                        expands: true,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Helper Text (Bottom)
        if (widget.helperText != null && widget.helperText!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              widget.helperText!,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ),
      ],
    );
  }
}
