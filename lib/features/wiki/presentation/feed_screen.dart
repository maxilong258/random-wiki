import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/layout/app_layout.dart';
import '../../../core/localization/app_strings.dart';
import '../../history/data/history_repository.dart';
import '../application/wiki_feed_controller.dart';
import '../domain/wiki_article.dart';
import 'open_article.dart';
import 'widgets/article_content.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PageController _pageController = PageController(keepPage: false);
  String? _recordedKey;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _recordVisible(WikiArticle? article) {
    if (article == null || article.storageKey == _recordedKey) return;
    _recordedKey = article.storageKey;
    unawaited(context.read<HistoryRepository>().record(article));
  }

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<WikiFeedController>();
    final articles = feed.articles;
    if (articles.isEmpty) {
      _recordedKey = null;
      return _LoadState(
        loading: feed.isLoading,
        error: feed.error,
        retry: () => unawaited(feed.retry()),
      );
    }

    final current = feed.currentArticle;
    if (current != null && current.storageKey != _recordedKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _recordVisible(feed.currentArticle);
      });
    }

    return Stack(
      children: [
        ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
            },
          ),
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            clipBehavior: Clip.hardEdge,
            itemCount: articles.length,
            onPageChanged: (index) {
              feed.setCurrentIndex(index);
              _recordVisible(feed.articles[index]);
            },
            itemBuilder: (context, index) => ClipRect(
              child: ArticleContent(
                article: articles[index],
                paged: true,
                onOpenDetail: () => openArticle(context, articles[index]),
              ),
            ),
          ),
        ),
        if (feed.loadMoreError != null)
          _LoadMoreBanner(onRetry: () => unawaited(feed.retry())),
      ],
    );
  }
}

class _LoadMoreBanner extends StatelessWidget {
  const _LoadMoreBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          AppLayout.pagedBottomReserve,
        ),
        child: Material(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
            child: Row(
              children: [
                Expanded(child: Text(strings.loadFailed)),
                TextButton(onPressed: onRetry, child: Text(strings.retry)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadState extends StatelessWidget {
  const _LoadState({
    required this.loading,
    required this.retry,
    this.error,
  });

  final bool loading;
  final VoidCallback retry;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Center(
      child: loading
          ? const CircularProgressIndicator()
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error == null ? strings.loading : strings.loadFailed),
                const SizedBox(height: 12),
                FilledButton(onPressed: retry, child: Text(strings.retry)),
              ],
            ),
    );
  }
}
