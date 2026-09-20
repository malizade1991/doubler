import '../../../domain/models/transcript_segment.dart';

class TranscriptManager {
  TranscriptManager({DateTime? startedAt}) : startedAt = startedAt ?? DateTime.now();

  final DateTime startedAt;
  final List<TranscriptSegment> segments = [];
  int _seq = 0;
  String? _openId;

  Duration get _elapsed => DateTime.now().difference(startedAt);

  void onSource(String text, {required bool isFinal}) {
    if (text.trim().isEmpty) {
      return;
    }
    if (_openId == null) {
      _seq += 1;
      final id = 'seg-$_seq';
      _openId = id;
      segments.add(
        TranscriptSegment(
          id: id,
          start: _elapsed,
          sourceText: text,
          translatedText: '',
        ),
      );
      return;
    }
    _updateOpen(sourceText: text, close: isFinal && _openHasTranslation);
  }

  void onTranslation(String text, {required bool isFinal}) {
    if (text.trim().isEmpty) {
      return;
    }
    if (_openId == null) {
      onSource('', isFinal: false);
      if (_openId == null) {
        _seq += 1;
        _openId = 'seg-$_seq';
        segments.add(
          TranscriptSegment(
            id: _openId!,
            start: _elapsed,
            sourceText: '',
            translatedText: text,
          ),
        );
      }
    }
    _updateOpen(translatedText: text, close: isFinal);
  }

  bool get _openHasTranslation {
    if (_openId == null) {
      return false;
    }
    return segments.last.translatedText.isNotEmpty;
  }

  void _updateOpen({
    String? sourceText,
    String? translatedText,
    required bool close,
  }) {
    if (segments.isEmpty) {
      return;
    }
    final last = segments.last;
    segments[segments.length - 1] = last.copyWith(
      sourceText: sourceText,
      translatedText: translatedText,
      end: close ? _elapsed : last.end,
    );
    if (close) {
      _openId = null;
    }
  }

  String asPlainText({
    required String sourceLabel,
    required String targetLabel,
  }) {
    final buf = StringBuffer();
    for (final s in segments) {
      buf.writeln(s.timestampLabel);
      buf.writeln('$sourceLabel:');
      buf.writeln(s.sourceText);
      buf.writeln('$targetLabel:');
      buf.writeln(s.translatedText);
      buf.writeln();
    }
    return buf.toString();
  }

  void clear() {
    segments.clear();
    _openId = null;
    _seq = 0;
  }
}
