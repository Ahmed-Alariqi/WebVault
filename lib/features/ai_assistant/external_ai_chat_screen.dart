import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/theme/app_theme.dart';
import '../../presentation/providers/ai_assistant_providers.dart';
import '../../data/models/ai_chat_model.dart';
import 'ai_chat_screen.dart'; // For CodeElementBuilder

// ─────────────────────────────────────────────────────────────────────────────
// Smart starter suggestions — context-aware
// ─────────────────────────────────────────────────────────────────────────────
List<Map<String, String>> _getSmartPrompts(String contextText) {
  final isUrl = contextText.trim().startsWith('http');

  if (isUrl) {
    return [
      {'icon': '📝', 'label': 'لخّص المحتوى', 'prompt': 'لخّص محتوى هذا الرابط باختصار واضح'},
      {'icon': '💡', 'label': 'الفكرة الرئيسية', 'prompt': 'ما هي الفكرة أو الرسالة الرئيسية في هذا الرابط؟'},
      {'icon': '🔑', 'label': 'أبرز النقاط', 'prompt': 'استخرج أبرز النقاط والمعلومات الهامة'},
      {'icon': '❓', 'label': 'أسئلة وأجوبة', 'prompt': 'اطرح علي أسئلة مفيدة حول محتوى هذا الرابط'},
    ];
  } else if (contextText.isNotEmpty) {
    return [
      {'icon': '🧠', 'label': 'اشرح لي', 'prompt': 'اشرح لي هذا النص بطريقة بسيطة وواضحة'},
      {'icon': '🌍', 'label': 'ترجم', 'prompt': 'ترجم هذا النص إلى العربية إذا كان بالإنجليزية، أو العكس'},
      {'icon': '✍️', 'label': 'حسّن الصياغة', 'prompt': 'حسّن صياغة هذا النص وأجعله أكثر احترافية'},
      {'icon': '📌', 'label': 'استخرج المصطلحات', 'prompt': 'استخرج المصطلحات والكلمات المفتاحية الهامة من هذا النص'},
    ];
  } else {
    return [
      {'icon': '🚀', 'label': 'ابدأ محادثة', 'prompt': 'مرحباً! ماذا يمكنك مساعدتي به اليوم؟'},
      {'icon': '✍️', 'label': 'اكتب لي', 'prompt': 'ساعدني في كتابة محتوى احترافي'},
      {'icon': '💡', 'label': 'أعطني أفكاراً', 'prompt': 'أعطني أفكاراً إبداعية لمشروعي'},
      {'icon': '📚', 'label': 'علّمني', 'prompt': 'علمني شيئاً جديداً ومفيداً اليوم'},
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ExternalAiChatScreen
// ─────────────────────────────────────────────────────────────────────────────
class ExternalAiChatScreen extends ConsumerStatefulWidget {
  final String initialText;

  const ExternalAiChatScreen({
    super.key,
    required this.initialText,
  });

  @override
  ConsumerState<ExternalAiChatScreen> createState() => _ExternalAiChatScreenState();
}

class _ExternalAiChatScreenState extends ConsumerState<ExternalAiChatScreen>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  late String _contextText;

  // STT
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  // Typing animation
  late AnimationController _typingDotController;

  @override
  void initState() {
    super.initState();
    _contextText = widget.initialText;

    _typingDotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Initialise sessions provider for this context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_contextText.isEmpty) {
        _loadClipboardContext();
      } else {
        ref.read(quickSessionsProvider.notifier).openForContext(_contextText);
      }

      // Restore draft
      final draft = ref.read(quickSessionsProvider.notifier).loadDraft();
      if (draft.isNotEmpty) {
        _controller.text = draft;
        _controller.selection =
            TextSelection.fromPosition(TextPosition(offset: draft.length));
      }
    });

    _controller.addListener(() {
      ref.read(quickSessionsProvider.notifier).saveDraft(_controller.text);
    });
  }

  Future<void> _loadClipboardContext() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty && mounted) {
      setState(() => _contextText = data.text!);
      ref.read(quickSessionsProvider.notifier).openForContext(_contextText);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingDotController.dispose();
    _speech.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    ref.read(quickSessionsProvider.notifier).sendMessage(text, _contextText);
    _controller.clear();
    _scrollToBottom();
  }

  void _toggleListening() async {
    if (!_speech.isAvailable) {
      bool available = await _speech.initialize(
        onError: (_) => setState(() => _isListening = false),
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
      );
      if (!available && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('التعرف على الصوت غير متاح الآن.', style: TextStyle()), backgroundColor: Colors.red.shade700),
        );
        return;
      }
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      final started = await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            setState(() {
              _controller.text = result.recognizedWords;
              _controller.selection = TextSelection.fromPosition(
                TextPosition(offset: _controller.text.length),
              );
              _isListening = false;
            });
          }
        },
        localeId: 'ar_SA',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
      );
      setState(() => _isListening = started);
    }
  }

  // ── History Sheet ────────────────────────────────────────────────────────

  void _showHistorySheet(bool isDark, List<QuickChatSession> sessions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _HistorySheet(
        sessions: sessions,
        isDark: isDark,
        activeId: ref.read(quickSessionsProvider).activeSessionId,
        onSelect: (id) {
          Navigator.pop(context);
          setState(() {
            _contextText = ""; // Clear clipboard context when loading an old chat
          });
          ref.read(quickSessionsProvider.notifier).switchToSession(id);
        },
        onDelete: (id) {
          ref.read(quickSessionsProvider.notifier).deleteSession(id);
        },
        onNewSession: () {
          Navigator.pop(context);
          ref.read(quickSessionsProvider.notifier).startNewSession(_contextText);
        },
      ),
    );
  }

  Future<void> _confirmClearActive(BuildContext ctx, bool isDark) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'حذف المحادثة الحالية',
          style: TextStyle(
            
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
          textDirection: TextDirection.rtl,
        ),
        content: Text(
          'هل تريد مسح رسائل المحادثة الحالية؟ ستبقى المحادثات الأخرى في السجل.',
          style: TextStyle(
            
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: Text('إلغاء',
                style: TextStyle(
                    
                    color: isDark ? Colors.white60 : Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('حذف',
                style: TextStyle(
                     color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(quickSessionsProvider.notifier).clearActiveSession();
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sessionsState = ref.watch(quickSessionsProvider);
    final messages = sessionsState.activeMessages;
    final isLoading = sessionsState.isLoading;

    if (isLoading) _scrollToBottom();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Blurred background
          Positioned.fill(
            child: GestureDetector(
              onTap: () => SystemNavigator.pop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: (isDark ? Colors.black : Colors.white)
                      .withValues(alpha: 0.4),
                ),
              ),
            ),
          ),

          // Main bottom sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 1.0, end: 0.0),
              builder: (context, value, child) =>
                  Transform.translate(offset: Offset(0, value * 500), child: child),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.92,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(26)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, -5),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(26)),
                  child: Column(
                    children: [
                      _buildHeader(isDark, sessionsState.sessions),
                      _buildContextBanner(isDark),
                      Expanded(
                        child: messages.isEmpty
                            ? _buildWelcome(isDark)
                            : _buildChatList(context, isDark, messages, isLoading),
                      ),
                      _buildInputBar(isDark, isLoading, messages.isEmpty),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark, List<QuickChatSession> sessions) {
    return Container(
      color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black26,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Row(
            children: [
              // Close
              IconButton(
                icon: Icon(PhosphorIcons.x(),
                    color: isDark ? Colors.white : Colors.black87),
                onPressed: () => SystemNavigator.pop(),
              ),
              const Spacer(),
              // Title
              Icon(
                PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                color: const Color(0xFF8A2BE2),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'مرشد زاد السريع',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  
                ),
              ),
              const Spacer(),
              // History
              if (sessions.isNotEmpty)
                IconButton(
                  icon: Icon(PhosphorIcons.clockCounterClockwise(),
                      color: isDark ? Colors.white60 : Colors.black45, size: 20),
                  tooltip: 'سجل المحادثات',
                  onPressed: () => _showHistorySheet(isDark, sessions),
                ),
              // Clear current
              IconButton(
                icon: Icon(PhosphorIcons.trash(),
                    color: isDark ? Colors.white54 : Colors.black45, size: 20),
                tooltip: 'حذف المحادثة الحالية',
                onPressed: () => _confirmClearActive(context, isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Context Banner ───────────────────────────────────────────────────────

  Widget _buildContextBanner(bool isDark) {
    if (_contextText.isEmpty) return const SizedBox.shrink();

    if (_contextText.trim().startsWith('http')) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 80,
          child: AnyLinkPreview(
            link: _contextText.trim(),
            displayDirection: UIDirection.uiDirectionHorizontal,
            showMultimedia: true,
            bodyMaxLines: 1,
            bodyTextOverflow: TextOverflow.ellipsis,
            titleStyle: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              
            ),
            bodyStyle: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 11,
              
            ),
            errorWidget: _buildTextContextChip(isDark),
            cache: const Duration(days: 7),
            backgroundColor: Colors.transparent,
            borderRadius: 0,
            removeElevation: true,
          ),
        ),
      );
    }

    return _buildTextContextChip(isDark);
  }

  Widget _buildTextContextChip(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(PhosphorIcons.textT(), size: 15, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _contextText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              textDirection: TextDirection.ltr,
            ),
          ),
        ],
      ),
    );
  }

  // ── Welcome  ─────────────────────────────────────────────────────────────

  Widget _buildWelcome(bool isDark) {
    final prompts = _getSmartPrompts(_contextText);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIcons.robot(PhosphorIconsStyle.fill),
              size: 44,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'كيف يمكنني مساعدتك؟',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
              
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _contextText.isNotEmpty
                ? 'لقد استلمت المحتوى — اختر اقتراحاً أو اكتب سؤالك'
                : 'اكتب سؤالك أو اختر اقتراحاً للبدء',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.black45,
              
            ),
          ),
          const SizedBox(height: 28),

          // Smart suggestion cards
          ...prompts.map((p) => _SmartPromptCard(
                icon: p['icon']!,
                label: p['label']!,
                prompt: p['prompt']!,
                isDark: isDark,
                onTap: () => _sendMessage(p['prompt']!),
              )),
        ],
      ),
    );
  }

  // ── Chat List ────────────────────────────────────────────────────────────

  Widget _buildChatList(
    BuildContext context,
    bool isDark,
    List<AiChatMessage> messages,
    bool isLoading,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length + (isLoading ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == messages.length && isLoading) {
          return _buildTypingIndicator(isDark);
        }
        final msg = messages[i];
        return _ChatBubble(msg: msg, isDark: isDark, context: ctx);
      },
    );
  }

  // ── Typing Indicator ─────────────────────────────────────────────────────

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: const Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: AnimatedBuilder(
          animation: _typingDotController,
          builder: (_, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final delay = index * 0.33;
                final phase = (_typingDotController.value - delay).clamp(0.0, 1.0);
                final opacity = (0.3 + 0.7 * _bounceCurve(phase)).clamp(0.3, 1.0);
                final scale = 0.7 + 0.3 * _bounceCurve(phase);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: opacity),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  double _bounceCurve(double t) {
    if (t < 0.5) return 2 * t;
    return 2 * (1 - t);
  }

  // ── Input Bar ────────────────────────────────────────────────────────────

  Widget _buildInputBar(bool isDark, bool isLoading, bool isEmpty) {
    return Container(
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Voice button
              _VoiceButton(
                isDark: isDark,
                isListening: _isListening,
                onTap: _toggleListening,
              ),
              const SizedBox(width: 8),

              // Text Field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: _isListening
                          ? AppTheme.primaryColor.withValues(alpha: 0.6)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06)),
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: !isLoading,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendMessage,
                    maxLines: 4,
                    minLines: 1,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: _isListening ? 'جارٍ الاستماع...' : 'اكتب سؤالك هنا...',
                      hintStyle: TextStyle(
                        color: _isListening
                            ? AppTheme.primaryColor
                            : (isDark ? Colors.white30 : Colors.black38),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Send button
              GestureDetector(
                onTap: isLoading ? null : () => _sendMessage(_controller.text),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isLoading
                        ? AppTheme.primaryColor.withValues(alpha: 0.4)
                        : AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    PhosphorIcons.paperPlaneRight(PhosphorIconsStyle.fill),
                    color: Colors.white,
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


}

// ─────────────────────────────────────────────────────────────────────────────
// Chat Bubble
// ─────────────────────────────────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final AiChatMessage msg;
  final bool isDark;
  final BuildContext context;

  const _ChatBubble(
      {required this.msg, required this.isDark, required this.context});

  @override
  Widget build(BuildContext c) {
    final isUser = msg.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 2),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(c).size.width * 0.84,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? AppTheme.primaryColor
              : (isDark ? AppTheme.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomLeft:
                isUser ? const Radius.circular(4) : const Radius.circular(20),
            bottomRight:
                !isUser ? const Radius.circular(4) : const Radius.circular(20),
          ),
          boxShadow: isUser
              ? [
                  BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
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
                textDirection: TextDirection.rtl,
              )
            : MarkdownBody(
                data: msg.content,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                    height: 1.6,
                    
                  ),
                  h1: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    
                  ),
                  h2: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    
                  ),
                  h3: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    
                  ),
                  code: TextStyle(
                    color: AppTheme.primaryColor,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF282C34)
                        : const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  blockquoteDecoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: AppTheme.primaryColor,
                        width: 3,
                      ),
                    ),
                  ),
                  listBullet: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  a: TextStyle(
                    color: AppTheme.primaryColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
                builders: {
                  'code': CodeElementBuilder(isDark, context),
                },
                onTapLink: (text, href, title) {
                  if (href != null) {
                    launchUrl(Uri.parse(href),
                        mode: LaunchMode.externalApplication);
                  }
                },
              ),
          ),
          if (!isUser) // Copy action button below bubble
            Padding(
              padding: const EdgeInsets.only(bottom: 14, right: 8, top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: 'نسخ',
                    child: GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: msg.content));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('تم النسخ', style: TextStyle()),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppTheme.primaryColor,
                            duration: const Duration(seconds: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(PhosphorIcons.copy(), size: 14, color: isDark ? Colors.white38 : Colors.black38),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else 
            const SizedBox(height: 14),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Smart Prompt Card
// ─────────────────────────────────────────────────────────────────────────────
class _SmartPromptCard extends StatelessWidget {
  final String icon;
  final String label;
  final String prompt;
  final bool isDark;
  final VoidCallback onTap;

  const _SmartPromptCard({
    required this.icon,
    required this.label,
    required this.prompt,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppTheme.primaryColor.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    prompt,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
            Icon(PhosphorIcons.arrowLeft(),
                size: 16,
                color: isDark ? Colors.white38 : Colors.black38),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Voice Button
// ─────────────────────────────────────────────────────────────────────────────
class _VoiceButton extends StatelessWidget {
  final bool isDark;
  final bool isListening;
  final VoidCallback onTap;

  const _VoiceButton(
      {required this.isDark, required this.isListening, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: isListening
              ? AppTheme.primaryColor.withValues(alpha: 0.15)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isListening
                ? AppTheme.primaryColor.withValues(alpha: 0.6)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Icon(
          isListening
              ? PhosphorIcons.microphoneSlash(PhosphorIconsStyle.fill)
              : PhosphorIcons.microphone(PhosphorIconsStyle.fill),
          color: isListening
              ? AppTheme.primaryColor
              : (isDark ? Colors.white54 : Colors.black45),
          size: 20,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// History Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _HistorySheet extends StatelessWidget {
  final List<QuickChatSession> sessions;
  final bool isDark;
  final String? activeId;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onDelete;
  final VoidCallback onNewSession;

  const _HistorySheet({
    required this.sessions,
    required this.isDark,
    required this.activeId,
    required this.onSelect,
    required this.onDelete,
    required this.onNewSession,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...sessions]
      ..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black26,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Title row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(PhosphorIcons.clockCounterClockwise(),
                    color: AppTheme.primaryColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  'سجل المحادثات',
                  style: TextStyle(
                    
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onNewSession,
                  icon: Icon(PhosphorIcons.plus(), size: 16),
                  label: const Text('جديد', style: TextStyle( fontSize: 13)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 4),

          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: sorted.length,
              itemBuilder: (_, i) {
                final s = sorted[i];
                final isActive = s.id == activeId;
                return Dismissible(
                  key: ValueKey(s.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => onDelete(s.id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  ),
                  child: ListTile(
                    onTap: () => onSelect(s.id),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.primaryColor.withValues(alpha: 0.15)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        PhosphorIcons.chatCircle(PhosphorIconsStyle.fill),
                        size: 16,
                        color: isActive
                            ? AppTheme.primaryColor
                            : (isDark ? Colors.white54 : Colors.black45),
                      ),
                    ),
                    title: Text(
                      s.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      '${s.messages.length} رسالة · ${_timeAgo(s.lastActivity)}',
                      style: TextStyle(
                        
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                    trailing: isActive
                        ? Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                            color: AppTheme.primaryColor, size: 18)
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inDays < 1) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
