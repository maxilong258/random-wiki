import 'package:flutter/widgets.dart';

class AppStrings {
  const AppStrings._(this.isChinese);

  final bool isChinese;

  static AppStrings of(BuildContext context) =>
      AppStrings._(Localizations.localeOf(context).languageCode == 'zh');

  String get appName => isChinese ? '随机 Wiki' : 'Random Wiki';
  String get favorites => isChinese ? '收藏列表' : 'Favorites';
  String get favoriteTab => isChinese ? '收藏' : 'Saved';
  String get history => isChinese ? '阅读历史' : 'History';
  String get settings => isChinese ? '语言与外观' : 'Language & appearance';
  String get settingsTooltip => isChinese ? '设置' : 'Settings';
  String get saveCurrent => isChinese ? '收藏当前词条' : 'Save this article';
  String get removeCurrent => isChinese ? '取消收藏' : 'Remove from favorites';
  String get removeFavoriteTitle =>
      isChinese ? '确认取消收藏？' : 'Remove from favorites?';
  String get cancel => isChinese ? '取消' : 'Cancel';
  String get confirm => isChinese ? '确认' : 'Confirm';
  String get backToTop => isChinese ? '返回顶部' : 'Back to top';
  String get contentLanguage =>
      isChinese ? '内容与界面语言' : 'Content & app language';
  String get appearance => isChinese ? '外观' : 'Appearance';
  String get followSystem => isChinese ? '跟随系统' : 'System';
  String get light => isChinese ? '浅色' : 'Light';
  String get dark => isChinese ? '深色' : 'Dark';
  String get noFavorites => isChinese ? '还没有收藏词条' : 'No saved articles yet';
  String get noHistory =>
      isChinese ? '阅读过的词条会出现在这里' : 'Articles you read will appear here';
  String get articleDetails => isChinese ? '词条详情' : 'Article';
  String get loading => isChinese ? '正在加载随机内容' : 'Loading a random article';
  String get loadFailed =>
      isChinese ? '加载失败，请检查网络后重试' : 'Could not load. Check your connection.';
  String get retry => isChinese ? '再试一次' : 'Try again';
  String get readOnWikipedia =>
      isChinese ? '在维基百科中阅读全文' : 'Read the full article on Wikipedia';
  String get closePreview => isChinese ? '关闭预览' : 'Close preview';
}
