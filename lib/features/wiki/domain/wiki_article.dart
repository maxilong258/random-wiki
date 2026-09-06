class WikiArticle {
  const WikiArticle({
    required this.title,
    required this.extract,
    required this.languageCode,
    required this.pageUrl,
    this.description,
    this.thumbnailUrl,
  });
  final String title, extract, languageCode, pageUrl;
  final String? description, thumbnailUrl;
  String get storageKey => '$languageCode:$title';
  String get imageHeroTag => 'article-image:$storageKey';
  Map<String, dynamic> toMap() => {
    'title': title,
    'extract': extract,
    'languageCode': languageCode,
    'pageUrl': pageUrl,
    'description': description,
    'thumbnailUrl': thumbnailUrl,
  };
  factory WikiArticle.fromMap(Map<dynamic, dynamic> map) => WikiArticle(
    title: map['title'] as String,
    extract: map['extract'] as String,
    languageCode: map['languageCode'] as String,
    pageUrl: map['pageUrl'] as String,
    description: map['description'] as String?,
    thumbnailUrl: map['thumbnailUrl'] as String?,
  );
}
