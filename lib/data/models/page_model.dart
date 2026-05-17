class PageModel {
  final String id;
  final String url;
  final String title;
  final String notes;
  final List<String> tags;
  final String? folderId;
  final bool isFavorite;
  final int visitCount;
  final DateTime? lastOpened;
  final DateTime createdAt;
  final double scrollPosition;
  final bool syncEnabled;

  const PageModel({
    required this.id,
    required this.url,
    required this.title,
    this.notes = '',
    this.tags = const [],
    this.folderId,
    this.isFavorite = false,
    this.visitCount = 0,
    this.lastOpened,
    required this.createdAt,
    this.scrollPosition = 0.0,
    this.syncEnabled = true,
  });

  PageModel copyWith({
    String? id,
    String? url,
    String? title,
    String? notes,
    List<String>? tags,
    String? folderId,
    bool? isFavorite,
    int? visitCount,
    DateTime? lastOpened,
    DateTime? createdAt,
    double? scrollPosition,
    bool? syncEnabled,
  }) {
    return PageModel(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      folderId: folderId ?? this.folderId,
      isFavorite: isFavorite ?? this.isFavorite,
      visitCount: visitCount ?? this.visitCount,
      lastOpened: lastOpened ?? this.lastOpened,
      createdAt: createdAt ?? this.createdAt,
      scrollPosition: scrollPosition ?? this.scrollPosition,
      syncEnabled: syncEnabled ?? this.syncEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'notes': notes,
      'tags': tags,
      'folderId': folderId,
      'isFavorite': isFavorite,
      'visitCount': visitCount,
      'lastOpened': lastOpened?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'scrollPosition': scrollPosition,
      'syncEnabled': syncEnabled,
    };
  }

  factory PageModel.fromJson(Map<String, dynamic> json) {
    return PageModel(
      id: json['id'] as String,
      url: json['url'] as String,
      title: json['title'] as String,
      notes: json['notes'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      folderId: json['folderId'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      visitCount: json['visitCount'] as int? ?? 0,
      lastOpened: json['lastOpened'] != null
          ? DateTime.parse(json['lastOpened'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      scrollPosition: (json['scrollPosition'] as num?)?.toDouble() ?? 0.0,
      syncEnabled: json['syncEnabled'] as bool? ?? true,
    );
  }

  factory PageModel.fromSupabaseJson(Map<String, dynamic> json) {
    return PageModel(
      id: json['id'] as String,
      url: json['url'] as String,
      title: json['title'] as String,
      notes: json['notes'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      folderId: json['folder_id'] as String?,
      isFavorite: json['is_favorite'] as bool? ?? false,
      visitCount: json['visit_count'] as int? ?? 0,
      lastOpened: json['last_opened'] != null
          ? DateTime.parse(json['last_opened'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      scrollPosition: (json['scroll_position'] as num?)?.toDouble() ?? 0.0,
      syncEnabled: true,
    );
  }
}
