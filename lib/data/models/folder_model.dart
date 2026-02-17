class FolderModel {
  final String id;
  final String name;
  final int iconCodePoint;
  final int colorValue;
  final DateTime createdAt;

  const FolderModel({
    required this.id,
    required this.name,
    this.iconCodePoint = 0xe2c7, // Icons.folder
    this.colorValue = 0xFF3F51B5, // Indigo
    required this.createdAt,
  });

  FolderModel copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    int? colorValue,
    DateTime? createdAt,
  }) {
    return FolderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: json['id'] as String,
      name: json['name'] as String,
      iconCodePoint: json['iconCodePoint'] as int? ?? 0xe2c7,
      colorValue: json['colorValue'] as int? ?? 0xFF3F51B5,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
