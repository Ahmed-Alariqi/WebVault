/// Model for AI chat messages
class AiChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime timestamp;
  final bool isLoading;

  const AiChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.isLoading = false,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  Map<String, String> toApiMessage() => {'role': role, 'content': content};

  AiChatMessage copyWith({String? content, bool? isLoading}) {
    return AiChatMessage(
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  factory AiChatMessage.fromJson(Map<dynamic, dynamic> json) {
    return AiChatMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isLoading: json['isLoading'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isLoading': isLoading,
    };
  }
}

/// Model for a standalone chat session in the Quick Tile AI Assistant
class QuickChatSession {
  final String id;
  final String title;
  final String contextHash; // MD5-like short hash of the context text
  final List<AiChatMessage> messages;
  final DateTime lastActivity;

  const QuickChatSession({
    required this.id,
    required this.title,
    required this.contextHash,
    required this.messages,
    required this.lastActivity,
  });

  /// Auto-generate a short human-readable title from the context
  static String generateTitle(String context) {
    final clean = context.trim();
    if (clean.startsWith('http')) {
      try {
        final uri = Uri.parse(clean);
        return uri.host.replaceAll('www.', '');
      } catch (_) {
        return clean.substring(0, clean.length.clamp(0, 40));
      }
    }
    return clean.length > 45 ? '${clean.substring(0, 42)}...' : clean;
  }

  QuickChatSession copyWith({
    List<AiChatMessage>? messages,
    DateTime? lastActivity,
  }) {
    return QuickChatSession(
      id: id,
      title: title,
      contextHash: contextHash,
      messages: messages ?? this.messages,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }

  factory QuickChatSession.fromJson(Map<dynamic, dynamic> json) {
    return QuickChatSession(
      id: json['id'] as String,
      title: json['title'] as String,
      contextHash: json['contextHash'] as String,
      messages: (json['messages'] as List)
          .map((e) => AiChatMessage.fromJson(Map<dynamic, dynamic>.from(e as Map)))
          .toList(),
      lastActivity: DateTime.parse(json['lastActivity'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'contextHash': contextHash,
      'messages': messages.map((m) => m.toJson()).toList(),
      'lastActivity': lastActivity.toIso8601String(),
    };
  }
}

/// Model for a chat session with an Expert Persona
class ExpertChatSession {
  final String id;
  final String title;
  final String personaSlug;
  final List<AiChatMessage> messages;
  final DateTime lastActivity;

  const ExpertChatSession({
    required this.id,
    required this.title,
    required this.personaSlug,
    required this.messages,
    required this.lastActivity,
  });

  ExpertChatSession copyWith({
    String? title,
    List<AiChatMessage>? messages,
    DateTime? lastActivity,
  }) {
    return ExpertChatSession(
      id: id,
      title: title ?? this.title,
      personaSlug: personaSlug,
      messages: messages ?? this.messages,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }

  factory ExpertChatSession.fromJson(Map<dynamic, dynamic> json) {
    return ExpertChatSession(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'محادثة',
      personaSlug: json['personaSlug'] as String,
      messages: (json['messages'] as List?)
              ?.map((e) => AiChatMessage.fromJson(Map<dynamic, dynamic>.from(e as Map)))
              .toList() ??
          [],
      lastActivity: DateTime.parse(json['lastActivity'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'personaSlug': personaSlug,
      'messages': messages.map((m) => m.toJson()).toList(),
      'lastActivity': lastActivity.toIso8601String(),
    };
  }
}
