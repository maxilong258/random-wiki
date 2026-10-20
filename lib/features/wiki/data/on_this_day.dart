import '../domain/wiki_article.dart';

List<WikiArticle> articlesFromOnThisDay(
  Map<String, dynamic> payload,
  String languageCode,
  DateTime today,
) {
  final events = payload['events'];
  if (events is! List) return const [];
  final rows = events.whereType<Map>().map(Map<String, dynamic>.from).toList()
    ..sort((a, b) => _year(b).compareTo(_year(a)));
  final articles = <WikiArticle>[];
  for (final event in rows) {
    final article = _articleFromEvent(event, languageCode, today);
    if (article != null) articles.add(article);
  }
  return articles;
}

WikiArticle? _articleFromEvent(
  Map<String, dynamic> event,
  String languageCode,
  DateTime today,
) {
  final text = (event['text'] as String? ?? '').trim();
  final page = _pickPage(event['pages']);
  final title = (page?['title'] as String? ?? '').trim();
  if (text.isEmpty || title.isEmpty) return null;
  final year = _year(event);
  return WikiArticle(
    title: title,
    extract: text,
    languageCode: languageCode,
    pageUrl: _pageUrl(page!, languageCode, title),
    description: _eyebrow(languageCode, year, today.year - year),
    thumbnailUrl: _thumbnail(page),
  );
}

Map<String, dynamic>? _pickPage(Object? pages) {
  if (pages is! List) return null;
  final standard = <Map<String, dynamic>>[];
  for (final page in pages) {
    if (page is! Map) continue;
    final map = Map<String, dynamic>.from(page);
    final namespace = map['namespace'];
    final id = namespace is Map ? namespace['id'] : null;
    if (id != null && id != 0) continue;
    final title = (map['title'] as String? ?? '').trim();
    if (title.isEmpty) continue;
    standard.add(map);
  }
  if (standard.isEmpty) return null;
  final topical = standard.where((page) {
    final title = page['title'] as String;
    return !RegExp(r'^\d{1,4}年?$').hasMatch(title);
  }).toList();
  final pool = topical.isNotEmpty ? topical : standard;
  for (final page in pool) {
    if (page['thumbnail'] is Map) return page;
  }
  return pool.first;
}

int _year(Map<String, dynamic> event) {
  final year = event['year'];
  if (year is int) return year;
  return int.tryParse('$year') ?? 0;
}

String _eyebrow(String languageCode, int year, int yearsAgo) {
  final chinese = languageCode.startsWith('zh');
  if (yearsAgo <= 0) return chinese ? '$year · 今年' : '$year · This year';
  if (!chinese && yearsAgo == 1) return '$year · 1 year ago';
  return chinese ? '$year · $yearsAgo年前' : '$year · $yearsAgo years ago';
}

String? _thumbnail(Map<String, dynamic> page) {
  final thumbnail = page['thumbnail'];
  if (thumbnail is Map && thumbnail['source'] is String) {
    final source = (thumbnail['source'] as String).trim();
    if (source.isNotEmpty) return source;
  }
  return null;
}

String _pageUrl(Map<String, dynamic> page, String languageCode, String title) {
  final urls = page['content_urls'];
  if (urls is Map) {
    final desktop = urls['desktop'];
    if (desktop is Map && desktop['page'] is String) {
      final url = (desktop['page'] as String).trim();
      if (url.isNotEmpty) return url;
    }
  }
  return 'https://$languageCode.wikipedia.org/wiki/${Uri.encodeComponent(title)}';
}
