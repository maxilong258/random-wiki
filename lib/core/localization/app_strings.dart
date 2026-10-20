import 'package:flutter/widgets.dart';
import '../../features/wiki/domain/article_depth.dart';
import 'app_language.dart';
import 'app_text.dart';

class AppStrings {
  const AppStrings.forLanguage(this.languageCode);

  final String languageCode;

  static AppStrings of(BuildContext context) => AppStrings.forLanguage(
    supportedLanguageCode(Localizations.localeOf(context).languageCode),
  );

  AppText get _copy => appTextFor(languageCode);

  String get appName => _copy.appName;
  String get onThisDay => _copy.onThisDay;
  String get wikiGuide => _copy.wikiGuide;
  String get switchFeed => _copy.switchFeed;
  String get favorites => _copy.favorites;
  String get favoriteTab => _copy.favoriteTab;
  String get history => _copy.history;
  String get settings => _copy.settings;
  String get explore => _copy.explore;
  String get articleDepth => _copy.articleDepth;
  String get articleDepthHint => _copy.articleDepthHint;
  String get settingsTooltip => _copy.settings;
  String get saveCurrent => _copy.saveCurrent;
  String get removeCurrent => _copy.removeCurrent;
  String get removeFavoriteTitle => _copy.removeFavoriteTitle;
  String get cancel => _copy.cancel;
  String get confirm => _copy.confirm;
  String get backToTop => _copy.backToTop;
  String get contentLanguage => _copy.contentLanguage;
  String get appearance => _copy.appearance;
  String get followSystem => _copy.followSystem;
  String get light => _copy.light;
  String get dark => _copy.dark;
  String depthLabel(ArticleDepth depth) => switch (depth) {
    ArticleDepth.popular => _copy.popular,
    ArticleDepth.familiar => _copy.familiar,
    ArticleDepth.balanced => _copy.balanced,
    ArticleDepth.niche => _copy.niche,
    ArticleDepth.obscure => _copy.obscure,
  };
  String get noFavorites => _copy.noFavorites;
  String get noHistory => _copy.noHistory;
  String get articleDetails => _copy.articleDetails;
  String get relatedArticles => _copy.relatedArticles;
  String get relatedFailed => _copy.relatedFailed;
  String get loading => _copy.loading;
  String get loadFailed => _copy.loadFailed;
  String get retry => _copy.retry;
  String get more => _copy.more;
  String get share => _copy.share;
  String get shareFailed => _copy.shareFailed;
  String get readOnWikipedia => _copy.readOnWikipedia;
  String get closePreview => _copy.closePreview;
  String get openLinkFailed => _copy.openLinkFailed;
}
