import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:random_wiki/features/wiki/data/wiki_cache.dart';
import 'package:random_wiki/features/wiki/domain/wiki_article.dart';

void main() {
  late Directory directory;
  late DateTime now;
  late WikiCache cache;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('wiki_cache_test');
    Hive.init(directory.path);
    now = DateTime(2026, 10, 20, 12);
    cache = WikiCache(
      await Hive.openBox<dynamic>('article_cache'),
      clock: () => now,
    );
  });

  tearDown(() async {
    await Hive.close();
    if (directory.existsSync()) await directory.delete(recursive: true);
  });

  test('vital titles last seven days', () async {
    final titles = [for (var index = 0; index < 500; index++) 'Title $index'];
    await cache.saveVitalTitles(3, titles);

    expect(await cache.readVitalTitles(3), titles);
    now = now.add(const Duration(days: 6, hours: 23));
    expect(await cache.readVitalTitles(3), titles);
    now = now.add(const Duration(hours: 1));
    expect(await cache.readVitalTitles(3), isNull);
  });

  test('a short vital list is not stored', () async {
    await cache.saveVitalTitles(3, const ['Only one']);
    expect(await cache.readVitalTitles(3), isNull);
  });

  test('article text lasts one day and keeps voyage separate', () async {
    const wikipedia = WikiArticle(
      title: '京都',
      extract: '京都是日本著名的古都。这里的寺庙和庭园很多，很适合慢慢走。',
      languageCode: 'zh',
      pageUrl: 'https://zh.wikipedia.org/wiki/京都',
    );
    const voyage = WikiArticle(
      title: '京都',
      extract: '京都是适合慢慢走的古都，寺庙和庭园都很多。',
      languageCode: 'zh',
      pageUrl: 'https://zh.wikivoyage.org/wiki/京都',
      source: ArticleSource.wikivoyage,
    );
    await cache.saveArticles(const [wikipedia, voyage]);

    final wikipediaHit = await cache.readArticles(
      'zh',
      ArticleSource.wikipedia,
      ['京都'],
    );
    final voyageHit = await cache.readArticles('zh', ArticleSource.wikivoyage, [
      '京都',
    ]);
    expect(wikipediaHit['京都']?.pageUrl, wikipedia.pageUrl);
    expect(voyageHit['京都']?.pageUrl, voyage.pageUrl);

    now = now.add(const Duration(days: 1));
    expect(
      await cache.readArticles('zh', ArticleSource.wikipedia, ['京都']),
      isEmpty,
    );
  });

  test('a failed random batch can be reused for one day', () async {
    const article = WikiArticle(
      title: '蘑菇',
      extract: '蘑菇是一类真菌的子实体，很多种类可以食用，也有种类有毒。',
      languageCode: 'zh',
      pageUrl: 'https://zh.wikipedia.org/wiki/蘑菇',
    );
    await cache.saveBatch('zh', 'obscure', const [article]);

    expect((await cache.readBatch('zh', 'obscure')).single.title, '蘑菇');
    now = now.add(const Duration(days: 1));
    expect(await cache.readBatch('zh', 'obscure'), isEmpty);
  });

  test('on this day is kept only for that date', () async {
    const article = WikiArticle(
      title: '故宫',
      extract: '故宫是明清两代的皇宫，今天是故宫博物院。',
      languageCode: 'zh',
      pageUrl: 'https://zh.wikipedia.org/wiki/故宫',
    );
    await cache.saveOnThisDay('zh', now, const [article]);
    await cache.saveOnThisDay('en', now.subtract(const Duration(days: 1)), [
      article,
    ]);

    expect((await cache.readOnThisDay('zh', now))?.single.title, '故宫');
    now = now.add(const Duration(days: 1));
    expect(await cache.readOnThisDay('zh', now), isNull);

    await cache.prune();
    expect(await cache.readOnThisDay('en', DateTime(2026, 10, 19)), isNull);
  });
}
