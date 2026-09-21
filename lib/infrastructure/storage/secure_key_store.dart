import 'package:flutter/services.dart';

abstract class SecureKeyStore {
  Future<String?> readApiKey();

  Future<void> writeApiKey(String key);

  Future<void> deleteApiKey();
}

/// Used by tests, and whenever the platform channel is unavailable.
class MemoryKeyStore implements SecureKeyStore {
  String? _value;

  @override
  Future<String?> readApiKey() async => _value;

  @override
  Future<void> writeApiKey(String key) async => _value = key;

  @override
  Future<void> deleteApiKey() async => _value = null;
}

/// Thin wrapper over the app-private key/value channel implemented natively in
/// `MainActivity.kt` (SharedPreferences) and `AppDelegate.swift` (NSUserDefaults).
class ChannelKeyValueStore {
  ChannelKeyValueStore({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(storeChannelName);

  static const storeChannelName = 'com.doubler.doubler/store';

  final MethodChannel _channel;

  Future<String?> read(String key) async {
    try {
      return await _channel.invokeMethod<String>('read', <String, Object?>{'key': key});
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<bool> write(String key, String value) => _invoke('write', <String, Object?>{
        'key': key,
        'value': value,
      });

  Future<bool> remove(String key) =>
      _invoke('remove', <String, Object?>{'key': key});

  Future<bool> _invoke(String method, Map<String, Object?> arguments) async {
    try {
      await _channel.invokeMethod<bool>(method, arguments);
      return true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}

/// Production store: persists the key on device so a saved key survives an app
/// restart, and keeps an in-memory mirror so behaviour is identical when no
/// platform implementation is present (unit tests, desktop runs).
class PlatformKeyStore implements SecureKeyStore {
  PlatformKeyStore({ChannelKeyValueStore? channel})
      : _channel = channel ?? ChannelKeyValueStore();

  static const storageKey = 'gemini_api_key';

  final ChannelKeyValueStore _channel;
  final MemoryKeyStore _mirror = MemoryKeyStore();

  @override
  Future<String?> readApiKey() async {
    final cached = await _mirror.readApiKey();
    if (cached != null) {
      return cached;
    }
    final stored = await _channel.read(storageKey);
    if (stored != null && stored.isNotEmpty) {
      await _mirror.writeApiKey(stored);
      return stored;
    }
    return null;
  }

  @override
  Future<void> writeApiKey(String key) async {
    await _mirror.writeApiKey(key);
    await _channel.write(storageKey, key);
  }

  @override
  Future<void> deleteApiKey() async {
    await _mirror.deleteApiKey();
    await _channel.remove(storageKey);
  }
}
