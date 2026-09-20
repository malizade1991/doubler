/// Domain-level failure. UI maps [code] via l10n in later phases.
class AppFailure implements Exception {
  const AppFailure({
    required this.code,
    this.message,
  });

  final String code;
  final String? message;

  @override
  String toString() => 'AppFailure($code)';
}
