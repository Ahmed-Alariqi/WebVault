/// Sub-persona mode (e.g. ERD, Flowchart, UML) attached to an [AiPersonaModel].
///
/// Stored as a JSONB array on `ai_personas.modes`. Each mode layers a
/// specialised system prompt + workflow on top of the persona's general
/// "Socratic expert" identity.
class AiPersonaMode {
  /// Stable machine key (e.g. `erd`, `flowchart`). Used to identify the mode
  /// when sent to the edge function and when logging usage.
  final String key;

  /// Human-readable Arabic name shown in the UI cards.
  final String name;

  /// Phosphor icon name (same convention as [AiPersonaModel.icon]).
  final String icon;

  /// Hex color (`#RRGGBB`).
  final String color;

  /// Short description shown under the card title.
  final String description;

  /// Specialised system prompt — appended **after** the persona's general
  /// instruction as a second `system` message. Should focus on methodology,
  /// output template and domain rules; identity/Socratic behaviour stays in
  /// the persona itself.
  final String systemPrompt;

  /// Optional output template guiding the model's final answer shape.
  final String outputTemplate;

  /// Per-mode quick suggestions shown after the user picks the mode.
  final List<Map<String, String>> quickActions;

  /// True for **exactly one** mode per persona (enforced by DB trigger).
  final bool isDefault;

  /// Allows hiding a mode without deleting it.
  final bool enabled;

  /// Display order in the cards list.
  final int sortOrder;

  const AiPersonaMode({
    required this.key,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
    required this.systemPrompt,
    this.outputTemplate = '',
    this.quickActions = const [],
    this.isDefault = false,
    this.enabled = true,
    this.sortOrder = 0,
  });

  factory AiPersonaMode.fromJson(Map<String, dynamic> json) {
    List<Map<String, String>> actions = const [];
    if (json['quick_actions'] is List) {
      actions = (json['quick_actions'] as List)
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')))
          .toList();
    }
    return AiPersonaMode(
      key: json['key'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? 'sparkle',
      color: json['color'] as String? ?? '#6366F1',
      description: json['description'] as String? ?? '',
      systemPrompt: json['system_prompt'] as String? ?? '',
      outputTemplate: json['output_template'] as String? ?? '',
      quickActions: actions,
      isDefault: json['is_default'] as bool? ?? false,
      enabled: json['enabled'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'name': name,
        'icon': icon,
        'color': color,
        'description': description,
        'system_prompt': systemPrompt,
        'output_template': outputTemplate,
        'quick_actions': quickActions,
        'is_default': isDefault,
        'enabled': enabled,
        'sort_order': sortOrder,
      };

  AiPersonaMode copyWith({
    String? key,
    String? name,
    String? icon,
    String? color,
    String? description,
    String? systemPrompt,
    String? outputTemplate,
    List<Map<String, String>>? quickActions,
    bool? isDefault,
    bool? enabled,
    int? sortOrder,
  }) {
    return AiPersonaMode(
      key: key ?? this.key,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      description: description ?? this.description,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      outputTemplate: outputTemplate ?? this.outputTemplate,
      quickActions: quickActions ?? this.quickActions,
      isDefault: isDefault ?? this.isDefault,
      enabled: enabled ?? this.enabled,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
