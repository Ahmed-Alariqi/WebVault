/// Model for admin push notifications
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? imageUrl;
  final String? targetUrl;
  final String? createdBy;
  final DateTime createdAt;
  final bool isRead;
  final bool personalizeWithName;
  final int sentCount;
  final int failedCount;
  final int totalTargeted;
  final String? userId;

  const NotificationModel({
    required this.id,
    required this.title,
    this.body = '',
    this.type = 'general',
    this.imageUrl,
    this.targetUrl,
    this.createdBy,
    required this.createdAt,
    this.isRead = false,
    this.personalizeWithName = false,
    this.sentCount = 0,
    this.failedCount = 0,
    this.totalTargeted = 0,
    this.userId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      imageUrl: json['image_url'] as String?,
      targetUrl: json['target_url'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      personalizeWithName: json['personalize_name'] == true,
      sentCount: json['sent_count'] as int? ?? 0,
      failedCount: json['failed_count'] as int? ?? 0,
      totalTargeted: json['total_targeted'] as int? ?? 0,
      userId: json['user_id'] as String?,
    );
  }

  /// Returns a copy with {user_name} replaced in title and body
  NotificationModel withPersonalizedName(String userName) {
    if (!personalizeWithName) return this;
    return NotificationModel(
      id: id,
      title: title.replaceAll('{user_name}', userName),
      body: body.replaceAll('{user_name}', userName),
      type: type,
      imageUrl: imageUrl,
      targetUrl: targetUrl,
      createdBy: createdBy,
      createdAt: createdAt,
      isRead: isRead,
      personalizeWithName: personalizeWithName,
      sentCount: sentCount,
      failedCount: failedCount,
      totalTargeted: totalTargeted,
      userId: userId,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    String? imageUrl,
    String? targetUrl,
    String? createdBy,
    DateTime? createdAt,
    bool? isRead,
    bool? personalizeWithName,
    int? sentCount,
    int? failedCount,
    int? totalTargeted,
    String? userId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      targetUrl: targetUrl ?? this.targetUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      personalizeWithName: personalizeWithName ?? this.personalizeWithName,
      sentCount: sentCount ?? this.sentCount,
      failedCount: failedCount ?? this.failedCount,
      totalTargeted: totalTargeted ?? this.totalTargeted,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'image_url': imageUrl,
      'target_url': targetUrl,
      'sent_count': sentCount,
      'failed_count': failedCount,
      'total_targeted': totalTargeted,
      'user_id': userId,
    };
  }
}
