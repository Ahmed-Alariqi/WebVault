import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_highlighter/flutter_highlighter.dart';
import 'package:flutter_highlighter/themes/atom-one-dark.dart';
import 'package:flutter_highlighter/themes/github.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/website_model.dart';
import '../../data/models/ai_chat_model.dart';
import '../../presentation/providers/ai_assistant_providers.dart';
import '../../l10n/app_localizations.dart';

class CodeElementBuilder extends MarkdownElementBuilder {
  final bool isDark;
  CodeElementBuilder(this.isDark);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (!element.textContent.contains('\n')) {
      return null; // Inline code uses default style
    }
    var language = 'dart';
    if (element.attributes['class'] != null) {
      String lg = element.attributes['class'] as String;
      if (lg.startsWith('language-')) {
        language = lg.substring(9);
      }
    }
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282C34) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: HighlightView(
          element.textContent.trim(),
          language: language,
          theme: isDark ? atomOneDarkTheme : githubTheme,
          padding: const EdgeInsets.all(12),
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        ),
      ),
    );
  }
}

class AiChatScreen extends ConsumerStatefulWidget {
  final WebsiteModel site;

  const AiChatScreen({super.key, required this.site});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  bool _isScanningMode = true;
  Timer? _scanningTimer;

  @override
  void initState() {
    super.initState();
    _scanningTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _isScanningMode = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scanningTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    ref.read(aiChatProvider(widget.site).notifier).sendMessage(text);
    _controller.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;
    final chatState = ref.watch(aiChatProvider(widget.site));

    // Auto-scroll when new messages arrive
    ref.listen(aiChatProvider(widget.site), (
      AiChatState? prev,
      AiChatState next,
    ) {
      if (prev?.messages.length != next.messages.length ||
          prev?.isLoading != next.isLoading) {
        _scrollToBottom();
      }
    });

    // Show error snackbar
    if (chatState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(chatState.error!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        ref.read(aiChatProvider(widget.site).notifier).clearError();
      });
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: Column(
        children: [
          // ── Premium Header ──
          _buildHeader(context, isDark, loc),
          // ── Chat Body ──
          Expanded(
            child: _isScanningMode
                ? _buildScanningView(context, isDark, loc)
                : (chatState.messages.isEmpty
                      ? _buildWelcomeView(context, isDark, loc)
                      : _buildChatList(context, isDark, chatState)),
          ),
          // ── Input Bar ──
          _buildInputBar(
            context,
            isDark,
            loc,
            chatState.isLoading || _isScanningMode,
          ),
        ],
      ),
    );
  }

  // ── Header with item context ──
  Widget _buildHeader(BuildContext context, bool isDark, AppLocalizations loc) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppTheme.darkSurface, AppTheme.darkBg]
              : [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withValues(alpha: 0.8),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: back + title + clear
          Row(
            children: [
              // Back / Close button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // AI badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      loc.aiAssistant,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Clear chat button
              GestureDetector(
                onTap: () =>
                    ref.read(aiChatProvider(widget.site).notifier).clearChat(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    PhosphorIcons.trash(),
                    color: Colors.white70,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Item context card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                // Item icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    PhosphorIcons.globe(PhosphorIconsStyle.fill),
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.site.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            PhosphorIcons.linkSimple(),
                            size: 10,
                            color: Colors.white38,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              loc.aiContextLoaded,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }

  // ── Scanning view ──
  Widget _buildScanningView(
    BuildContext context,
    bool isDark,
    AppLocalizations loc,
  ) {
    // Show "Fetching data from [URL]"
    final domain = widget.site.url.isNotEmpty
        ? Uri.tryParse(widget.site.url)?.host ?? widget.site.url
        : widget.site.title;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glowing search/globe icon
          Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.05,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                          PhosphorIcons.scan(),
                          size: 64,
                          color: AppTheme.accentColor,
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .slideY(begin: -0.3, end: 0.3, duration: 1000.ms)
                        .fadeIn(duration: 500.ms),
                  ],
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.05, 1.05),
                duration: 1000.ms,
              )
              .shimmer(duration: 1500.ms, color: Colors.white24),

          const SizedBox(height: 32),

          // Scanning text
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'جاري جلب البيانات من $domain...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 500.ms),

          const SizedBox(height: 16),

          Text(
            loc.aiContextLoaded, // Usually translates to something suitable
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    ).animate().fadeOut(delay: 1700.ms, duration: 300.ms);
  }

  // ── Welcome view with suggested questions ──
  Widget _buildWelcomeView(
    BuildContext context,
    bool isDark,
    AppLocalizations loc,
  ) {
    final suggestions = [
      loc.aiSuggestWhat,
      loc.aiSuggestHow,
      loc.aiSuggestFeatures,
      loc.aiSuggestUse,
      loc.aiSuggestFit,
      loc.aiSuggestSimplify,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          // AI Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              PhosphorIcons.robot(PhosphorIconsStyle.fill),
              color: Colors.white,
              size: 36,
            ),
          ).animate().scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
            duration: 500.ms,
            curve: Curves.easeOutBack,
          ),
          const SizedBox(height: 20),
          Text(
            loc.aiAssistant,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            loc.aiPoweredBy,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 32),
          // Suggested questions grid
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: suggestions.asMap().entries.map((entry) {
              final i = entry.key;
              final q = entry.value;
              return GestureDetector(
                    onTap: () => _sendMessage(q),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIcons.sparkle(),
                            size: 14,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              q,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.lightTextPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: (400 + i * 80).ms)
                  .slideY(begin: 0.2, end: 0, delay: (400 + i * 80).ms);
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Chat message list ──
  Widget _buildChatList(
    BuildContext context,
    bool isDark,
    AiChatState chatState,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i >= chatState.messages.length) {
          // Loading indicator
          return _buildTypingIndicator(isDark);
        }
        final msg = chatState.messages[i];
        return _buildMessageBubble(context, msg, isDark, i);
      },
    );
  }

  // ── Single message bubble ──
  Widget _buildMessageBubble(
    BuildContext context,
    AiChatMessage msg,
    bool isDark,
    int index,
  ) {
    final isUser = msg.isUser;
    return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82,
            ),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser
                  ? AppTheme.primaryColor
                  : (isDark ? AppTheme.darkSurface : Colors.white),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
              border: isUser
                  ? null
                  : Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
              boxShadow: [
                BoxShadow(
                  color: isUser
                      ? AppTheme.primaryColor.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: isUser
                ? Text(
                    msg.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  )
                : _TypewriterMarkdown(
                    content: msg.content,
                    isDark: isDark,
                    animate:
                        index ==
                        ref.read(aiChatProvider(widget.site)).messages.length -
                            1,
                  ),
          ),
        )
        .animate()
        .fadeIn(duration: 250.ms)
        .slideX(begin: isUser ? 0.1 : -0.1, end: 0, duration: 250.ms);
  }

  // ── Typing indicator ──
  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0, isDark),
            const SizedBox(width: 5),
            _buildDot(1, isDark),
            const SizedBox(width: 5),
            _buildDot(2, isDark),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildDot(int index, bool isDark) {
    return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(0.6, 0.6),
          end: const Offset(1.0, 1.0),
          duration: 600.ms,
          delay: (index * 200).ms,
        )
        .fadeIn(begin: 0.3, duration: 600.ms, delay: (index * 200).ms);
  }

  // ── Input Bar ──
  Widget _buildInputBar(
    BuildContext context,
    bool isDark,
    AppLocalizations loc,
    bool isLoading,
  ) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !isLoading,
                textInputAction: TextInputAction.send,
                onSubmitted: (text) => _sendMessage(text),
                maxLines: 3,
                minLines: 1,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: loc.aiTypeMessage,
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white30 : Colors.black26,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isLoading ? null : () => _sendMessage(_controller.text),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: isLoading
                    ? null
                    : LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.accentColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: isLoading
                    ? (isDark ? Colors.white10 : Colors.black12)
                    : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isLoading
                    ? null
                    : [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Icon(
                PhosphorIcons.paperPlaneRight(PhosphorIconsStyle.fill),
                color: isLoading ? Colors.grey : Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Typewriter Markdown Widget ──
class _TypewriterMarkdown extends StatefulWidget {
  final String content;
  final bool isDark;
  final bool animate;

  const _TypewriterMarkdown({
    required this.content,
    required this.isDark,
    this.animate = false,
  });

  @override
  State<_TypewriterMarkdown> createState() => _TypewriterMarkdownState();
}

class _TypewriterMarkdownState extends State<_TypewriterMarkdown> {
  String _displayedText = '';
  Timer? _timer;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    if (widget.animate && widget.content.isNotEmpty) {
      _startTypewriter();
    } else {
      _displayedText = widget.content;
      _isComplete = true;
    }
  }

  @override
  void didUpdateWidget(covariant _TypewriterMarkdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      if (widget.animate && !_isComplete) {
        _startTypewriter();
      } else {
        _displayedText = widget.content;
        _isComplete = true;
      }
    }
  }

  void _startTypewriter() {
    _timer?.cancel();
    _displayedText = '';
    _isComplete = false;
    int charIndex = 0;
    final totalChars = widget.content.length;
    // Speed: ~1ms per char for ultra fast feeling
    _timer = Timer.periodic(const Duration(milliseconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      // Add multiple characters per tick for longer texts
      final charsPerTick = totalChars > 500 ? 10 : (totalChars > 200 ? 5 : 3);
      charIndex += charsPerTick;
      if (charIndex >= totalChars) {
        charIndex = totalChars;
        timer.cancel();
        _isComplete = true;
      }
      setState(() {
        _displayedText = widget.content.substring(0, charIndex);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: _displayedText,
      selectable: true,
      onTapLink: (text, href, title) {
        if (href != null) {
          launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
        }
      },
      builders: {'code': CodeElementBuilder(widget.isDark)},
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          color: widget.isDark
              ? AppTheme.darkTextPrimary
              : AppTheme.lightTextPrimary,
          fontSize: 14,
          height: 1.6,
        ),
        h1: TextStyle(
          color: widget.isDark
              ? AppTheme.darkTextPrimary
              : AppTheme.lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        h2: TextStyle(
          color: widget.isDark
              ? AppTheme.darkTextPrimary
              : AppTheme.lightTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        h3: TextStyle(
          color: widget.isDark
              ? AppTheme.darkTextPrimary
              : AppTheme.lightTextPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        strong: TextStyle(
          color: widget.isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w700,
        ),
        listBullet: TextStyle(
          color: widget.isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
          fontSize: 14,
        ),
        code: TextStyle(
          color: AppTheme.primaryColor,
          backgroundColor: widget.isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          fontSize: 13,
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isDark ? Colors.white10 : Colors.black12,
          ),
        ),
        a: TextStyle(
          color: AppTheme.accentColor,
          decoration: TextDecoration.underline,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
              width: 3,
            ),
          ),
        ),
      ),
    );
  }
}
