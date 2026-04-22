import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:any_link_preview/any_link_preview.dart';

import '../../core/theme/app_theme.dart';
import '../../presentation/providers/ai_assistant_providers.dart';
import 'ai_chat_screen.dart'; // To reuse CodeElementBuilder if needed
import 'dart:ui';

class ExternalAiChatScreen extends ConsumerStatefulWidget {
  final String initialText;

  const ExternalAiChatScreen({
    super.key,
    required this.initialText,
  });

  @override
  ConsumerState<ExternalAiChatScreen> createState() => _ExternalAiChatScreenState();
}

class _ExternalAiChatScreenState extends ConsumerState<ExternalAiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  late String _contextText;
  bool _sessionBannerDismissed = false;

  @override
  void initState() {
    super.initState();
    _contextText = widget.initialText;
    
    if (_contextText.isEmpty) {
      _loadClipboardContext();
    }

    // Restore last draft
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final draft = ref.read(externalAiChatProvider(_contextText).notifier).loadDraft();
      if (draft.isNotEmpty) {
        _controller.text = draft;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: draft.length),
        );
      }
    });

    // Auto-save draft on every keystroke
    _controller.addListener(() {
      ref.read(externalAiChatProvider(_contextText).notifier).saveDraft(_controller.text);
    });
  }

  Future<void> _loadClipboardContext() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      if (mounted) {
        setState(() {
          _contextText = data.text!;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    ref.read(externalAiChatProvider(_contextText).notifier).sendMessage(text);
    _controller.clear();
    _scrollToBottom();
  }

  Future<void> _confirmClearChat(BuildContext ctx, bool isDark) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'حذف المحادثة',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
          textDirection: TextDirection.rtl,
        ),
        content: Text(
          'هل أنت متأكد؟ سيتم حذف جميع الرسائل ولا يمكن استرجاعها.',
          style: TextStyle(
            fontFamily: 'Cairo',
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: isDark ? Colors.white60 : Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo', color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(externalAiChatProvider(_contextText).notifier).clearChat();
      setState(() => _sessionBannerDismissed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatState = ref.watch(externalAiChatProvider(_contextText));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Blurred background
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                SystemNavigator.pop(); 
              },
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          
          // Bottom Sheet Chat UI
          Align(
            alignment: Alignment.bottomCenter,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 1.0, end: 0.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, value * 500),
                  child: child,
                );
              },
              child: Container(
                height: MediaQuery.of(context).size.height * 0.90, // 90% of screen
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, -5),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Column(
                    children: [
                      // Custom Header
                      Container(
                        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Column(
                          children: [
                              // Drag handle
                            Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white24 : Colors.black26,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    PhosphorIcons.x(),
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  onPressed: () {
                                    SystemNavigator.pop();
                                  },
                                ),
                                const Spacer(),
                                Icon(
                                  PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                                  color: const Color(0xFF8A2BE2),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'مرشد زاد السريع',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                const Spacer(),
                                 // Clear chat button with confirmation
                                 IconButton(
                                   icon: Icon(
                                     PhosphorIcons.trash(),
                                     color: isDark ? Colors.white54 : Colors.black45,
                                     size: 20,
                                   ),
                                   tooltip: 'حذف المحادثة',
                                   onPressed: () => _confirmClearChat(context, isDark),
                                 ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      if (_contextText.isNotEmpty)
                        if (_contextText.trim().startsWith('http'))
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: SizedBox(
                              height: 85, 
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
                                  fontFamily: 'Cairo',
                                ),
                                bodyStyle: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black54,
                                  fontSize: 11,
                                  fontFamily: 'Cairo',
                                ),
                                errorWidget: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                  child: Row(
                                    children: [
                                      Icon(PhosphorIcons.link(), size: 16, color: AppTheme.primaryColor),
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
                                ),
                                cache: const Duration(days: 7),
                                backgroundColor: Colors.transparent,
                                borderRadius: 0,
                                removeElevation: true,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            child: Row(
                              children: [
                                Icon(PhosphorIcons.textT(), size: 16, color: AppTheme.primaryColor),
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
                          ),

                      // Resume session banner
                      if (chatState.messages.isNotEmpty && !_sessionBannerDismissed)
                        _buildResumeBanner(isDark, chatState.messages.length),

                      Expanded(
                        child: chatState.messages.isEmpty
                            ? _buildWelcomeMessage(isDark)
                            : _buildChatList(context, isDark, chatState),
                      ),
                      
                      _buildInputBar(context, isDark, chatState.isLoading),
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

  Widget _buildResumeBanner(bool isDark, int messageCount) {
    final isFirstOpen = !_sessionBannerDismissed;
    if (!isFirstOpen) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: isDark ? 0.25 : 0.12),
            AppTheme.accentColor.withValues(alpha: isDark ? 0.15 : 0.07),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(PhosphorIcons.clockCounterClockwise(), size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'استئناف المحادثة السابقة · $messageCount رسالة',
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _sessionBannerDismissed = true),
            child: Icon(
              PhosphorIcons.x(),
              size: 16,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIcons.robot(PhosphorIconsStyle.fill),
              size: 48,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'كيف يمكنني مساعدتك؟',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.initialText.isNotEmpty
                ? 'لقد استلمت الرابط/النص، اسألني عنه الآن!'
                : 'اكتب سؤالك بالأسفل للبدء',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.black54,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(BuildContext context, bool isDark, AiChatState chatState) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == chatState.messages.length && chatState.isLoading) {
          return _buildLoadingIndicator(isDark);
        }
        
        final msg = chatState.messages[index];
        final isUser = msg.role == 'user';
        
        return Align(
          alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUser
                  ? AppTheme.primaryColor
                  : (isDark ? AppTheme.darkSurface : Colors.white),
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomLeft: isUser ? const Radius.circular(0) : const Radius.circular(20),
                bottomRight: !isUser ? const Radius.circular(0) : const Radius.circular(20),
              ),
              boxShadow: isUser ? null : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: isUser
                ? Text(
                    msg.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.5,
                      fontFamily: 'Cairo',
                    ),
                  )
                : MarkdownBody(
                    data: msg.content,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 15,
                        height: 1.6,
                        fontFamily: 'Cairo',
                      ),
                      code: TextStyle(
                        fontFamily: 'monospace',
                        backgroundColor: isDark ? Colors.white10 : Colors.black12,
                        color: isDark ? Colors.amber.shade200 : Colors.brown.shade800,
                      ),
                    ),
                    builders: {
                      'code': CodeElementBuilder(isDark, context),
                    },
                    onTapLink: (text, href, title) {
                      if (href != null) launchUrl(Uri.parse(href));
                    },
                  ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: const Radius.circular(0),
          ),
        ),
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, bool isDark, bool isLoading) {
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
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.initialText.isNotEmpty && ref.watch(externalAiChatProvider(widget.initialText)).messages.isEmpty && !isLoading)
            _buildQuickPrompts(isDark),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(24),
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
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'اكتب سؤالك هنا...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white30 : Colors.black26,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: isLoading ? null : () => _sendMessage(_controller.text),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
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

  Widget _buildQuickPrompts(bool isDark) {
    final prompts = ["لخص هذا الرابط", "اشرح الفكرة الرئيسية", "ترجم المحتوى", "استخرج النقاط الهامة"];
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
              onPressed: () => _sendMessage(prompts[index]),
            );
          },
        ),
      ),
    );
  }
}
