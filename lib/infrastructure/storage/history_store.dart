import '../../domain/models/dubbing_session.dart';

abstract class HistoryStore {
  Future<List<DubbingSession>> list();

  Future<DubbingSession?> getById(String id);

  Future<void> upsert(DubbingSession session);

  Future<void> delete(String id);

  Future<void> clear();
}

class MemoryHistoryStore implements HistoryStore {
  final Map<String, DubbingSession> _items = {};

  @override
  Future<List<DubbingSession>> list() async {
    final values = _items.values.toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return values;
  }

  @override
  Future<DubbingSession?> getById(String id) async => _items[id];

  @override
  Future<void> upsert(DubbingSession session) async {
    _items[session.id] = session;
  }

  @override
  Future<void> delete(String id) async {
    _items.remove(id);
  }

  @override
  Future<void> clear() async => _items.clear();
}
