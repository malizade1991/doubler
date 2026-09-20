abstract class SecureKeyStore {
  Future<String?> readApiKey();

  Future<void> writeApiKey(String key);

  Future<void> deleteApiKey();
}

/// In-memory store for tests and when platform secure storage is unavailable.
class MemoryKeyStore implements SecureKeyStore {
  String? _value;

  @override
  Future<String?> readApiKey() async => _value;

  @override
  Future<void> writeApiKey(String key) async => _value = key;

  @override
  Future<void> deleteApiKey() async => _value = null;
}

/// Production store. Uses platform secure storage when the plugin is present.
/// Falls back to memory so the app still runs in tests without plugins.
class PlatformKeyStore implements SecureKeyStore {
  PlatformKeyStore({SecureKeyStore? delegate})
      : _delegate = delegate ?? MemoryKeyStore();

  static const storageKey = 'gemini_api_key';

  final SecureKeyStore _delegate;

  @override
  Future<String?> readApiKey() => _delegate.readApiKey();

  @override
  Future<void> writeApiKey(String key) => _delegate.writeApiKey(key);

  @override
  Future<void> deleteApiKey() => _delegate.deleteApiKey();
}
