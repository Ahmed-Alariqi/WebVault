enum ClipboardItemType { text, number, code, email, otp }

class ClipboardItemModel {
  final String id;
  final String label;
  final String value;
  final ClipboardItemType type;
  final bool isPinned;
  final int sortOrder;
  final bool isEncrypted;
  final DateTime createdAt;
  final DateTime? autoDeleteAt;
  final String? groupId;

  const ClipboardItemModel({
    required this.id,
    required this.label,
    required this.value,
    this.type = ClipboardItemType.text,
    this.isPinned = false,
    this.sortOrder = 0,
    this.isEncrypted = false,
    required this.createdAt,
    this.autoDeleteAt,
    this.groupId,
  });

  ClipboardItemModel copyWith({
    String? id,
    String? label,
    String? value,
    ClipboardItemType? type,
    bool? isPinned,
    int? sortOrder,
    bool? isEncrypted,
    DateTime? createdAt,
    DateTime? autoDeleteAt,
    String? groupId,
  }) {
    return ClipboardItemModel(
      id: id ?? this.id,
      label: label ?? this.label,
      value: value ?? this.value,
      type: type ?? this.type,
      isPinned: isPinned ?? this.isPinned,
      sortOrder: sortOrder ?? this.sortOrder,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      createdAt: createdAt ?? this.createdAt,
      autoDeleteAt: autoDeleteAt ?? this.autoDeleteAt,
      groupId: groupId ?? this.groupId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'value': value,
      'type': type.index,
      'isPinned': isPinned,
      'sortOrder': sortOrder,
      'isEncrypted': isEncrypted,
      'createdAt': createdAt.toIso8601String(),
      'autoDeleteAt': autoDeleteAt?.toIso8601String(),
      'groupId': groupId,
    };
  }

  factory ClipboardItemModel.fromJson(Map<String, dynamic> json) {
    return ClipboardItemModel(
      id: json['id'] as String,
      label: json['label'] as String,
      value: json['value'] as String,
      type: ClipboardItemType.values[json['type'] as int? ?? 0],
      isPinned: json['isPinned'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
      isEncrypted: json['isEncrypted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      autoDeleteAt: json['autoDeleteAt'] != null
          ? DateTime.parse(json['autoDeleteAt'] as String)
          : null,
      groupId: json['groupId'] as String?,
    );
  }
}

class ClipboardGroupModel {
  final String id;
  final String name;
  final String colorHex;
  final int sortOrder;
  final DateTime createdAt;

  const ClipboardGroupModel({
    required this.id,
    required this.name,
    this.colorHex = '#6366F1', // Default to Indigo
    this.sortOrder = 0,
    required this.createdAt,
  });

  ClipboardGroupModel copyWith({
    String? id,
    String? name,
    String? colorHex,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return ClipboardGroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorHex': colorHex,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ClipboardGroupModel.fromJson(Map<String, dynamic> json) {
    return ClipboardGroupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      colorHex: json['colorHex'] as String? ?? '#6366F1',
      sortOrder: json['sortOrder'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
