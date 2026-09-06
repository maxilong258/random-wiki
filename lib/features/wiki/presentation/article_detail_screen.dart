import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/widgets/app_circle_icon_button.dart';
import '../../favorites/data/saved_articles_repository.dart';
import '../domain/wiki_article.dart';
import 'widgets/article_content.dart';

class ArticleDetailScreen extends StatelessWidget {
  const ArticleDetailScreen({super.key, required this.article});

  final WikiArticle article;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final saved = context.watch<SavedArticlesRepository>();
    final isSaved = saved.contains(article);
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 68,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Align(
            child: AppCircleIconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
        ),
        title: Text(strings.articleDetails),
        actions: [
          AppCircleIconButton(
            tooltip: isSaved ? strings.removeCurrent : strings.saveCurrent,
            onPressed: () => saved.toggle(article),
            icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ArticleContent(article: article),
    );
  }
}
