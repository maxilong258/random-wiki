import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../../app/app_router.dart';
import '../../history/data/history_repository.dart';
import '../domain/wiki_article.dart';

void openArticle(BuildContext context, WikiArticle article) {
  unawaited(context.read<HistoryRepository>().record(article));
  Navigator.pushNamed(context, AppRouter.articleDetail, arguments: article);
}
