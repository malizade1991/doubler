import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/dubbing_session.dart';
import '../../../infrastructure/storage/history_store.dart';

final historyStoreProvider = Provider<HistoryStore>(
  (ref) => MemoryHistoryStore(),
);

final historyControllerProvider =
    AsyncNotifierProvider<HistoryController, List<DubbingSession>>(
  HistoryController.new,
);

class HistoryController extends AsyncNotifier<List<DubbingSession>> {
  HistoryStore get _store => ref.read(historyStoreProvider);

  @override
  Future<List<DubbingSession>> build() => _store.list();

  Future<void> save(DubbingSession session) async {
    await _store.upsert(session);
    state = AsyncData(await _store.list());
  }

  Future<void> remove(String id) async {
    await _store.delete(id);
    state = AsyncData(await _store.list());
  }

  Future<void> clearAll() async {
    await _store.clear();
    state = const AsyncData([]);
  }
}
