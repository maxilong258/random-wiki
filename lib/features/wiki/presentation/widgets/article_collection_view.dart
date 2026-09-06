import 'package:flutter/material.dart';
import '../../../../core/layout/app_layout.dart';
import '../../../../core/localization/app_strings.dart';
import '../../domain/wiki_article.dart';
import 'article_list_card.dart';

class ArticleCollectionView extends StatefulWidget {
  const ArticleCollectionView({
    super.key,
    required this.articles,
    required this.emptyText,
    required this.emptyIcon,
    required this.listStorageKey,
    required this.backToTopHeroTag,
    required this.onOpen,
    this.trailingBuilder,
  });

  final List<WikiArticle> articles;
  final String emptyText;
  final IconData emptyIcon;
  final String listStorageKey;
  final String backToTopHeroTag;
  final ValueChanged<WikiArticle> onOpen;
  final Widget Function(BuildContext context, WikiArticle article)?
      trailingBuilder;

  @override
  State<ArticleCollectionView> createState() => _ArticleCollectionViewState();
}

class _ArticleCollectionViewState extends State<ArticleCollectionView> {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateBackToTop);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateBackToTop)
      ..dispose();
    super.dispose();
  }

  void _updateBackToTop() {
    final shouldShow = _scrollController.offset > 360;
    if (shouldShow != _showBackToTop) {
      setState(() => _showBackToTop = shouldShow);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.emptyIcon, size: 48),
            const SizedBox(height: 12),
            Text(widget.emptyText),
          ],
        ),
      );
    }

    final colors = Theme.of(context).colorScheme;
    return Stack(
      children: [
        ListView.separated(
          key: PageStorageKey<String>(widget.listStorageKey),
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            AppLayout.listBottomReserve,
          ),
          itemCount: widget.articles.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, index) {
            final article = widget.articles[index];
            return ArticleListCard(
              article: article,
              onTap: () => widget.onOpen(article),
              trailing: widget.trailingBuilder?.call(context, article),
            );
          },
        ),
        if (_showBackToTop)
          Positioned(
            right: 18,
            bottom: AppLayout.backToTopBottom,
            child: FloatingActionButton.small(
              heroTag: widget.backToTopHeroTag,
              tooltip: AppStrings.of(context).backToTop,
              elevation: 0,
              highlightElevation: 0,
              backgroundColor: colors.onSurface,
              foregroundColor: colors.surface,
              onPressed: () => _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
              ),
              child: const Icon(Icons.arrow_upward),
            ),
          ),
      ],
    );
  }
}
