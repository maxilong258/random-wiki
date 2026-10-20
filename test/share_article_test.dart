import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_wiki/features/wiki/domain/wiki_article.dart';
import 'package:random_wiki/features/wiki/presentation/share_article.dart';
import 'package:random_wiki/features/wiki/presentation/widgets/article_content.dart';

void main() {
  const article = WikiArticle(
    title: '故宫',
    extract: '故宫是明清两代的皇家宫殿，旧称紫禁城，位于北京中轴线的中心。',
    languageCode: 'zh',
    pageUrl: 'https://zh.wikipedia.org/wiki/故宫',
  );

  test('share text includes the title and page link', () {
    expect(
      articleShareText(article),
      '故宫\nhttps://zh.wikipedia.org/wiki/故宫',
    );
  });

  testWidgets('share sits beside more on the feed card', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ArticleContent(
            article: article,
            paged: true,
            onOpenDetail: () {},
          ),
        ),
      ),
    );

    expect(find.text('More'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
  });

  testWidgets('share sits beside the wiki button on the detail page', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ArticleContent(article: article))),
    );

    expect(find.text('Wiki page'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
  });
}
