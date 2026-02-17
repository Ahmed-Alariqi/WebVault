/// Model for admin-published tools shown in Discover
class ToolModel {
  final String id;
  final String title;
  final String url;
  final String description;
  final String? imageUrl;
  final String category;
  final List<String> tags;
  final bool isFeatured;
  final String? createdBy;
  final DateTime createdAt;

  const ToolModel({
    required this.id,
    required this.title,
    required this.url,
    this.description = '',
    this.imageUrl,
    this.category = '',
    this.tags = const [],
    this.isFeatured = false,
    this.createdBy,
    required this.createdAt,
  });

  factory ToolModel.fromJson(Map<String, dynamic> json) {
    return ToolModel(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      category: json['category'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      isFeatured: json['is_featured'] as bool? ?? false,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'description': description,
      'image_url': imageUrl,
      'category': category,
      'tags': tags,
      'is_featured': isFeatured,
    };
  }
}
