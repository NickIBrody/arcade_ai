import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// API keys live here. On Android this is backed by the hardware-backed
/// Keystore (AES-GCM), so the secret never sits in plaintext on disk.
class SecureStore {
  static const _opts = AndroidOptions(encryptedSharedPreferences: true);
  final _storage = const FlutterSecureStorage(aOptions: _opts);

  String _keyFor(String providerId) => 'apikey::$providerId';
  String _extrasFor(String providerId) => 'extras::$providerId';

  Future<void> saveKey(String providerId, String key) =>
      _storage.write(key: _keyFor(providerId), value: key);

  Future<String?> readKey(String providerId) =>
      _storage.read(key: _keyFor(providerId));

  Future<void> deleteKey(String providerId) =>
      _storage.delete(key: _keyFor(providerId));

  Future<void> saveExtras(String providerId, Map<String, String> extras) =>
      _storage.write(key: _extrasFor(providerId), value: jsonEncode(extras));

  Future<Map<String, String>> readExtras(String providerId) async {
    final raw = await _storage.read(key: _extrasFor(providerId));
    if (raw == null) return {};
    return (jsonDecode(raw) as Map).cast<String, String>();
  }

  Future<List<String>> configuredProviderIds() async {
    final all = await _storage.readAll();
    return all.keys
        .where((k) => k.startsWith('apikey::'))
        .map((k) => k.substring('apikey::'.length))
        .toList();
  }

  Future<void> wipe() => _storage.deleteAll();
}
