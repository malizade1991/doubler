import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/transcript_segment.dart';
import 'transcript_manager.dart';

class TranscriptState {
  const TranscriptState({this.segments = const []});

  final List<TranscriptSegment> segments;
}

final transcriptControllerProvider =
    NotifierProvider<TranscriptController, TranscriptState>(
  TranscriptController.new,
);

class TranscriptController extends Notifier<TranscriptState> {
  TranscriptManager _manager = TranscriptManager();

  TranscriptManager get manager => _manager;

  @override
  TranscriptState build() => const TranscriptState();

  void startSession() {
    _manager = TranscriptManager();
    state = const TranscriptState();
  }

  void addSource(String text, {required bool isFinal}) {
    _manager.onSource(text, isFinal: isFinal);
    state = TranscriptState(segments: List.of(_manager.segments));
  }

  void addTranslation(String text, {required bool isFinal}) {
    _manager.onTranslation(text, isFinal: isFinal);
    state = TranscriptState(segments: List.of(_manager.segments));
  }

  String exportTxt({required String sourceLabel, required String targetLabel}) {
    return _manager.asPlainText(
      sourceLabel: sourceLabel,
      targetLabel: targetLabel,
    );
  }
}
