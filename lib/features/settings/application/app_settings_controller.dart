import 'package:flutter/material.dart';
import '../../../core/localization/app_language.dart';
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
    final code = supportedLanguageCode(value);
    if (code == _languageCode) return;
    _languageCode = code;
    notifyListeners();
    await _preferences.saveLanguageCode(code);
  }

  Future<void> setArticleDepth(ArticleDepth value) async {
    if (value == _articleDepth) return;
    _articleDepth = value;
    notifyListeners();
    await _preferences.saveArticleDepth(value);
  }
}
