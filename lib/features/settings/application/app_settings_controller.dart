import 'package:flutter/material.dart';
import '../../../core/storage/app_preferences.dart';
import '../../wiki/domain/article_depth.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController(this._preferences)
    : _themeMode = _preferences.readThemeMode(),
      _languageCode = _preferences.readLanguageCode(),
      _articleDepth = _preferences.readArticleDepth();
  final AppPreferences _preferences;
  ThemeMode _themeMode;
  String _languageCode;
  ArticleDepth _articleDepth;
  ThemeMode get themeMode => _themeMode;
  String get languageCode => _languageCode;
  ArticleDepth get articleDepth => _articleDepth;
  Future<void> setThemeMode(ThemeMode value) async {
    _themeMode = value;
    notifyListeners();
    await _preferences.saveThemeMode(value);
  }

  Future<void> setLanguageCode(String value) async {
    _languageCode = value;
    notifyListeners();
    await _preferences.saveLanguageCode(value);
  }

  Future<void> setArticleDepth(ArticleDepth value) async {
    if (value == _articleDepth) return;
    _articleDepth = value;
    notifyListeners();
    await _preferences.saveArticleDepth(value);
  }
}
