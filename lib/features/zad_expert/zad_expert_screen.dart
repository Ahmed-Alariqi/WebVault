import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/theme/app_theme.dart';
import '../../data/models/ai_chat_model.dart';
import '../../data/models/ai_persona_model.dart';
import '../../presentation/providers/zad_expert_providers.dart';
import '../ai_assistant/ai_chat_screen.dart'; // For CodeElementBuilder
import '../ai_assistant/widgets/chat_prompt_bridge.dart';


// ─────────────────────────────────────────────────────────────────────────────
// Helper: Parse hex color
// ─────────────────────────────────────────────────────────────────────────────
Color hexToColor(String hex) {
  hex = hex.replaceAll('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  return Color(int.parse(hex, radix: 16));
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: Map icon name to PhosphorIcon
// ─────────────────────────────────────────────────────────────────────────────
IconData personaIconFromName(String name) {
  switch (name) {
    case 'code':
      return PhosphorIcons.code(PhosphorIconsStyle.fill);
    case 'paintBrush':
      return PhosphorIcons.paintBrush(PhosphorIconsStyle.fill);
    case 'pencilLine':
      return PhosphorIcons.pencilLine(PhosphorIconsStyle.fill);
    case 'magic':
      return PhosphorIcons.magicWand(PhosphorIconsStyle.fill);
    case 'robot':
      return PhosphorIcons.robot(PhosphorIconsStyle.fill);
    case 'brain':
      return PhosphorIcons.brain(PhosphorIconsStyle.fill);
    case 'graduationCap':
      return PhosphorIcons.graduationCap(PhosphorIconsStyle.fill);
    case 'lightbulb':
      return PhosphorIcons.lightbulb(PhosphorIconsStyle.fill);
    case 'chart':
      return PhosphorIcons.chartLineUp(PhosphorIconsStyle.fill);
    case 'treeStructure':
      return PhosphorIcons.treeStructure(PhosphorIconsStyle.fill);
    case 'flow':
      return PhosphorIcons.flowArrow(PhosphorIconsStyle.fill);
    default:
      return PhosphorIcons.sparkle(PhosphorIconsStyle.fill);
  }
}

class ZadExpertScreen extends ConsumerStatefulWidget {
  const ZadExpertScreen({super.key});

  @override
  ConsumerState<ZadExpertScreen> createState() => _ZadExpertScreenState();
}

class _ZadExpertScreenState extends ConsumerState<ZadExpertScreen>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  bool _isOverlayActive = false;
  final ScrollController _scrollController = ScrollController();
  final _focusNode = FocusNode();

  // STT
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _sttAvailable = true;
  bool _speechInitialized = false;

  // Typing animation
  late AnimationController _typingDotController;

  // Track current active session to auto-scroll on switch
  String? _lastActiveSessionId;

  @override
  void initState() {
    super.initState();
    _typingDotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
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

  /// Instant jump to bottom (used when opening a session that already has
  /// messages, so the user lands on the latest message instead of the first).
  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _sendMessage(String text) {
    final persona = ref.read(selectedPersonaProvider);
    if (text.trim().isEmpty || persona == null) return;
    HapticFeedback.lightImpact();
    ref.read(expertChatProvider(persona).notifier).sendMessage(text);
    _controller.clear();
    _scrollToBottom();
  }

  /// Pulls selected text into the input as a markdown quote so the user can
  /// ask a follow-up question about that specific passage.
  void _quoteAndAsk(String selected) {
    final trimmed = selected.trim();
    if (trimmed.isEmpty) return;
    HapticFeedback.lightImpact();
    final quoted =
        trimmed.split('\n').map((l) => '> $l').join('\n');
    final newText = '$quoted\n\n';
    setState(() {
      _controller.text = newText;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
    Future.microtask(() {
      if (!mounted) return;
      _focusNode.requestFocus();
      _scrollToBottom();
    });
  }

  /// Re-runs the last user prompt against the active persona. When [variant]
  /// is provided, a short hidden instruction is appended so the model
  /// produces a different style of answer (simpler / more detailed / with
  /// examples / etc.). The variant text never appears in the visible chat.
  void _handleRegenerate(AiPersonaModel persona, {String? variant}) {
    final chatState = ref.read(expertChatProvider(persona));
    final messages = chatState.activeMessages;
    if (messages.isEmpty) return;

    final lastMsg = messages.last;
    String? promptToResend;

    if (lastMsg.role == 'assistant') {
      if (messages.length >= 2) {
        promptToResend = messages[messages.length - 2].content;
        ref.read(expertChatProvider(persona).notifier).deleteLastMessage();
        ref.read(expertChatProvider(persona).notifier).deleteLastMessage();
      }
    } else {
      promptToResend = lastMsg.content;
      ref.read(expertChatProvider(persona).notifier).deleteLastMessage();
    }

    if (promptToResend == null) return;

    final modifier = variant == null || variant.isEmpty
        ? ''
        : '\n\n[توجيه للإجابة: $variant]';
    HapticFeedback.mediumImpact();
    _sendMessage(promptToResend + modifier);
  }

  Future<bool> _ensureSpeechReady() async {
    if (_speechInitialized && _speech.isAvailable) return true;
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('STT status: $status');
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (err) {
          debugPrint('STT error: ${err.errorMsg} permanent=${err.permanent}');
          if (mounted) {
            setState(() => _isListening = false);
            if (err.permanent) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تعذّر الوصول للميكروفون: ${err.errorMsg}'),
                  backgroundColor: Colors.red.shade700,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
      );
      _speechInitialized = available;
      if (mounted) setState(() => _sttAvailable = available);
      return available;
    } catch (e) {
      debugPrint('STT init exception: $e');
      _speechInitialized = false;
      if (mounted) setState(() => _sttAvailable = false);
      return false;
    }
  }

  void _toggleListening() async {
    if (_isListening) {
      HapticFeedback.lightImpact();
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    HapticFeedback.mediumImpact();
    final ready = await _ensureSpeechReady();
    if (!ready) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('التعرف على الصوت غير متاح. تأكد من إذن الميكروفون.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final basePrefix = _controller.text.trim().isEmpty
        ? ''
        : '${_controller.text.trim()} ';

    try {
      if (mounted) setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() {
            _controller.text = basePrefix + result.recognizedWords;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
            if (result.finalResult) {
              _isListening = false;
            }
          });
        },
        localeId: 'ar_SA',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.dictation,
        ),
      );
    } catch (e) {
      debugPrint('STT listen exception: $e');
      if (mounted) {
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في بدء التسجيل: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final personasAsync = ref.watch(expertPersonasProvider);
    final selectedPersona = ref.watch(selectedPersonaProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: personasAsync.when(
        loading: () => _buildLoadingView(isDark),
        error: (e, _) => _buildErrorView(isDark, e.toString()),
        data: (personas) {
          if (personas.isEmpty) {
            return _buildEmptyView(isDark);
          }

          // Auto-select first persona if none selected
          if (selectedPersona == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(selectedPersonaProvider.notifier).state = personas.first;
            });
            return _buildLoadingView(isDark);
          }

          final chatState = ref.watch(expertChatProvider(selectedPersona));
          final personaColor = hexToColor(selectedPersona.color);

          // Auto-scroll on new messages
          ref.listen(expertChatProvider(selectedPersona), (prev, next) {
            if (prev?.activeMessages.length != next.activeMessages.length ||
                prev?.isLoading != next.isLoading) {
              _scrollToBottom();
            }
          });

          // Error snackbar
          if (chatState.error != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(chatState.error!),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
              ref
                  .read(expertChatProvider(selectedPersona).notifier)
                  .clearError();
            });
          }

          return ChatPromptBridge(
            // Lets descendants (mermaid widgets, selection toolbars) push
            // a prompt back into this screen's input field.
            inject: _quoteAndAsk,
            child: Column(
              children: [
                _buildHeader(
                    isDark, selectedPersona, personaColor, personas),
                Expanded(
                  child: IgnorePointer(
                    ignoring: _isOverlayActive,
                    child: chatState.activeMessages.isEmpty
                        ? _buildWelcome(
                            isDark, selectedPersona, personaColor)
                        : _buildChatList(isDark, chatState, personaColor,
                            selectedPersona),
                  ),
                ),
                _buildPersonaStrip(isDark, personas, selectedPersona),
                _buildInputBar(
                    isDark, chatState.isLoading, personaColor),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Loading ──
  Widget _buildLoadingView(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'جارٍ تحميل الشخصيات...',
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black45,
              
            ),
          ),
        ],
      ),
    );
  }

  // ── Error ──
  Widget _buildErrorView(bool isDark, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIcons.warning(PhosphorIconsStyle.duotone),
                size: 64, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text('حدث خطأ في تحميل الشخصيات',
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    
                    fontSize: 16)),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontSize: 12)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(expertPersonasProvider),
              icon: Icon(PhosphorIcons.arrowClockwise()),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty ──
  Widget _buildEmptyView(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIcons.robot(PhosphorIconsStyle.duotone),
              size: 64, color: isDark ? Colors.white24 : Colors.black12),
          const SizedBox(height: 16),
          Text('لا توجد شخصيات متاحة حالياً',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black45,
              )),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, AiPersonaModel persona, Color personaColor,
      List<AiPersonaModel> personas) {
    final chatState = ref.watch(expertChatProvider(persona));
    
    // Optimized Branding: Near-solid for maximum clarity without glare
    final headerBgColor = isDark 
      ? Color.alphaBlend(personaColor.withValues(alpha: 0.94), AppTheme.darkSurface)
      : Color.alphaBlend(personaColor.withValues(alpha: 0.88), Colors.white);
    
    return Container(
      constraints: const BoxConstraints(minHeight: 65),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        bottom: 6,
        left: 4,
        right: 8,
      ),
      decoration: BoxDecoration(
        color: headerBgColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: personaColor.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          Expanded(
            child: GestureDetector(
              onTap: () => _showPersonaSelector(personas),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(personaIconFromName(persona.icon),
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          persona.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (chatState.isLoading)
                          Row(
                            children: [
                              const SizedBox(
                                width: 8,
                                height: 8,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                                ),
                              ).animate(onPlay: (c) => c.repeat()).rotate(duration: 2.seconds),
                              const SizedBox(width: 6),
                              const Text(
                                'يجري التفكير والرد...',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic,
                                ),
                              ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds, color: Colors.white),
                            ],
                          )
                        else
                          Text(
                            persona.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeaderActionBtn(
                icon: PhosphorIcons.plus(),
                isDark: isDark,
                isSolidHeader: true,
                onTap: () {
                  ref.read(expertChatProvider(persona).notifier).clearActiveSession();
                  HapticFeedback.lightImpact();
                },
              ),
              const SizedBox(width: 4),
              _HeaderActionBtn(
                icon: PhosphorIcons.clockCounterClockwise(),
                isDark: isDark,
                isSolidHeader: true,
                onTap: () => _showHistorySheet(isDark, persona),
              ),
              const SizedBox(width: 4),
              _HeaderActionBtn(
                icon: PhosphorIcons.userSwitch(),
                isDark: isDark,
                isSolidHeader: true,
                onTap: () => _showPersonaSelector(personas),
              ),
              PopupMenuButton<String>(
                icon: Icon(PhosphorIcons.dotsThreeVertical(), 
                    color: Colors.white, size: 22),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (value) {
                  if (value == 'export') {
                    _exportChat(persona, chatState.activeMessages);
                  } else if (value == 'delete') {
                    _confirmClearActive(isDark, persona);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.export(), size: 18, color: personaColor),
                        const SizedBox(width: 10),
                        const Text('تصدير'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.trash(), size: 18, color: Colors.redAccent),
                        const SizedBox(width: 10),
                        const Text('مسح', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }

  void _showPersonaSelector(List<AiPersonaModel> personas) {
    if (personas.isEmpty) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'اختر خبيرك الاستراتيجي',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.35, // Slimmer height, wider width
                ),
                itemCount: personas.length,
                itemBuilder: (context, index) {
                  final p = personas[index];
                  final isSelected = p.slug == ref.watch(selectedPersonaProvider)?.slug;
                  final pColor = hexToColor(p.color);

                  return InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      ref.read(selectedPersonaProvider.notifier).state = p;
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? pColor.withValues(alpha: 0.12)
                            : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.withValues(alpha: 0.06)),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? pColor : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: pColor,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: pColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ] : null,
                            ),
                            child: Icon(
                              personaIconFromName(p.icon),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            p.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            p.description,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white38 : Colors.black54,
                            ),
                          ),
                        ],
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

  void _showHistorySheet(bool isDark, AiPersonaModel persona) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _HistorySheet(
        sessions: ref.read(expertChatProvider(persona)).sessions,
        isDark: isDark,
        persona: persona,
        activeId: ref.read(expertChatProvider(persona)).activeSessionId,
        onSelect: (id) {
          Navigator.pop(context);
          ref.read(expertChatProvider(persona).notifier).switchToSession(id);
        },
        onDelete: (id) {
          ref.read(expertChatProvider(persona).notifier).deleteSession(id);
        },
        onNewSession: () {
          Navigator.pop(context);
          ref.read(expertChatProvider(persona).notifier).startNewSession();
        },
      ),
    );
  }

  Future<void> _exportChat(AiPersonaModel persona, List<AiChatMessage> messages) async {
    if (messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('المحادثة فارغة، لا يوجد شيء لتصديره')),
      );
      return;
    }

    try {
      final buffer = StringBuffer();
      buffer.writeln('# محادثة مع: ${persona.name}');
      buffer.writeln('### الوصف: ${persona.description}');
      buffer.writeln('---');
      for (final msg in messages) {
        if (msg.isUser) {
          buffer.writeln('**أنت:**');
        } else {
          buffer.writeln('**${persona.name}:**');
        }
        buffer.writeln(msg.content);
        buffer.writeln('');
      }

      final bytes = utf8.encode(buffer.toString());
      final xFile = XFile.fromData(
        Uint8List.fromList(bytes),
        name: 'ZadExpert_${persona.slug}_Chat.md',
        mimeType: 'text/markdown',
      );

      await Share.shareXFiles(
        [xFile],
        subject: 'تصدير محادثة خبير زاد - ${persona.name}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التصدير: $e')),
      );
    }
  }

  void _confirmClearActive(bool isDark, AiPersonaModel persona) async {
    setState(() => _isOverlayActive = true); // Block diagrams interaction
    
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('مسح المحادثة',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87)),
        content: Text(
          'هل تريد مسح جميع رسائل "${persona.name}"؟ لا يمكن التراجع عن هذا الفعل.',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء',
                style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف الآن'),
          ),
        ],
      ),
    );

    setState(() => _isOverlayActive = false); // Re-enable interaction

    if (confirmed == true && mounted) {
      ref.read(expertChatProvider(persona).notifier).clearActiveSession();
      HapticFeedback.vibrate();
    }
  }

  // ── Welcome View ──
  Widget _buildWelcome(
      bool isDark, AiPersonaModel persona, Color personaColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [personaColor, personaColor.withValues(alpha: 0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: personaColor.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(personaIconFromName(persona.icon),
                color: Colors.white, size: 40),
          )
              .animate()
              .scale(
                  begin: const Offset(0.7, 0.7),
                  curve: Curves.easeOutBack,
                  duration: 500.ms)
              .fadeIn(),
          const SizedBox(height: 20),

          Text(
            persona.name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
              
            ),
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 6),
          Text(
            persona.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.black45,
              
            ),
          ).animate().fadeIn(delay: 250.ms),

          const SizedBox(height: 32),

          // Quick actions
          ...persona.quickActions.asMap().entries.map((entry) {
            final i = entry.key;
            final action = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () {
                  _controller.text = action['prompt'] ?? '';
                  _focusNode.requestFocus();
                  // Move cursor to end
                  _controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: _controller.text.length),
                  );
                  HapticFeedback.lightImpact();
                },
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? personaColor.withValues(alpha: 0.1)
                        : personaColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: personaColor.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                          size: 16, color: personaColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          action['label'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                            
                          ),
                        ),
                      ),
                      Icon(PhosphorIcons.arrowRight(),
                          size: 16,
                          color: isDark ? Colors.white38 : Colors.black26),
                    ],
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: (300 + i * 100).ms, duration: 300.ms)
                .slideX(begin: 0.1, delay: (300 + i * 100).ms);
          }),
        ],
      ),
    );
  }

  // ── Chat List ──
  Widget _buildChatList(bool isDark, ExpertSessionsState chatState,
      Color personaColor, AiPersonaModel persona) {
    final messages = chatState.activeMessages;

    // Auto-jump to bottom whenever the active session changes (e.g. opening
    // the persona screen on an existing session, or switching from history).
    if (chatState.activeSessionId != _lastActiveSessionId) {
      _lastActiveSessionId = chatState.activeSessionId;
      _jumpToBottom();
    }

    // With streaming we insert an empty assistant placeholder as soon as the
    // request starts; that placeholder bubble itself renders inline typing
    // dots (see _InlineTypingDots in the bubble body), so the standalone
    // indicator below the list is only needed in the brief instant before
    // the placeholder is created OR if the last message is the user's.
    final last = messages.isNotEmpty ? messages.last : null;
    final showTyping = chatState.isLoading &&
        (last == null || last.role == 'user');

    // Locate the index of the most recent user-authored message so we can
    // light up its edit affordance — even when one or more assistant replies
    // come after it. Edit is suppressed while the assistant is streaming
    // (would corrupt the active generation), and only appears once the
    // reply finishes.
    int lastUserIndex = -1;
    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i].role == 'user') {
        lastUserIndex = i;
        break;
      }
    }
    final canEditLastUser = !chatState.isLoading && lastUserIndex != -1;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length + (showTyping ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == messages.length && showTyping) {
          return _buildTypingIndicator(isDark, personaColor);
        }
        final msg = messages[i];
        final isLastUserMsg = canEditLastUser && i == lastUserIndex;
        return _ExpertBubble(
          msg: msg,
          isDark: isDark,
          personaColor: personaColor,
          personaIcon: persona.icon,
          isLast: i == messages.length - 1,
          showEditAction: isLastUserMsg,
          onSuggestionSelected: (text) => _sendMessage(text),
          onRegenerate: ({String? variant}) =>
              _handleRegenerate(persona, variant: variant),
          onAskAbout: _quoteAndAsk,
          onEdit: isLastUserMsg
              ? (newText) {
                  HapticFeedback.mediumImpact();
                  ref
                      .read(expertChatProvider(persona).notifier)
                      .editAndResendLast(newText);
                  _scrollToBottom();
                }
              : null,
        );
      },
    );
  }

  // ── Typing indicator ──
  Widget _buildTypingIndicator(bool isDark, Color personaColor) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20)
              .copyWith(bottomRight: const Radius.circular(4)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: AnimatedBuilder(
          animation: _typingDotController,
          builder: (_, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final delay = index * 0.33;
                final phase =
                    (_typingDotController.value - delay).clamp(0.0, 1.0);
                final opacity =
                    (0.3 + 0.7 * _bounceCurve(phase)).clamp(0.3, 1.0);
                final scale = 0.7 + 0.3 * _bounceCurve(phase);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: personaColor.withValues(alpha: opacity),
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

  double _bounceCurve(double t) => t < 0.5 ? 2 * t : 2 * (1 - t);

  // ── Persona Strip (horizontal icons above input) ──
  Widget _buildPersonaStrip(
      bool isDark, List<AiPersonaModel> personas, AiPersonaModel selected) {
    if (personas.length <= 1) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: personas.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final p = personas[i];
            final isSelected = p.slug == selected.slug;
            final color = hexToColor(p.color);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(selectedPersonaProvider.notifier).state = p;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.15)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? color.withValues(alpha: 0.4)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(personaIconFromName(p.icon),
                        size: 16,
                        color: isSelected
                            ? color
                            : (isDark ? Colors.white38 : Colors.black38)),
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      Text(
                        p.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                          
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Input Bar ──
  Widget _buildInputBar(bool isDark, bool isLoading, Color personaColor) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Voice button
          if (_sttAvailable) ...[
            GestureDetector(
              onTap: _toggleListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _isListening
                      ? Colors.redAccent.withValues(alpha: 0.15)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.black.withValues(alpha: 0.04)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _isListening
                      ? PhosphorIcons.stop(PhosphorIconsStyle.fill)
                      : PhosphorIcons.microphone(),
                  color: _isListening
                      ? Colors.redAccent
                      : (isDark ? Colors.white54 : Colors.black45),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _isListening
                      ? personaColor.withValues(alpha: 0.6)
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
                  hintText:
                      _isListening ? 'جارٍ الاستماع...' : 'اكتب رسالتك هنا...',
                  hintStyle: TextStyle(
                    color: _isListening
                        ? personaColor
                        : (isDark ? Colors.white30 : Colors.black38),
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          GestureDetector(
            onTap:
                isLoading ? null : () => _sendMessage(_controller.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: isLoading
                    ? null
                    : LinearGradient(
                        colors: [personaColor, personaColor.withValues(alpha: 0.7)]),
                color: isLoading
                    ? personaColor.withValues(alpha: 0.3)
                    : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isLoading
                    ? null
                    : [
                        BoxShadow(
                          color: personaColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
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
    );
  }
}

/// Specialized header action button for Zad Expert
class _HeaderActionBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final bool isSolidHeader;
  final VoidCallback onTap;

  const _HeaderActionBtn({
    required this.icon,
    required this.isDark,
    this.isSolidHeader = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isSolidHeader
        ? Colors.white
        : (isDark ? Colors.white70 : Colors.black54);

    // For the solid header (Zad Expert) we render a clean icon-only button
    // — no translucent pill, no border — so the persona avatar and title
    // stay the visual anchor. The Material/InkWell pair gives us a subtle
    // circular ripple on tap without any resting background.
    if (isSolidHeader) {
      return Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          splashColor: Colors.white.withValues(alpha: 0.18),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 22, color: iconColor),
          ),
        ),
      );
    }

    // Non-solid (light/dark surface) headers keep the soft chip look.
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat Bubble
// ─────────────────────────────────────────────────────────────────────────────
class _ExpertBubble extends StatefulWidget {
  final AiChatMessage msg;
  final bool isDark;
  final Color personaColor;
  final String personaIcon;
  final Function(String)? onSuggestionSelected;
  /// Called when the user taps regenerate. [variant] is a short Arabic
  /// directive (e.g. "اشرح بشكل أبسط") appended to the original prompt to
  /// steer the next answer. Null/empty means "regenerate as-is".
  final void Function({String? variant})? onRegenerate;
  final ValueChanged<String>? onEdit;
  /// Invoked when the user picks "اسأل عن هذا" from the selection toolbar.
  /// The selected substring of the message is forwarded so the parent can
  /// inject it as a quote into the chat input.
  final ValueChanged<String>? onAskAbout;
  final bool isLast;
  /// Forces the edit/resend affordance to show on this bubble. Used by the
  /// parent to mark the most recent user-authored message as editable even
  /// when one or more assistant replies follow it.
  final bool showEditAction;

  const _ExpertBubble({
    required this.msg,
    required this.isDark,
    required this.personaColor,
    required this.personaIcon,
    this.onSuggestionSelected,
    this.onRegenerate,
    this.onEdit,
    this.onAskAbout,
    this.isLast = false,
    this.showEditAction = false,
  });

  @override
  State<_ExpertBubble> createState() => _ExpertBubbleState();
}

class _ExpertBubbleState extends State<_ExpertBubble> {
  bool _editing = false;
  TextEditingController? _editController;

  AiChatMessage get msg => widget.msg;
  bool get isDark => widget.isDark;
  Color get personaColor => widget.personaColor;
  String get personaIcon => widget.personaIcon;
  Function(String)? get onSuggestionSelected => widget.onSuggestionSelected;
  void Function({String? variant})? get onRegenerate => widget.onRegenerate;
  ValueChanged<String>? get onEdit => widget.onEdit;
  bool get isLast => widget.isLast;

  void _startEditing() {
    HapticFeedback.lightImpact();
    setState(() {
      _editController = TextEditingController(text: msg.content);
      _editing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editing = false;
      _editController?.dispose();
      _editController = null;
    });
  }

  void _submitEdit() {
    final newText = _editController?.text.trim() ?? '';
    if (newText.isEmpty) return;
    if (newText == msg.content.trim()) {
      _cancelEditing();
      return;
    }
    final cb = onEdit;
    setState(() {
      _editing = false;
      _editController?.dispose();
      _editController = null;
    });
    cb?.call(newText);
  }

  @override
  void dispose() {
    _editController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.84,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            // Message bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? personaColor
                    : (isDark ? AppTheme.darkSurface : Colors.white),
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                  bottomRight: !isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? personaColor.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isUser
                  ? (_editing
                      ? _buildEditField()
                      : Text(
                          msg.content,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.6,
                          ),
                          textDirection: TextDirection.rtl,
                        ))
                  : msg.content.trim().isEmpty
                  // Empty assistant bubble during streaming: show inline
                  // three-dot loader so the bubble itself is the typing
                  // indicator (no separate one renders below).
                  ? _InlineTypingDots(personaColor: personaColor)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectionArea(
                          contextMenuBuilder: (ctx, sel) {
                            // Compose a context menu with the standard "Copy"
                            // action plus a custom "Ask about this" item that
                            // pulls the selected text into the input as a
                            // markdown quote.
                            return AdaptiveTextSelectionToolbar.buttonItems(
                              anchors: sel.contextMenuAnchors,
                              buttonItems: [
                                ContextMenuButtonItem(
                                  label: 'نسخ',
                                  onPressed: () {
                                    sel.copySelection(
                                        SelectionChangedCause.toolbar);
                                  },
                                ),
                                if (widget.onAskAbout != null)
                                  ContextMenuButtonItem(
                                    label: 'اسأل عن هذا',
                                    onPressed: () async {
                                      // Round-trip via system clipboard:
                                      // SelectableRegion exposes the
                                      // selection internally but no public
                                      // getter, so we copy then read back.
                                      sel.copySelection(
                                          SelectionChangedCause.toolbar);
                                      sel.hideToolbar();
                                      final cd = await Clipboard.getData(
                                          Clipboard.kTextPlain);
                                      final text = cd?.text ?? '';
                                      if (text.isNotEmpty) {
                                        widget.onAskAbout!(text);
                                      }
                                    },
                                  ),
                              ],
                            );
                          },
                          child: MarkdownBody(
                          data: _getCleanContent(msg.content),
                          selectable: false,
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
                              color: personaColor,
                              backgroundColor: personaColor.withValues(alpha: 0.1),
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
                                  color: personaColor,
                                  width: 3,
                                ),
                              ),
                            ),
                            listBullet: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                            a: TextStyle(
                              color: personaColor,
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
                        // Suggestion Chips
                        if (!isUser) _buildSuggestions(msg.content),
                      ],
                    ),
            ),
            // Action buttons for AI messages — hidden while the bubble is
            // still empty (streaming hasn't produced any content yet) so we
            // don't show "copy/share/regenerate" under a blank placeholder.
            if (!isUser && msg.content.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _BubbleAction(
                      icon: PhosphorIcons.copy(),
                      tooltip: 'نسخ',
                      isDark: isDark,
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: _getCleanContent(msg.content)));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('تم نسخ نص الرسالة'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: personaColor,
                            duration: const Duration(seconds: 1),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    _BubbleAction(
                      icon: PhosphorIcons.shareNetwork(),
                      tooltip: 'مشاركة',
                      isDark: isDark,
                      onTap: () => Share.share(_getCleanContent(msg.content)),
                    ),
                    if (isLast && onRegenerate != null) ...[
                      const SizedBox(width: 4),
                      _RegenerateButton(
                        isDark: isDark,
                        personaColor: personaColor,
                        onRegenerate: onRegenerate!,
                      ),
                    ],
                  ],
                ),
              ),
            // Action buttons for User messages — appear on the most recent
            // user-authored message (even if assistant replies follow it),
            // and stay hidden while we're editing in place.
            if (isUser && widget.showEditAction && !_editing)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEdit != null) ...[
                      _BubbleAction(
                        icon: PhosphorIcons.pencilSimple(),
                        tooltip: 'تعديل وإعادة إرسال',
                        isDark: isDark,
                        onTap: _startEditing,
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (onRegenerate != null)
                      _BubbleAction(
                        icon: PhosphorIcons.arrowsClockwise(),
                        tooltip: 'إعادة إرسال الطلب',
                        isDark: isDark,
                        onTap: () => onRegenerate!(),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField() {
    final controller = _editController!;
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): _ExpertDismissIntent(),
      },
      child: Actions(
        actions: {
          _ExpertDismissIntent: CallbackAction<_ExpertDismissIntent>(
            onInvoke: (_) {
              _cancelEditing();
              return null;
            },
          ),
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  PhosphorIcons.pencilSimpleLine(PhosphorIconsStyle.fill),
                  size: 12,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 6),
                Text(
                  'تعديل الرسالة',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            EditTextField(
              controller: controller,
              accent: personaColor,
              hint: 'عدّل رسالتك ثم اضغط إعادة الإرسال…',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'سيتم استبدال الرد السابق وإعادة توليده',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _ExpertEditActionButton(
                  label: 'إلغاء',
                  icon: PhosphorIcons.x(),
                  onTap: _cancelEditing,
                  isPrimary: false,
                  primaryColor: personaColor,
                ),
                const SizedBox(width: 8),
                _ExpertEditActionButton(
                  label: 'إعادة الإرسال',
                  icon: PhosphorIcons.paperPlaneRight(PhosphorIconsStyle.fill),
                  onTap: _submitEdit,
                  isPrimary: true,
                  primaryColor: personaColor,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 180.ms).scaleXY(begin: 0.97, end: 1, duration: 180.ms);
  }

  String _getCleanContent(String content) {
    if (!content.contains('[SUGGESTIONS]')) return content;
    final regExp = RegExp(r'\[SUGGESTIONS\][\s\S]*?\[/SUGGESTIONS\]');
    return content.replaceAll(regExp, '').trim();
  }

  Widget _buildSuggestions(String content) {
    if (!content.contains('[SUGGESTIONS]')) return const SizedBox.shrink();
    
    final regExp = RegExp(r'\[SUGGESTIONS\]([\s\S]*?)\[/SUGGESTIONS\]');
    final match = regExp.firstMatch(content);
    if (match == null) return const SizedBox.shrink();

    final suggestionsText = match.group(1) ?? '';
    final list = suggestionsText.split('|').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    if (list.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 1,
            width: double.infinity,
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
          ),
          const SizedBox(height: 12),
          Text(
            'استمر في تطوير الفكرة:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: list.map((s) => _SuggestionChip(
              text: s,
              isDark: isDark,
              color: personaColor,
              onTap: () {
                HapticFeedback.mediumImpact();
                onSuggestionSelected?.call(s);
              },
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  final bool isDark;
  final Color color;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.text,
    required this.isDark,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? color.withValues(alpha: 0.1) : color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.3 : 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white.withValues(alpha: 0.9) : color.darken(0.1),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded, size: 14, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

/// Three-dot loader rendered *inside* the empty assistant bubble while we
/// wait for the first streaming chunk. The bubble already gives us padding
/// and rounded background, so this is just the animated content.
class _InlineTypingDots extends StatefulWidget {
  final Color personaColor;
  const _InlineTypingDots({required this.personaColor});

  @override
  State<_InlineTypingDots> createState() => _InlineTypingDotsState();
}

class _InlineTypingDotsState extends State<_InlineTypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _ctl,
            builder: (_, _) {
              // Phase-shift each dot by 1/3 of the cycle.
              final t = (_ctl.value - i / 3) % 1.0;
              final s = t < 0.5 ? t * 2 : (1 - t) * 2; // triangle 0→1→0
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Opacity(
                  opacity: 0.35 + 0.65 * s,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: widget.personaColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class _BubbleAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isDark;
  final VoidCallback onTap;

  const _BubbleAction({
    required this.icon,
    required this.tooltip,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              size: 14, color: isDark ? Colors.white38 : Colors.black38),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Regenerate button — visible as a single icon, tap opens a sheet with the
// available answer-style variants (simpler / more detailed / with examples …).
// Variants are kept hidden behind one tap so the bubble action row stays
// compact, but they remain discoverable.
// ─────────────────────────────────────────────────────────────────────────────
class _RegenerateButton extends StatelessWidget {
  final bool isDark;
  final Color personaColor;
  final void Function({String? variant}) onRegenerate;

  const _RegenerateButton({
    required this.isDark,
    required this.personaColor,
    required this.onRegenerate,
  });

  static const List<_RegenVariant> _variants = [
    _RegenVariant(
      label: 'إعادة كما هي',
      hint: 'نفس السؤال بنفس الأسلوب',
      icon: 0xE7B0, // arrows clockwise (placeholder, replaced below)
      variant: null,
    ),
    _RegenVariant(
      label: 'اشرح بشكل أبسط',
      hint: 'لغة سهلة وموجزة بلا مصطلحات',
      icon: 0,
      variant: 'اشرح الفكرة بلغة بسيطة جداً ومفهومة لمبتدئ، تجنّب المصطلحات التقنية قدر الإمكان.',
    ),
    _RegenVariant(
      label: 'أكثر تفصيلاً',
      hint: 'إجابة شاملة وعميقة',
      icon: 0,
      variant: 'وسّع الإجابة بشكل أعمق وأكثر تفصيلاً، اشرح الخلفية والسياق وكل جانب مهم.',
    ),
    _RegenVariant(
      label: 'مع أمثلة عملية',
      hint: 'أمثلة واقعية قابلة للتطبيق',
      icon: 0,
      variant: 'أضف 2-3 أمثلة عملية واضحة وواقعية لكل نقطة رئيسية.',
    ),
    _RegenVariant(
      label: 'نقاط مختصرة',
      hint: 'إجابة على شكل bullet points',
      icon: 0,
      variant: 'حوّل الإجابة إلى قائمة نقاط مختصرة وواضحة، كل نقطة في سطر واحد.',
    ),
    _RegenVariant(
      label: 'مع مخطط Mermaid',
      hint: 'مخطط بصري يلخّص الفكرة',
      icon: 0,
      variant: 'أضف في نهاية الإجابة مخطط Mermaid مناسب يلخّص الفكرة بصرياً داخل ```mermaid```.',
    ),
  ];

  Future<void> _open(BuildContext context) async {
    HapticFeedback.lightImpact();
    final selected = await showModalBottomSheet<_RegenVariant>(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.bold),
                      size: 18, color: personaColor),
                  const SizedBox(width: 8),
                  Text(
                    'إعادة توليد بأسلوب آخر',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'اختر كيف تريد إعادة الإجابة. سيُحذف الرد السابق ويُعاد السؤال نفسه مع توجيه إضافي خفي.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ..._variants.map((v) => ListTile(
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: personaColor.withValues(alpha: 0.12),
                    child: Icon(_iconFor(v),
                        size: 16, color: personaColor),
                  ),
                  title: Text(
                    v.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    v.hint,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  onTap: () => Navigator.pop(ctx, v),
                )),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
    if (selected != null) {
      onRegenerate(variant: selected.variant);
    }
  }

  IconData _iconFor(_RegenVariant v) {
    if (v.variant == null) return PhosphorIcons.arrowsClockwise();
    if (v.label.contains('أبسط')) return PhosphorIcons.lightbulbFilament();
    if (v.label.contains('تفصيل')) return PhosphorIcons.bookOpen();
    if (v.label.contains('أمثلة')) return PhosphorIcons.lightning();
    if (v.label.contains('نقاط')) return PhosphorIcons.listBullets();
    if (v.label.contains('Mermaid')) return PhosphorIcons.treeStructure();
    return PhosphorIcons.sparkle();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'إعادة توليد الرد',
      child: GestureDetector(
        onTap: () => _open(context),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(PhosphorIcons.arrowsClockwise(),
              size: 14, color: isDark ? Colors.white38 : Colors.black38),
        ),
      ),
    );
  }
}

class _RegenVariant {
  final String label;
  final String hint;
  final int icon;
  final String? variant;
  const _RegenVariant({
    required this.label,
    required this.hint,
    required this.icon,
    required this.variant,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// History Sheet (Local to Expert)
// ─────────────────────────────────────────────────────────────────────────────
class _HistorySheet extends StatelessWidget {
  final List<ExpertChatSession> sessions;
  final bool isDark;
  final AiPersonaModel persona;
  final String? activeId;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onDelete;
  final VoidCallback onNewSession;

  const _HistorySheet({
    required this.sessions,
    required this.isDark,
    required this.persona,
    required this.activeId,
    required this.onSelect,
    required this.onDelete,
    required this.onNewSession,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...sessions]
      ..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));

    final personaColor = hexToColor(persona.color);

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
                    color: personaColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  'سجل محادثات (${persona.name})',
                  style: TextStyle(
                    
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onNewSession,
                  icon: Icon(PhosphorIcons.plus(), size: 16),
                  label: const Text('محادثة جديدة', style: TextStyle( fontSize: 13)),
                  style: TextButton.styleFrom(
                    foregroundColor: personaColor,
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
                
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  selected: isActive,
                  selectedTileColor: personaColor.withValues(alpha: 0.1),
                  title: Text(
                    s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    '${s.messages.length} رسالة • منذ ${_formatTime(s.lastActivity)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  onTap: () => onSelect(s.id),
                  trailing: IconButton(
                    icon: Icon(PhosphorIcons.trash(),
                        size: 18, color: Colors.grey.shade500),
                    onPressed: () {
                      onDelete(s.id);
                    },
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

  String _formatTime(DateTime pt) {
    final diff = DateTime.now().difference(pt);
    if (diff.inDays > 0) return '${diff.inDays} يوم';
    if (diff.inHours > 0) return '${diff.inHours} ساعة';
    if (diff.inMinutes > 0) return '${diff.inMinutes} دقيقة';
    return 'الآن';
  }
}

/// Esc-key intent for cancelling edit mode in `_ExpertBubble`.
class _ExpertDismissIntent extends Intent {
  const _ExpertDismissIntent();
}

/// Pill button used inside the polished edit field. Primary fills with the
/// persona's contrast color; ghost variant uses a soft translucent surface.
class _ExpertEditActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  final Color primaryColor;

  const _ExpertEditActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isPrimary,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isPrimary ? Colors.white : Colors.white.withValues(alpha: 0.15);
    final fg = isPrimary ? primaryColor : Colors.white;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

