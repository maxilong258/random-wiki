import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_wiki/features/home/presentation/feed_mode_button.dart';
import 'package:random_wiki/features/wiki/domain/wiki_feed_mode.dart';

void main() {
  testWidgets('title menu switches the home feed', (tester) async {
    WikiFeedMode? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: FeedModeButton(
              mode: WikiFeedMode.random,
              onSelected: (mode) => selected = mode,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Random Wiki'), findsOneWidget);
    await tester.tap(find.byType(PopupMenuButton<WikiFeedMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckedPopupMenuItem<WikiFeedMode>).at(1));
    await tester.pumpAndSettle();

    expect(selected, WikiFeedMode.onThisDay);
  });
}
