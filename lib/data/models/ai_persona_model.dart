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
  });

  factory AiPersonaModel.fromJson(Map<String, dynamic> json) {
    // Parse quick_actions from JSON
    List<Map<String, String>> actions = [];
    if (json['quick_actions'] is List) {
      actions = (json['quick_actions'] as List)
          .map((e) => Map<String, String>.from(e as Map))
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
      };
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

  const AiProviderModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.baseUrl,
    required this.apiKey,
    required this.isActive,
    required this.supportedModels,
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
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'slug': slug,
        'base_url': baseUrl,
        'api_key': apiKey,
        'is_active': isActive,
        'supported_models': supportedModels,
      };
}
