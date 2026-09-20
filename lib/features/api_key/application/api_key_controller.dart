import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../infrastructure/gemini/gemini_connection_tester.dart';
import '../../../infrastructure/storage/secure_key_store.dart';
import '../domain/api_key_validator.dart';

final secureKeyStoreProvider = Provider<SecureKeyStore>(
  (ref) => PlatformKeyStore(),
);

final geminiConnectionTesterProvider = Provider<GeminiConnectionTester>(
  (ref) => GeminiConnectionTester(),
);

class ApiKeyState {
  const ApiKeyState({
    this.hasKey = false,
    this.masked,
    this.busy = false,
    this.messageCode,
  });

  final bool hasKey;
  final String? masked;
  final bool busy;
  final String? messageCode;

  ApiKeyState copyWith({
    bool? hasKey,
    String? masked,
    bool? busy,
    String? messageCode,
    bool clearMessage = false,
  }) {
    return ApiKeyState(
      hasKey: hasKey ?? this.hasKey,
      masked: masked ?? this.masked,
      busy: busy ?? this.busy,
      messageCode: clearMessage ? null : (messageCode ?? this.messageCode),
    );
  }
}

final apiKeyControllerProvider =
    AsyncNotifierProvider<ApiKeyController, ApiKeyState>(ApiKeyController.new);

class ApiKeyController extends AsyncNotifier<ApiKeyState> {
  SecureKeyStore get _store => ref.read(secureKeyStoreProvider);

  GeminiConnectionTester get _tester =>
      ref.read(geminiConnectionTesterProvider);

  @override
  Future<ApiKeyState> build() async {
    final key = await _store.readApiKey();
    if (key == null || key.isEmpty) {
      return const ApiKeyState();
    }
    return ApiKeyState(hasKey: true, masked: ApiKeyValidator.mask(key));
  }

  Future<void> save(String raw) async {
    final result = ApiKeyValidator.validate(raw);
    if (!result.isValid) {
      state = AsyncData(
        (state.value ?? const ApiKeyState()).copyWith(
          messageCode: result.code,
        ),
      );
      return;
    }
    await _store.writeApiKey(raw.trim());
    state = AsyncData(
      ApiKeyState(
        hasKey: true,
        masked: ApiKeyValidator.mask(raw.trim()),
        messageCode: 'keySaved',
      ),
    );
  }

  Future<void> delete() async {
    await _store.deleteApiKey();
    state = const AsyncData(ApiKeyState(messageCode: 'keyDeleted'));
  }

  Future<void> testConnection() async {
    final current = state.value ?? const ApiKeyState();
    state = AsyncData(current.copyWith(busy: true, clearMessage: true));
    final key = await _store.readApiKey();
    if (key == null || key.isEmpty) {
      state = AsyncData(current.copyWith(busy: false, messageCode: 'keyMissing'));
      return;
    }
    try {
      await _tester.testKey(key);
      state = AsyncData(
        current.copyWith(busy: false, hasKey: true, messageCode: 'connectionOk'),
      );
    } on AppFailure catch (e) {
      state = AsyncData(current.copyWith(busy: false, messageCode: e.code));
    }
  }
}
