import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_wiki/features/wiki/data/related_articles.dart';
import 'package:random_wiki/features/wiki/domain/wiki_article.dart';
import 'package:random_wiki/features/wiki/presentation/widgets/related_articles_section.dart';

void main() {
  test('related pages skip the current article and disambiguation', () {
    final articles = articlesFromRelatedPages(
      [
        {
          'title': '故宫',
          'extract': '故宫是明清两代的皇家宫殿，旧称紫禁城。',
          'fullurl': 'https://zh.wikipedia.org/wiki/故宫',
        },
        {
          'title': '保和殿',
          'extract': '保和殿是北京故宫外朝的三大殿之一，位于中和殿以北。',
          'thumbnail': {'source': 'https://example.com/baohe.jpg'},
          'fullurl': 'https://zh.wikipedia.org/wiki/保和殿',
        },
        {
          'title': '故宫 (消歧义)',
          'extract': '故宫可以指以下几处宫殿。',
          'pageprops': {'disambiguation': ''},
        },
        {'title': '太短', 'extract': '太短'},
      ],
      'zh',
      excludeTitle: '故宫',
      limit: 6,
    );

    expect(articles.map((article) => article.title), ['保和殿']);
    expect(articles.single.thumbnailUrl, 'https://example.com/baohe.jpg');
  });

  testWidgets('detail section lists related articles', (tester) async {
    const source = WikiArticle(
      title: '故宫',
      extract: '故宫是明清两代的皇家宫殿。',
      languageCode: 'zh',
      pageUrl: 'https://zh.wikipedia.org/wiki/故宫',
    );
    const related = WikiArticle(
      title: '保和殿',
      extract: '保和殿是北京故宫外朝的三大殿之一。',
      languageCode: 'zh',
      pageUrl: 'https://zh.wikipedia.org/wiki/保和殿',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RelatedArticlesSection(
            article: source,
            loader: (_) async => const [related],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Related articles'), findsOneWidget);
    expect(find.text('保和殿'), findsOneWidget);
  });
}
