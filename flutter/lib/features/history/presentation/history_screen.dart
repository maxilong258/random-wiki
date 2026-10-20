import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_strings.dart';
import '../../wiki/presentation/open_article.dart';
import '../../wiki/presentation/widgets/article_collection_view.dart';
import '../data/history_repository.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryRepository>();
    return ArticleCollectionView(
      articles: history.all,
      emptyText: AppStrings.of(context).noHistory,
      emptyIcon: Icons.history,
      listStorageKey: 'history_list',
      backToTopHeroTag: 'history_back_to_top',
      onOpen: (article) => openArticle(context, article),
    );
  }
}
