import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_strings.dart';
import '../../wiki/domain/wiki_article.dart';
import '../../wiki/presentation/open_article.dart';
import '../../wiki/presentation/widgets/article_collection_view.dart';
import '../data/saved_articles_repository.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<SavedArticlesRepository>();
    final strings = AppStrings.of(context);
    return ArticleCollectionView(
      articles: saved.all,
      emptyText: strings.noFavorites,
      emptyIcon: Icons.bookmark_border,
      listStorageKey: 'favorites_list',
      backToTopHeroTag: 'favorites_back_to_top',
      onOpen: (article) => openArticle(context, article),
      trailingBuilder: (context, article) => IconButton(
        tooltip: strings.removeCurrent,
        onPressed: () => _confirmRemove(context, saved, article),
        icon: const Icon(Icons.bookmark),
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    SavedArticlesRepository saved,
    WikiArticle article,
  ) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.removeFavoriteTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.confirm),
          ),
        ],
      ),
    );
    if (confirmed == true && saved.contains(article)) {
      await saved.toggle(article);
    }
  }
}
