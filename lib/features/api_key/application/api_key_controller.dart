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

/// Outcome of a save attempt, so the UI can pick a snackbar vs. an inline
/// error and haptics.
enum ApiKeySaveResult { saved, empty, tooShort, invalid }

class ApiKeyState {
  const ApiKeyState({
    this.hasKey = false,
    this.masked,
    this.busy = false,
    this.messageCode,
    this.warningCode,
    this.kind,
  });

  final bool hasKey;
  final String? masked;
  final bool busy;
  final String? messageCode;

  /// Shown after a successful save when the key looks legacy (e.g. `AIza…`).
  final String? warningCode;

  final ApiKeyKind? kind;

  bool get hasWarning => warningCode != null;

  ApiKeyState copyWith({
    bool? hasKey,
    String? masked,
    bool? busy,
    String? messageCode,
    String? warningCode,
    ApiKeyKind? kind,
    bool clearMessage = false,
    bool clearWarning = false,
  }) {
    return ApiKeyState(
      hasKey: hasKey ?? this.hasKey,
      masked: masked ?? this.masked,
      busy: busy ?? this.busy,
      messageCode: clearMessage ? null : (messageCode ?? this.messageCode),
      warningCode: clearWarning ? null : (warningCode ?? this.warningCode),
      kind: kind ?? this.kind,
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
    return ApiKeyState(
      hasKey: true,
      masked: ApiKeyValidator.mask(key),
      kind: ApiKeyValidator.kindOf(key),
    );
  }

  /// Validates, normalises and stores the key. Invalid input is never
  /// written; it only sets an inline message.
  Future<ApiKeySaveResult> save(String raw) async {
    final result = ApiKeyValidator.validate(raw);
    if (!result.isValid) {
      state = AsyncData(
        (state.value ?? const ApiKeyState()).copyWith(
          messageCode: result.code,
          clearWarning: true,
        ),
      );
      return switch (result.code) {
        'keyEmpty' => ApiKeySaveResult.empty,
        'keyTooShort' => ApiKeySaveResult.tooShort,
        _ => ApiKeySaveResult.invalid,
      };
    }
    await _store.writeApiKey(result.normalized);
    state = AsyncData(
      ApiKeyState(
        hasKey: true,
        masked: ApiKeyValidator.mask(result.normalized),
        messageCode: 'keySaved',
        warningCode: result.warningCode,
        kind: result.kind,
      ),
    );
    return ApiKeySaveResult.saved;
  }

  Future<void> delete() async {
    await _store.deleteApiKey();
    state = const AsyncData(ApiKeyState(messageCode: 'keyDeleted'));
  }

  /// Returns the l10n code to surface (`null` when the test succeeded).
  Future<String?> testConnection() async {
    final current = state.value ?? const ApiKeyState();
    state = AsyncData(current.copyWith(busy: true, clearMessage: true));
    final key = await _store.readApiKey();
    if (key == null || key.isEmpty) {
      state = AsyncData(
        current.copyWith(busy: false, messageCode: 'keyMissing'),
      );
      return 'keyMissing';
    }
    try {
      await _tester.testKey(key);
      state = AsyncData(
        current.copyWith(
          busy: false,
          hasKey: true,
          messageCode: 'connectionOk',
          kind: ApiKeyValidator.kindOf(key),
        ),
      );
      return null;
    } on AppFailure catch (e) {
      // A quota error still proves the key itself is valid.
      final keyAccepted = e.code == 'connectionOkQuota';
      state = AsyncData(
        current.copyWith(
          busy: false,
          hasKey: true,
          messageCode: e.code,
          kind: ApiKeyValidator.kindOf(key),
        ),
      );
      return keyAccepted ? null : e.code;
    } on Object {
      state = AsyncData(
        current.copyWith(busy: false, messageCode: 'geminiUnavailable'),
      );
      return 'geminiUnavailable';
    }
  }
}
