import 'package:flutter/material.dart';
import '../../../core/storage/app_preferences.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController(this._preferences)
    : _themeMode = _preferences.readThemeMode(),
      _languageCode = _preferences.readLanguageCode();
  final AppPreferences _preferences;
  ThemeMode _themeMode;
  String _languageCode;
  ThemeMode get themeMode => _themeMode;
  String get languageCode => _languageCode;
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
}
