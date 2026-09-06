import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/app_router.dart';
import '../../../core/layout/app_layout.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/widgets/app_circle_icon_button.dart';
import '../../favorites/data/saved_articles_repository.dart';
import '../../favorites/presentation/favorites_screen.dart';
import '../../history/presentation/history_screen.dart';
import '../../settings/application/app_settings_controller.dart';
import '../../wiki/application/wiki_feed_controller.dart';
import '../../wiki/data/wiki_repository.dart';
import '../../wiki/presentation/feed_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  WikiFeedController? _feed;
  AppSettingsController? _settings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_settings != null) return;
    _settings = context.read<AppSettingsController>()
      ..addListener(_onSettingsChanged);
    final feed = WikiFeedController(
      context.read<WikiRepository>(),
      _settings!.languageCode,
    );
    _feed = feed;
    unawaited(feed.start());
  }

  @override
  void dispose() {
    _settings?.removeListener(_onSettingsChanged);
    _feed?.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    final feed = _feed;
    final code = _settings?.languageCode;
    if (feed == null || code == null) return;
    unawaited(feed.changeLanguage(code));
  }

  @override
  Widget build(BuildContext context) {
    final feed = _feed;
    if (feed == null) return const SizedBox.shrink();
    final strings = AppStrings.of(context);
    final titles = [strings.appName, strings.favorites, strings.history];
    return ChangeNotifierProvider.value(
      value: feed,
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          title: Text(titles[_index]),
          actions: [
            if (_index == 0) const _CurrentArticleBookmark(),
            if (_index == 0) const SizedBox(width: 8),
            AppCircleIconButton(
              tooltip: strings.settingsTooltip,
              onPressed: () => Navigator.pushNamed(context, AppRouter.settings),
              icon: const Icon(Icons.tune),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: IndexedStack(
          index: _index,
          children: const [
            FeedScreen(),
            FavoritesScreen(),
            HistoryScreen(),
          ],
        ),
        bottomNavigationBar: _FloatingTabBar(
          selectedIndex: _index,
          onSelected: (index) => setState(() => _index = index),
        ),
      ),
    );
  }
}

class _CurrentArticleBookmark extends StatelessWidget {
  const _CurrentArticleBookmark();

  @override
  Widget build(BuildContext context) {
    final article = context.select(
      (WikiFeedController feed) => feed.currentArticle,
    );
    final saved = context.watch<SavedArticlesRepository>();
    final strings = AppStrings.of(context);
    final isSaved = article != null && saved.contains(article);
    return AppCircleIconButton(
      tooltip: isSaved ? strings.removeCurrent : strings.saveCurrent,
      onPressed: article == null ? null : () => saved.toggle(article),
      icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
    );
  }
}

class _FloatingTabBar extends StatelessWidget {
  const _FloatingTabBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = Theme.of(context).colorScheme;
    final items = [
      (Icons.auto_stories_outlined, strings.appName),
      (Icons.bookmark_border, strings.favoriteTab),
      (Icons.history, strings.history),
    ];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppLayout.floatingBarOuterPadding),
        child: Center(
          heightFactor: 1,
          child: Container(
            height: AppLayout.floatingBarHeight,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.onSurface,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(items.length, (index) {
                final selected = index == selectedIndex;
                final item = items[index];
                return GestureDetector(
                  onTap: () => onSelected(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    width: selected ? 128 : 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selected ? colors.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(21),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.$1,
                          size: 18,
                          color: selected ? colors.onSurface : colors.surface,
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          child: selected
                              ? Padding(
                                  padding: const EdgeInsets.only(left: 5),
                                  child: Text(
                                    item.$2,
                                    style: TextStyle(
                                      color: colors.onSurface,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
