import 'package:doubler/features/transcript/application/transcript_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('segments keep timestamp source and translation', () {
    final manager = TranscriptManager(
      startedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
    manager.onSource('Hello world', isFinal: true);
    manager.onTranslation('سلام دنیا', isFinal: true);

    expect(manager.segments, hasLength(1));
    final seg = manager.segments.first;
    expect(seg.sourceText, 'Hello world');
    expect(seg.translatedText, 'سلام دنیا');
    expect(seg.timestampLabel, matches(RegExp(r'\d{2}:\d{2}\.\d{3}')));

    final txt = manager.asPlainText(
      sourceLabel: 'English',
      targetLabel: 'Persian',
    );
    expect(txt, contains('Hello world'));
    expect(txt, contains('سلام دنیا'));
  });
}
