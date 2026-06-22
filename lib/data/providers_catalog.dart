import '../models/llm_provider.dart';

/// Built-in provider catalog. OpenAI-compatible providers share one client path;
/// Anthropic, Gemini, Yandex and GigaChat use their own request shaping.
class ProvidersCatalog {
  static const List<LlmProvider> builtIns = [
    LlmProvider(
      id: 'openai',
      name: 'OpenAI',
      tagline: 'GPT и o-серия',
      baseUrl: 'https://api.openai.com/v1',
      format: ApiFormat.openai,
      accent: '10A37F',
      models: ['gpt-5', 'gpt-5-mini', 'gpt-4o', 'o3'],
      supportsReasoning: true,
      supportsVision: true,
    ),
    LlmProvider(
      id: 'anthropic',
      name: 'Anthropic',
      tagline: 'Claude Opus / Sonnet',
      baseUrl: 'https://api.anthropic.com/v1',
      format: ApiFormat.anthropic,
      accent: 'D97757',
      models: [
        'claude-opus-4-8',
        'claude-sonnet-4-6',
        'claude-haiku-4-5-20251001',
      ],
      supportsReasoning: true,
      supportsVision: true,
    ),
    LlmProvider(
      id: 'gemini',
      name: 'Google Gemini',
      tagline: 'Gemini',
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
      format: ApiFormat.openai,
      accent: '4285F4',
      models: ['gemini-2.0-flash', 'gemini-1.5-pro'],
      supportsVision: true,
    ),
    LlmProvider(
      id: 'groq',
      name: 'Groq',
      tagline: 'LPU — очень быстро',
      baseUrl: 'https://api.groq.com/openai/v1',
      format: ApiFormat.openai,
      accent: 'F55036',
      models: ['llama-3.3-70b-versatile', 'deepseek-r1-distill-llama-70b'],
      supportsReasoning: true,
    ),
    LlmProvider(
      id: 'deepseek',
      name: 'DeepSeek',
      tagline: 'Чат и reasoning',
      baseUrl: 'https://api.deepseek.com',
      format: ApiFormat.openai,
      accent: '4D6BFE',
      models: ['deepseek-chat', 'deepseek-reasoner'],
      supportsReasoning: true,
    ),
    LlmProvider(
      id: 'xai',
      name: 'xAI Grok',
      tagline: 'Grok',
      baseUrl: 'https://api.x.ai/v1',
      format: ApiFormat.openai,
      accent: 'FFFFFF',
      models: ['grok-2-latest', 'grok-2-vision-latest'],
      supportsVision: true,
    ),
    LlmProvider(
      id: 'mistral',
      name: 'Mistral',
      tagline: 'Large / Codestral',
      baseUrl: 'https://api.mistral.ai/v1',
      format: ApiFormat.openai,
      accent: 'FF7000',
      models: ['mistral-large-latest', 'codestral-latest'],
    ),
    LlmProvider(
      id: 'together',
      name: 'Together AI',
      tagline: 'Open models',
      baseUrl: 'https://api.together.xyz/v1',
      format: ApiFormat.openai,
      accent: '0F6FFF',
      models: ['meta-llama/Llama-3.3-70B-Instruct-Turbo'],
    ),
    LlmProvider(
      id: 'openrouter',
      name: 'OpenRouter',
      tagline: 'Шлюз ко всему',
      baseUrl: 'https://openrouter.ai/api/v1',
      format: ApiFormat.openai,
      accent: '6467F2',
      models: ['anthropic/claude-sonnet-4-6', 'openai/gpt-4o'],
      supportsReasoning: true,
      supportsVision: true,
    ),
    LlmProvider(
      id: 'cohere',
      name: 'Cohere',
      tagline: 'Command',
      baseUrl: 'https://api.cohere.ai/compatibility/v1',
      format: ApiFormat.openai,
      accent: '39594D',
      models: ['command-r-plus', 'command-r'],
    ),
    LlmProvider(
      id: 'gigachat',
      name: 'GigaChat',
      tagline: 'Сбер',
      baseUrl: 'https://gigachat.devices.sberbank.ru/api/v1',
      format: ApiFormat.gigachat,
      accent: '00B956',
      models: ['GigaChat', 'GigaChat-Pro', 'GigaChat-Max'],
      keyHint: 'Authorization key (Base64)',
      fullySupported: false,
    ),
    LlmProvider(
      id: 'yandex',
      name: 'YandexGPT',
      tagline: 'Алиса / Foundation Models',
      baseUrl: 'https://llm.api.cloud.yandex.net/foundationModels/v1',
      format: ApiFormat.yandex,
      accent: 'FC3F1D',
      models: ['yandexgpt', 'yandexgpt-lite'],
      keyHint: 'Api-Key',
      extraFields: [
        ExtraField(key: 'folder_id', label: 'Folder ID', hint: 'b1g...'),
      ],
      fullySupported: false,
    ),
    LlmProvider(
      id: 'granite',
      name: 'IBM Granite',
      tagline: 'watsonx.ai',
      baseUrl: 'https://us-south.ml.cloud.ibm.com/ml/v1',
      format: ApiFormat.openai,
      accent: '0F62FE',
      models: ['ibm/granite-3-8b-instruct'],
      extraFields: [
        ExtraField(key: 'project_id', label: 'Project ID'),
      ],
      fullySupported: false,
    ),
    LlmProvider(
      id: 'ollama',
      name: 'Ollama',
      tagline: 'Сервер Ollama (localhost)',
      baseUrl: 'http://localhost:11434/v1',
      format: ApiFormat.openai,
      accent: 'CCCCCC',
      models: ['llama3.2', 'qwen2.5', 'gemma2'],
      keyHint: 'ключ не нужен',
      supportsReasoning: true,
    ),
  ];

  static LlmProvider customTemplate() => const LlmProvider(
        id: 'custom',
        name: 'Свой провайдер',
        tagline: 'Свой эндпоинт',
        baseUrl: '',
        format: ApiFormat.openai,
        accent: '8B5CF6',
        builtIn: false,
        supportsReasoning: true,
        supportsVision: true,
      );

  static LlmProvider? byId(String id) {
    for (final p in builtIns) {
      if (p.id == id) return p;
    }
    return null;
  }

  // English taglines, mapped by id (Russian ones live on the provider itself).
  static const Map<String, String> _en = {
    'openai': 'GPT & o-series',
    'anthropic': 'Claude Opus / Sonnet',
    'gemini': 'Gemini',
    'groq': 'LPU — very fast',
    'deepseek': 'Chat & reasoning',
    'xai': 'Grok',
    'mistral': 'Large / Codestral',
    'together': 'Open models',
    'openrouter': 'Gateway to everything',
    'cohere': 'Command',
    'gigachat': 'Sber',
    'yandex': 'Alice / Foundation Models',
    'granite': 'watsonx.ai',
    'ollama': 'Ollama server (localhost)',
    'custom': 'Custom endpoint',
  };

  static String tagline(LlmProvider p, bool ru) =>
      ru ? p.tagline : (_en[p.id] ?? p.tagline);
}
