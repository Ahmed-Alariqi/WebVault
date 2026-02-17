/// Model for admin push notifications
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? targetUrl;
  final String? createdBy;
  final DateTime createdAt;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    this.body = '',
    this.type = 'general',
    this.targetUrl,
    this.createdBy,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      targetUrl: json['target_url'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'target_url': targetUrl,
    };
  }
}
