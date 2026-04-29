import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/ai_chat_model.dart';
import '../../data/models/ai_persona_model.dart';
import '../../data/models/ai_persona_mode.dart';
import '../../data/models/ai_stats_model.dart';
import '../../data/services/zad_expert_service.dart';
import '../../data/services/connectivity_service.dart';
import '../../core/constants.dart';

const String _kPersonasCacheKey = 'personas_v1';

List<AiPersonaModel> _readPersonasCache() {
  try {
    final box = Hive.box(kExpertPersonasCacheBox);
    final raw = box.get(_kPersonasCacheKey);
    if (raw is List && raw.isNotEmpty) {
      return raw
          .map((e) => AiPersonaModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
  } catch (_) {}
  return const [];
}

void _writePersonasCache(List<AiPersonaModel> personas) {
  try {
    final box = Hive.box(kExpertPersonasCacheBox);
    // Note: AiPersonaModel.toJson() omits `id` (used for Supabase upserts).
    // We need `id` to reconstruct the model on read, so we attach it here.
    final data = personas
        .map((p) => {...p.toJson(), 'id': p.id})
        .toList();
    box.put(_kPersonasCacheKey, data);
  } catch (_) {}
}

// ─────────────────────────────────────────────────────────────────────────────
// Personas — fetched from Supabase
// ─────────────────────────────────────────────────────────────────────────────

final expertPersonasProvider =
    FutureProvider.autoDispose<List<AiPersonaModel>>((ref) async {
  try {
    final fresh = await ZadExpertService.fetchPersonas();
    if (fresh.isNotEmpty) {
      _writePersonasCache(fresh);
    }
    return fresh;
  } catch (e) {
    // Offline / network failure: fall back to last cached personas so the
    // user can still enter Zad Expert and use locally-stored chat sessions.
    final cached = _readPersonasCache();
    if (cached.isNotEmpty) return cached;
    rethrow;
  }
});

/// Currently selected persona
final selectedPersonaProvider = StateProvider<AiPersonaModel?>((ref) => null);

/// Currently selected sub-persona mode (per persona slug).
///
/// Null  = persona-only behaviour (no mode layered on top).
/// Set when the user picks a mode card on the welcome screen.
final selectedModeProvider =
    StateProvider.family<AiPersonaMode?, String>((ref, _) => null);

// ─────────────────────────────────────────────────────────────────────────────
// Admin — providers management
// ─────────────────────────────────────────────────────────────────────────────

final adminAiProvidersProvider =
    FutureProvider.autoDispose<List<AiProviderModel>>((ref) async {
  return ZadExpertService.fetchProviders();
});

final adminAllPersonasProvider =
    FutureProvider.autoDispose<List<AiPersonaModel>>((ref) async {
  return ZadExpertService.fetchAllPersonas();
});

// ─────────────────────────────────────────────────────────────────────────────
// Admin — usage statistics dashboard
// ─────────────────────────────────────────────────────────────────────────────

/// Currently selected period for the stats tab. Driven by the segmented
/// selector at the top of the dashboard.
final aiStatsPeriodProvider =
    StateProvider<AiStatsPeriod>((ref) => AiStatsPeriod.today);

/// All six providers below `watch` the period so they auto-refresh whenever
/// the admin flips the selector. They're `autoDispose` so leaving the tab
/// frees memory.

final aiOverviewProvider =
    FutureProvider.autoDispose<AiOverviewStats>((ref) async {
  final period = ref.watch(aiStatsPeriodProvider);
  return ZadExpertService.fetchOverview(period.days);
});

final aiTopPersonasProvider =
    FutureProvider.autoDispose<List<AiPersonaUsage>>((ref) async {
  final period = ref.watch(aiStatsPeriodProvider);
  return ZadExpertService.fetchTopPersonas(period.days);
});

final aiTopProvidersProvider =
    FutureProvider.autoDispose<List<AiProviderUsage>>((ref) async {
  final period = ref.watch(aiStatsPeriodProvider);
  return ZadExpertService.fetchTopProviders(period.days);
});

final aiTopUsersProvider =
    FutureProvider.autoDispose<List<AiUserUsage>>((ref) async {
  final period = ref.watch(aiStatsPeriodProvider);
  return ZadExpertService.fetchTopUsers(period.days);
});

final aiKeyHealthProvider =
    FutureProvider.autoDispose<List<AiKeyHealth>>((ref) async {
  final period = ref.watch(aiStatsPeriodProvider);
  return ZadExpertService.fetchKeyHealth(period.days);
});

final aiRecentErrorsProvider =
    FutureProvider.autoDispose<List<AiErrorEntry>>((ref) async {
  // Recent errors aren't bound to the period selector — always show the
  // last 10 errors regardless, since the panel's purpose is troubleshooting.
  return ZadExpertService.fetchRecentErrors();
});

// ─────────────────────────────────────────────────────────────────────────────
// Expert Chat — per-persona multi-session with local storage
// ─────────────────────────────────────────────────────────────────────────────

class ExpertSessionsState {
  final List<ExpertChatSession> sessions;
  final String? activeSessionId;
  final bool isLoading;
  final String? error;

  const ExpertSessionsState({
    this.sessions = const [],
    this.activeSessionId,
    this.isLoading = false,
    this.error,
  });

  ExpertChatSession? get activeSession =>
      sessions.where((s) => s.id == activeSessionId).firstOrNull;

  List<AiChatMessage> get activeMessages => activeSession?.messages ?? [];

  ExpertSessionsState copyWith({
    List<ExpertChatSession>? sessions,
    String? activeSessionId,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ExpertSessionsState(
      sessions: sessions ?? this.sessions,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ExpertSessionsNotifier extends StateNotifier<ExpertSessionsState> {
  final String personaSlug;
  final String personaId;
  final Ref _ref;

  ExpertSessionsNotifier({
    required this.personaSlug,
    required this.personaId,
    required Ref ref,
  })  : _ref = ref,
        super(const ExpertSessionsState()) {
    _loadAllSessions();
  }

  /// Resolve the active mode key from the per-persona [selectedModeProvider].
  /// Returns `null` when no mode is selected (legacy behaviour).
  String? get _activeModeKey =>
      _ref.read(selectedModeProvider(personaSlug))?.key;

  String get _hiveKey => 'expert_sessions_$personaSlug';

  void _loadAllSessions() {
    try {
      final box = Hive.box(kExpertSessionsBox);
      final raw = box.get(_hiveKey);
      if (raw != null && raw is List && raw.isNotEmpty) {
        final sessions = raw
            .map((e) => ExpertChatSession.fromJson(Map<dynamic, dynamic>.from(e as Map)))
            .toList()
          ..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
        state = state.copyWith(sessions: sessions);
        
        // Auto-activate the most recent session if exists
        if (sessions.isNotEmpty) {
          state = state.copyWith(activeSessionId: sessions.first.id);
        }
      } else {
        // Try to migrate old single session
        final oldBox = Hive.box('ai_chats');
        final oldRaw = oldBox.get('expert_chat_$personaSlug');
        if (oldRaw != null && oldRaw is List && oldRaw.isNotEmpty) {
          final msgs = oldRaw
              .map((e) => AiChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          final id = DateTime.now().millisecondsSinceEpoch.toString();
          final session = ExpertChatSession(
            id: id,
            title: 'المحادثة السابقة',
            personaSlug: personaSlug,
            messages: msgs,
            lastActivity: DateTime.now(),
          );
          state = state.copyWith(sessions: [session], activeSessionId: id);
          _saveAllSessions();
        }
      }
    } catch (_) {}
  }

  void _saveAllSessions() {
    try {
      final box = Hive.box(kExpertSessionsBox);
      final data = state.sessions.map((s) => s.toJson()).toList();
      box.put(_hiveKey, data);
    } catch (_) {}
  }

  void startNewSession() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final session = ExpertChatSession(
      id: id,
      title: 'محادثة جديدة',
      personaSlug: personaSlug,
      messages: [],
      lastActivity: DateTime.now(),
    );

    final trimmed = [session, ...state.sessions].take(20).toList(); // keep last 20
    state = state.copyWith(sessions: trimmed, activeSessionId: id);
    _saveAllSessions();
  }

  void switchToSession(String id) {
    if (state.sessions.any((s) => s.id == id)) {
      state = state.copyWith(activeSessionId: id);
    }
  }

  void deleteSession(String id) {
    final updated = state.sessions.where((s) => s.id != id).toList();
    String? nextActive = state.activeSessionId;
    if (nextActive == id) {
      nextActive = updated.isNotEmpty ? updated.first.id : null;
    }
    state = state.copyWith(sessions: updated, activeSessionId: nextActive);
    _saveAllSessions();
  }

  void clearActiveSession() {
    final id = state.activeSessionId;
    if (id == null) return;
    
    final updated = state.sessions.map((s) {
      if (s.id == id) {
        return s.copyWith(messages: [], lastActivity: DateTime.now(), title: 'محادثة جديدة');
      }
      return s;
    }).toList();
    
    state = state.copyWith(sessions: updated);
    _saveAllSessions();
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || state.isLoading) return;

    // Offline guard: if we know there's no connectivity, surface a friendly
    // error in the same SnackBar style the screen already uses, instead of
    // letting the HTTP layer throw a raw SocketException.
    final online = await _ref.read(connectivityServiceProvider).isOnline;
    if (!online) {
      state = state.copyWith(
        error: 'لا يوجد اتصال بالإنترنت. تعذّر إرسال الرسالة.',
      );
      return;
    }

    // Auto-create session if none active
    if (state.activeSessionId == null) {
      startNewSession();
    }

    final userMsg = AiChatMessage(
      role: 'user',
      content: content.trim(),
      timestamp: DateTime.now(),
    );

    final currentMessages = state.activeMessages;
    final updatedMessages = [...currentMessages, userMsg];

    _updateSessionMessages(updatedMessages);
    state = state.copyWith(isLoading: true, clearError: true);

    // Insert an empty assistant placeholder we'll progressively fill from the
    // SSE stream. The UI sees content grow chunk-by-chunk for a "live typing"
    // experience and we never hit the 90s timeout window again.
    final aiTimestamp = DateTime.now();
    AiChatMessage aiMsg = AiChatMessage(
      role: 'assistant',
      content: '',
      timestamp: aiTimestamp,
    );
    _updateSessionMessages([...updatedMessages, aiMsg], isAiReply: true);

    try {
      final modeKey = _activeModeKey;
      final buffer = StringBuffer();
      await for (final chunk in ZadExpertService.sendMessageStream(
        personaId: personaId,
        chatHistory: updatedMessages,
        modeKey: modeKey,
      )) {
        buffer.write(chunk);
        aiMsg = aiMsg.copyWith(content: buffer.toString());
        _updateSessionMessages([...updatedMessages, aiMsg], isAiReply: true);
      }

      // Defensive fallback: if streaming silently produced nothing (network
      // proxy stripping SSE, provider misconfig, …) try the classic
      // non-streaming endpoint once before giving up.
      if (buffer.isEmpty) {
        try {
          final fallback = await ZadExpertService.sendMessage(
            personaId: personaId,
            chatHistory: updatedMessages,
            modeKey: modeKey,
          );
          if (fallback.trim().isNotEmpty) {
            aiMsg = aiMsg.copyWith(content: fallback);
            _updateSessionMessages([...updatedMessages, aiMsg],
                isAiReply: true);
            state = state.copyWith(isLoading: false);
            _saveAllSessions();
            return;
          }
        } catch (_) {/* fall through to error path */}

        _updateSessionMessages(updatedMessages);
        state = state.copyWith(
          isLoading: false,
          error: 'لم يصل أي رد من الخدمة',
        );
        return;
      }

      state = state.copyWith(isLoading: false);
      _saveAllSessions();
    } catch (e) {
      // Drop the (possibly partial) assistant placeholder so we don't keep
      // a half-typed message in history when the stream errored.
      _updateSessionMessages(updatedMessages);
      String msg;
      if (e is SocketException || e is TimeoutException) {
        msg = 'لا يوجد اتصال بالإنترنت. تعذّر إرسال الرسالة.';
      } else {
        msg = e.toString().replaceAll('Exception: ', '');
      }
      state = state.copyWith(
        isLoading: false,
        error: msg,
      );
    }
  }

  void _updateSessionMessages(List<AiChatMessage> messages, {bool isAiReply = false}) {
    final id = state.activeSessionId;
    if (id == null) return;

    final updated = state.sessions.map((s) {
      if (s.id == id) {
        // Generate title from first user message if it's currently a new session
        String title = s.title;
        if (s.messages.isEmpty && title == 'محادثة جديدة') {
          final firstUser = messages.firstWhere((m) => m.isUser).content;
          title = firstUser.length > 30 ? '${firstUser.substring(0, 30)}...' : firstUser;
        }
        return s.copyWith(messages: messages, lastActivity: DateTime.now(), title: title);
      }
      return s;
    }).toList();

    state = state.copyWith(sessions: updated);
  }

  void clearError() => state = state.copyWith(clearError: true);

  void deleteLastMessage() {
    final session = state.activeSession;
    if (session == null || session.messages.isEmpty) return;

    final updatedMessages = List<AiChatMessage>.from(session.messages)..removeLast();
    _updateSessionMessages(updatedMessages);
    _saveAllSessions();
  }

  /// Edit the last user message: remove the last user message and any
  /// assistant reply that came after it, then resend with the new content.
  Future<void> editAndResendLast(String newContent) async {
    if (newContent.trim().isEmpty || state.isLoading) return;
    final session = state.activeSession;
    if (session == null || session.messages.isEmpty) return;

    final msgs = List<AiChatMessage>.from(session.messages);

    // Remove trailing assistant reply (if any), then the user message before it.
    if (msgs.isNotEmpty && msgs.last.role == 'assistant') {
      msgs.removeLast();
    }
    if (msgs.isNotEmpty && msgs.last.role == 'user') {
      msgs.removeLast();
    } else {
      // Nothing to edit (no trailing user message).
      return;
    }

    _updateSessionMessages(msgs);
    _saveAllSessions();

    await sendMessage(newContent);
  }
}

/// Family provider — one chat sessions manger per persona slug.
final expertChatProvider = StateNotifierProvider.family<ExpertSessionsNotifier,
    ExpertSessionsState, AiPersonaModel>(
  (ref, persona) => ExpertSessionsNotifier(
    personaSlug: persona.slug,
    personaId: persona.id,
    ref: ref,
  ),
);
