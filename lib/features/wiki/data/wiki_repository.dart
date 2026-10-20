import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import '../domain/article_depth.dart';
import '../domain/wiki_article.dart';
import 'on_this_day.dart';
import 'related_articles.dart';

class WikiRepository {
  WikiRepository();

  final _client = http.Client();
  final _random = Random();
  final Map<int, Future<List<String>>> _vitalLoads = {};
  final Map<ArticleDepth, List<String>> _vitalPools = {};

  static const _headers = {
    'User-Agent': 'RandomWiki/1.0.4 (https://github.com/maxilong258/random-wiki)',
    'Api-User-Agent':
        'RandomWiki/1.0.4 (https://github.com/maxilong258/random-wiki)',
  };

  Future<WikiArticle> randomArticle(String languageCode) async =>
      (await randomArticles(languageCode, count: 1)).first;

  Future<List<WikiArticle>> randomArticles(
    String languageCode, {
    int count = 6,
    ArticleDepth depth = ArticleDepth.balanced,
    int skip = 0,
  }) async {
    if (articleDepthUsesVitalList(depth)) {
      final vital = await _vitalArticles(
        languageCode,
        depth: depth,
        count: count,
        skip: skip,
      );
      if (vital != null) return vital;
    }
    final fetchCount = articleDepthUsesVitalList(depth) ? depthFetchCount(count) : 20;
    final articles =
        await _fetchRandomArticles(languageCode, fetchCount, depth: depth) ??
        await _fetchRandomArticles(languageCode, fetchCount, depth: depth);
    if (articles != null && articles.isNotEmpty) return articles;
    throw Exception('Unable to load Wikipedia articles.');
  }

  Future<List<WikiArticle>?> _vitalArticles(
    String languageCode, {
    required ArticleDepth depth,
    required int count,
    required int skip,
  }) async {
    final pool = await _vitalPool(depth);
    if (pool == null) return null;
    if (skip >= pool.length) return const [];
    final english = pool.skip(skip).take(depthFetchCount(count)).toList();
    final titles = await _titlesInLanguage(english, languageCode);
    if (titles.isEmpty) return const [];
    return _fetchByTitles(languageCode, titles);
  }

  Future<List<String>?> _vitalPool(ArticleDepth depth) async {
    final cached = _vitalPools[depth];
    if (cached != null) return cached;
    final level3 = await _englishVital(3);
    if (level3.length < vitalMinimumCounts[3]!) return null;
    final List<String> pool;
    if (depth == ArticleDepth.popular) {
      pool = [...level3];
    } else {
      final level4 = await _englishVital(4);
      if (level4.length < vitalMinimumCounts[4]!) return null;
      pool = knownVitalTitles(level3, level4);
    }
    pool.shuffle(_random);
    return _vitalPools[depth] = pool;
  }

  Future<List<String>> _englishVital(int level) {
    return _vitalLoads[level] ??= _loadEnglishVital(level).then((titles) {
      if (titles.length < vitalMinimumCounts[level]!) {
        _vitalLoads.remove(level);
      }
      return titles;
    }, onError: (Object error, StackTrace stack) {
      _vitalLoads.remove(level);
      Error.throwWithStackTrace(error, stack);
    });
  }

  Future<List<String>> _loadEnglishVital(int level) async {
    final pages = level == 3 ? const [vitalLevel3Page] : vitalLevel4Pages;
    final titles = <String>{};
    for (final page in pages) {
      titles.addAll(await _articleLinks(page));
    }
    return titles.toList();
  }

  Future<List<String>> _articleLinks(String title) async {
    final titles = <String>[];
    String? continueToken;
    do {
      final payload = await _get('en.wikipedia.org', '/w/api.php', {
        'action': 'query',
        'prop': 'links',
        'titles': title,
        'redirects': '1',
        'plnamespace': '0',
        'pllimit': 'max',
        'format': 'json',
        'formatversion': '2',
        'plcontinue': ?continueToken,
      });
      final pages = payload['query']?['pages'];
      if (pages is List && pages.isNotEmpty && pages.first is Map) {
        final links = (pages.first as Map)['links'];
        if (links is List) {
          for (final link in links) {
            if (link is! Map) continue;
            final linked = link['title'];
            if (linked is String && linked.isNotEmpty && !linked.contains('|')) {
              titles.add(linked);
            }
          }
        }
      }
      final token = payload['continue'];
      continueToken = token is Map ? token['plcontinue'] as String? : null;
    } while (continueToken != null);
    return titles;
  }

  Future<List<String>> _titlesInLanguage(
    List<String> englishTitles,
    String languageCode,
  ) async {
    if (languageCode == 'en' || englishTitles.isEmpty) return englishTitles;
    final translated = <String>[];
    for (var start = 0; start < englishTitles.length; start += 40) {
      final chunk = englishTitles.skip(start).take(40).toList();
      final payload = await _get('en.wikipedia.org', '/w/api.php', {
        'action': 'query',
        'titles': chunk.join('|'),
        'prop': 'langlinks',
        'lllang': languageCode,
        'lllimit': 'max',
        'redirects': '1',
        'format': 'json',
        'formatversion': '2',
      });
      final pages = payload['query']?['pages'];
      if (pages is! List) continue;
      for (final page in pages) {
        if (page is! Map) continue;
        final links = page['langlinks'];
        if (links is! List || links.isEmpty || links.first is! Map) continue;
        final title = (links.first as Map)['title'];
        if (title is String && title.isNotEmpty && !title.contains('|')) {
          translated.add(title);
        }
      }
    }
    return translated;
  }

  Future<List<WikiArticle>> _fetchByTitles(
    String languageCode,
    List<String> titles,
  ) async {
    if (titles.isEmpty) return const [];
    final payload = await _get('$languageCode.wikipedia.org', '/w/api.php', {
      'action': 'query',
      'titles': titles.join('|'),
      ..._articleProps(limit: titles.length.clamp(1, 20)),
    });
    return _articlesFromQuery(payload, languageCode);
  }

  Future<List<WikiArticle>?> _fetchRandomArticles(
    String languageCode,
    int fetchCount, {
    required ArticleDepth depth,
  }) async {
    try {
      final payload = await _get('$languageCode.wikipedia.org', '/w/api.php', {
        'action': 'query',
        'generator': 'random',
        'grnnamespace': '0',
        'grnlimit': fetchCount.toString(),
        ..._articleProps(includePageviews: true, limit: fetchCount),
      });
      final pages = _queryPages(payload);
      await _completePageviews(languageCode, pages);
      final selected = selectByArticleDepth(
        pages,
        depth,
        languageCode,
        pageviewsOf: (page) => page['pageviews'],
      );
      final articles = _articlesFromPages(selected, languageCode);
      return articles.isEmpty ? null : articles;
    } catch (_) {
      return null;
    }
  }

  Future<void> _completePageviews(
    String languageCode,
    List<Map<String, dynamic>> pages,
  ) async {
    final missing = pages.where((page) => page['pageviews'] is! Map).toList();
    for (var start = 0; start < missing.length; start += 5) {
      final chunk = missing.skip(start).take(5).toList();
      final ids = [
        for (final page in chunk)
          if (page['pageid'] is int) page['pageid'].toString(),
      ];
      if (ids.isEmpty) continue;
      try {
        final payload = await _get('$languageCode.wikipedia.org', '/w/api.php', {
          'action': 'query',
          'pageids': ids.join('|'),
          'prop': 'pageviews',
          'pvipdays': '14',
          'format': 'json',
          'formatversion': '2',
        });
        final byId = <int, Object?>{};
        for (final page in _queryPages(payload)) {
          final id = page['pageid'];
          if (id is int) byId[id] = page['pageviews'];
        }
        for (final page in chunk) {
          final views = byId[page['pageid']];
          if (views is Map) page['pageviews'] = views;
        }
      } catch (_) {}
    }
  }

  Future<Map<String, dynamic>> _get(
    String host,
    String path,
    Map<String, String> query,
  ) async {
    final response = await _client
        .get(Uri.https(host, path, query), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Unable to load Wikipedia articles.');
    }
    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) {
      throw Exception('Unable to load Wikipedia articles.');
    }
    return payload;
  }

  List<Map<String, dynamic>> _queryPages(Map<String, dynamic> payload) {
    final pages = payload['query']?['pages'];
    if (pages is! List) return const [];
    return [
      for (final page in pages)
        if (page is Map<String, dynamic>) page,
    ];
  }

  Map<String, String> _articleProps({
    bool includePageviews = false,
    int? limit,
  }) {
    final props = <String, String>{
      'prop': includePageviews
          ? 'extracts|pageviews|pageimages|description|info|pageprops'
          : 'extracts|pageimages|description|info|pageprops',
      'exintro': '1',
      'explaintext': '1',
      'inprop': 'url',
      'piprop': 'thumbnail',
      'pithumbsize': '800',
      'ppprop': 'disambiguation',
      'format': 'json',
      'formatversion': '2',
    };
    if (limit != null) {
      props['exlimit'] = limit.toString();
      props['pilimit'] = limit.toString();
    }
    if (includePageviews) props['pvipdays'] = '14';
    return props;
  }

  List<WikiArticle> _articlesFromQuery(
    Map<String, dynamic> payload,
    String languageCode,
  ) {
    return _articlesFromPages(_queryPages(payload), languageCode);
  }

  List<WikiArticle> _articlesFromPages(
    List<Map<String, dynamic>> pages,
    String languageCode,
  ) {
    return pages
        .where((page) {
          final extract = (page['extract'] as String? ?? '').trim();
          final pageProps = page['pageprops'] as Map<String, dynamic>?;
          return extract.length >= 50 &&
              !(pageProps?.containsKey('disambiguation') ?? false);
        })
        .map((page) => _articleFromPage(page, languageCode))
        .toList();
  }

  WikiArticle _articleFromPage(
    Map<String, dynamic> page,
    String languageCode,
  ) {
    final title = (page['title'] as String? ?? '').trim();
    final thumbnail = page['thumbnail'] as Map<String, dynamic>?;
    return WikiArticle(
      title: title,
      extract: (page['extract'] as String? ?? '').trim(),
      languageCode: languageCode,
      description: page['description'] as String?,
      thumbnailUrl: thumbnail?['source'] as String?,
      pageUrl: page['fullurl'] as String? ??
          'https://$languageCode.wikipedia.org/wiki/${Uri.encodeComponent(title)}',
    );
  }

  Future<List<WikiArticle>> relatedArticles(
    String languageCode,
    String title, {
    int limit = 6,
  }) async {
    final fetchCount = (limit + 2).clamp(1, 20);
    final response = await _client
        .get(
          Uri.https('$languageCode.wikipedia.org', '/w/api.php', {
            'action': 'query',
            'generator': 'search',
            'gsrsearch': 'morelike:$title',
            'gsrlimit': fetchCount.toString(),
            'gsrnamespace': '0',
            'prop': 'extracts|pageimages|description|info|pageprops',
            'exintro': '1',
            'explaintext': '1',
            'exlimit': fetchCount.toString(),
            'inprop': 'url',
            'piprop': 'thumbnail',
            'pithumbsize': '400',
            'pilimit': fetchCount.toString(),
            'ppprop': 'disambiguation',
            'format': 'json',
            'formatversion': '2',
          }),
          headers: const {
            'User-Agent':
                'RandomWiki/1.0.4 (https://github.com/maxilong258/random-wiki)',
            'Api-User-Agent':
                'RandomWiki/1.0.4 (https://github.com/maxilong258/random-wiki)',
          },
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Unable to load related articles.');
    }
    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) {
      throw Exception('Unable to load related articles.');
    }
    final query = payload['query'];
    final pages = query is Map ? query['pages'] : null;
    return articlesFromRelatedPages(
      pages is List ? pages : const [],
      languageCode,
      excludeTitle: title.trim(),
      limit: limit,
    );
  }

  Future<List<WikiArticle>> onThisDay(String languageCode) async {
    final today = DateTime.now();
    final month = today.month.toString().padLeft(2, '0');
    final day = today.day.toString().padLeft(2, '0');
    final response = await _client
        .get(
          Uri.https(
            '$languageCode.wikipedia.org',
            '/api/rest_v1/feed/onthisday/events/$month/$day',
          ),
          headers: const {
            'User-Agent':
                'RandomWiki/1.0.4 (https://github.com/maxilong258/random-wiki)',
            'Api-User-Agent':
                'RandomWiki/1.0.4 (https://github.com/maxilong258/random-wiki)',
          },
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Unable to load on this day.');
    }
    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) {
      throw Exception('Unable to load on this day.');
    }
    return articlesFromOnThisDay(payload, languageCode, today);
  }

  void dispose() => _client.close();
}
