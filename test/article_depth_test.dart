import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_wiki/features/settings/presentation/article_depth_control.dart';
import 'package:random_wiki/features/wiki/domain/article_depth.dart';

void main() {
  test('known vital articles leave out the essential list', () {
    expect(
      knownVitalTitles(['Earth', 'Moon'], ['Earth', 'Chess', 'Moon']),
      ['Chess'],
    );
  });

  test('daily view bands match WikiScroll and scale Chinese down', () {
    expect(depthDailyViewBand(ArticleDepth.obscure, 'en'), (0, 2));
    expect(depthDailyViewBand(ArticleDepth.niche, 'en'), (2, 30));
    expect(depthDailyViewBand(ArticleDepth.balanced, 'en').$1, 10);
    expect(depthDailyViewBand(ArticleDepth.obscure, 'zh'), (0, 0.4));
    expect(depthDailyViewBand(ArticleDepth.balanced, 'zh').$1, 2);
  });

  test('missing pageviews stay unknown and lag days are not zeros', () {
    final pages = [
      {'id': 'low', 'pageviews': {'d1': 1, 'd2': null}},
      {'id': 'quiet', 'pageviews': {'d1': 0, 'd2': null}},
      {'id': 'unknown'},
    ];
    final selected = selectByArticleDepth(
      pages,
      ArticleDepth.obscure,
      'en',
      pageviewsOf: (page) => page['pageviews'],
    );

    expect(selected.map((page) => page['id']), ['low', 'quiet']);
    expect(
      averageDailyViews({'d1': 10, 'd2': null}, {'d2'}),
      10,
    );
  });

  test('balanced keeps a near miss when few pages clear the floor', () {
    final pages = [
      for (var index = 0; index < 4; index++)
        {'id': 'hot-$index', 'pageviews': {'d1': 20}},
      {'id': 'close', 'pageviews': {'d1': 8}},
      {'id': 'far', 'pageviews': {'d1': 1}},
    ];
    final selected = selectByArticleDepth(
      pages,
      ArticleDepth.balanced,
      'en',
      pageviewsOf: (page) => page['pageviews'],
    );

    expect(selected.map((page) => page['id']), contains('close'));
    expect(selected.map((page) => page['id']), isNot(contains('far')));
  });

  testWidgets('depth slider reports the selected stop', (tester) async {
    ArticleDepth? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ArticleDepthControl(
            depth: ArticleDepth.balanced,
            onChanged: (depth) => selected = depth,
          ),
        ),
      ),
    );

    expect(find.text('Article depth'), findsOneWidget);
    expect(find.text('Balanced'), findsOneWidget);
    tester.widget<Slider>(find.byType(Slider)).onChanged!(0);
    expect(selected, ArticleDepth.popular);
  });
}
