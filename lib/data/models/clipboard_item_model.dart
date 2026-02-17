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
    );
  }
}
