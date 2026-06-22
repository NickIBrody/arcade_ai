import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  String locale; // 'en' | 'ru'
  String activeProviderId;
  String activeModel;
  bool onboarded;

  // security
  bool encryptionEnabled; // toggle the secure backend (always on by default)
  bool autoLockEnabled; // require biometric/credential when reopening

  // generation
  double temperature;
  int maxTokens;
  String systemPrompt;
  bool streamResponses;
  bool showReasoning;

  AppSettings({
    this.locale = 'ru',
    this.activeProviderId = '',
    this.activeModel = '',
    this.onboarded = false,
    this.encryptionEnabled = true,
    this.autoLockEnabled = false,
    this.temperature = 0.7,
    this.maxTokens = 2048,
    this.systemPrompt = '',
    this.streamResponses = true,
    this.showReasoning = true,
  });
}

class SettingsStore {
  late SharedPreferences _p;

  Future<AppSettings> load() async {
    _p = await SharedPreferences.getInstance();
    return AppSettings(
      locale: _p.getString('locale') ?? 'ru',
      activeProviderId: _p.getString('activeProviderId') ?? '',
      activeModel: _p.getString('activeModel') ?? '',
      onboarded: _p.getBool('onboarded') ?? false,
      encryptionEnabled: _p.getBool('encryptionEnabled') ?? true,
      autoLockEnabled: _p.getBool('autoLockEnabled') ?? false,
      temperature: _p.getDouble('temperature') ?? 0.7,
      maxTokens: _p.getInt('maxTokens') ?? 2048,
      systemPrompt: _p.getString('systemPrompt') ?? '',
      streamResponses: _p.getBool('streamResponses') ?? true,
      showReasoning: _p.getBool('showReasoning') ?? true,
    );
  }

  Future<void> save(AppSettings s) async {
    await _p.setString('locale', s.locale);
    await _p.setString('activeProviderId', s.activeProviderId);
    await _p.setString('activeModel', s.activeModel);
    await _p.setBool('onboarded', s.onboarded);
    await _p.setBool('encryptionEnabled', s.encryptionEnabled);
    await _p.setBool('autoLockEnabled', s.autoLockEnabled);
    await _p.setDouble('temperature', s.temperature);
    await _p.setInt('maxTokens', s.maxTokens);
    await _p.setString('systemPrompt', s.systemPrompt);
    await _p.setBool('streamResponses', s.streamResponses);
    await _p.setBool('showReasoning', s.showReasoning);
  }

  // custom providers persisted as JSON list
  Future<void> saveCustomProviders(String json) =>
      _p.setString('customProviders', json);
  String customProvidersJson() => _p.getString('customProviders') ?? '[]';

  // chat history persisted as JSON list of sessions
  Future<void> saveSessions(String json) => _p.setString('sessions', json);
  String sessionsJson() => _p.getString('sessions') ?? '[]';

  // user-added models, keyed by provider id: {"openai": ["gpt-x", ...]}
  Future<void> saveExtraModels(String json) =>
      _p.setString('extraModels', json);
  String extraModelsJson() => _p.getString('extraModels') ?? '{}';
}
