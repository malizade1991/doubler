import 'package:doubler/domain/models/dubbing_session.dart';
import 'package:doubler/domain/models/transcript_segment.dart';
import 'package:doubler/features/history/application/history_controller.dart';
import 'package:doubler/infrastructure/storage/history_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('history store lists newest first and deletes', () async {
    final store = MemoryHistoryStore();
    final older = DubbingSession(
      id: '1',
      startedAt: DateTime(2026, 1, 1),
      sourceLanguage: 'en-US',
      targetLanguage: 'fa-IR',
      duration: const Duration(seconds: 10),
      transcript: const [
        TranscriptSegment(
          id: 'a',
          start: Duration.zero,
          sourceText: 'Hi',
          translatedText: 'سلام',
        ),
      ],
      status: SessionStatus.completed,
    );
    final newer = DubbingSession(
      id: '2',
      startedAt: DateTime(2026, 2, 1),
      sourceLanguage: 'en-US',
      targetLanguage: 'fa-IR',
      duration: const Duration(seconds: 5),
      transcript: const [],
      status: SessionStatus.completed,
    );
    await store.upsert(older);
    await store.upsert(newer);
    final list = await store.list();
    expect(list.first.id, '2');
    await store.delete('2');
    expect(await store.list(), hasLength(1));
  });

  test('history controller save and remove', () async {
    final store = MemoryHistoryStore();
    final container = ProviderContainer(
      overrides: [historyStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    await container.read(historyControllerProvider.future);
    await container.read(historyControllerProvider.notifier).save(
          DubbingSession(
            id: 'x',
            startedAt: DateTime.now(),
            sourceLanguage: 'auto',
            targetLanguage: 'fa-IR',
            duration: Duration.zero,
            transcript: const [],
            status: SessionStatus.completed,
          ),
        );
    expect(container.read(historyControllerProvider).value, hasLength(1));
    await container.read(historyControllerProvider.notifier).remove('x');
    expect(container.read(historyControllerProvider).value, isEmpty);
  });
}
