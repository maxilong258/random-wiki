import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../wiki/domain/wiki_article.dart';

class HistoryRepository extends ChangeNotifier {
  HistoryRepository(this._box) {
    _listenable = _box.listenable();
    _listenable.addListener(notifyListeners);
  }

  static const maxEntries = 100;
  static const _openedAt = 'openedAt';

  final Box<dynamic> _box;
  late final ValueListenable<Box<dynamic>> _listenable;

  Future<void> record(WikiArticle article) async {
    await _box.put(article.storageKey, {
      ...article.toMap(),
      _openedAt: DateTime.now().millisecondsSinceEpoch,
    });
    await _evictOldestIfNeeded();
  }

  List<WikiArticle> get all {
    final entries = _entries();
    entries.sort(_byOpenedAtDesc);
    return entries.map(WikiArticle.fromMap).toList();
  }

  List<Map<dynamic, dynamic>> _entries() =>
      _box.values.whereType<Map<dynamic, dynamic>>().toList();

  Future<void> _evictOldestIfNeeded() async {
    while (_box.length > maxEntries) {
      dynamic oldestKey;
      var oldestAt = 1 << 62;
      for (final key in _box.keys) {
        final value = _box.get(key);
        if (value is! Map) continue;
        final openedAt = value[_openedAt] as int? ?? 0;
        if (openedAt < oldestAt) {
          oldestAt = openedAt;
          oldestKey = key;
        }
      }
      if (oldestKey == null) break;
      await _box.delete(oldestKey);
    }
  }

  int _byOpenedAtDesc(Map<dynamic, dynamic> a, Map<dynamic, dynamic> b) {
    final aAt = a[_openedAt] as int? ?? 0;
    final bAt = b[_openedAt] as int? ?? 0;
    return bAt.compareTo(aAt);
  }

  @override
  void dispose() {
    _listenable.removeListener(notifyListeners);
    super.dispose();
  }
}
