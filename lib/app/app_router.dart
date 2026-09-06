import 'package:flutter/material.dart';
import '../features/home/presentation/home_shell.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/wiki/domain/wiki_article.dart';
import '../features/wiki/presentation/article_detail_screen.dart';

abstract final class AppRouter {
  static const home = '/';
  static const settings = '/settings';
  static const articleDetail = '/article';

  static Route<void> generateRoute(RouteSettings route) {
    return MaterialPageRoute<void>(
      settings: route,
      builder: (_) => switch (route.name) {
        settings => const SettingsScreen(),
        articleDetail when route.arguments is WikiArticle =>
          ArticleDetailScreen(article: route.arguments! as WikiArticle),
        _ => const HomeShell(),
      },
    );
  }
}
