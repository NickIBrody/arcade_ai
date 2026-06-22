import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

import '../data/providers_catalog.dart';
import '../data/secure_store.dart';
import '../data/settings_store.dart';
import '../models/chat.dart';
import '../models/llm_provider.dart';
import '../services/llm_client.dart';

class AppState extends ChangeNotifier {
  final SettingsStore _settingsStore = SettingsStore();
  final SecureStore secure = SecureStore();
  final LlmClient _client = LlmClient();

  late AppSettings settings;
  final List<LlmProvider> customProviders = [];
  final Map<String, List<String>> extraModels = {};
  final List<ChatSession> sessions = [];
  String? _currentId;

  List<String> get modelsForActive {
    final p = activeProvider;
    if (p == null) return const [];
    final extra = extraModels[p.id] ?? const [];
    return <String>[...p.models, ...extra.where((m) => !p.models.contains(m))];
  }

  Future<void> addModel(String model) async {
    final p = activeProvider;
    final m = model.trim();
    if (p == null || m.isEmpty) return;
    final list = extraModels.putIfAbsent(p.id, () => []);
    if (!list.contains(m) && !p.models.contains(m)) list.add(m);
    await _settingsStore.saveExtraModels(jsonEncode(extraModels));
    notifyListeners();
  }

  ChatSession get currentSession {
    if (sessions.isEmpty || !sessions.any((s) => s.id == _currentId)) {
      final s = ChatSession(id: _newId());
      sessions.add(s);
      _currentId = s.id;
    }
    return sessions.firstWhere((s) => s.id == _currentId);
  }

  List<ChatMessage> get messages => currentSession.messages;

  List<ChatSession> get orderedSessions =>
      [...sessions]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  bool locked = false;
  bool _sending = false;
  bool _stop = false;
  bool get sending => _sending;

  void stopGenerating() => _stop = true;

  List<LlmProvider> get allProviders =>
      [...ProvidersCatalog.builtIns, ...customProviders];

  LlmProvider? get activeProvider {
    for (final p in allProviders) {
      if (p.id == settings.activeProviderId) return p;
    }
    return null;
  }

  Future<void> init() async {
    settings = await _settingsStore.load();
    _loadCustomProviders();
    _loadSessions();
    _loadExtraModels();
    // Biometric auto-lock is a mobile-only feature (local_auth has no Linux backend).
    locked = settings.autoLockEnabled && (Platform.isAndroid || Platform.isIOS);
    notifyListeners();
  }

  void _loadCustomProviders() {
    customProviders.clear();
    final raw = jsonDecode(_settingsStore.customProvidersJson()) as List;
    for (final e in raw) {
      customProviders.add(LlmProvider.fromJson(e as Map<String, dynamic>));
    }
  }

  void _loadExtraModels() {
    extraModels.clear();
    final raw = jsonDecode(_settingsStore.extraModelsJson()) as Map;
    raw.forEach((k, v) {
      extraModels[k as String] = (v as List).cast<String>();
    });
  }

  void _loadSessions() {
    sessions.clear();
    final raw = jsonDecode(_settingsStore.sessionsJson()) as List;
    for (final e in raw) {
      sessions.add(ChatSession.fromJson(e as Map<String, dynamic>));
    }
    if (sessions.isNotEmpty) _currentId = orderedSessions.first.id;
  }

  Future<void> persistSessions() async {
    await _settingsStore
        .saveSessions(jsonEncode(sessions.map((e) => e.toJson()).toList()));
  }

  // ---- chat sessions ----
  void newChat() {
    if (currentSession.messages.isEmpty) {
      notifyListeners();
      return;
    }
    final s = ChatSession(id: _newId());
    sessions.add(s);
    _currentId = s.id;
    notifyListeners();
  }

  void openSession(String id) {
    _currentId = id;
    notifyListeners();
  }

  ChatSession? _lastDeleted;

  Future<void> deleteSession(String id) async {
    final idx = sessions.indexWhere((s) => s.id == id);
    if (idx < 0) return;
    _lastDeleted = sessions.removeAt(idx);
    if (_currentId == id) {
      _currentId = sessions.isEmpty ? null : orderedSessions.first.id;
    }
    await persistSessions();
    notifyListeners();
  }

  Future<void> restoreLastDeleted() async {
    final s = _lastDeleted;
    if (s == null) return;
    sessions.add(s);
    _currentId = s.id;
    _lastDeleted = null;
    await persistSessions();
    notifyListeners();
  }

  Future<void> persistSettings() async {
    await _settingsStore.save(settings);
    notifyListeners();
  }

  Future<void> persistCustomProviders() async {
    await _settingsStore
        .saveCustomProviders(jsonEncode(customProviders.map((e) => e.toJson()).toList()));
  }

  // ---- onboarding / connection ----
  Future<void> connect({
    required LlmProvider provider,
    required String apiKey,
    required String model,
    Map<String, String> extras = const {},
    bool isCustom = false,
  }) async {
    if (isCustom) {
      customProviders.removeWhere((p) => p.id == provider.id);
      customProviders.add(provider);
      await persistCustomProviders();
    }
    await secure.saveKey(provider.id, apiKey);
    if (extras.isNotEmpty) await secure.saveExtras(provider.id, extras);
    settings
      ..activeProviderId = provider.id
      ..activeModel = model
      ..onboarded = true;
    await persistSettings();
  }

  Future<void> setActiveModel(String model) async {
    settings.activeModel = model;
    await persistSettings();
  }

  void unlock() {
    locked = false;
    notifyListeners();
  }

  // ---- chat ----
  void clearChat() => newChat();

  Future<void> send(String text, {List<Attachment> images = const []}) async {
    final provider = activeProvider;
    if (provider == null || _sending) return;
    if (text.trim().isEmpty && images.isEmpty) return;

    final session = currentSession;
    if (session.title.isEmpty && text.trim().isNotEmpty) {
      session.title =
          text.trim().length > 40 ? '${text.trim().substring(0, 40)}…' : text.trim();
    }
    session.messages.add(ChatMessage(role: Role.user, text: text, images: images));
    final reply = ChatMessage(role: Role.assistant, streaming: true);
    session.messages.add(reply);
    session.touch();
    _sending = true;
    _stop = false;
    notifyListeners();

    try {
      final key = await secure.readKey(provider.id) ?? '';
      final extras = await secure.readExtras(provider.id);
      final cfg = GenerationConfig(
        temperature: settings.temperature,
        maxTokens: settings.maxTokens,
        systemPrompt: settings.systemPrompt,
        stream: settings.streamResponses,
      );

      final stream = _client.stream(
        provider: provider,
        apiKey: key,
        model: settings.activeModel,
        history: messages.where((m) => m != reply).toList(),
        config: cfg,
        extras: extras,
      );

      await for (final d in stream) {
        if (_stop) break;
        reply.text += d.text;
        reply.reasoning += d.reasoning;
        notifyListeners();
      }
    } catch (e) {
      reply.error = e.toString();
    } finally {
      reply.streaming = false;
      _sending = false;
      session.touch();
      await persistSessions();
      notifyListeners();
    }
  }

  // ---- compare two models on one prompt ----
  Future<void> compareSend(String text, String modelB) async {
    final provider = activeProvider;
    if (provider == null || _sending || text.trim().isEmpty) return;
    final modelA = settings.activeModel;

    final session = currentSession;
    if (session.title.isEmpty) {
      session.title =
          text.trim().length > 40 ? '${text.trim().substring(0, 40)}…' : text.trim();
    }
    session.messages.add(ChatMessage(role: Role.user, text: text));
    final reply = ChatMessage(
      role: Role.assistant,
      compare: true,
      streaming: true,
      altStreaming: true,
      modelA: modelA,
      modelB: modelB,
    );
    session.messages.add(reply);
    session.touch();
    _sending = true;
    _stop = false;
    notifyListeners();

    final history = session.messages.where((m) => m != reply).toList();
    final key = await secure.readKey(provider.id) ?? '';
    final extras = await secure.readExtras(provider.id);
    GenerationConfig cfg() => GenerationConfig(
          temperature: settings.temperature,
          maxTokens: settings.maxTokens,
          systemPrompt: settings.systemPrompt,
          stream: settings.streamResponses,
        );

    Future<void> streamInto(String model, bool isA) async {
      try {
        await for (final d in _client.stream(
            provider: provider,
            apiKey: key,
            model: model,
            history: history,
            config: cfg(),
            extras: extras)) {
          if (_stop) break;
          if (isA) {
            reply.text += d.text;
            reply.reasoning += d.reasoning;
          } else {
            reply.altText += d.text;
            reply.altReasoning += d.reasoning;
          }
          notifyListeners();
        }
      } catch (e) {
        if (isA) {
          reply.error = e.toString();
        } else {
          reply.altError = e.toString();
        }
      }
    }

    await Future.wait([streamInto(modelA, true), streamInto(modelB, false)]);
    reply.streaming = false;
    reply.altStreaming = false;
    _sending = false;
    session.touch();
    await persistSessions();
    notifyListeners();
  }

  Future<void> pickComparison(ChatMessage m, bool keepA) async {
    if (!keepA) {
      m.text = m.altText;
      m.reasoning = m.altReasoning;
      m.error = m.altError;
    }
    settings.activeModel = keepA ? m.modelA : m.modelB;
    m.compare = false;
    m.altText = '';
    m.altReasoning = '';
    await persistSettings();
    await persistSessions();
    notifyListeners();
  }

  @override
  void dispose() {
    _client.dispose();
    super.dispose();
  }
}
