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
