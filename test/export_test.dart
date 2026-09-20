import 'package:doubler/domain/models/transcript_segment.dart';
import 'package:doubler/features/transcript/application/transcript_export.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const segments = [
    TranscriptSegment(
      id: '1',
      start: Duration(milliseconds: 4250),
      end: Duration(milliseconds: 8700),
      sourceText: 'Hello',
      translatedText: 'سلام',
    ),
  ];

  test('SRT timestamps use comma milliseconds', () {
    expect(
      TranscriptExport.formatSrtTime(const Duration(milliseconds: 4250)),
      '00:00:04,250',
    );
    final srt = TranscriptExport.srt(segments);
    expect(srt, contains('00:00:04,250 --> 00:00:08,700'));
    expect(srt, contains('Hello'));
    expect(srt, contains('سلام'));
  });

  test('JSON includes bilingual fields', () {
    final json = TranscriptExport.jsonDoc(segments);
    expect(json, contains('"source": "Hello"'));
    expect(json, contains('"translated": "سلام"'));
  });
}
