import 'ai_persona_mode.dart';

/// Model for an AI Persona (Zad Expert personality)
class AiPersonaModel {
  final String id;
  final String name;
  final String slug;
  final String description;
  final String icon;
  final String color;
  final String systemInstruction;
  final String providerId;
  final String modelId;
  final double temperature;
  final int maxTokens;
  final bool isActive;
  final int sortOrder;
  final List<Map<String, String>> quickActions;
  final List<AiPersonaMode> modes;

  const AiPersonaModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.icon,
    required this.color,
    required this.systemInstruction,
    required this.providerId,
    required this.modelId,
    required this.temperature,
    required this.maxTokens,
    required this.isActive,
    required this.sortOrder,
    required this.quickActions,
    this.modes = const [],
  });

  /// True when this persona exposes specialised modes (cards UX).
  bool get hasModes => modes.where((m) => m.enabled).isNotEmpty;

  /// Visible modes ordered by [AiPersonaMode.sortOrder].
  List<AiPersonaMode> get visibleModes {
    final list = modes.where((m) => m.enabled).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  /// The single default mode if any, otherwise null.
  AiPersonaMode? get defaultMode {
    for (final m in visibleModes) {
      if (m.isDefault) return m;
    }
    return null;
  }

  /// Look up a mode by its stable [key].
  AiPersonaMode? modeByKey(String? key) {
    if (key == null || key.isEmpty) return null;
    for (final m in modes) {
      if (m.key == key) return m;
    }
    return null;
  }

  factory AiPersonaModel.fromJson(Map<String, dynamic> json) {
    // Parse quick_actions from JSON
    List<Map<String, String>> actions = [];
    if (json['quick_actions'] is List) {
      actions = (json['quick_actions'] as List)
          .map((e) => Map<String, String>.from(e as Map))
          .toList();
    }

    // Parse modes from JSONB array
    List<AiPersonaMode> modes = const [];
    if (json['modes'] is List) {
      modes = (json['modes'] as List)
          .whereType<Map>()
          .map((e) => AiPersonaMode.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return AiPersonaModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? 'robot',
      color: json['color'] as String? ?? '#6366F1',
      systemInstruction: json['system_instruction'] as String? ?? '',
      providerId: json['provider_id'] as String,
      modelId: json['model_id'] as String? ?? '',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.5,
      maxTokens: json['max_tokens'] as int? ?? 4096,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      quickActions: actions,
      modes: modes,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'slug': slug,
        'description': description,
        'icon': icon,
        'color': color,
        'system_instruction': systemInstruction,
        'provider_id': providerId,
        'model_id': modelId,
        'temperature': temperature,
        'max_tokens': maxTokens,
        'is_active': isActive,
        'sort_order': sortOrder,
        'quick_actions': quickActions,
        'modes': modes.map((m) => m.toJson()).toList(),
      };

  // Identity is keyed off the stable [id] so that Riverpod family providers
  // (e.g. `expertChatProvider`) keep returning the *same* notifier instance
  // even when the persona list is refetched and a new model object is built.
  // Without this, every refresh would spawn a fresh chat notifier and the
  // user would appear to lose their previous sessions until reload.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiPersonaModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Identifies which app-level AI consumer a provider serves.
///
/// * [zadExpert]: the persona-based Zad Expert chat (each persona picks
///   its own model, so [AiProviderModel.selectedModel] is ignored).
/// * [aiAssistant]: the general "understand more" assistant used across
///   the app (discover cards, embedded browser, Quick Tile, Zad Hub).
///   Uses [AiProviderModel.selectedModel] to decide which model to call.
enum AiProviderPurpose {
  zadExpert('zad-expert'),
  aiAssistant('ai-assistant');

  final String slug;
  const AiProviderPurpose(this.slug);

  static AiProviderPurpose fromSlug(String? slug) {
    for (final p in values) {
      if (p.slug == slug) return p;
    }
    return AiProviderPurpose.zadExpert;
  }

  /// Admin-facing Arabic label for the segmented control.
  String get arabicLabel {
    switch (this) {
      case AiProviderPurpose.zadExpert:
        return 'خبير زاد';
      case AiProviderPurpose.aiAssistant:
        return 'المساعد الذكي العام';
    }
  }
}

/// Model for an AI Provider (Groq, OpenRouter, Ollama, etc.)
class AiProviderModel {
  final String id;
  final String name;
  final String slug;
  final String baseUrl;
  final String apiKey;
  final bool isActive;
  final List<String> supportedModels;
  final AiProviderPurpose purpose;
  // Only meaningful when [purpose] == ai-assistant. When null/empty, the
  // first entry of [supportedModels] is used. Zad Expert personas ignore
  // this and provide their own model per-persona.
  final String? selectedModel;

  const AiProviderModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.baseUrl,
    required this.apiKey,
    required this.isActive,
    required this.supportedModels,
    this.purpose = AiProviderPurpose.zadExpert,
    this.selectedModel,
  });

  factory AiProviderModel.fromJson(Map<String, dynamic> json) {
    return AiProviderModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      baseUrl: json['base_url'] as String? ?? '',
      apiKey: json['api_key'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      supportedModels: (json['supported_models'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      purpose: AiProviderPurpose.fromSlug(json['purpose'] as String?),
      selectedModel: (json['selected_model'] as String?)?.trim().isNotEmpty == true
          ? (json['selected_model'] as String).trim()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'slug': slug,
        'base_url': baseUrl,
        'api_key': apiKey,
        'is_active': isActive,
        'supported_models': supportedModels,
        'purpose': purpose.slug,
        'selected_model': selectedModel,
      };

  AiProviderModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? baseUrl,
    String? apiKey,
    bool? isActive,
    List<String>? supportedModels,
    AiProviderPurpose? purpose,
    String? selectedModel,
    bool clearSelectedModel = false,
  }) {
    return AiProviderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      isActive: isActive ?? this.isActive,
      supportedModels: supportedModels ?? this.supportedModels,
      purpose: purpose ?? this.purpose,
      selectedModel:
          clearSelectedModel ? null : (selectedModel ?? this.selectedModel),
    );
  }
}
