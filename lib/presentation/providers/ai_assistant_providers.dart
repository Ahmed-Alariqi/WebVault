import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/ai_chat_model.dart';
import '../../data/models/website_model.dart';
import '../../data/services/ai_assistant_service.dart';

/// Provider to temporarily hold extracted browser content for AI chat
final extractedBrowserContentProvider = StateProvider<String?>((ref) => null);

/// State for an AI chat session
class AiChatState {
  final List<AiChatMessage> messages;
  final bool isLoading;
  final String? error;

  const AiChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  AiChatState copyWith({
    List<AiChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier that manages the chat session state
class AiChatNotifier extends StateNotifier<AiChatState> {
  final WebsiteModel item;

  AiChatNotifier(this.item) : super(const AiChatState()) {
    _loadChatHistory();
  }

  void _loadChatHistory() {
    try {
      final box = Hive.box('ai_chats');
      final data = box.get('chat_${item.id}');
      if (data != null && data is List) {
        final messages = data
            .map(
              (e) =>
                  AiChatMessage.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
        state = state.copyWith(messages: messages);
      }
    } catch (e) {
      // ignore parsing errors and start fresh
    }
  }

  void _saveChatHistory() {
    try {
      final box = Hive.box('ai_chats');
      final data = state.messages.map((m) => m.toJson()).toList();
      box.put('chat_${item.id}', data);
    } catch (e) {
      // ignore
    }
  }

  /// Send a user message and get AI response
  Future<void> sendMessage(String content, [String? pageContent]) async {
    if (content.trim().isEmpty || state.isLoading) return;

    // Add user message
    final userMessage = AiChatMessage(
      role: 'user',
      content: content.trim(),
      timestamp: DateTime.now(),
    );

    final updatedMessages = [...state.messages, userMessage];
    state = state.copyWith(
      messages: updatedMessages,
      isLoading: true,
      error: null,
    );

    try {
      // Call AI service
      final responseText = await AiAssistantService.sendMessage(
        item: item,
        chatHistory: updatedMessages,
        pageContent: pageContent,
      );

      // Add assistant response
      final assistantMessage = AiChatMessage(
        role: 'assistant',
        content: responseText,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...updatedMessages, assistantMessage],
        isLoading: false,
      );
      _saveChatHistory();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      // Remove loading message from history if any error happens, or we can just leave it as is
      // but without the mock. Better to revert updatedMessages or just save current state.
      _saveChatHistory();
    }
  }

  /// Clear the error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear all messages
  void clearChat() {
    state = const AiChatState();
    _saveChatHistory();
  }
}

/// State to control bottom sheet visibility and expanded state
class AiBottomSheetState {
  final bool isVisible;
  final bool isExpanded;
  const AiBottomSheetState({this.isVisible = false, this.isExpanded = false});
}

final aiBottomSheetStateProvider = StateProvider<AiBottomSheetState>((ref) => const AiBottomSheetState());

/// Provider to control visibility of the floating AI button
final aiButtonVisibilityProvider = StateProvider<bool>((ref) => false);

/// Family provider — each item gets its own chat session. Made persistent across show/hide.
final aiChatProvider = StateNotifierProvider.family<AiChatNotifier, AiChatState, WebsiteModel>(
      (ref, item) => AiChatNotifier(item),
    );

/// State notifier for external AI Assistant chats
class ExternalAiChatNotifier extends StateNotifier<AiChatState> {
  final String initialContext;

  static const _hiveKey = 'external_chat_history';
  static const _draftKey = 'external_chat_draft';

  ExternalAiChatNotifier(this.initialContext) : super(const AiChatState()) {
    _loadChatHistory();
  }

  void _loadChatHistory() {
    try {
      final box = Hive.box('ai_chats');
      final data = box.get(_hiveKey);
      if (data != null && data is List && data.isNotEmpty) {
        final messages = data
            .map((e) => AiChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        state = state.copyWith(messages: messages);
      }
    } catch (_) {}
  }

  void _saveChatHistory() {
    try {
      final box = Hive.box('ai_chats');
      final data = state.messages.map((m) => m.toJson()).toList();
      box.put(_hiveKey, data);
    } catch (_) {}
  }

  Future<void> saveDraft(String text) async {
    try {
      final box = Hive.box('ai_chats');
      box.put(_draftKey, text);
    } catch (_) {}
  }

  String loadDraft() {
    try {
      final box = Hive.box('ai_chats');
      return (box.get(_draftKey) as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || state.isLoading) return;

    // Clear draft on send
    await saveDraft('');

    final userMessage = AiChatMessage(
      role: 'user',
      content: content.trim(),
      timestamp: DateTime.now(),
    );

    final updatedMessages = [...state.messages, userMessage];
    state = state.copyWith(
      messages: updatedMessages,
      isLoading: true,
      error: null,
    );

    try {
      final responseText = await AiAssistantService.sendMessage(
        item: null,
        chatHistory: updatedMessages,
        externalUrlOrText: initialContext.isNotEmpty ? initialContext : null,
      );

      final assistantMessage = AiChatMessage(
        role: 'assistant',
        content: responseText,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...updatedMessages, assistantMessage],
        isLoading: false,
      );
      _saveChatHistory();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearChat() {
    state = const AiChatState();
    _saveChatHistory();
    saveDraft('');
  }
}

/// Provider for external AI chats — NOT auto-disposed so session persists.
final externalAiChatProvider = StateNotifierProvider.family<ExternalAiChatNotifier, AiChatState, String>(
  (ref, contextText) => ExternalAiChatNotifier(contextText),
);
