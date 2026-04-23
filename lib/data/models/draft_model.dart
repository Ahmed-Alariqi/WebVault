/// Model for admin content drafts — idea → in_progress → ready → published
class DraftModel {
  final String id;
  final String? title;
  final String? url;
  final String? notes;
  final String? description;
  final String? imageUrl;
  final List<String> tags;
  final String? categoryId;
  final String contentType;
  final String actionValue;
  final String pricingModel;
  final String status; // 'idea' | 'in_progress' | 'ready'
  final String priority; // 'low' | 'normal' | 'high' | 'urgent'
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? publishedWebsiteId;

  const DraftModel({
    required this.id,
    this.title,
    this.url,
    this.notes,
    this.description,
    this.imageUrl,
    this.tags = const [],
    this.categoryId,
    this.contentType = 'website',
    this.actionValue = '',
    this.pricingModel = 'free',
    this.status = 'idea',
    this.priority = 'normal',
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.publishedWebsiteId,
  });

  /// Whether this draft has been published
  bool get isPublished => publishedWebsiteId != null;

  /// Completion percentage (0.0 – 1.0) based on filled fields
  double get completionPercentage {
    int filled = 0;
    const totalFields = 6;

    if (title != null && title!.trim().isNotEmpty) filled++;
    if (url != null && url!.trim().isNotEmpty) filled++;
    if (description != null && description!.trim().isNotEmpty) filled++;
    if (categoryId != null && categoryId!.trim().isNotEmpty) filled++;
    if (tags.isNotEmpty) filled++;
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) filled++;

    return filled / totalFields;
  }

  /// Whether the draft has minimum required fields to publish
  bool get isReadyToPublish =>
      title != null &&
      title!.trim().isNotEmpty &&
      url != null &&
      url!.trim().isNotEmpty;

  /// Display-friendly title (falls back to notes or URL)
  String get displayTitle {
    if (title != null && title!.trim().isNotEmpty) return title!;
    if (notes != null && notes!.trim().isNotEmpty) {
      return notes!.length > 60 ? '${notes!.substring(0, 60)}…' : notes!;
    }
    if (url != null && url!.trim().isNotEmpty) return url!;
    return 'مسودة بدون عنوان';
  }

  factory DraftModel.fromJson(Map<String, dynamic> json) {
    return DraftModel(
      id: json['id'] as String,
      title: json['title'] as String?,
      url: json['url'] as String?,
      notes: json['notes'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      categoryId: json['category_id'] as String?,
      contentType: json['content_type'] as String? ?? 'website',
      actionValue: json['action_value'] as String? ?? '',
      pricingModel: json['pricing_model'] as String? ?? 'free',
      status: json['status'] as String? ?? 'idea',
      priority: json['priority'] as String? ?? 'normal',
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      publishedWebsiteId: json['published_website_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'notes': notes,
      'description': description,
      'image_url': imageUrl,
      'tags': tags,
      'category_id': categoryId,
      'content_type': contentType,
      'action_value': actionValue,
      'pricing_model': pricingModel,
      'status': status,
      'priority': priority,
    };
  }

  DraftModel copyWith({
    String? title,
    String? url,
    String? notes,
    String? description,
    String? imageUrl,
    List<String>? tags,
    String? categoryId,
    String? contentType,
    String? actionValue,
    String? pricingModel,
    String? status,
    String? priority,
    String? publishedWebsiteId,
  }) {
    return DraftModel(
      id: id,
      title: title ?? this.title,
      url: url ?? this.url,
      notes: notes ?? this.notes,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      categoryId: categoryId ?? this.categoryId,
      contentType: contentType ?? this.contentType,
      actionValue: actionValue ?? this.actionValue,
      pricingModel: pricingModel ?? this.pricingModel,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      publishedWebsiteId: publishedWebsiteId ?? this.publishedWebsiteId,
    );
  }
}
