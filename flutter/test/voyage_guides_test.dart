import 'package:flutter_test/flutter_test.dart';
import 'package:random_wiki/features/wiki/data/voyage_guides.dart';
import 'package:random_wiki/features/wiki/domain/wiki_article.dart';

void main() {
  test('keeps a destination and drops phrasebooks and disambiguation', () {
    const kyoto = {
      'title': '京都',
      'ns': 0,
      'extract': '京都是日本的古都，寺庙和庭园很多，适合慢慢走。',
    };
    const phrasebook = {
      'title': '英语会话手册',
      'ns': 0,
      'extract': '这是一本会话手册，用来学习日常英语表达。',
    };
    const topic = {
      'title': 'Travel topics',
      'ns': 0,
      'extract': 'Travel topics collect practical advice for a journey.',
    };
    const ambiguous = {
      'title': 'Georgia',
      'ns': 0,
      'extract':
          'Georgia may refer to a country or to a state in the United States.',
      'pageprops': {'disambiguation': ''},
    };

    expect(isVoyageDestination(kyoto), isTrue);
    expect(isVoyageDestination(phrasebook), isFalse);
    expect(isVoyageDestination(topic), isFalse);
    expect(isVoyageDestination(ambiguous), isFalse);
  });

  test(
    'reads the first prose paragraph when the guide has no introduction',
    () {
      const text = '''
== 地区 ==
京都是日本著名的古都。这里的寺庙和庭园很多，很适合慢慢走。

== 城市 ==
东京 - 日本的首都。
''';

      expect(guideLead(text), '京都是日本著名的古都。这里的寺庙和庭园很多，很适合慢慢走。');
    },
  );

  test('prefers a page banner over a map or icon', () {
    final names = voyageImageCandidates({
      'images': [
        {'title': 'File:Map mag.png'},
        {'title': 'File:Aiga hotelinformation.svg'},
        {'title': 'File:Balearic Islands Wikivoyage banner.jpg'},
        {'title': 'File:Harbor.jpg'},
      ],
    });

    expect(names.first, 'File:Balearic Islands Wikivoyage banner.jpg');
    expect(names, isNot(contains('File:Map mag.png')));
  });

  test('builds a voyage card that does not collide with a Wikipedia save', () {
    final articles = articlesFromVoyagePages([
      {
        'title': '京都',
        'ns': 0,
        'extract': '京都是日本的古都，寺庙和庭园很多，适合慢慢走。',
        'description': '日本古都',
        'fullurl': 'https://zh.wikivoyage.org/wiki/京都',
        'thumbnail': {'source': 'https://upload.wikimedia.org/kyoto.jpg'},
      },
    ], 'zh');

    expect(articles, hasLength(1));
    expect(articles.single.pageUrl, 'https://zh.wikivoyage.org/wiki/京都');
    expect(articles.single.source, ArticleSource.wikivoyage);
    expect(articles.single.storageKey, 'zh:voyage:京都');
    expect(
      WikiArticle.fromMap(articles.single.toMap()).storageKey,
      'zh:voyage:京都',
    );
  });
}
