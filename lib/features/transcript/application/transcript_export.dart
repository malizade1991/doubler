import 'dart:convert';

import '../../../domain/models/transcript_segment.dart';

enum ExportKind { txt, srt, json }

abstract final class TranscriptExport {
  static String formatSrtTime(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$h:$m:$s,$ms';
  }

  static String srt(
    List<TranscriptSegment> segments, {
    bool bilingual = true,
  }) {
    final buf = StringBuffer();
    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final end = seg.end ?? seg.start + const Duration(seconds: 3);
      buf.writeln('${i + 1}');
      buf.writeln('${formatSrtTime(seg.start)} --> ${formatSrtTime(end)}');
      if (bilingual) {
        if (seg.sourceText.isNotEmpty) {
          buf.writeln(seg.sourceText);
        }
        if (seg.translatedText.isNotEmpty) {
          buf.writeln(seg.translatedText);
        }
      } else {
        buf.writeln(
          seg.translatedText.isNotEmpty ? seg.translatedText : seg.sourceText,
        );
      }
      buf.writeln();
    }
    return buf.toString();
  }

  static String jsonDoc(List<TranscriptSegment> segments) {
    return const JsonEncoder.withIndent('  ').convert([
      for (final s in segments)
        {
          'id': s.id,
          'startMs': s.start.inMilliseconds,
          'endMs': (s.end ?? s.start).inMilliseconds,
          'source': s.sourceText,
          'translated': s.translatedText,
        },
    ]);
  }

  static String txt(
    List<TranscriptSegment> segments, {
    required String sourceLabel,
    required String targetLabel,
    bool bilingual = true,
  }) {
    final buf = StringBuffer();
    for (final s in segments) {
      buf.writeln(s.timestampLabel);
      if (bilingual) {
        buf.writeln('$sourceLabel:');
        buf.writeln(s.sourceText);
        buf.writeln('$targetLabel:');
        buf.writeln(s.translatedText);
      } else {
        buf.writeln(s.translatedText.isNotEmpty ? s.translatedText : s.sourceText);
      }
      buf.writeln();
    }
    return buf.toString();
  }
}
