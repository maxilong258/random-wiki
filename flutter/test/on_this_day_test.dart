import 'package:flutter_test/flutter_test.dart';
import 'package:random_wiki/features/wiki/data/on_this_day.dart';

void main() {
  test('on this day prefers the topical page and keeps the event text', () {
    final articles = articlesFromOnThisDay(
      {
        'events': [
          {
            'year': 1548,
            'text': '玻利维亚首都拉巴斯建成。',
            'pages': [
              {
                'title': '1548年',
                'namespace': {'id': 0},
                'content_urls': {
                  'desktop': {'page': 'https://zh.wikipedia.org/wiki/1548年'},
                },
              },
              {
                'title': '拉巴斯',
                'namespace': {'id': 0},
                'thumbnail': {'source': 'https://example.com/la-paz.jpg'},
                'content_urls': {
                  'desktop': {'page': 'https://zh.wikipedia.org/wiki/拉巴斯'},
                },
              },
            ],
          },
          {
            'year': 2020,
            'text': '较近的事件。',
            'pages': [
              {
                'title': '示例',
                'namespace': {'id': 0},
                'content_urls': {
                  'desktop': {'page': 'https://zh.wikipedia.org/wiki/示例'},
                },
              },
            ],
          },
        ],
      },
      'zh',
      DateTime(2026, 10, 20),
    );

    expect(articles.map((article) => article.title), ['示例', '拉巴斯']);
    expect(articles.last.description, '1548 · 478年前');
    expect(articles.last.extract, '玻利维亚首都拉巴斯建成。');
    expect(articles.last.thumbnailUrl, 'https://example.com/la-paz.jpg');
    expect(articles.last.pageUrl, 'https://zh.wikipedia.org/wiki/拉巴斯');
  });

  test('english events use a years-ago label', () {
    final articles = articlesFromOnThisDay(
      {
        'events': [
          {
            'year': 1776,
            'text': 'The Declaration of Independence was adopted.',
            'pages': [
              {'title': '1776', 'namespace': {'id': 0}},
              {
                'title': 'United States Declaration of Independence',
                'namespace': {'id': 0},
              },
            ],
          },
        ],
      },
      'en',
      DateTime(2026, 10, 20),
    );

    expect(articles.single.title, 'United States Declaration of Independence');
    expect(articles.single.description, '1776 · 250 years ago');
    expect(
      articles.single.pageUrl,
      'https://en.wikipedia.org/wiki/United%20States%20Declaration%20of%20Independence',
    );
  });
}
