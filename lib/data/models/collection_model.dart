import 'website_model.dart';

/// A curated collection of items (e.g., "Best AI Courses 2026").
class CollectionModel {
  final String id;
  final String title;
  final String description;
  final String? coverImageUrl;
  final int colorValue;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Items inside this collection (populated via join query).
  final List<WebsiteModel> items;

  /// Number of items (can be from count query or items.length).
  final int itemCount;

  const CollectionModel({
    required this.id,
    required this.title,
    this.description = '',
    this.coverImageUrl,
    this.colorValue = 4282339765,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
    this.itemCount = 0,
  });

  factory CollectionModel.fromJson(Map<String, dynamic> json) {
    // Parse embedded items from a join query if present
    List<WebsiteModel> parsedItems = [];
    int count = 0;

    if (json['collection_items'] != null) {
      final rawItems = json['collection_items'] as List;
      count = rawItems.length;
      parsedItems = rawItems
          .where((ci) => ci['websites'] != null)
          .map((ci) => WebsiteModel.fromJson(ci['websites']))
          .toList();
    }

    return CollectionModel(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      coverImageUrl: json['cover_image_url'],
      colorValue: (json['color_value'] ?? 0x3F51B5) | 0xFF000000,
      sortOrder: json['sort_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      items: parsedItems,
      itemCount: json['item_count'] ?? count,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'cover_image_url': coverImageUrl,
    'color_value': colorValue & 0xFFFFFF,
    'sort_order': sortOrder,
    'is_active': isActive,
  };

  CollectionModel copyWith({
    String? title,
    String? description,
    String? coverImageUrl,
    int? colorValue,
    int? sortOrder,
    bool? isActive,
    List<WebsiteModel>? items,
    int? itemCount,
  }) {
    return CollectionModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      colorValue: colorValue ?? this.colorValue,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      items: items ?? this.items,
      itemCount: itemCount ?? this.itemCount,
    );
  }
}
