import 'package:doubler/core/errors/app_failure.dart';
import 'package:doubler/features/api_key/application/api_key_controller.dart';
import 'package:doubler/features/api_key/domain/api_key_validator.dart';
import 'package:doubler/infrastructure/gemini/gemini_connection_tester.dart';
import 'package:doubler/infrastructure/storage/secure_key_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects empty, short, and spaced keys; masks secrets', () {
    expect(ApiKeyValidator.validate('').code, 'keyEmpty');
    expect(ApiKeyValidator.validate('short').code, 'keyTooShort');
    expect(ApiKeyValidator.validate('AIza has space 1234567890').code, 'keyInvalid');
    expect(ApiKeyValidator.validate('AIzaSyDummyKeyValue123456').isValid, isTrue);
    expect(
      ApiKeyValidator.mask('AIzaSyDummyKeyValue123456'),
      isNot(contains('DummyKeyValue')),
    );
  });

  test('memory store save and delete', () async {
    final store = MemoryKeyStore();
    await store.writeApiKey('AIzaSyDummyKeyValue123456');
    expect(await store.readApiKey(), 'AIzaSyDummyKeyValue123456');
    await store.deleteApiKey();
    expect(await store.readApiKey(), isNull);
  });

  test('connection tester maps HTTP codes without exposing the key', () async {
    final tester = GeminiConnectionTester(
      get: (uri) async {
        expect(uri.toString(), isNot(contains('print')));
        if (uri.queryParameters['key'] == 'bad') {
          return 403;
        }
        if (uri.queryParameters['key'] == 'quota') {
          return 429;
        }
        return 200;
      },
    );

    await tester.testKey('good-enough-key-value-xx');
    expect(
      () => tester.testKey('bad'),
      throwsA(isA<AppFailure>().having((e) => e.code, 'code', 'keyInvalid')),
    );
    expect(
      () => tester.testKey('quota'),
      throwsA(isA<AppFailure>().having((e) => e.code, 'code', 'quotaExceeded')),
    );
  });

  test('controller save then delete via overrides', () async {
    final store = MemoryKeyStore();
    final container = ProviderContainer(
      overrides: [
        secureKeyStoreProvider.overrideWithValue(store),
        geminiConnectionTesterProvider.overrideWithValue(
          GeminiConnectionTester(get: (uri) async => 200),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(apiKeyControllerProvider.future);
    await container
        .read(apiKeyControllerProvider.notifier)
        .save('AIzaSyDummyKeyValue123456');
    expect(container.read(apiKeyControllerProvider).value!.hasKey, isTrue);
    await container.read(apiKeyControllerProvider.notifier).delete();
    expect(container.read(apiKeyControllerProvider).value!.hasKey, isFalse);
  });
}
