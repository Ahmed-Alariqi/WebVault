class CommunityPost {
  final String id;
  final String userId;
  final String content;
  final String? imageUrl;
  final String? linkUrl;
  final String? linkTitle;
  final String category;
  final bool isPinned;
  final bool isArchived;
  final Map<String, dynamic> reactions;
  final int repliesCount;
  final DateTime createdAt;
  final String? authorName;

  const CommunityPost({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrl,
    this.linkUrl,
    this.linkTitle,
    this.category = 'general',
    this.isPinned = false,
    this.isArchived = false,
    this.reactions = const {},
    this.repliesCount = 0,
    required this.createdAt,
    this.authorName,
  });

  CommunityPost copyWith({
    String? id,
    String? userId,
    String? content,
    String? imageUrl,
    String? linkUrl,
    String? linkTitle,
    String? category,
    bool? isPinned,
    bool? isArchived,
    Map<String, dynamic>? reactions,
    int? repliesCount,
    DateTime? createdAt,
    String? authorName,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      linkUrl: linkUrl ?? this.linkUrl,
      linkTitle: linkTitle ?? this.linkTitle,
      category: category ?? this.category,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      reactions: reactions ?? this.reactions,
      repliesCount: repliesCount ?? this.repliesCount,
      createdAt: createdAt ?? this.createdAt,
      authorName: authorName ?? this.authorName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'image_url': imageUrl,
      'link_url': linkUrl,
      'link_title': linkTitle,
      'category': category,
      'is_pinned': isPinned,
      'is_archived': isArchived,
      'reactions': reactions,
      'replies_count': repliesCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      linkUrl: json['link_url'] as String?,
      linkTitle: json['link_title'] as String?,
      category: json['category'] as String? ?? 'general',
      isPinned: json['is_pinned'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      reactions: (json['reactions'] as Map<String, dynamic>?) ?? {},
      repliesCount: json['replies_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorName: json['authorName'] as String?,
    );
  }
}

class CommunityReply {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String? authorName;

  const CommunityReply({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.authorName,
  });

  CommunityReply copyWith({
    String? id,
    String? postId,
    String? userId,
    String? content,
    DateTime? createdAt,
    String? authorName,
  }) {
    return CommunityReply(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      authorName: authorName ?? this.authorName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CommunityReply.fromJson(Map<String, dynamic> json) {
    return CommunityReply(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorName: json['authorName'] as String?,
    );
  }
}
