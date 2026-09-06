import 'package:flutter_test/flutter_test.dart';
import 'package:random_wiki/features/wiki/domain/wiki_article.dart';

void main() {
  test('article is preserved when stored locally', () {
    const article = WikiArticle(
      title: '墨子',
      extract: '墨子是中国古代思想家。',
      languageCode: 'zh',
      pageUrl: 'https://zh.wikipedia.org/wiki/墨子',
      description: '中国古代思想家',
    );

    final restored = WikiArticle.fromMap(article.toMap());

    expect(restored.title, article.title);
    expect(restored.pageUrl, article.pageUrl);
    expect(restored.thumbnailUrl, isNull);
  });
}
