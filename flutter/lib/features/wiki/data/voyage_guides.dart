import '../domain/wiki_article.dart';

const voyagePhrasebookCategories = {
  'en': 'Category:Phrasebooks',
  'de': 'Kategorie:Sprachführer',
  'es': 'Categoría:Guías de conversación',
  'fr': 'Catégorie:Guides linguistiques',
  'he': 'קטגוריה:שיחונים',
  'it': 'Categoria:Frasari',
  'ja': 'カテゴリ:会話集',
  'nl': 'Categorie:Taalgids',
  'pl': 'Kategoria:Rozmówki',
  'pt': 'Categoria:Guias de conversação',
  'ru': 'Категория:Разговорники',
  'zh': 'Category:会话手册',
};

final _phrasebookTitle = RegExp(
  r'\bphrasebooks?\b|^Sprachführer\b|^Guías? de conversación\b|^Guides? linguistiques?\b|^שיחו[ןנ]|^Frasari[oi]?\b|会話集$|^Taalgids\b|^Rozmówki\b|^Guias? de conversação\b|разговорник|会话手册|會話手冊',
  caseSensitive: false,
  unicode: true,
);
final _travelTopicTitle = RegExp(
  r'^(?:travel topics?|itineraries)(?:[ :/]|$)',
  caseSensitive: false,
);
final _cjk = RegExp(r'[\u3040-\u30ff\u3400-\u9fff\uac00-\ud7af]');
final _heading = RegExp(r'^\s*=+[^=].*=+\s*$');
final _listEntry = RegExp(r'^[^.!?。！？]{1,60}\s[-–—:]\s');
final _sentence = RegExp(r'[.!?。！？]');
final _sentenceEnd = RegExp('[.!?。！？…]["\'”’»)]*\$');
final _imageName = RegExp(r'\.(?:jpe?g|png|webp)$', caseSensitive: false);
final _excludedImage = RegExp(
  r'\b(?:flag|logo|icon|symbol|map|locator|coat.of.arms|gpx|pictogram|default|disambig)\b',
  caseSensitive: false,
);
final _genericBanner = RegExp(
  r'^File:(?:Africa|Asia|Europe|Oceania|North America|South America|Antarctica|Australia|Caribbean|New Zealand|Middle East)[ _].*banner',
  caseSensitive: false,
);

bool isVoyageDestination(Map<String, dynamic> page) {
  final title = (page['title'] as String? ?? '').trim();
  if (title.isEmpty || title.contains('|')) return false;
  final namespace = page['ns'];
  if (namespace is int && namespace != 0) return false;
  if (_phrasebookTitle.hasMatch(title) || _travelTopicTitle.hasMatch(title)) {
    return false;
  }
  final pageProps = page['pageprops'];
  if (pageProps is Map && pageProps.containsKey('disambiguation')) return false;
  final categories = page['categories'];
  if (categories is List && categories.isNotEmpty) return false;
  return true;
}

bool guideReadable(String text) {
  final value = text.trim();
  return value.length >= (_cjk.hasMatch(value) ? 20 : 40);
}

/// Wikivoyage often starts at the first heading, so the intro extract is empty.
String guideLead(String text) {
  final paragraphs = <String>[];
  final current = <String>[];
  void flush() {
    if (current.isEmpty) return;
    paragraphs.add(current.join(' '));
    current.clear();
  }

  for (final raw in text.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty || _heading.hasMatch(line) || _listEntry.hasMatch(line)) {
      flush();
      continue;
    }
    current.add(line);
  }
  flush();

  var lead = '';
  for (var paragraph in paragraphs) {
    paragraph = paragraph.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (paragraph.endsWith(':') || paragraph.endsWith('：')) {
      paragraph = paragraph.replaceFirst(RegExp(r'[^.!?。！？]*[:：]$'), '').trim();
    }
    if (paragraph.length < _leadMinimum(paragraph) ||
        !_sentence.hasMatch(paragraph)) {
      continue;
    }
    lead = lead.isEmpty ? paragraph : '$lead $paragraph';
    if (lead.length >= 300) break;
  }
  if (lead.length >= _leadMinimum(lead) && _sentenceEnd.hasMatch(lead)) {
    return lead;
  }
  return lead.replaceFirst(RegExp(r'[^.!?。！？]*$'), '').trim();
}

int _leadMinimum(String text) => _cjk.hasMatch(text) ? 25 : 60;

List<String> voyageImageCandidates(Map<String, dynamic> page) {
  final images = page['images'];
  if (images is! List) return const [];
  final names = <String>[];
  for (final image in images) {
    if (image is! Map) continue;
    final title = image['title'];
    if (title is! String || title.length > 240 || title.contains('|')) continue;
    if (!title.toLowerCase().startsWith('file:') ||
        !_imageName.hasMatch(title)) {
      continue;
    }
    final spaced = title.replaceAll('_', ' ');
    if (_excludedImage.hasMatch(spaced) || _genericBanner.hasMatch(spaced)) {
      continue;
    }
    names.add(title);
  }
  final unique = names.toSet().toList()
    ..sort((a, b) {
      final bannerA = a.toLowerCase().contains('banner') ? 1 : 0;
      final bannerB = b.toLowerCase().contains('banner') ? 1 : 0;
      return bannerB.compareTo(bannerA);
    });
  return unique.take(2).toList();
}

List<WikiArticle> articlesFromVoyagePages(
  List<Map<String, dynamic>> pages,
  String languageCode,
) {
  final articles = <WikiArticle>[];
  for (final page in pages) {
    if (!isVoyageDestination(page)) continue;
    final title = (page['title'] as String).trim();
    final extract = ((page['extract'] as String?) ?? '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (!guideReadable(extract)) continue;
    final thumbnail = page['thumbnail'];
    final source = thumbnail is Map ? thumbnail['source'] as String? : null;
    final thumbnailUrl = source?.trim();
    articles.add(
      WikiArticle(
        title: title,
        extract: extract,
        languageCode: languageCode,
        description: page['description'] as String?,
        thumbnailUrl: thumbnailUrl == null || thumbnailUrl.isEmpty
            ? null
            : thumbnailUrl,
        pageUrl:
            page['fullurl'] as String? ??
            'https://$languageCode.wikivoyage.org/wiki/${Uri.encodeComponent(title.replaceAll(' ', '_'))}',
        source: ArticleSource.wikivoyage,
      ),
    );
  }
  return articles;
}
