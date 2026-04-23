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

/// Notifier that manages the chat session state (for in-app website chats)
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
        item: item,
        chatHistory: updatedMessages,
        pageContent: pageContent,
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
      _saveChatHistory();
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

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

// ─────────────────────────────────────────────────────────────────────────────
// QUICK TILE (External) — Multi-Session Manager
// ─────────────────────────────────────────────────────────────────────────────

/// Max number of sessions to store locally
const _kMaxSessions = 10;
const _kSessionsHiveKey = 'quick_chat_sessions';
const _kDraftHiveKey = 'quick_chat_draft';

/// State for the Quick Tile multi-session manager
class QuickSessionsState {
  final List<QuickChatSession> sessions;
  final String? activeSessionId;
  final bool isLoading;
  final String? error;

  const QuickSessionsState({
    this.sessions = const [],
    this.activeSessionId,
    this.isLoading = false,
    this.error,
  });

  QuickChatSession? get activeSession =>
      sessions.where((s) => s.id == activeSessionId).firstOrNull;

  List<AiChatMessage> get activeMessages => activeSession?.messages ?? [];

  QuickSessionsState copyWith({
    List<QuickChatSession>? sessions,
    String? activeSessionId,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return QuickSessionsState(
      sessions: sessions ?? this.sessions,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class QuickSessionsNotifier extends StateNotifier<QuickSessionsState> {
  QuickSessionsNotifier() : super(const QuickSessionsState()) {
    _loadAllSessions();
  }

  // ── Persistence Helpers ──────────────────────────────────────────────────

  void _loadAllSessions() {
    try {
      final box = Hive.box('ai_chats');
      final raw = box.get(_kSessionsHiveKey);
      if (raw != null && raw is List && raw.isNotEmpty) {
        final sessions = raw
            .map((e) => QuickChatSession.fromJson(Map<dynamic, dynamic>.from(e as Map)))
            .toList()
          ..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
        state = state.copyWith(sessions: sessions);
      }
    } catch (_) {}
  }

  void _saveAllSessions() {
    try {
      final box = Hive.box('ai_chats');
      final data = state.sessions.map((s) => s.toJson()).toList();
      box.put(_kSessionsHiveKey, data);
    } catch (_) {}
  }

  // ── Session Management ───────────────────────────────────────────────────

  /// Opens the correct session for the given context (URL/text).
  /// If a matching session exists → resumes. Otherwise → creates fresh.
  void openForContext(String contextText) {
    if (contextText.trim().isEmpty) {
      startNewSession(contextText);
      return;
    }

    final hash = _computeHash(contextText);
    final existing = state.sessions
        .where((s) => s.contextHash == hash)
        .toList()
      ..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));

    if (existing.isNotEmpty) {
      state = state.copyWith(activeSessionId: existing.first.id);
    } else {
      startNewSession(contextText);
    }
  }

  /// Force-starts a brand new empty session for the given context.
  void startNewSession(String contextText) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final session = QuickChatSession(
      id: id,
      title: QuickChatSession.generateTitle(contextText),
      contextHash: _computeHash(contextText),
      messages: [],
      lastActivity: DateTime.now(),
    );

    final trimmed = [session, ...state.sessions].take(_kMaxSessions).toList();
    state = state.copyWith(sessions: trimmed, activeSessionId: id);
    _saveAllSessions();
  }

  /// Switch to a previous session by ID.
  void switchToSession(String sessionId) {
    state = state.copyWith(activeSessionId: sessionId);
  }

  /// Delete a specific session by ID.
  void deleteSession(String sessionId) {
    final updated = state.sessions.where((s) => s.id != sessionId).toList();
    String? nextId = state.activeSessionId;
    if (nextId == sessionId) {
      nextId = updated.firstOrNull?.id;
    }
    state = state.copyWith(sessions: updated, activeSessionId: nextId);
    _saveAllSessions();
  }

  /// Clear only the active session's messages (not delete it from history).
  void clearActiveSession() {
    final id = state.activeSessionId;
    if (id == null) return;
    final updated = state.sessions.map((s) {
      if (s.id == id) return s.copyWith(messages: []);
      return s;
    }).toList();
    state = state.copyWith(sessions: updated);
    _saveAllSessions();
  }

  // ── Messaging ────────────────────────────────────────────────────────────

  Future<void> sendMessage(String content, String contextText) async {
    if (content.trim().isEmpty || state.isLoading) return;

    // Ensure there's an active session
    if (state.activeSessionId == null) {
      openForContext(contextText);
    }

    await saveDraft('');

    final userMessage = AiChatMessage(
      role: 'user',
      content: content.trim(),
      timestamp: DateTime.now(),
    );

    _updateActiveMessages([...state.activeMessages, userMessage]);
    state = state.copyWith(isLoading: true, error: null, clearError: true);

    try {
      final responseText = await AiAssistantService.sendMessage(
        item: null,
        chatHistory: state.activeMessages,
        externalUrlOrText: contextText.isNotEmpty ? contextText : null,
      );

      final assistantMessage = AiChatMessage(
        role: 'assistant',
        content: responseText,
        timestamp: DateTime.now(),
      );

      _updateActiveMessages([...state.activeMessages, assistantMessage]);
      state = state.copyWith(isLoading: false);
      _saveAllSessions();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void _updateActiveMessages(List<AiChatMessage> messages) {
    final id = state.activeSessionId;
    if (id == null) return;
    final updated = state.sessions.map((s) {
      if (s.id == id) {
        return s.copyWith(messages: messages, lastActivity: DateTime.now());
      }
      return s;
    }).toList();
    state = state.copyWith(sessions: updated);
  }

  void clearError() => state = state.copyWith(clearError: true);

  // ── Draft ────────────────────────────────────────────────────────────────

  Future<void> saveDraft(String text) async {
    try {
      Hive.box('ai_chats').put(_kDraftHiveKey, text);
    } catch (_) {}
  }

  String loadDraft() {
    try {
      return (Hive.box('ai_chats').get(_kDraftHiveKey) as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  // ── Utilities ────────────────────────────────────────────────────────────

  static String _computeHash(String text) {
    // Simple repeatable hash — no external deps needed
    final clean = text.trim().toLowerCase();
    int h = 0;
    for (final c in clean.codeUnits) {
      h = (h * 31 + c) & 0xFFFFFFFF;
    }
    return h.toRadixString(16);
  }
}

/// The single provider for the Quick Tile multi-session system.
final quickSessionsProvider =
    StateNotifierProvider.autoDispose<QuickSessionsNotifier, QuickSessionsState>(
  (ref) => QuickSessionsNotifier(),
);
