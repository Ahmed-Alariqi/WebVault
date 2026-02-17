/// Model for content categories
class CategoryModel {
  final String id;
  final String name;
  final int iconCodePoint;
  final int colorValue;
  final int sortOrder;

  const CategoryModel({
    required this.id,
    required this.name,
    this.iconCodePoint = 983044,
    this.colorValue = 4282339765,
    this.sortOrder = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      iconCodePoint: json['icon_code_point'] as int? ?? 983044,
      colorValue: json['color_value'] as int? ?? 4282339765,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon_code_point': iconCodePoint,
      'color_value': colorValue,
      'sort_order': sortOrder,
    };
  }
}
