import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../domain/wiki_article.dart';

class WikiRepository {
  WikiRepository(this._cache);

  final Box<dynamic> _cache;
  final _client = http.Client();

  Future<WikiArticle> randomArticle(String languageCode) async =>
      (await randomArticles(languageCode, count: 1)).first;

  Future<List<WikiArticle>> randomArticles(
    String languageCode, {
    int count = 6,
  }) async {
    // Ask for extras so stubs/disambiguation do not trigger another round trip.
    // extracts/pageimages cap at 20 per request.
    final fetchCount = (count + 4).clamp(1, 20);
    final articles = await _fetchRandomArticles(languageCode, fetchCount) ??
        await _fetchRandomArticles(languageCode, fetchCount);
    if (articles != null && articles.isNotEmpty) {
      await _cache.put(
        'batch_$languageCode',
        articles.map((article) => article.toMap()).toList(),
      );
      return articles;
    }
    final cached = _cache.get('batch_$languageCode');
    if (cached is List) {
      final articles = cached
          .whereType<Map>()
          .map(WikiArticle.fromMap)
          .toList();
      if (articles.isNotEmpty) return articles;
    }
    throw Exception('Unable to load Wikipedia articles.');
  }

  Future<List<WikiArticle>?> _fetchRandomArticles(
    String languageCode,
    int fetchCount,
  ) async {
    try {
      final response = await _client
          .get(
            Uri.https('$languageCode.wikipedia.org', '/w/api.php', {
              'action': 'query',
              'generator': 'random',
              'grnnamespace': '0',
              'grnlimit': fetchCount.toString(),
              'prop': 'extracts|pageimages|description|info|pageprops',
              'exintro': '1',
              'explaintext': '1',
              'exlimit': fetchCount.toString(),
              'inprop': 'url',
              'piprop': 'thumbnail',
              'pithumbsize': '800',
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
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final query = json['query'] as Map<String, dynamic>?;
      final pages = query?['pages'] as List<dynamic>? ?? const [];
      final articles = pages
          .whereType<Map<String, dynamic>>()
          .where((page) {
            final extract = (page['extract'] as String? ?? '').trim();
            final pageProps = page['pageprops'] as Map<String, dynamic>?;
            return extract.length >= 50 &&
                !(pageProps?.containsKey('disambiguation') ?? false);
          })
          .map((page) => _articleFromPage(page, languageCode))
          .toList();
      return articles.isEmpty ? null : articles;
    } catch (_) {
      return null;
    }
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

  void dispose() => _client.close();
}
