/// Model for admin-published websites shown in Discover
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
  });

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
    );
  }

  factory WebsiteModel.fromJson(Map<String, dynamic> json) {
    return WebsiteModel(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
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
    };
  }
}
