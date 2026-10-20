enum ArticleSource { wikipedia, wikivoyage }

class WikiArticle {
  const WikiArticle({
    required this.title,
    required this.extract,
    required this.languageCode,
    required this.pageUrl,
    this.description,
    this.thumbnailUrl,
    this.source = ArticleSource.wikipedia,
  });
  final String title, extract, languageCode, pageUrl;
  final String? description, thumbnailUrl;
  final ArticleSource source;
  String get storageKey => switch (source) {
    ArticleSource.wikipedia => '$languageCode:$title',
    ArticleSource.wikivoyage => '$languageCode:voyage:$title',
  };
  String get imageHeroTag => 'article-image:$storageKey';
  Map<String, dynamic> toMap() => {
    'title': title,
    'extract': extract,
    'languageCode': languageCode,
    'pageUrl': pageUrl,
    'description': description,
    'thumbnailUrl': thumbnailUrl,
    'source': source.name,
  };
  factory WikiArticle.fromMap(Map<dynamic, dynamic> map) {
    final stored = map['source'];
    final url = map['pageUrl'];
    final source = stored is String
        ? ArticleSource.values.asNameMap()[stored] ?? ArticleSource.wikipedia
        : url is String && url.contains('wikivoyage.org')
        ? ArticleSource.wikivoyage
        : ArticleSource.wikipedia;
    return WikiArticle(
      title: map['title'] as String,
      extract: map['extract'] as String,
      languageCode: map['languageCode'] as String,
      pageUrl: map['pageUrl'] as String,
      description: map['description'] as String?,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      source: source,
    );
  }
}
