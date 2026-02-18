class SuggestionModel {
  final String id;
  final String userId;
  final String pageTitle;
  final String pageUrl;
  final String? pageDescription;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SuggestionModel({
    required this.id,
    required this.userId,
    required this.pageTitle,
    required this.pageUrl,
    this.pageDescription,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SuggestionModel.fromJson(Map<String, dynamic> json) {
    return SuggestionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      pageTitle: json['page_title'] as String,
      pageUrl: json['page_url'] as String,
      pageDescription: json['page_description'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'page_title': pageTitle,
      'page_url': pageUrl,
      'page_description': pageDescription,
      'status': status,
    };
  }
}
