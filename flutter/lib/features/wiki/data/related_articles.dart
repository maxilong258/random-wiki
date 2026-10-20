import '../domain/wiki_article.dart';

List<WikiArticle> articlesFromRelatedPages(
  List<dynamic> pages,
  String languageCode, {
  required String excludeTitle,
  int limit = 6,
}) {
  final articles = <WikiArticle>[];
  for (final page in pages.whereType<Map>()) {
    final article = _articleFromPage(
      Map<String, dynamic>.from(page),
      languageCode,
    );
    if (article == null || article.title == excludeTitle) continue;
    articles.add(article);
    if (articles.length >= limit) break;
  }
  return articles;
}

WikiArticle? _articleFromPage(Map<String, dynamic> page, String languageCode) {
  final title = (page['title'] as String? ?? '').trim();
  final extract = (page['extract'] as String? ?? '').trim();
  final pageProps = page['pageprops'];
  if (title.isEmpty || extract.length < 20) return null;
  if (pageProps is Map && pageProps.containsKey('disambiguation')) return null;
  final thumbnail = page['thumbnail'];
  final source = thumbnail is Map ? thumbnail['source'] as String? : null;
  return WikiArticle(
    title: title,
    extract: extract,
    languageCode: languageCode,
    description: page['description'] as String?,
    thumbnailUrl: source?.trim().isEmpty ?? true ? null : source!.trim(),
    pageUrl: page['fullurl'] as String? ??
        'https://$languageCode.wikipedia.org/wiki/${Uri.encodeComponent(title)}',
  );
}
