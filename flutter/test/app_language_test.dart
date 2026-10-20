import 'package:flutter_test/flutter_test.dart';
import 'package:random_wiki/core/localization/app_language.dart';
import 'package:random_wiki/core/localization/app_strings.dart';
import 'package:random_wiki/core/localization/app_text.dart';
import 'package:random_wiki/features/wiki/domain/article_depth.dart';

void main() {
  test('offers the same fifteen languages as WikiScroll', () {
    expect(appLanguages.map((language) => language.code), [
      'en',
      'es',
      'fr',
      'de',
      'it',
      'pt',
      'ru',
      'ja',
      'zh',
      'ar',
      'hi',
      'ko',
      'he',
      'nl',
      'pl',
    ]);
    for (final language in appLanguages) {
      expect(appTextFor(language.code).settings, isNotEmpty);
    }
  });

  test('arabic korean and hindi guides fall back to English', () {
    expect(voyageEdition('ar'), 'en');
    expect(voyageEdition('ko'), 'en');
    expect(voyageEdition('hi'), 'en');
    expect(voyageEdition('ja'), 'ja');
    expect(voyageEdition('zh'), 'zh');
  });

  test('each language has its own interface copy', () {
    final japanese = AppStrings.forLanguage('ja');
    expect(japanese.settings, '設定');
    expect(japanese.depthLabel(ArticleDepth.popular), '人気');
    expect(yearsAgoPhrase('zh', 478), '478年前');
    expect(yearsAgoPhrase('en', 250), '250 years ago');
    expect(yearsAgoPhrase('ru', 21), '21 год назад');
    expect(yearsAgoPhrase('pl', 2), '2 lata temu');
  });

  test('an unknown language code stays on Chinese', () {
    expect(supportedLanguageCode(null), 'zh');
    expect(supportedLanguageCode('xx'), 'zh');
    expect(supportedLanguageCode('de'), 'de');
  });
}
