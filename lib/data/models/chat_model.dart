class ConversationModel {
  final String id;
  final String userId;
  final String? lastMessage;
  final DateTime lastMessageAt;
  final int unreadAdminCount;
  final int unreadUserCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? userProfile; // Joined profile data

  ConversationModel({
    required this.id,
    required this.userId,
    this.lastMessage,
    required this.lastMessageAt,
    this.unreadAdminCount = 0,
    this.unreadUserCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.userProfile,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: DateTime.parse(
        json['last_message_at'] as String,
      ).toLocal(),
      unreadAdminCount: json['unread_admin_count'] as int? ?? 0,
      unreadUserCount: json['unread_user_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
      userProfile: json['profiles'] as Map<String, dynamic>?,
    );
  }
}

class MessageModel {
  final String id;
  final String conversationId;
  final String? senderId;
  final bool isAdmin;
  final String content;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    this.senderId,
    required this.isAdmin,
    required this.content,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String?,
      isAdmin: json['is_admin'] as bool? ?? false,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}
