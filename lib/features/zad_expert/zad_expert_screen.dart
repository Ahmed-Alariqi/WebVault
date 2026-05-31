import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_animate/flutter_animate.dart';

import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../presentation/providers/membership_providers.dart';



import '../../core/theme/app_theme.dart';
import '../../presentation/widgets/responsive_layout.dart';

import '../../data/models/ai_chat_model.dart';

import '../../data/models/ai_persona_model.dart';

import '../../data/models/ai_persona_mode.dart';
import '../../data/models/web_tools_models.dart';
import '../../data/services/web_tools_service.dart';

import '../../presentation/providers/zad_expert_providers.dart';

import '../../data/services/connectivity_service.dart';

import '../ai_assistant/ai_chat_screen.dart'; // For CodeElementBuilder

import '../ai_assistant/widgets/chat_prompt_bridge.dart';

import 'widgets/mode_cards_view.dart';
import 'persona_selector_sheet.dart';
import '../discover/widgets/premium_unlock_sheet.dart';
import '../../presentation/providers/referral_providers.dart';





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

    case 'flowArrow':

      return PhosphorIcons.flowArrow(PhosphorIconsStyle.fill);

    case 'database':

      return PhosphorIcons.database(PhosphorIconsStyle.fill);

    case 'sequence':

    case 'arrowsLeftRight':

      return PhosphorIcons.arrowsLeftRight(PhosphorIconsStyle.fill);

    case 'class':

    case 'squaresFour':

      return PhosphorIcons.squaresFour(PhosphorIconsStyle.fill);

    case 'architecture':

    case 'buildings':

      return PhosphorIcons.buildings(PhosphorIconsStyle.fill);

    case 'stack':

      return PhosphorIcons.stack(PhosphorIconsStyle.fill);

    case 'sparkle':

      return PhosphorIcons.sparkle(PhosphorIconsStyle.fill);

    case 'rocket':

      return PhosphorIcons.rocket(PhosphorIconsStyle.fill);

    case 'target':

      return PhosphorIcons.target(PhosphorIconsStyle.fill);

    case 'globe':

      return PhosphorIcons.globe(PhosphorIconsStyle.fill);

    case 'atom':

      return PhosphorIcons.atom(PhosphorIconsStyle.fill);

    case 'gear':

      return PhosphorIcons.gear(PhosphorIconsStyle.fill);

    case 'shield':

      return PhosphorIcons.shield(PhosphorIconsStyle.fill);

    case 'key':

      return PhosphorIcons.key(PhosphorIconsStyle.fill);

    case 'book':

      return PhosphorIcons.bookOpen(PhosphorIconsStyle.fill);

    case 'fire':

      return PhosphorIcons.fire(PhosphorIconsStyle.fill);

    case 'flask':

      return PhosphorIcons.flask(PhosphorIconsStyle.fill);

    case 'microscope':

      return PhosphorIcons.microscope(PhosphorIconsStyle.fill);

    case 'image':

      return PhosphorIcons.image(PhosphorIconsStyle.fill);

    case 'video':

      return PhosphorIcons.videoCamera(PhosphorIconsStyle.fill);

    case 'briefcase':

      return PhosphorIcons.briefcase(PhosphorIconsStyle.fill);

    case 'palette':

      return PhosphorIcons.palette(PhosphorIconsStyle.fill);

    case 'terminal':

      return PhosphorIcons.terminalWindow(PhosphorIconsStyle.fill);

    case 'gitBranch':

      return PhosphorIcons.gitBranch(PhosphorIconsStyle.fill);

    case 'package':

      return PhosphorIcons.package(PhosphorIconsStyle.fill);

    case 'cloud':

      return PhosphorIcons.cloud(PhosphorIconsStyle.fill);

    case 'bug':

      return PhosphorIcons.bug(PhosphorIconsStyle.fill);

    case 'rocketLaunch':

      return PhosphorIcons.rocketLaunch(PhosphorIconsStyle.fill);

    case 'chatCircle':

      return PhosphorIcons.chatCircle(PhosphorIconsStyle.fill);

    case 'compass':

      return PhosphorIcons.compass(PhosphorIconsStyle.fill);

    case 'crown':

      return PhosphorIcons.crown(PhosphorIconsStyle.fill);

    case 'trophy':

      return PhosphorIcons.trophy(PhosphorIconsStyle.fill);

    case 'megaphone':

      return PhosphorIcons.megaphone(PhosphorIconsStyle.fill);

    case 'hammer':

      return PhosphorIcons.hammer(PhosphorIconsStyle.fill);

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
  String? _activeToolMode;

  final _webSearchPatterns = RegExp(r'(ابحث|إبحث|ابحث عن|إبحث عن|ابحث في الإنترنت|إبحث في الإنترنت|اخر اخبار|آخر أخبار|آخر اخبار|اخر أخبار|اخر تحديث|آخر تحديث|في 2026|عام 2026)', caseSensitive: false);
  final _urlRegex = RegExp(r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)');

  bool _shouldAutoSearch(String text) => _webSearchPatterns.hasMatch(text);
  bool _containsUrl(String text) => _urlRegex.hasMatch(text);
  String? _extractUrl(String text) => _urlRegex.stringMatch(text);

  bool _sttAvailable = true;

  bool _speechInitialized = false;



  // Typing animation

  late AnimationController _typingDotController;

  // Recording pulse animation for the input pill
  late AnimationController _recordingPulseController;



  // Track current active session to auto-scroll on switch

  String? _lastActiveSessionId;



  @override

  void initState() {

    super.initState();

    _typingDotController = AnimationController(

      vsync: this,

      duration: const Duration(milliseconds: 1200),

    )..repeat();

    _recordingPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Keep the composer's visual states (focus glow, send button enable/disable,
    // counter, mic colors) in sync with text + focus changes.
    _controller.addListener(_onComposerStateChange);
    _focusNode.addListener(_onComposerStateChange);

  }

  void _onComposerStateChange() {
    if (mounted) setState(() {});
  }

  @override

  void dispose() {
    _controller.removeListener(_onComposerStateChange);
    _focusNode.removeListener(_onComposerStateChange);

    _controller.dispose();

    _scrollController.dispose();

    _focusNode.dispose();

    _typingDotController.dispose();
    _recordingPulseController.dispose();

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



  void _sendMessage(String text) async {
    final persona = ref.read(selectedPersonaProvider);
    if (text.trim().isEmpty || persona == null) return;
    HapticFeedback.lightImpact();

    Future<String?> Function()? toolTask;

    if (_activeToolMode == 'search' && persona.hasWebSearch) {
      toolTask = () => _performWebSearch(persona, text.trim());
      _clearToolMode();
    } else if (_activeToolMode == 'url' && persona.hasUrlReader) {
      toolTask = () => _performUrlRead(persona, text.trim());
      _clearToolMode();
    } else if (persona.hasWebSearch && _shouldAutoSearch(text.trim())) {
      toolTask = () => _performWebSearch(persona, text.trim());
    } else if (persona.hasUrlReader && _containsUrl(text.trim())) {
      final url = _extractUrl(text.trim());
      if (url != null) {
        toolTask = () => _performUrlRead(persona, url);
      }
    }

    if (!mounted) return;

    // Premium Check
    final memStatus = ref.read(membershipStatusProvider);
    final hasAccess = !persona.isPremium || memStatus.hasAccessTo(type: 'persona', id: persona.id);

    if (!hasAccess) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => PremiumFeatureSheet(
          title: 'شخصيات خبير زاد PRO 👑',
          description: 'الوصول إلى شخصية "${persona.name}" يتطلب تفعيل العضوية. يمكنك فتحها الآن من خلال دعوة أصدقائك للتطبيق.',
          icon: PhosphorIcons.brain(PhosphorIconsStyle.fill),
          onAction: (sheetRef) async {

            HapticFeedback.lightImpact();
            await shareViralInvitation(sheetRef);

          },
          actionLabel: 'ادعُ أصدقاءك لفتح الميزة',
          themeColor: const Color(0xFFF59E0B),
          isDark: isDark,
        ),
      );
      return;
    }

    ref.read(expertChatProvider(persona).notifier).sendMessage(text, webToolTask: toolTask);

    _controller.clear();
    _scrollToBottom();
  }

  Future<String?> _performWebSearch(AiPersonaModel persona, String query) async {
    final provider = ref.read(expertChatProvider(persona).notifier);
    
    // Initial State: Search start
    final steps = [
      ToolStep(label: 'جارٍ البحث في الإنترنت عن: $query', details: []),
    ];
    provider.setToolLoading(null, steps: steps);

    try {
      // 1. Search Query
      final results = await WebToolsService.search(query);
      if (results.isEmpty) {
        provider.setToolLoading(null, steps: [
          ToolStep(label: 'لم يتم العثور على نتائج للبحث', isDone: true),
        ]);
        return null;
      }

      // 2. Pre-fetching & Parallel Execution
      // We take the top 5 results and start reading them simultaneously
      final topResults = results.take(5).toList();
      
      steps[0] = ToolStep(
        label: 'تم العثور على ${results.length} نتائج بحث',
        details: topResults.map((r) => r.domain).toList(),
        isDone: true,
      );
      
      // Add a placeholder for reading progress
      steps.add(ToolStep(
        label: 'جارٍ تحليل وقراءة أهم ${topResults.length} مصادر...',
        details: topResults.map((r) => '⏳ ${r.domain}').toList(),
      ));
      provider.setToolLoading(null, steps: List.from(steps));

      final readContents = List<String?>.filled(topResults.length, null);
      int completedCount = 0;

      // Launch all read requests in parallel
      final List<Future<void>> readFutures = [];
      for (int i = 0; i < topResults.length; i++) {
        final index = i;
        final r = topResults[index];
        
        readFutures.add(() async {
          try {
            final res = await WebToolsService.readUrl(r.url);
            readContents[index] = res.content;
          } catch (e) {
            debugPrint('Error reading ${r.url}: $e');
            // We don't fail the whole process if one URL fails
          } finally {
            completedCount++;
            // Real-time UI Update: Mark this specific source as done in the tree
            // We use the same order to keep the UI stable
            steps[1] = ToolStep(
              label: 'جارٍ قراءة المصادر ($completedCount/${topResults.length})...',
              details: List.generate(topResults.length, (idx) {
                if (readContents[idx] != null || (idx < index && completedCount > idx)) {
                   return '✓ ${topResults[idx].domain}';
                }
                if (idx == index && readContents[idx] == null) {
                   // If it finished with error or just finished
                   return '✓ ${topResults[idx].domain}';
                }
                return '... ${topResults[idx].domain}';
              }),
            );
            provider.setToolLoading(null, steps: List.from(steps));
          }
        }());
      }

      // Wait for all parallel reading tasks to finish
      await Future.wait(readFutures);

      // Final Step: Formatting and AI Handover
      steps[1] = ToolStep(
        label: 'تم الانتهاء من قراءة وتحليل المصادر بنجاح',
        details: topResults.map((res) => '✓ ${res.domain}').toList(),
        isDone: true,
      );
      
      steps.add(const ToolStep(label: '🤖 جارٍ تجهيز وصياغة الرد الاحترافي...', details: []));
      provider.setToolLoading(null, steps: List.from(steps));

      final buffer = StringBuffer('## نتائج البحث عن: $query\n\n');
      for (var i = 0; i < results.length; i++) {
        final r = results[i];
        buffer.writeln('### [${i + 1}] ${r.title}');
        buffer.writeln('الرابط: ${r.url}');
        
        // If we have content from our top 5 read results, include it
        if (i < topResults.length && readContents[i] != null && readContents[i]!.isNotEmpty) {
          buffer.writeln('المحتوى التفصيلي للصفحة:');
          buffer.writeln(readContents[i]!);
        } else {
          buffer.writeln('وصف مختصر:');
          buffer.writeln(r.description);
        }
        buffer.writeln();
      }

      buffer.writeln('## تعليمات هامة جداً لصياغة الرد والمصادر:');
      buffer.writeln('1. قدم إجابة مفصلة، دقيقة، وقيمة جداً للمستخدم، ولا تقتصر على إجابة سطحية.');
      buffer.writeln('2. في نهاية إجابتك، أضف قسماً بعنوان "المصادر:" وضع فيه قائمة نقطية بأسماء المواقع لتكون قابلة للضغط كروابط.');
      buffer.writeln('3. صيغة المصادر يجب أن تكون روابط Markdown صريحة هكذا: [اسم الموقع](رابط الموقع).');
      buffer.writeln('4. لا تضع أي مصادر أو أرقام كمصادر وسط النص، فقط في النهاية تحت قسم المصادر.');

      await Future.delayed(const Duration(milliseconds: 300));
      return buffer.toString();
    } catch (e) {
      debugPrint('Web search error: $e');
      return null;
    }
  }

  Future<String?> _performUrlRead(AiPersonaModel persona, String url) async {
    final provider = ref.read(expertChatProvider(persona).notifier);
    final domain = Uri.tryParse(url)?.host.replaceFirst('www.', '') ?? url;
    
    final steps = [
      ToolStep(label: 'جارٍ قراءة وتحليل الرابط: $domain', details: []),
    ];
    provider.setToolLoading(null, steps: steps);

    try {
      final result = await WebToolsService.readUrl(url);
      
      steps[0] = ToolStep(
        label: 'تمت قراءة المحتوى بنجاح',
        details: ['✓ $domain'],
        isDone: true,
      );
      steps.add(const ToolStep(label: '🤖 جارٍ تجهيز الرد...', details: []));
      provider.setToolLoading(null, steps: steps);

      await Future.delayed(const Duration(milliseconds: 400));

      return '## محتوى الرابط: $url\n\n${result.content}\n\n'
             '## تعليمات هامة لصياغة الرد:\n'
             'قدم إجابة تحليلية ومفيدة جداً بناءً على محتوى الرابط. في نهاية الإجابة اذكر المصدر كرابط قابل للضغط هكذا: [مصدر المحتوى]($url).';
    } catch (e) {
      debugPrint('URL read error: $e');
      return null;
    }
  }

  void _toggleToolMode(String mode) {
    setState(() {
      if (_activeToolMode == mode) {
        _activeToolMode = null;
      } else {
        _activeToolMode = mode;
      }
    });
  }

  void _clearToolMode() {
    if (mounted) setState(() => _activeToolMode = null);
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
      _recordingPulseController.stop();
      _recordingPulseController.reset();
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

      if (mounted) {
        setState(() => _isListening = true);
        _recordingPulseController.repeat();
      }

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



    return ResponsiveLayout(
      maxWidth: 760,
      child: Scaffold(

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

                  isDark,

                  chatState.isLoading,

                  personaColor,

                  selectedPersona,

                ),

              ],

            ),

          );

        },

      ),

    ),
  );

  }



  // ── Loading ──

  Widget _buildLoadingView(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Premium Animated Robot Loader
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow circles
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2000.ms, curve: Curves.easeInOut),
              
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1500.ms, curve: Curves.easeInOut),

              // Main Robot Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  PhosphorIcons.robot(PhosphorIconsStyle.fill),
                  color: Colors.white,
                  size: 30,
                ),
              ).animate(onPlay: (c) => c.repeat())
               .shimmer(duration: 2000.ms, color: Colors.white24)
               .shake(hz: 0.5, curve: Curves.easeInOut, rotation: 0.05),
            ],
          ),
          
          const SizedBox(height: 32),

          // Loading Text with Fade effect
          Text(
            'خبير زاد يجهز شخصياته...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
              fontFamily: 'Cairo',
              letterSpacing: -0.5,
            ),
          ).animate(onPlay: (c) => c.repeat())
           .fadeIn(duration: 1000.ms)
           .then()
           .fadeOut(duration: 1000.ms, delay: 500.ms),

          const SizedBox(height: 8),

          Text(
            'جارٍ تحميل البيانات الذكية',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white38 : Colors.black38,
              fontFamily: 'Cairo',
            ),
          ).animate().fadeIn(delay: 400.ms),
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

    // Offline-aware UI: when there's no connectivity we render a slim red
    // banner above the header bar and trim the header's status-bar inset
    // (since the banner itself already sits under the status bar).
    final isOffline = ref.watch(isOnlineProvider).maybeWhen(
      data: (online) => !online,
      orElse: () => false,
    );

    // Optimized Branding: Near-solid for maximum clarity without glare

    final headerBgColor = isDark 

      ? Color.alphaBlend(personaColor.withValues(alpha: 0.94), AppTheme.darkSurface)

      : Color.alphaBlend(personaColor.withValues(alpha: 0.88), Colors.white);

    

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _OfflineBanner(isVisible: isOffline, isDark: isDark),
        Container(

      constraints: const BoxConstraints(minHeight: 65),

      padding: EdgeInsets.only(

        // When the offline banner is visible above us it already consumes
        // the status-bar inset, so don't double-pad here.
        top: (isOffline ? 4 : MediaQuery.of(context).padding.top + 4),

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

                        Row(
                          mainAxisSize: MainAxisSize.min,
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
                            if (persona.isPremium) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'PRO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        if (chatState.isLoading)
                          _HeaderTypingIndicator()

                        else

                          Builder(builder: (_) {

                            final activeMode =

                                ref.watch(selectedModeProvider(persona.slug));

                            if (activeMode != null) {

                              return GestureDetector(

                                onTap: () => _maybeChangeMode(persona),

                                child: Row(

                                  mainAxisSize: MainAxisSize.min,

                                  children: [

                                    Icon(

                                      personaIconFromName(activeMode.icon),

                                      size: 11,

                                      color: Colors.white.withValues(alpha: 0.85),

                                    ),

                                    const SizedBox(width: 4),

                                    Flexible(

                                      child: Text(

                                        'وضع: ${activeMode.name}',

                                        maxLines: 1,

                                        overflow: TextOverflow.ellipsis,

                                        style: TextStyle(

                                          color: Colors.white.withValues(alpha: 0.85),

                                          fontSize: 10,

                                          fontWeight: FontWeight.w700,

                                        ),

                                      ),

                                    ),

                                    const SizedBox(width: 4),

                                    Icon(PhosphorIcons.caretDown(),

                                        size: 9,

                                        color: Colors.white.withValues(alpha: 0.7)),

                                  ],

                                ),

                              );

                            }

                            return Text(

                              persona.description,

                              maxLines: 1,

                              overflow: TextOverflow.ellipsis,

                              style: TextStyle(

                                color: Colors.white.withValues(alpha: 0.7),

                                fontSize: 10,

                                fontWeight: FontWeight.w500,

                              ),

                            );

                          }),

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

                  ref.read(expertChatProvider(persona).notifier).startNewSession();

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

    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),
      ],
    );

  }



  void _showPersonaSelector(List<AiPersonaModel> personas) {
    if (personas.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PersonaSelectorSheet(
        personas: personas,
        selectedSlug: ref.watch(selectedPersonaProvider)?.slug,
        onSelect: (p) {
          ref.read(selectedPersonaProvider.notifier).state = p;
          Navigator.pop(ctx);
        },
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



  // ── Mode activation helpers ─────────────────────────────────────────

  //

  // Picking a mode card writes to [selectedModeProvider] and starts a fresh

  // session so the new system prompt isn't muddled with prior context.

  void _activateMode(AiPersonaModel persona, AiPersonaMode mode) {

    HapticFeedback.lightImpact();

    ref.read(selectedModeProvider(persona.slug).notifier).state = mode;

    // If the active session already has messages, branch into a new one to

    // give the layered prompt a clean canvas. Empty sessions are reused.

    final chat = ref.read(expertChatProvider(persona));

    if (chat.activeMessages.isNotEmpty) {

      ref.read(expertChatProvider(persona).notifier).startNewSession();

    }

    _focusNode.requestFocus();

  }



  /// Confirm before resetting the active mode (would lose chat context if

  /// any). Returns the user back to the mode picker by clearing the provider.

  Future<void> _maybeChangeMode(AiPersonaModel persona) async {

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final chat = ref.read(expertChatProvider(persona));

    final hasMessages = chat.activeMessages.isNotEmpty;



    bool proceed = !hasMessages;

    if (hasMessages) {

      setState(() => _isOverlayActive = true);

      proceed = await showDialog<bool>(

            context: context,

            builder: (_) => AlertDialog(

              backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,

              shape:

                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

              title: Text('تغيير الوضع؟',

                  style: TextStyle(

                      fontWeight: FontWeight.bold,

                      color: isDark ? Colors.white : Colors.black87)),

              content: Text(

                'سيتم بدء محادثة جديدة بالوضع الجديد. المحادثة الحالية ستبقى محفوظة في السجل.',

                style: TextStyle(

                    color: isDark ? Colors.white70 : Colors.black54),

              ),

              actions: [

                TextButton(

                    onPressed: () => Navigator.pop(context, false),

                    child: const Text('إلغاء')),

                ElevatedButton(

                    onPressed: () => Navigator.pop(context, true),

                    style: ElevatedButton.styleFrom(

                        backgroundColor: AppTheme.primaryColor,

                        foregroundColor: Colors.white),

                    child: const Text('متابعة')),

              ],

            ),

          ) ??

          false;

      if (mounted) setState(() => _isOverlayActive = false);

    }



    if (!proceed || !mounted) return;

    if (hasMessages) {

      ref.read(expertChatProvider(persona).notifier).startNewSession();

    }

    ref.read(selectedModeProvider(persona.slug).notifier).state = null;

    HapticFeedback.mediumImpact();

  }



  // ── Welcome View ──

  //

  // Three flavours:

  //   • Persona has no modes → original avatar + persona quickActions (legacy).

  //   • Persona has modes & no mode picked yet → mode cards picker.

  //   • Persona has modes & a mode is active   → mini header (persona + mode

  //     badge) followed by the *mode's* quickActions.

  Widget _buildWelcome(

      bool isDark, AiPersonaModel persona, Color personaColor) {

    final activeMode = ref.watch(selectedModeProvider(persona.slug));



    // Case A — persona has modes and none selected: show the picker.

    if (persona.hasModes && activeMode == null) {

      return ModeCardsView(

        persona: persona,

        personaColor: personaColor,

        isDark: isDark,

        onSelect: (mode) => _activateMode(persona, mode),

      );

    }



    // Effective quick actions + heading source: the active mode (if any),

    // otherwise the persona itself.

    final effectiveActions = activeMode?.quickActions.isNotEmpty == true

        ? activeMode!.quickActions

        : persona.quickActions;

    final effectiveColor = activeMode != null

        ? hexToColor(activeMode.color)

        : personaColor;

    final effectiveIcon = activeMode?.icon ?? persona.icon;

    final effectiveTitle = activeMode?.name ?? persona.name;

    final effectiveSubtitle = activeMode?.description ?? persona.description;



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

                colors: [effectiveColor, effectiveColor.withValues(alpha: 0.6)],

                begin: Alignment.topLeft,

                end: Alignment.bottomRight,

              ),

              borderRadius: BorderRadius.circular(28),

              boxShadow: [

                BoxShadow(

                  color: effectiveColor.withValues(alpha: 0.3),

                  blurRadius: 24,

                  offset: const Offset(0, 8),

                ),

              ],

            ),

            child: Icon(personaIconFromName(effectiveIcon),

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

            effectiveTitle,

            style: TextStyle(

              fontSize: 22,

              fontWeight: FontWeight.w800,

              color: isDark ? Colors.white : Colors.black87,

              

            ),

          ).animate().fadeIn(delay: 150.ms),



          if (activeMode != null) ...[

            const SizedBox(height: 6),

            // Tappable "change mode" pill — sets the mode back to null which

            // re-renders the picker on next frame.

            GestureDetector(

              onTap: () => _maybeChangeMode(persona),

              child: Container(

                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

                decoration: BoxDecoration(

                  color: effectiveColor.withValues(alpha: 0.12),

                  borderRadius: BorderRadius.circular(999),

                  border: Border.all(

                      color: effectiveColor.withValues(alpha: 0.3), width: 1),

                ),

                child: Row(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    Icon(PhosphorIcons.arrowsClockwise(),

                        size: 12, color: effectiveColor),

                    const SizedBox(width: 4),

                    Text(

                      'تغيير الوضع',

                      style: TextStyle(

                        fontSize: 11,

                        fontWeight: FontWeight.w700,

                        color: effectiveColor,

                        fontFamily: 'Cairo',

                      ),

                    ),

                  ],

                ),

              ),

            ).animate().fadeIn(delay: 200.ms),

          ],



          const SizedBox(height: 6),

          Text(

            effectiveSubtitle,

            textAlign: TextAlign.center,

            style: TextStyle(

              fontSize: 13,

              color: isDark ? Colors.white54 : Colors.black45,

              

            ),

          ).animate().fadeIn(delay: 250.ms),



          const SizedBox(height: 32),



          // Quick actions

          ...effectiveActions.asMap().entries.map((entry) {

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
    final showTyping = chatState.isLoading && (last == null || last.role == 'user');
    final showLoader = showTyping || chatState.toolLoadingLabel != null || (chatState.toolSteps?.isNotEmpty == true);

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

      itemCount: messages.length + (showLoader ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == messages.length && showLoader) {
          return _buildTypingIndicator(
            isDark, 
            personaColor, 
            toolLabel: chatState.toolLoadingLabel,
            toolSteps: chatState.toolSteps,
          );
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

  Widget _buildTypingIndicator(bool isDark, Color personaColor, {String? toolLabel, List<ToolStep>? toolSteps}) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(24)
              .copyWith(bottomRight: const Radius.circular(4)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (toolSteps != null && toolSteps.isNotEmpty)
              _ToolExecutionTree(steps: toolSteps, accentColor: personaColor, isDark: isDark)
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
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
                                width: 8,
                                height: 8,
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
                  if (toolLabel != null) ...[
                    const SizedBox(width: 12),
                    Text(
                      toolLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: personaColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
          ],
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



  // ── Input Bar (Modern Pill Composer) ──
  //
  // A single unified pill that hosts the text field, mic button, and send
  // button. Uses Clip.antiAlias on the outer shell so the inner TextField's
  // rectangular hit/highlight area is clipped to the rounded corners — this
  // is what fixes the "sharp inner edges over the rounded outer container"
  // visual bug.

  Widget _buildInputBar(bool isDark, bool isLoading, Color personaColor, AiPersonaModel? persona) {

    final hasText = _controller.text.trim().isNotEmpty;
    final isFocused = _focusNode.hasFocus;
    final isActive = isFocused || _isListening;

    // Dark mode composer surface: clearly elevated above darkSurface
    // (#1A1A2E) with a subtle indigo cast that matches the app's accent
    // palette. The result is a "premium" pill that reads as a raised card
    // rather than a dark hole sitting inside a darker frame.
    final shellBg = isDark
        ? AppTheme.darkCard
        : const Color(0xFFF4F5F7);
    final shellBorder = isActive
        ? personaColor.withValues(alpha: isDark ? 0.55 : 0.45)
        : (isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.06));

    return Container(

      padding: EdgeInsets.only(

        left: 12,

        right: 12,

        top: 10,

        bottom: MediaQuery.of(context).padding.bottom + 10,

      ),

      decoration: BoxDecoration(

        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,

        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),

      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Unified pill ─────────────────────────────────────────────
          Builder(
            builder: (_) {
              // Pill geometry is completely static. We no longer animate
              // shadows, borders, or size while listening — that caused the
              // whole input to "breathe" which felt heavy. Instead:
              //   • The mic icon has its own localized halo pulse
              //     (see _ComposerIconButton).
              //   • A subtle chasing light travels around the pill's border
              //     in the active persona color — drawn as an overlay so it
              //     can never affect the pill's layout.
              final staticShadow = isActive
                  ? [
                      BoxShadow(
                        color: personaColor.withValues(alpha: 0.18),
                        blurRadius: 18,
                        spreadRadius: 0.5,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.25 : 0.05,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ];

              const borderRadius = BorderRadius.all(Radius.circular(26));

              return Stack(
                children: [
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: shellBg,
                      borderRadius: borderRadius,
                      border: Border.all(color: shellBorder, width: 1.2),
                      boxShadow: staticShadow,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                      // Mic (leading in RTL = right side)
                      if (_sttAvailable)
                        _ComposerIconButton(
                          icon: _isListening
                              ? PhosphorIcons.stop(PhosphorIconsStyle.fill)
                              : PhosphorIcons.microphone(),
                          tooltip: _isListening ? 'إيقاف الاستماع' : 'إدخال صوتي',
                          isActive: _isListening,
                          activeColor: Colors.redAccent,
                          isDark: isDark,
                          pulse: _isListening,
                          onTap: isLoading ? null : _toggleListening,
                        ),

                      // Text field
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: _sttAvailable ? 4 : 12,
                          ),
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            enabled: !isLoading,
                            textInputAction: TextInputAction.newline,
                            keyboardType: TextInputType.multiline,
                            maxLines: 6,
                            minLines: 1,
                            textDirection: TextDirection.rtl,
                            cursorColor: personaColor,
                            cursorWidth: 1.6,
                            cursorRadius: const Radius.circular(2),
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.45,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              // The global InputDecorationTheme forces
                              // filled=true with darkBg as the fill color in
                              // dark mode, which paints a near-black box
                              // *inside* our pill. Disable that explicitly so
                              // the TextField inherits the pill's surface.
                              filled: false,
                              fillColor: Colors.transparent,
                              isCollapsed: true,
                              hintText: _isListening
                                  ? 'جارٍ الاستماع…'
                                  : (_activeToolMode == 'search'
                                      ? 'اكتب سؤالك، سيتم البحث في الإنترنت...'
                                      : (_activeToolMode == 'url'
                                          ? 'أرفق الرابط لقراءة محتواه...'
                                          : 'اكتب رسالتك هنا…')),
                              hintStyle: TextStyle(
                                fontSize: 15,
                                color: _isListening
                                    ? personaColor
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.55)
                                        : Colors.black.withValues(alpha: 0.40)),
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Web Search Tool
                      if (persona != null && persona.hasWebSearch && (_activeToolMode == null || _activeToolMode == 'search'))
                        _InlineToolIcon(
                          icon: PhosphorIcons.globe(),
                          activeIcon: PhosphorIcons.globe(PhosphorIconsStyle.fill),
                          tooltip: 'بحث الويب',
                          isActive: _activeToolMode == 'search',
                          activeColor: personaColor,
                          isDark: isDark,
                          onTap: isLoading ? null : () => _toggleToolMode('search'),
                        ),
                        
                      // URL Reader Tool
                      if (persona != null && persona.hasUrlReader && (_activeToolMode == null || _activeToolMode == 'url'))
                        _InlineToolIcon(
                          icon: PhosphorIcons.link(),
                          activeIcon: PhosphorIcons.link(PhosphorIconsStyle.bold),
                          tooltip: 'قراءة الرابط',
                          isActive: _activeToolMode == 'url',
                          activeColor: personaColor,
                          isDark: isDark,
                          onTap: isLoading ? null : () => _toggleToolMode('url'),
                        ),

                      // Send/Stop button (trailing in RTL = left side)
                      _ComposerSendButton(
                        isLoading: isLoading,
                        isEnabled: hasText || isLoading,
                        color: personaColor,
                        isDark: isDark,
                        onTap: () => _sendMessage(_controller.text),
                        onStop: () {
                          HapticFeedback.mediumImpact();
                          if (persona != null) {
                            ref.read(expertChatProvider(persona).notifier).stopGeneration();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                  ),
                  // Chasing-light border overlay. Only painted while the
                  // user is actively dictating. The SweepGradient rotates
                  // with _recordingPulseController, creating a smooth
                  // comet-like highlight that travels around the pill
                  // in the current persona color. IgnorePointer keeps
                  // the text field fully interactive, and the overlay
                  // never contributes to layout so the input size stays
                  // perfectly still (no breathing, no wobble).
                  if (_isListening)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _recordingPulseController,
                          builder: (_, _) {
                            return CustomPaint(
                              painter: _ChasingBorderPainter(
                                progress: _recordingPulseController.value,
                                color: personaColor,
                                radius: 26,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          // Footer removed — kept minimal to avoid visual noise.
        ],
      ),

    );

  }

}

// ── Tool Execution Tree Widget ─────────────────────────────────────────────

class _ToolExecutionTree extends StatelessWidget {
  final List<ToolStep> steps;
  final Color accentColor;
  final bool isDark;

  const _ToolExecutionTree({
    required this.steps,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < steps.length; i++)
          _buildStep(steps[i], i == steps.length - 1),
      ],
    );
  }

  Widget _buildStep(ToolStep step, bool isLast) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStepIcon(step.isDone),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                step.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: step.isDone ? FontWeight.w600 : FontWeight.w800,
                  color: step.isDone
                      ? (isDark ? Colors.white54 : Colors.black45)
                      : accentColor,
                ),
              ),
            ),
          ],
        ),
        if (step.details.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 24, top: 4, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final detail in step.details)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 1,
                          color: isDark ? Colors.white10 : Colors.black12,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          detail,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              width: 1,
              height: step.details.isNotEmpty ? 10 : 15,
              color: isDark ? Colors.white10 : Colors.black12,
            ),
          ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildStepIcon(bool isDone) {
    if (isDone) {
      return Icon(
        PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
        size: 16,
        color: const Color(0xFF10B981),
      );
    }
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: accentColor,
            shape: BoxShape.circle,
          ),
        ).animate(onPlay: (c) => c.repeat()).scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1.2, 1.2),
              duration: 800.ms,
              curve: Curves.easeInOut,
            ).then().scale(
              begin: const Offset(1.2, 1.2),
              end: const Offset(0.5, 0.5),
            ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Composer sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Tonal icon button used inside the modern composer pill (e.g., mic).
class _ComposerIconButton extends StatefulWidget {
  final IconData icon;
  final String? tooltip;
  final bool isActive;
  final bool isDark;
  final bool pulse;
  final Color activeColor;
  final VoidCallback? onTap;

  const _ComposerIconButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
    this.tooltip,
    this.isActive = false,
    this.pulse = false,
    this.activeColor = Colors.redAccent,
  });

  @override
  State<_ComposerIconButton> createState() => _ComposerIconButtonState();
}

class _ComposerIconButtonState extends State<_ComposerIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (widget.pulse) _pulseCtrl.repeat();
  }

  @override
  void didUpdateWidget(covariant _ComposerIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat();
    } else if (!widget.pulse && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    final fg = widget.isActive
        ? widget.activeColor
        : (widget.isDark ? Colors.white70 : Colors.black54);
    final bg = widget.isActive
        ? widget.activeColor.withValues(alpha: widget.isDark ? 0.18 : 0.12)
        : Colors.transparent;

    Widget btn = Material(
      color: bg,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: disabled ? null : widget.onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            widget.icon,
            size: 20,
            color: disabled ? fg.withValues(alpha: 0.4) : fg,
          ),
        ),
      ),
    );

    if (widget.pulse) {
      btn = SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, _) {
                // Calmer mic halo: smaller expansion + softer alpha so the icon
                // feels alive without the heavy "throb" that distorted the
                // composer. We also keep the halo strictly behind the icon by
                // bounding its growth to the available padding around the button.
                final t = _pulseCtrl.value;
                return Container(
                  width: 40 + 12 * t,
                  height: 40 + 12 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.activeColor
                        .withValues(alpha: (1 - t) * 0.18),
                  ),
                );
              },
            ),
            btn,
          ],
        ),
      );
    } else {
      btn = SizedBox(
        width: 44,
        height: 44,
        child: Center(child: btn),
      );
    }


    if (widget.tooltip != null) {
      btn = Tooltip(message: widget.tooltip!, child: btn);
    }
    return btn;
  }
}

/// The smart send button. Three visual states: disabled, active (gradient
/// + soft persona glow), and loading (spinner inside the same circle).
class _ComposerSendButton extends StatelessWidget {
  final bool isLoading;
  final bool isEnabled;
  final bool isDark;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onStop;

  const _ComposerSendButton({
    required this.isLoading,
    required this.isEnabled,
    required this.isDark,
    required this.color,
    required this.onTap,
    this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveBg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    final tooltipMsg = isLoading
        ? 'إيقاف توليد الرد'
        : (isEnabled ? 'إرسال' : null);

    Widget button = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: isEnabled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  Color.lerp(color, Colors.black, 0.18) ?? color,
                ],
              )
            : null,
        color: isEnabled ? null : inactiveBg,
        shape: BoxShape.circle,
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isLoading ? onStop : (isEnabled ? onTap : null),
          customBorder: const CircleBorder(),
          child: Center(
            child: isLoading
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: const AlwaysStoppedAnimation(
                            Colors.white70,
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat())
                       .rotate(duration: 2000.ms),
                      Icon(
                        PhosphorIcons.stop(PhosphorIconsStyle.fill),
                        size: 12,
                        color: Colors.white,
                      ),
                    ],
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      PhosphorIcons.paperPlaneRight(
                        PhosphorIconsStyle.fill,
                      ),
                      key: ValueKey(isEnabled),
                      size: 18,
                      color: isEnabled
                          ? Colors.white
                          : (isDark
                              ? Colors.white38
                              : Colors.black38),
                    ),
                  ),
          ),
        ),
      ),
    );

    if (tooltipMsg != null) {
      return Tooltip(message: tooltipMsg, child: button);
    }
    return button;
  }
}



/// Clean header typing indicator: animated dots only, no spinner.
class _HeaderTypingIndicator extends StatefulWidget {
  const _HeaderTypingIndicator();

  @override
  State<_HeaderTypingIndicator> createState() => _HeaderTypingIndicatorState();
}

class _HeaderTypingIndicatorState extends State<_HeaderTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIcons.robot(PhosphorIconsStyle.fill),
            size: 10,
            color: Colors.white.withValues(alpha: 0.9),
          ).animate(onPlay: (c) => c.repeat())
           .shimmer(duration: 1500.ms, color: Colors.white54),
          const SizedBox(width: 4),
          Text(
            'يجري التفكير',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              fontFamily: 'Cairo',
              letterSpacing: 0.2,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 4),
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, _) {
              final t = _ctrl.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final delay = i * 0.33;
                  final phase = (t - delay).clamp(0.0, 1.0);
                  final opacity = (0.3 + 0.7 * _ease(phase)).clamp(0.3, 1.0);
                  return Container(
                    width: 2.5,
                    height: 2.5,
                    margin: const EdgeInsets.symmetric(horizontal: 0.8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: opacity),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  double _ease(double t) {
    return t < 0.5 ? 2 * t * t : 1 - 2 * (1 - t) * (1 - t);
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

                            'code': CodeElementBuilder(isDark, context, onActionRequested: onSuggestionSelected, messageContent: msg.content, enableExec: true),

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





// -- Offline Banner --------------------------------------------------------
class _OfflineBanner extends StatelessWidget {
  final bool isVisible;
  final bool isDark;

  const _OfflineBanner({required this.isVisible, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: !isVisible
            ? const SizedBox(width: double.infinity, height: 0)
            : Container(
                key: const ValueKey('offline-banner'),
                width: double.infinity,
                color: AppTheme.errorColor.withValues(alpha: isDark ? 0.18 : 0.12),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 4,
                  bottom: 6,
                  left: 12,
                  right: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        PhosphorIcons.wifiSlash(PhosphorIconsStyle.bold),
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'أنت في وضع عدم الاتصال',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Paints a single soft "comet" of light that chases around the rounded
/// rectangle border of the composer pill. The stroke sits exactly on the
/// pill's outer edge (inset by half the stroke width), uses a SweepGradient
/// rotated by [progress] ∈ [0,1], and fades to transparent at both ends so
/// only a short arc of [color] is visible at any time. The effect is
/// deliberately subtle — professional, not flashy — and never changes the
/// pill's geometry because it's drawn as an overlay inside a Positioned.fill.
class _ChasingBorderPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double radius;

  _ChasingBorderPainter({
    required this.progress,
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 1.6;
    final rect = Offset.zero & size;
    final inset = rect.deflate(strokeWidth / 2);
    final rrect = RRect.fromRectAndRadius(inset, Radius.circular(radius));

    // Rotate a narrow "comet" sweep around the center. The gradient has
    // a short lit arc (~22% of the perimeter) surrounded by fully
    // transparent stops so the rest of the border stays clean.
    final sweep = SweepGradient(
      startAngle: 0,
      endAngle: 2 * math.pi,
      transform: GradientRotation(2 * math.pi * progress),
      colors: [
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 0.55),
        color.withValues(alpha: 0.95),
        color.withValues(alpha: 0.55),
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.70, 0.80, 0.88, 0.96, 1.0, 1.0],
    );

    final paint = Paint()
      ..shader = sweep.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _ChasingBorderPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.radius != radius;
}

class CodeExecResultWidget extends StatefulWidget {
  final CodeExecResult result;
  final void Function(String prompt)? onActionRequested;
  
  const CodeExecResultWidget({super.key, required this.result, this.onActionRequested});

  @override
  State<CodeExecResultWidget> createState() => _CodeExecResultWidgetState();
}

class _CodeExecResultWidgetState extends State<CodeExecResultWidget> {
  bool _isExpanded = false;

  bool _isBase64Image(String text) {
    final t = text.trim();
    if (t.startsWith('iVBORw0KGgo') || t.startsWith('/9j/')) return true;
    if (t.startsWith('data:image')) return true;
    return false;
  }

  Widget _buildImage(String text) {
    try {
      String b64 = text.trim();
      if (b64.contains(',')) {
        b64 = b64.split(',').last;
      }
      b64 = b64.replaceAll(RegExp(r'\s+'), '');
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.memory(
          const Base64Decoder().convert(b64),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Text('فشل عرض الصورة.', style: TextStyle(color: Colors.red)),
        ),
      );
    } catch (e) {
      return Text('بيانات الصورة غير صالحة: $e', style: const TextStyle(color: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final res = widget.result;
    final color = res.isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    
    var output = res.displayOutput.trim();
    if (res.isSuccess && (output == 'Accepted' || output.isEmpty)) {
      output = '✅ تم التنفيذ بنجاح.\n(ملاحظة: هذا الأمر لا يملك مخرجات نصية لعرضها. استخدم استعلام SELECT لرؤية البيانات)';
    }

    final isImage = _isBase64Image(output);
    
    final lines = output.split('\n');
    final hasLongOutput = !isImage && lines.length > 8;
    final displayText = hasLongOutput && !_isExpanded 
        ? '${lines.take(8).join('\n')}\n...' 
        : output;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Title Bar (Terminal Style) ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF2D2D2D),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.terminalWindow(PhosphorIconsStyle.fill),
                  size: 16,
                  color: res.isSuccess ? color : const Color(0xFFEF4444),
                ),
                const SizedBox(width: 12),
                Text(
                  res.isSuccess ? 'Terminal - Success' : 'Terminal - Error',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (res.memoryFormatted != null) ...[
                  Text(
                    res.memoryFormatted!,
                    style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'),
                  ),
                  const SizedBox(width: 8),
                ],
                if (res.time != null)
                  Text(
                    '${res.time}s',
                    style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'),
                  ),
              ],
            ),
          ),
          
          // ── Output Area ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: color, width: 3)),
            ),
            child: isImage 
              ? _buildImage(output)
              : SelectableText(
                  displayText,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.5,
                    color: res.isSuccess ? Colors.white : const Color(0xFFFFA5A5),
                  ),
                ),
          ),

          // ── Smart AI Actions & Expand ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
            ),
            child: Row(
              children: [
                if (widget.onActionRequested != null)
                  GestureDetector(
                    onTap: () {
                      if (!res.isSuccess) {
                        widget.onActionRequested!('الرجاء تحليل هذا الخطأ البرمجي الذي ظهر أثناء التنفيذ وإصلاحه:\n\n```\n$output\n```');
                      } else {
                        widget.onActionRequested!('الرجاء شرح هذه المخرجات التي ظهرت أثناء تنفيذ الكود:\n\n```\n$output\n```');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: res.isSuccess ? Colors.blue.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: res.isSuccess ? Colors.blue.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            res.isSuccess ? Icons.lightbulb_outline : Icons.bug_report_outlined,
                            size: 14,
                            color: res.isSuccess ? Colors.blue[300] : Colors.red[300],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            res.isSuccess ? 'اشرح المخرجات' : 'أصلح الخطأ',
                            style: TextStyle(
                              color: res.isSuccess ? Colors.blue[300] : Colors.red[300],
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Spacer(),
                if (hasLongOutput)
                  GestureDetector(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    child: Text(
                      _isExpanded ? 'عرض أقل' : 'عرض المزيد (${lines.length - 8} أسطر)',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineToolIcon extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String tooltip;
  final bool isActive;
  final Color activeColor;
  final bool isDark;
  final VoidCallback? onTap;

  const _InlineToolIcon({
    required this.icon,
    this.activeIcon,
    required this.tooltip,
    required this.isActive,
    required this.activeColor,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      decoration: BoxDecoration(
        color: isActive 
          ? activeColor.withValues(alpha: isDark ? 0.12 : 0.10) 
          : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive 
            ? activeColor.withValues(alpha: 0.4) 
            : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
          width: 1.2,
        ),
        boxShadow: isActive ? [
          BoxShadow(
            color: activeColor.withValues(alpha: isDark ? 0.25 : 0.15),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: Stack(
                  key: ValueKey<bool>(isActive),
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      isActive ? (activeIcon ?? icon) : icon,
                      size: 20,
                      color: isActive ? activeColor : (isDark ? Colors.white54 : Colors.black45),
                    ),
                    if (isActive)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF4F5F7),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            PhosphorIcons.x(PhosphorIconsStyle.bold),
                            size: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
