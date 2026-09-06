import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}
