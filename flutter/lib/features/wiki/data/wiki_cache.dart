import 'package:hive_flutter/hive_flutter.dart';
import '../domain/article_depth.dart';
import '../domain/wiki_article.dart';

class WikiCache {
  WikiCache(this._box, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final Box<dynamic> _box;
  final DateTime Function() _clock;

  static const vitalTtl = Duration(days: 7);
  static const articleTtl = Duration(days: 1);
  static const batchTtl = Duration(days: 1);
  static const voyageSlot = 'voyage';

  Future<List<String>?> readVitalTitles(int level) async {
    final key = 'vital:$level';
    final value = _box.get(key);
    final titles = value is Map ? value['titles'] : null;
    if (value is! Map ||
        !_fresh(value['savedAt'], vitalTtl) ||
        titles is! List) {
      await _box.delete(key);
      return null;
    }
    final stored = [
      for (final title in titles)
        if (title is String && title.isNotEmpty) title,
    ];
    return stored.isEmpty ? null : stored;
  }

  Future<void> saveVitalTitles(int level, List<String> titles) async {
    if (titles.length < (vitalMinimumCounts[level] ?? 1)) return;
    await _box.put('vital:$level', {
      'savedAt': _clock().millisecondsSinceEpoch,
      'titles': titles,
    });
  }

  Future<Map<String, WikiArticle>> readArticles(
    String languageCode,
    ArticleSource source,
    Iterable<String> titles,
  ) async {
    final found = <String, WikiArticle>{};
    for (final title in titles) {
      final key = _articleKey(languageCode, source, title);
      final value = _box.get(key);
      final raw = value is Map ? value['article'] : null;
      if (value is! Map ||
          !_fresh(value['savedAt'], articleTtl) ||
          raw is! Map) {
        await _box.delete(key);
        continue;
      }
      final article = WikiArticle.fromMap(raw);
      if (article.title != title || article.languageCode != languageCode) {
        await _box.delete(key);
        continue;
      }
      found[title] = article;
    }
    return found;
  }

  Future<void> saveArticles(List<WikiArticle> articles) async {
    if (articles.isEmpty) return;
    final savedAt = _clock().millisecondsSinceEpoch;
    await _box.putAll({
      for (final article in articles)
        _articleKey(article.languageCode, article.source, article.title): {
          'savedAt': savedAt,
          'article': article.toMap(),
        },
    });
  }

  Future<List<WikiArticle>> readBatch(String languageCode, String slot) async {
    final key = 'batch:$languageCode:$slot';
    final value = _box.get(key);
    if (value is! Map || !_fresh(value['savedAt'], batchTtl)) {
      await _box.delete(key);
      return const [];
    }
    return _articlesOf(value['articles']);
  }

  Future<void> saveBatch(
    String languageCode,
    String slot,
    List<WikiArticle> articles,
  ) async {
    if (articles.isEmpty) return;
    await _box.put('batch:$languageCode:$slot', {
      'savedAt': _clock().millisecondsSinceEpoch,
      'articles': [for (final article in articles) article.toMap()],
    });
  }

  Future<List<WikiArticle>?> readOnThisDay(
    String languageCode,
    DateTime day,
  ) async {
    final value = _box.get(_dayKey(languageCode, day));
    if (value is! Map) return null;
    final articles = _articlesOf(value['articles']);
    return articles.isEmpty ? null : articles;
  }

  Future<void> saveOnThisDay(
    String languageCode,
    DateTime day,
    List<WikiArticle> articles,
  ) async {
    if (articles.isEmpty) return;
    final key = _dayKey(languageCode, day);
    final prefix = 'day:$languageCode:';
    final older = [
      for (final stored in _box.keys)
        if (stored is String && stored.startsWith(prefix) && stored != key)
          stored,
    ];
    if (older.isNotEmpty) await _box.deleteAll(older);
    await _box.put(key, {
      'articles': [for (final article in articles) article.toMap()],
    });
  }

  Future<void> prune() async {
    final today = _dayStamp(_clock());
    final stale = <dynamic>[];
    for (final key in _box.keys) {
      if (key is! String) {
        stale.add(key);
        continue;
      }
      final value = _box.get(key);
      if (key.startsWith('day:')) {
        if (!key.endsWith(today)) stale.add(key);
        continue;
      }
      final ttl = _ttlFor(key);
      if (ttl == null) continue;
      if (value is! Map || !_fresh(value['savedAt'], ttl)) stale.add(key);
    }
    if (stale.isNotEmpty) await _box.deleteAll(stale);
  }

  bool _fresh(Object? savedAt, Duration ttl) {
    if (savedAt is! int) return false;
    final age = _clock().difference(
      DateTime.fromMillisecondsSinceEpoch(savedAt),
    );
    return age >= Duration.zero && age < ttl;
  }

  Duration? _ttlFor(String key) {
    if (key.startsWith('vital:')) return vitalTtl;
    if (key.startsWith('article:') || key.startsWith('batch:')) {
      return articleTtl;
    }
    return null;
  }

  String _articleKey(String languageCode, ArticleSource source, String title) {
    final storage = switch (source) {
      ArticleSource.wikipedia => '$languageCode:$title',
      ArticleSource.wikivoyage => '$languageCode:voyage:$title',
    };
    return 'article:$storage';
  }

  String _dayKey(String languageCode, DateTime day) =>
      'day:$languageCode:${_dayStamp(day)}';

  String _dayStamp(DateTime day) {
    final year = day.year.toString().padLeft(4, '0');
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '$year-$month-$date';
  }

  List<WikiArticle> _articlesOf(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map) WikiArticle.fromMap(item),
    ];
  }
}
