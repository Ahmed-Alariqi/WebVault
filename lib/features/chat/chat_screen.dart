import 'package:file_picker/file_picker.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/chat_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../presentation/widgets/offline_warning_widget.dart';
import '../../data/models/chat_model.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _conversationId;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 300,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _conversationId == null) return;

    _messageController.clear();
    await userSendMessage(_conversationId!, text);
    _scrollToBottom();
  }

  bool _isUploadingImage = false;

  Future<void> _pickAndSendImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      final fileBytes = result.files.single.bytes!;
      final fileName = result.files.single.name;
      final fileExtension = fileName.split('.').last;

      if (!mounted) return;
      setState(() => _isUploadingImage = true);

      try {
        if (_conversationId == null) return;

        final imageUrl = await uploadChatImageBytes(
          fileBytes,
          _conversationId!,
          fileExtension,
        );
        if (imageUrl != null) {
          await userSendMessage(_conversationId!, '[IMAGE] $imageUrl');
          _scrollToBottom();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.chatFailedUpload),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.chatError(e.toString()),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUploadingImage = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Watch conversation to get the ID and mark as read
    final conversationAsync = ref.watch(userConversationProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.chatSupport,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              AppLocalizations.of(context)!.chatSupportSub,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(PhosphorIcons.caretLeft()),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: conversationAsync.when(
          data: (conversation) {
            if (conversation == null) {
              return Center(
                child: Text(AppLocalizations.of(context)!.chatInitError),
              );
            }

            _conversationId = conversation.id;

            // Mark as read whenever the screen rebuilds (user is looking at it)
            if (conversation.unreadUserCount > 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                markConversationReadByUser(conversation.id);
              });
            }

            final messagesAsync = ref.watch(userMessagesStreamProvider);

            return Column(
              children: [
                Expanded(
                  child: messagesAsync.when(
                    data: (messages) {
                      if (messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                PhosphorIcons.chatCircleDots(
                                  PhosphorIconsStyle.duotone,
                                ),
                                size: 64,
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                AppLocalizations.of(context)!.chatSendMsg,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(context)!.chatHereToHelp,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // We want to scroll to bottom when new messages arrive.
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 24,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = !msg.isAdmin; // user sent it

                          return Directionality(
                            // Force LTR so bubble positions are never mirrored
                            textDirection: ui.TextDirection.ltr,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                mainAxisAlignment: isMe
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (!isMe) ...[
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppTheme.primaryColor
                                          .withValues(alpha: 0.12),
                                      child: const Icon(
                                        Icons.support_agent_rounded,
                                        size: 18,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  GestureDetector(
                                    onLongPress: isMe
                                        ? () => _showActionMenu(context, msg)
                                        : null,
                                    child: Container(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                            0.75,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: isMe
                                            ? const LinearGradient(
                                                colors: [
                                                  AppTheme.primaryColor,
                                                  Color(0xFF7C4DFF),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : null,
                                        color: isMe
                                            ? null
                                            : (isDark
                                                  ? const Color(0xFF2C2C3E)
                                                  : Colors.white),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isMe
                                                ? AppTheme.primaryColor
                                                      .withValues(alpha: 0.25)
                                                : Colors.black.withValues(
                                                    alpha: isDark ? 0.2 : 0.07,
                                                  ),
                                            blurRadius: isMe ? 12 : 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(20),
                                          topRight: const Radius.circular(20),
                                          bottomLeft: isMe
                                              ? const Radius.circular(20)
                                              : const Radius.circular(4),
                                          bottomRight: isMe
                                              ? const Radius.circular(4)
                                              : const Radius.circular(20),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          if (msg.content.startsWith(
                                            '[IMAGE] ',
                                          ))
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.network(
                                                msg.content.replaceFirst(
                                                  '[IMAGE] ',
                                                  '',
                                                ),
                                                width: 200,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => const Icon(
                                                      Icons.broken_image,
                                                      color: Colors.white54,
                                                    ),
                                              ),
                                            )
                                          else
                                            Directionality(
                                              // Let text content use natural text direction
                                              textDirection:
                                                  ui.TextDirection.rtl,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  msg.content,
                                                  textAlign: TextAlign.start,
                                                  style: TextStyle(
                                                    color: isMe
                                                        ? Colors.white
                                                        : (isDark
                                                              ? Colors.white
                                                              : Colors.black87),
                                                    fontSize: 15,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat.jm().format(
                                              msg.createdAt,
                                            ),
                                            style: TextStyle(
                                              color: isMe
                                                  ? Colors.white.withValues(
                                                      alpha: 0.65,
                                                    )
                                                  : (isDark
                                                        ? Colors.white38
                                                        : Colors.black38),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (isMe) const SizedBox(width: 4),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) {
                      final errStr = e.toString().toLowerCase();
                      final isOffline =
                          errStr.contains('socketexception') ||
                          errStr.contains('failed host lookup') ||
                          errStr.contains('connection refused') ||
                          errStr.contains('clientexception') ||
                          errStr.contains('network is unreachable') ||
                          errStr.contains('xmlhttprequest error') ||
                          errStr.contains('network error') ||
                          errStr.contains('fetch failed') ||
                          errStr.contains('offline');

                      if (isOffline) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: OfflineWarningWidget(error: e),
                          ),
                        );
                      }

                      return Center(
                        child: Text(
                          AppLocalizations.of(context)!.chatError(e.toString()),
                        ),
                      );
                    },
                  ),
                ),

                // Input Area
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (_isUploadingImage)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.chatUploadingImg,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              PhosphorIcons.image(),
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                            onPressed: _pickAndSendImage,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 16,
                              ),
                              textCapitalization: TextCapitalization.sentences,
                              minLines: 1,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(
                                  context,
                                )!.chatTypeMsg,
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                PhosphorIcons.paperPlaneTilt(
                                  PhosphorIconsStyle.fill,
                                ),
                                color: Colors.white,
                                size: 22,
                              ),
                              onPressed: _sendMessage,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) {
            final errStr = e.toString().toLowerCase();
            final isOffline =
                errStr.contains('socketexception') ||
                errStr.contains('failed host lookup') ||
                errStr.contains('connection refused') ||
                errStr.contains('clientexception') ||
                errStr.contains('network is unreachable') ||
                errStr.contains('xmlhttprequest error') ||
                errStr.contains('network error') ||
                errStr.contains('fetch failed') ||
                errStr.contains('offline');

            if (isOffline) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: OfflineWarningWidget(error: e),
                ),
              );
            }

            return Center(
              child: Text(
                AppLocalizations.of(context)!.chatError(e.toString()),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showActionMenu(BuildContext context, MessageModel message) {
    if (message.content.startsWith('[IMAGE] ')) return; // Skip for images

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(
                  PhosphorIcons.pencilLine(),
                  color: AppTheme.primaryColor,
                ),
                title: Text(l10n.edit),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(message);
                },
              ),
              ListTile(
                leading: Icon(
                  PhosphorIcons.trash(),
                  color: AppTheme.errorColor,
                ),
                title: Text(l10n.delete),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(message);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(MessageModel message) {
    final editCtrl = TextEditingController(text: message.content);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.edit),
        content: TextField(
          controller: editCtrl,
          maxLines: 5,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final newContent = editCtrl.text.trim();
              if (newContent.isNotEmpty && newContent != message.content) {
                try {
                  await updateMessage(
                    message.id,
                    message.conversationId,
                    newContent,
                  );
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Edit failed: $e')));
                  }
                }
              } else {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(MessageModel message) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.deleteMessageTitle),
        content: Text(l10n.deleteMessageContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              await deleteMessage(message.id, message.conversationId);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.deleteLabel)));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
