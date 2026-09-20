import 'transcript_segment.dart';

enum SessionStatus { completed, error, interrupted }

class DubbingSession {
  const DubbingSession({
    required this.id,
    required this.startedAt,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.duration,
    required this.transcript,
    required this.status,
  });

  final String id;
  final DateTime startedAt;
  final String sourceLanguage;
  final String targetLanguage;
  final Duration duration;
  final List<TranscriptSegment> transcript;
  final SessionStatus status;
}
