/// Model for admin-published items shown in Discover
class WebsiteModel {
  final String id;
  final String title;
  final String url;
  final String description;
  final String? imageUrl;
  final List<String> tags;
  final String? categoryId;
  final bool isTrending;
  final bool isPopular;
  final bool isFeatured;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ── New fields ──
  final String contentType; // 'website' | 'prompt' | 'offer' | 'announcement'
  final String actionValue; // Copyable text (prompt, code, key…)
  final DateTime? expiresAt; // Auto-hide after this time
  final bool isActive; // Manual on/off toggle
  final String? videoUrl; // Optional tutorial/explainer video
  final String pricingModel; // 'free', 'freemium', 'paid'

  const WebsiteModel({
    required this.id,
    required this.title,
    required this.url,
    this.description = '',
    this.imageUrl,
    this.tags = const [],
    this.categoryId,
    this.isTrending = false,
    this.isPopular = false,
    this.isFeatured = false,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.contentType = 'website',
    this.actionValue = '',
    this.expiresAt,
    this.isActive = true,
    this.videoUrl,
    this.pricingModel = 'free',
  });

  /// Whether this item has expired
  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  /// Whether this item has a copyable value
  bool get hasCopyableValue => actionValue.trim().isNotEmpty;

  /// Whether this item has a visitable URL
  bool get hasUrl => url.trim().isNotEmpty;

  /// Whether this item has a video
  bool get hasVideo => videoUrl != null && videoUrl!.trim().isNotEmpty;

  WebsiteModel copyWith({
    String? title,
    String? url,
    String? description,
    String? imageUrl,
    List<String>? tags,
    String? categoryId,
    bool? isTrending,
    bool? isPopular,
    bool? isFeatured,
    String? contentType,
    String? actionValue,
    DateTime? expiresAt,
    bool? isActive,
    String? videoUrl,
    String? pricingModel,
  }) {
    return WebsiteModel(
      id: id,
      title: title ?? this.title,
      url: url ?? this.url,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      categoryId: categoryId ?? this.categoryId,
      isTrending: isTrending ?? this.isTrending,
      isPopular: isPopular ?? this.isPopular,
      isFeatured: isFeatured ?? this.isFeatured,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      contentType: contentType ?? this.contentType,
      actionValue: actionValue ?? this.actionValue,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      videoUrl: videoUrl ?? this.videoUrl,
      pricingModel: pricingModel ?? this.pricingModel,
    );
  }

  factory WebsiteModel.fromJson(Map<String, dynamic> json) {
    return WebsiteModel(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      categoryId: json['category_id'] as String?,
      isTrending: json['is_trending'] as bool? ?? false,
      isPopular: json['is_popular'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      contentType: json['content_type'] as String? ?? 'website',
      actionValue: json['action_value'] as String? ?? '',
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      videoUrl: json['video_url'] as String?,
      pricingModel: json['pricing_model'] as String? ?? 'free',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'description': description,
      'image_url': imageUrl,
      'tags': tags,
      'category_id': categoryId,
      'is_trending': isTrending,
      'is_popular': isPopular,
      'is_featured': isFeatured,
      'content_type': contentType,
      'action_value': actionValue,
      'expires_at': expiresAt?.toIso8601String(),
      'is_active': isActive,
      'video_url': videoUrl,
      'pricing_model': pricingModel,
    };
  }
}
