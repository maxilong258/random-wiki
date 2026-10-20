import 'package:flutter/widgets.dart';

class AppLanguage {
  const AppLanguage(this.code, this.nativeName, {this.rtl = false});

  final String code;
  final String nativeName;
  final bool rtl;

  TextDirection get textDirection =>
      rtl ? TextDirection.rtl : TextDirection.ltr;
}

const appLanguages = [
  AppLanguage('en', 'English'),
  AppLanguage('es', 'Español'),
  AppLanguage('fr', 'Français'),
  AppLanguage('de', 'Deutsch'),
  AppLanguage('it', 'Italiano'),
  AppLanguage('pt', 'Português'),
  AppLanguage('ru', 'Русский'),
  AppLanguage('ja', '日本語'),
  AppLanguage('zh', '中文'),
  AppLanguage('ar', 'العربية', rtl: true),
  AppLanguage('hi', 'हिन्दी'),
  AppLanguage('ko', '한국어'),
  AppLanguage('he', 'עברית', rtl: true),
  AppLanguage('nl', 'Nederlands'),
  AppLanguage('pl', 'Polski'),
];

final appLanguagesByCode = {
  for (final language in appLanguages) language.code: language,
};

const voyageEditions = {
  'en',
  'es',
  'fr',
  'de',
  'it',
  'pt',
  'ru',
  'ja',
  'zh',
  'he',
  'nl',
  'pl',
};

String supportedLanguageCode(String? code) =>
    appLanguagesByCode.containsKey(code) ? code! : 'zh';

String voyageEdition(String languageCode) =>
    voyageEditions.contains(languageCode) ? languageCode : 'en';
