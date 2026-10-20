import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/wiki/domain/article_depth.dart';

class AppPreferences {
  AppPreferences(this._preferences);
  final SharedPreferences _preferences;
  ThemeMode readThemeMode() => switch (_preferences.getString('theme_mode')) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
  Future<void> saveThemeMode(ThemeMode mode) =>
      _preferences.setString('theme_mode', mode.name);
  String readLanguageCode() => _preferences.getString('wiki_language') ?? 'zh';
  Future<void> saveLanguageCode(String value) =>
      _preferences.setString('wiki_language', value);
  ArticleDepth readArticleDepth() {
    final stored = _preferences.getString('article_depth');
    if (stored == null) return ArticleDepth.balanced;
    return ArticleDepth.values.asNameMap()[stored] ?? ArticleDepth.balanced;
  }
  Future<void> saveArticleDepth(ArticleDepth depth) =>
      _preferences.setString('article_depth', depth.name);
}
