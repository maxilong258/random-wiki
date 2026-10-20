import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../data/wiki_repository.dart';
import '../../domain/wiki_article.dart';
import '../open_article.dart';
import 'article_list_card.dart';

class RelatedArticlesSection extends StatefulWidget {
  const RelatedArticlesSection({
    super.key,
    required this.article,
    this.loader,
  });

  final WikiArticle article;
  final Future<List<WikiArticle>> Function(WikiArticle article)? loader;

  @override
  State<RelatedArticlesSection> createState() => _RelatedArticlesSectionState();
}

class _RelatedArticlesSectionState extends State<RelatedArticlesSection> {
  late Future<List<WikiArticle>> _future;
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _future = _fetch();
  }

  @override
  void didUpdateWidget(RelatedArticlesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.article.storageKey != widget.article.storageKey) {
      _future = _fetch();
    }
  }

  Future<List<WikiArticle>> _fetch() {
    final loader = widget.loader;
    if (loader != null) return loader(widget.article);
    return context.read<WikiRepository>().relatedArticles(
      widget.article.languageCode,
      widget.article.title,
    );
  }

  void _retry() => setState(() => _future = _fetch());

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return FutureBuilder<List<WikiArticle>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _RelatedFrame(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snapshot.hasError) {
          return _RelatedFrame(
            child: Row(
              children: [
                Expanded(child: Text(strings.relatedFailed)),
                TextButton(onPressed: _retry, child: Text(strings.retry)),
              ],
            ),
          );
        }
        final articles = snapshot.data ?? const <WikiArticle>[];
        if (articles.isEmpty) return const SizedBox.shrink();
        return _RelatedFrame(
          child: Column(
            children: [
              for (var index = 0; index < articles.length; index++) ...[
                if (index > 0) const SizedBox(height: 10),
                ArticleListCard(
                  article: articles[index],
                  onTap: () => openArticle(context, articles[index]),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RelatedFrame extends StatelessWidget {
  const _RelatedFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.of(context).relatedArticles,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
