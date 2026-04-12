/// Model for AI-generated content preparation result
class AiContentResult {
  final String title;
  final String description;
  final String categoryName;
  final String subcategory;
  final String contentType;
  final List<String> tags;
  final String sourceUrl;

  const AiContentResult({
    required this.title,
    required this.description,
    required this.categoryName,
    required this.subcategory,
    required this.contentType,
    required this.tags,
    this.sourceUrl = '',
  });

  factory AiContentResult.fromJson(Map<String, dynamic> json) {
    return AiContentResult(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      categoryName: json['category_name'] as String? ?? '',
      subcategory: json['subcategory'] as String? ?? '',
      contentType: json['content_type'] as String? ?? 'website',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      sourceUrl: json['source_url'] as String? ?? '',
    );
  }

  AiContentResult copyWith({
    String? title,
    String? description,
    String? categoryName,
    String? subcategory,
    String? contentType,
    List<String>? tags,
    String? sourceUrl,
  }) {
    return AiContentResult(
      title: title ?? this.title,
      description: description ?? this.description,
      categoryName: categoryName ?? this.categoryName,
      subcategory: subcategory ?? this.subcategory,
      contentType: contentType ?? this.contentType,
      tags: tags ?? this.tags,
      sourceUrl: sourceUrl ?? this.sourceUrl,
    );
  }
}
