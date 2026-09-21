import 'dart:io';

import 'package:doubler/features/api_key/application/api_key_controller.dart';
import 'package:doubler/features/api_key/domain/api_key_validator.dart';
import 'package:doubler/infrastructure/gemini/gemini_connection_tester.dart';
import 'package:doubler/infrastructure/storage/secure_key_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Google's current auth-key shape (as issued by AI Studio in 2026):
/// `AQ.` followed by base64url — dots included.
const userKey = 'AQ.Ab8RN6KVeLqAg8hRML6fYK4u8uE0owodMSiRG_tKAmP15lyGZA';

void main() {
  group('ApiKeyValidator', () {
    test('accepts a modern AQ. auth key', () {
      final result = ApiKeyValidator.validate(userKey);
      expect(result.isValid, isTrue);
      expect(result.normalized, userKey);
      expect(result.isAuthKey, isTrue);
      expect(result.kind, ApiKeyKind.authKey);
      expect(result.warningCode, isNull);
      expect(result.code, isNull);
    });

    test('accepts a legacy AIza key and warns about the shape', () {
      final result = ApiKeyValidator.validate('AIzaSyDummyKeyValue123456789');
      expect(result.isValid, isTrue);
      expect(result.kind, ApiKeyKind.standardKey);
      expect(result.warningCode, 'keyWarningLegacy');
    });

    test('accepts an unknown but plausible token, warning only', () {
      final result = ApiKeyValidator.validate('custom-key_0123456789ABCDEF');
      expect(result.isValid, isTrue);
      expect(result.kind, ApiKeyKind.unknown);
      expect(result.warningCode, 'keyWarningShape');
    });

    test('separates empty from too short', () {
      expect(ApiKeyValidator.validate('').code, 'keyEmpty');
      expect(ApiKeyValidator.validate('   ').code, 'keyEmpty');
      expect(ApiKeyValidator.validate('AQ.short').code, 'keyTooShort');
    });

    test('rejects interior whitespace and non-key characters', () {
      expect(
        ApiKeyValidator.validate('AQ.abc def_rstuvwxyz_0123456789').code,
        'keyInvalid',
      );
      expect(
        ApiKeyValidator.validate('AQ.abc*def_rstuvwxyz_0123456789').code,
        'keyInvalid',
      );
    });

    test('cleans up the ways people actually paste a key', () {
      expect(ApiKeyValidator.validate('  "$userKey"  ').normalized, userKey);
      expect(
        ApiKeyValidator.validate('x-goog-api-key: $userKey').normalized,
        userKey,
      );
      expect(
        ApiKeyValidator.validate('AI Studio API key = $userKey').normalized,
        userKey,
      );
      expect(
        ApiKeyValidator.validate('https://aistudio.google.com/apps/api?key=$userKey')
            .normalized,
        userKey,
      );
      // A key copied out of a chat app keeps zero-width and bidi marks.
      const dirty = 'AQ.' '\u200B' 'Ab8RN6KVeLqAg8hRML6fYK4u8uE0owodMSiRG_tKAmP15lyGZA'
        '\u202D' '\uFEFF';
      expect(ApiKeyValidator.validate(dirty).normalized, userKey);
      expect(ApiKeyValidator.validate(dirty).isValid, isTrue);
    });

    test('keeps the longest line when a label is pasted with the key', () {
      final result = ApiKeyValidator.validate('My Gemini key\n$userKey,');
      expect(result.normalized, userKey);
    });

    test('mask never leaks the whole key', () {
      final masked = ApiKeyValidator.mask(userKey);
      expect(masked, isNot(contains('b8RN6KVeLq')));
      expect(masked.startsWith('AQ.A'), isTrue);
      expect(masked.endsWith('GZA'), isTrue);
    });
  });

  test('valid key is stored and reflected in state', () async {
    final store = MemoryKeyStore();
    final container = ProviderContainer(
      overrides: [secureKeyStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    final result = await container
        .read(apiKeyControllerProvider.notifier)
        .save('  $userKey  ');
    expect(result, ApiKeySaveResult.saved);
    expect(await store.readApiKey(), userKey);
    final state = container.read(apiKeyControllerProvider).requireValue;
    expect(state.hasKey, isTrue);
    expect(state.masked, isNot(userKey));
    expect(state.kind, ApiKeyKind.authKey);
    expect(state.warningCode, isNull);
  });

  test('legacy key is stored but flagged as legacy', () async {
    final store = MemoryKeyStore();
    final container = ProviderContainer(
      overrides: [secureKeyStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    final result = await container
        .read(apiKeyControllerProvider.notifier)
        .save('AIzaSyDummyKeyValue123456789');
    expect(result, ApiKeySaveResult.saved);
    expect(
      container.read(apiKeyControllerProvider).requireValue.warningCode,
      'keyWarningLegacy',
    );
  });

  test('invalid key is not stored', () async {
    final store = MemoryKeyStore();
    await store.writeApiKey(userKey);
    final container = ProviderContainer(
      overrides: [secureKeyStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    // Let the controller finish loading first: an assertion race on the
    // initial AsyncLoading → AsyncData transition is not what we test here.
    await container.read(apiKeyControllerProvider.future);
    final result = await container
        .read(apiKeyControllerProvider.notifier)
        .save('short');
    expect(result, ApiKeySaveResult.tooShort);
    // A rejected save must never wipe a key that already works.
    expect(await store.readApiKey(), userKey);
    expect(
      container.read(apiKeyControllerProvider).requireValue.messageCode,
      'keyTooShort',
    );
  });

  test('delete removes the stored key and reports it', () async {
    final store = MemoryKeyStore();
    await store.writeApiKey(userKey);
    final container = ProviderContainer(
      overrides: [secureKeyStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    await container.read(apiKeyControllerProvider.notifier).delete();
    expect(await store.readApiKey(), isNull);
    final state = container.read(apiKeyControllerProvider).requireValue;
    expect(state.hasKey, isFalse);
    expect(state.messageCode, 'keyDeleted');
  });

  test('connection test sends the key in the x-goog-api-key header', () async {
    final store = MemoryKeyStore();
    await store.writeApiKey(userKey);
    final seen = <Uri>[];
    final headers = <String, String>{};
    final tester = GeminiConnectionTester(get: (uri, requestHeaders) async {
      seen.add(uri);
      headers.addAll(requestHeaders);
      return 200;
    });
    final container = ProviderContainer(
      overrides: [
        secureKeyStoreProvider.overrideWithValue(store),
        geminiConnectionTesterProvider.overrideWithValue(tester),
      ],
    );
    addTearDown(container.dispose);
    final code = await container
        .read(apiKeyControllerProvider.notifier)
        .testConnection();
    expect(code, isNull);
    expect(headers['x-goog-api-key'], userKey);
    // Header auth needs no query parameter, so none is ever sent.
    expect(seen.single.queryParameters.containsKey('key'), isFalse);
    expect(
      container.read(apiKeyControllerProvider).requireValue.messageCode,
      'connectionOk',
    );
  });

  test('legacy fallback retries once with the query parameter', () async {
    final store = MemoryKeyStore();
    await store.writeApiKey('AIzaSyDummyKeyValue123456789');
    final seen = <Uri>[];
    final tester = GeminiConnectionTester(get: (uri, headers) async {
      seen.add(uri);
      return seen.length == 1 ? 401 : 200;
    });
    final container = ProviderContainer(
      overrides: [
        secureKeyStoreProvider.overrideWithValue(store),
        geminiConnectionTesterProvider.overrideWithValue(tester),
      ],
    );
    addTearDown(container.dispose);
    final code = await container
        .read(apiKeyControllerProvider.notifier)
        .testConnection();
    expect(code, isNull);
    expect(seen, hasLength(2));
    expect(seen.last.queryParameters['key'], 'AIzaSyDummyKeyValue123456789');
  });

  test('401 on both schemes surfaces as an invalid key', () async {
    final store = MemoryKeyStore();
    await store.writeApiKey(userKey);
    final tester = GeminiConnectionTester(get: (uri, headers) async => 401);
    final container = ProviderContainer(
      overrides: [
        secureKeyStoreProvider.overrideWithValue(store),
        geminiConnectionTesterProvider.overrideWithValue(tester),
      ],
    );
    addTearDown(container.dispose);
    final code = await container
        .read(apiKeyControllerProvider.notifier)
        .testConnection();
    expect(code, 'keyInvalid');
    expect(
      container.read(apiKeyControllerProvider).requireValue.messageCode,
      'keyInvalid',
    );
  });

  test('a rejected legacy key is explained as legacy, not as invalid', () async {
    final store = MemoryKeyStore();
    await store.writeApiKey('AIzaSyDummyKeyValue123456789');
    final tester = GeminiConnectionTester(get: (uri, headers) async => 400);
    final container = ProviderContainer(
      overrides: [
        secureKeyStoreProvider.overrideWithValue(store),
        geminiConnectionTesterProvider.overrideWithValue(tester),
      ],
    );
    addTearDown(container.dispose);
    final code = await container
        .read(apiKeyControllerProvider.notifier)
        .testConnection();
    expect(code, 'keyLegacyRejected');
  });

  test('429 still proves the key works', () async {
    final store = MemoryKeyStore();
    await store.writeApiKey(userKey);
    final tester = GeminiConnectionTester(get: (uri, headers) async => 429);
    final container = ProviderContainer(
      overrides: [
        secureKeyStoreProvider.overrideWithValue(store),
        geminiConnectionTesterProvider.overrideWithValue(tester),
      ],
    );
    addTearDown(container.dispose);
    final code = await container
        .read(apiKeyControllerProvider.notifier)
        .testConnection();
    expect(code, isNull);
    expect(
      container.read(apiKeyControllerProvider).requireValue.messageCode,
      'connectionOkQuota',
    );
  });

  test('a transport failure never blames the key', () async {
    final store = MemoryKeyStore();
    await store.writeApiKey(userKey);
    final tester = GeminiConnectionTester(
      get: (uri, headers) async => throw const SocketException('closed'),
    );
    final container = ProviderContainer(
      overrides: [
        secureKeyStoreProvider.overrideWithValue(store),
        geminiConnectionTesterProvider.overrideWithValue(tester),
      ],
    );
    addTearDown(container.dispose);
    final code = await container
        .read(apiKeyControllerProvider.notifier)
        .testConnection();
    expect(code, 'networkUnavailable');
  });

  test('connection test with no key says keyMissing', () async {
    final store = MemoryKeyStore();
    final tester = GeminiConnectionTester(get: (uri, headers) async => 200);
    final container = ProviderContainer(
      overrides: [
        secureKeyStoreProvider.overrideWithValue(store),
        geminiConnectionTesterProvider.overrideWithValue(tester),
      ],
    );
    addTearDown(container.dispose);
    final code = await container
        .read(apiKeyControllerProvider.notifier)
        .testConnection();
    expect(code, 'keyMissing');
  });
}
