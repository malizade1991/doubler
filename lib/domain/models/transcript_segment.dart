class TranscriptSegment {
  const TranscriptSegment({
    required this.id,
    required this.start,
    required this.sourceText,
    required this.translatedText,
    this.end,
  });

  final String id;
  final Duration start;
  final Duration? end;
  final String sourceText;
  final String translatedText;

  TranscriptSegment copyWith({
    Duration? end,
    String? sourceText,
    String? translatedText,
  }) {
    return TranscriptSegment(
      id: id,
      start: start,
      end: end ?? this.end,
      sourceText: sourceText ?? this.sourceText,
      translatedText: translatedText ?? this.translatedText,
    );
  }

  String get timestampLabel {
    final ms = start.inMilliseconds;
    final m = (ms ~/ 60000).toString().padLeft(2, '0');
    final s = ((ms % 60000) ~/ 1000).toString().padLeft(2, '0');
    final frac = (ms % 1000).toString().padLeft(3, '0');
    return '$m:$s.$frac';
  }
}
