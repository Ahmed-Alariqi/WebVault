import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../data/services/transcription_service.dart';
import '../../presentation/providers/ai_assistant_providers.dart';
import '../../l10n/app_localizations.dart';

class CodeElementBuilder extends MarkdownElementBuilder {
  final bool isDark;
  final BuildContext context;
  CodeElementBuilder(this.isDark, this.context);

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
    final codeText = element.textContent.trim();
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF282C34) : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Code block header: language + copy ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    language,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  const Spacer(),
                  _CopyCodeButton(code: codeText, isDark: isDark),
                ],
              ),
            ),
            // ── Code body ──
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: HighlightView(
                  codeText,
                  language: language,
                  theme: isDark ? atomOneDarkTheme : githubTheme,
                  padding: const EdgeInsets.all(12),
                  textStyle: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small copy button used inside code blocks
class _CopyCodeButton extends StatefulWidget {
  final String code;
  final bool isDark;
  const _CopyCodeButton({required this.code, required this.isDark});

  @override
  State<_CopyCodeButton> createState() => _CopyCodeButtonState();
}

class _CopyCodeButtonState extends State<_CopyCodeButton> {
  bool _copied = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _copy,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _copied
            ? Icon(
                Icons.check_rounded,
                key: const ValueKey('check'),
                size: 14,
                color: Colors.green,
              )
            : Icon(
                Icons.copy_rounded,
                key: const ValueKey('copy'),
                size: 14,
                color: widget.isDark ? Colors.white38 : Colors.black38,
              ),
      ),
    );
  }
}

class AiChatScreen extends ConsumerStatefulWidget {
  final WebsiteModel site;
  final bool isFromBrowser;
  final bool showHeader;

  const AiChatScreen({
    super.key, 
    required this.site,
    this.isFromBrowser = false,
    this.showHeader = true,
  });

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _controller      = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode        = FocusNode();

  // ── Voice input (STT) ────────────────────────────────────────────────
  final _transcriptionService = TranscriptionService();
  bool _isRecording    = false; // mic is capturing audio
  bool _isTranscribing = false; // audio sent to Groq, waiting for text

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
    _transcriptionService.dispose(); // release mic resources
    super.dispose();
  }

  // ── Voice Input Handlers ─────────────────────────────────────────────

  /// Starts microphone recording (called on mic button tap/hold-start).
  Future<void> _startVoiceInput() async {
    try {
      HapticFeedback.mediumImpact();
      await _transcriptionService.startRecording();
      if (mounted) setState(() => _isRecording = true);
    } catch (e) {
      final msg = e.toString().contains('microphone_permission_denied')
          ? 'يرجى السماح بالوصول إلى الميكروفون من إعدادات التطبيق.'
          : 'خطأ في بدء التسجيل: $e';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  /// Stops recording, sends to Groq Whisper and puts text in the input field.
  Future<void> _stopVoiceInput() async {
    if (!_isRecording) return;
    setState(() { _isRecording = false; _isTranscribing = true; });
    HapticFeedback.lightImpact();
    try {
      final text = await _transcriptionService.stopAndTranscribe();
      if (mounted && text.isNotEmpty) {
        _controller.text = text;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: text.length),
        );
        HapticFeedback.selectionClick();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل التحويل: $e'),
            backgroundColor: Colors.orange.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTranscribing = false);
    }
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
    HapticFeedback.lightImpact();
    
    final pageContent = widget.isFromBrowser 
        ? ref.read(extractedBrowserContentProvider)
        : null;
        
    ref.read(aiChatProvider(widget.site).notifier).sendMessage(text, pageContent);
    _controller.clear();
    _scrollToBottom();
  }

  /// Detects whether [text] is primarily Arabic ('ar') or English ('en').
  String _detectLanguage(String text) {
    final arabicPattern = RegExp(r'[\u0600-\u06FF]');
    return arabicPattern.hasMatch(text) ? 'ar' : 'en';
  }

  /// Generates contextual follow-up suggestion chips based on the AI response.
  List<String> _generateDynamicSuggestions(
    String lastAiContent,
    String lastUserMessage,
  ) {
    final lang = _detectLanguage(lastUserMessage);
    final lower = lastAiContent.toLowerCase();
    final hasCode = lastAiContent.contains('```');
    final mentionsInstall = lower.contains('install') ||
        lower.contains('npm ') ||
        lower.contains('pip ') ||
        lower.contains('brew ') ||
        lower.contains('apt ') ||
        lower.contains('\u062a\u062b\u0628\u064a\u062a') ||
        lower.contains('setup');
    final mentionsUsage = lower.contains('how to use') ||
        lower.contains('usage') ||
        lower.contains('run the') ||
        lower.contains('execute') ||
        lower.contains('\u0643\u064a\u0641 \u062a\u0633\u062a\u062e\u062f\u0645') ||
        lower.contains('\u0637\u0631\u064a\u0642\u0629 \u0627\u0644\u0627\u0633\u062a\u062e\u062f\u0627\u0645');
    final mentionsFeature = lower.contains('feature') ||
        lower.contains('support') ||
        lower.contains('capability') ||
        lower.contains('\u0645\u064a\u0632\u0629') ||
        lower.contains('\u064a\u062f\u0639\u0645');

    if (lang == 'ar') {
      if (mentionsInstall && !hasCode) {
        return ['\u0623\u0639\u0637\u0646\u064a \u0643\u0648\u062f \u0627\u0644\u062a\u062b\u0628\u064a\u062a', '\u0645\u0627 \u0627\u0644\u0645\u062a\u0637\u0644\u0628\u0627\u062a \u0627\u0644\u0623\u0633\u0627\u0633\u064a\u0629\u061f', '\u0643\u064a\u0641 \u0623\u062a\u062d\u0642\u0642 \u0645\u0646 \u0627\u0644\u062a\u062b\u0628\u064a\u062a\u061f'];
      } else if (hasCode) {
        return ['\u0627\u0634\u0631\u062d \u0627\u0644\u0643\u0648\u062f \u0628\u0634\u0643\u0644 \u0623\u0628\u0633\u0637', '\u0647\u0644 \u0647\u0646\u0627\u0643 \u0623\u062e\u0637\u0627\u0621 \u0634\u0627\u0626\u0639\u0629\u061f', '\u0643\u064a\u0641 \u0623\u062b\u0628\u0651\u062a \u0647\u0630\u0647 \u0627\u0644\u0623\u062f\u0627\u0629\u061f'];
      } else if (mentionsUsage) {
        return ['\u0623\u0639\u0637\u0646\u064a \u0645\u062b\u0627\u0644 \u0639\u0645\u0644\u064a', '\u0645\u0627 \u0623\u0647\u0645 \u0627\u0644\u0625\u0639\u062f\u0627\u062f\u0627\u062a\u061f', '\u0645\u0627 \u0627\u0644\u0623\u062e\u0637\u0627\u0621 \u0627\u0644\u0634\u0627\u0626\u0639\u0629\u061f'];
      } else if (mentionsFeature) {
        return ['\u0643\u064a\u0641 \u0623\u0633\u062a\u062e\u062f\u0645\u0647\u0627\u061f', '\u0643\u064a\u0641 \u0623\u062b\u0628\u0651\u062a\u0647\u0627\u061f', '\u0647\u0644 \u062a\u0648\u062c\u062f \u0646\u0633\u062e\u0629 \u0645\u062c\u0627\u0646\u064a\u0629\u061f'];
      }
      return ['\u0643\u064a\u0641 \u0623\u0633\u062a\u062e\u062f\u0645\u0647\u0627\u061f', '\u0623\u0639\u0637\u0646\u064a \u0645\u062b\u0627\u0644 \u0643\u0648\u062f', '\u0647\u0644 \u0647\u0646\u0627\u0643 \u0623\u062f\u0627\u0629 \u0628\u062f\u064a\u0644\u0629\u061f'];
    } else {
      if (mentionsInstall && !hasCode) {
        return ['Show me the install code', 'What are the prerequisites?', 'How to verify installation?'];
      } else if (hasCode) {
        return ['Explain the code further', 'What are common errors?', 'How do I install this?'];
      } else if (mentionsUsage) {
        return ['Give me a practical example', 'What are key settings?', 'What are common pitfalls?'];
      } else if (mentionsFeature) {
        return ['How do I use it?', 'How do I install it?', 'Is there a free plan?'];
      }
      return ['How do I use it?', 'Show me a code example', 'Is there an alternative?'];
    }
  }

  /// Builds the animated follow-up suggestion chips shown after each AI reply.
  Widget _buildDynamicChips(
    BuildContext context,
    bool isDark,
    List<String> suggestions,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 2),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions.asMap().entries.map((entry) {
          final i = entry.key;
          final label = entry.value;
          return _SuggestionChip(
            label: label,
            isDark: isDark,
            onTap: () => _sendMessage(label),
          )
              .animate()
              .fadeIn(delay: (i * 90).ms, duration: 220.ms)
              .slideY(begin: 0.15, end: 0, delay: (i * 90).ms, duration: 220.ms);
        }).toList(),
      ),
    );
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
          // ── Premium Header (Hidden in Bottom Sheet) ──
          if (widget.showHeader)
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
            chatState.messages.isEmpty,
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
              return _SuggestionChip(
                    label: q,
                    isDark: isDark,
                    onTap: () => _sendMessage(q),
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
    final messages = chatState.messages;
    final lastIsAssistant = messages.isNotEmpty && !messages.last.isUser;
    final showDynamicChips = lastIsAssistant && !chatState.isLoading;
    final chipsIndex = messages.length;
    final typingIndex = messages.length + (showDynamicChips ? 1 : 0);
    final totalCount =
        messages.length + (showDynamicChips ? 1 : 0) + (chatState.isLoading ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: totalCount,
      itemBuilder: (ctx, i) {
        // Regular message bubbles
        if (i < messages.length) {
          return _buildMessageBubble(context, messages[i], isDark, i);
        }
        // Dynamic follow-up chips after last AI reply
        if (showDynamicChips && i == chipsIndex) {
          final lastAiMsg = messages.last;
          final lastUserMsg = messages.lastWhere(
            (m) => m.isUser,
            orElse: () => lastAiMsg,
          );
          final suggestions = _generateDynamicSuggestions(
            lastAiMsg.content,
            lastUserMsg.content,
          );
          return _buildDynamicChips(context, isDark, suggestions);
        }
        // Typing indicator while loading
        if (chatState.isLoading && i == typingIndex) {
          return _buildTypingIndicator(isDark);
        }
        return const SizedBox.shrink();
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
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TypewriterMarkdown(
                        content: msg.content,
                        isDark: isDark,
                        animate:
                            index ==
                            ref
                                    .read(aiChatProvider(widget.site))
                                    .messages
                                    .length -
                                1,
                      ),
                      const SizedBox(height: 6),
                      // ── Copy entire reply button ──
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: _CopyReplyButton(
                          text: msg.content,
                          isDark: isDark,
                        ),
                      ),
                    ],
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
    bool isChatEmpty,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isFromBrowser && !isLoading && isChatEmpty)
            _buildQuickPrompts(isDark),
          Row(
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
          const SizedBox(width: 8),

          // ── Microphone button (Voice Input / STT) ───────────────────
          GestureDetector(
            onTap: isLoading
                ? null
                : (_isRecording ? _stopVoiceInput : _startVoiceInput),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _isRecording
                    ? Colors.red.shade500
                    : _isTranscribing
                        ? AppTheme.primaryColor.withValues(alpha: 0.6)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.black.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isRecording
                      ? Colors.red.shade400
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08)),
                ),
                boxShadow: _isRecording
                    ? [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.4),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: _isTranscribing
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : Icon(
                      _isRecording
                          ? PhosphorIcons.stop(PhosphorIconsStyle.fill)
                          : PhosphorIcons.microphone(PhosphorIconsStyle.fill),
                      color: _isRecording
                          ? Colors.white
                          : (isDark ? Colors.white60 : Colors.black45),
                      size: 20,
                    ),
            )
            .animate(target: _isRecording ? 1.0 : 0.0)
            .scaleXY(begin: 1.0, end: 1.08, duration: 600.ms, curve: Curves.easeInOut)
            .then()
            .scaleXY(begin: 1.08, end: 1.0, duration: 600.ms, curve: Curves.easeInOut),
          ),

          const SizedBox(width: 8),

          // ── Send button ─────────────────────────────────────────────
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
      ],
      ),
    );
  }
  // ── Quick Prompts (Chips) ──
  Widget _buildQuickPrompts(bool isDark) {
    final prompts = ["لخص هذه الصفحة", "اشرح الفكرة الرئيسية", "استخرج الأكواد البرمجية"];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: prompts.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            return ActionChip(
              label: Text(
                prompts[index],
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white : Colors.black87,
                  fontFamily: 'Cairo',
                ),
              ),
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onPressed: () {
                _sendMessage(prompts[index]);
              },
            );
          },
        ),
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
      builders: {'code': CodeElementBuilder(widget.isDark, context)},
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

/// Copy-entire-reply button shown at the bottom of AI responses
class _CopyReplyButton extends StatefulWidget {
  final String text;
  final bool isDark;
  const _CopyReplyButton({required this.text, required this.isDark});

  @override
  State<_CopyReplyButton> createState() => _CopyReplyButtonState();
}

class _CopyReplyButtonState extends State<_CopyReplyButton> {
  bool _copied = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.text));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _copy,
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _copied
              ? Row(
                  key: const ValueKey('copied'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Colors.green.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'تم النسخ',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade400,
                      ),
                    ),
                  ],
                )
              : Row(
                  key: const ValueKey('copy'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.copy_rounded,
                      size: 13,
                      color: widget.isDark ? Colors.white24 : Colors.black26,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'نسخ',
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.isDark ? Colors.white24 : Colors.black26,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Reusable animated suggestion chip with press effect + haptic
// ══════════════════════════════════════════════════════════════════
class _SuggestionChip extends StatefulWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _pressed
                ? (widget.isDark
                    ? Colors.white.withValues(alpha: 0.13)
                    : AppTheme.primaryColor.withValues(alpha: 0.09))
                : (widget.isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _pressed
                  ? AppTheme.primaryColor.withValues(alpha: 0.45)
                  : (widget.isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                size: 12,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
