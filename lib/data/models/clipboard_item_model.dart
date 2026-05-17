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
  final bool syncEnabled;

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
    this.syncEnabled = true,
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
    bool clearGroupId = false,
    bool? syncEnabled,
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
      groupId: clearGroupId ? null : (groupId ?? this.groupId),
      syncEnabled: syncEnabled ?? this.syncEnabled,
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
      'syncEnabled': syncEnabled,
    };
  }

  /// Converts to Supabase-compatible JSON with correct column names.
  /// - 'value' → 'content' (Supabase column name)
  /// - 'type' int → text string (Supabase stores as text)
  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'label': label,
      'content': value,
      'type': type.name,
      'is_pinned': isPinned,
      'sort_order': sortOrder,
      'is_encrypted': isEncrypted,
      'created_at': createdAt.toIso8601String(),
      'auto_delete_at': autoDeleteAt?.toIso8601String(),
      'group_id': groupId,
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
      syncEnabled: json['syncEnabled'] as bool? ?? true,
    );
  }

  /// Creates from Supabase row data (snake_case columns).
  factory ClipboardItemModel.fromSupabaseJson(Map<String, dynamic> json) {
    ClipboardItemType resolvedType = ClipboardItemType.text;
    final rawType = json['type'];
    if (rawType is String) {
      resolvedType = ClipboardItemType.values.firstWhere(
        (e) => e.name == rawType,
        orElse: () => ClipboardItemType.text,
      );
    }
    return ClipboardItemModel(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      value: json['content'] as String? ?? '',
      type: resolvedType,
      isPinned: json['is_pinned'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
      isEncrypted: json['is_encrypted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      autoDeleteAt: json['auto_delete_at'] != null
          ? DateTime.parse(json['auto_delete_at'] as String)
          : null,
      groupId: json['group_id'] as String?,
      syncEnabled: true,
    );
  }
}

class ClipboardGroupModel {
  final String id;
  final String name;
  final String colorHex;
  final String iconStr;
  final int sortOrder;
  final DateTime createdAt;
  final bool syncEnabled;

  const ClipboardGroupModel({
    required this.id,
    required this.name,
    this.colorHex = '#6366F1', // Default to Indigo
    this.iconStr = 'folder', // Default icon
    this.sortOrder = 0,
    required this.createdAt,
    this.syncEnabled = true,
  });

  ClipboardGroupModel copyWith({
    String? id,
    String? name,
    String? colorHex,
    String? iconStr,
    int? sortOrder,
    DateTime? createdAt,
    bool? syncEnabled,
  }) {
    return ClipboardGroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      iconStr: iconStr ?? this.iconStr,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      syncEnabled: syncEnabled ?? this.syncEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorHex': colorHex,
      'iconStr': iconStr,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
      'syncEnabled': syncEnabled,
    };
  }

  factory ClipboardGroupModel.fromJson(Map<String, dynamic> json) {
    return ClipboardGroupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      colorHex: json['colorHex'] as String? ?? '#6366F1',
      iconStr: json['iconStr'] as String? ?? 'folder',
      sortOrder: json['sortOrder'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      syncEnabled: json['syncEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'name': name,
      'color_hex': colorHex,
      'icon_str': iconStr,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ClipboardGroupModel.fromSupabaseJson(Map<String, dynamic> json) {
    return ClipboardGroupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      colorHex: json['color_hex'] as String? ?? '#6366F1',
      iconStr: json['icon_str'] as String? ?? 'folder',
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      syncEnabled: true,
    );
  }
}
