enum ApiFormat { openai, anthropic, gemini, yandex, gigachat }

extension ApiFormatLabel on ApiFormat {
  String get label => switch (this) {
        ApiFormat.openai => 'OpenAI-совместимый',
        ApiFormat.anthropic => 'Anthropic',
        ApiFormat.gemini => 'Google Gemini',
        ApiFormat.yandex => 'Yandex Foundation',
        ApiFormat.gigachat => 'GigaChat (OAuth)',
      };
}

class ExtraField {
  final String key;
  final String label;
  final String hint;
  const ExtraField({required this.key, required this.label, this.hint = ''});
}

class LlmProvider {
  final String id;
  final String name;
  final String tagline;
  final String baseUrl;
  final ApiFormat format;
  final List<String> models;
  final String accent; // hex without #, for the provider chip glow
  final String keyHint;
  final List<ExtraField> extraFields;
  final bool supportsReasoning;
  final bool supportsVision;
  final bool builtIn;
  final bool fullySupported;

  const LlmProvider({
    required this.id,
    required this.name,
    required this.tagline,
    required this.baseUrl,
    required this.format,
    this.models = const [],
    this.accent = '8B5CF6',
    this.keyHint = 'API key',
    this.extraFields = const [],
    this.supportsReasoning = false,
    this.supportsVision = false,
    this.builtIn = true,
    this.fullySupported = true,
  });

  LlmProvider copyWith({
    String? id,
    String? name,
    String? baseUrl,
    ApiFormat? format,
    List<String>? models,
  }) {
    return LlmProvider(
      id: id ?? this.id,
      name: name ?? this.name,
      tagline: tagline,
      baseUrl: baseUrl ?? this.baseUrl,
      format: format ?? this.format,
      models: models ?? this.models,
      accent: accent,
      keyHint: keyHint,
      extraFields: extraFields,
      supportsReasoning: supportsReasoning,
      supportsVision: supportsVision,
      builtIn: builtIn,
      fullySupported: fullySupported,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tagline': tagline,
        'baseUrl': baseUrl,
        'format': format.name,
        'models': models,
        'accent': accent,
        'builtIn': builtIn,
      };

  factory LlmProvider.fromJson(Map<String, dynamic> j) => LlmProvider(
        id: j['id'],
        name: j['name'],
        tagline: j['tagline'] ?? '',
        baseUrl: j['baseUrl'],
        format: ApiFormat.values.firstWhere((f) => f.name == j['format'],
            orElse: () => ApiFormat.openai),
        models: (j['models'] as List?)?.cast<String>() ?? const [],
        accent: j['accent'] ?? '8B5CF6',
        builtIn: j['builtIn'] ?? false,
      );
}
