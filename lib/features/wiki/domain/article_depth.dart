import 'dart:math' as math;

enum ArticleDepth { popular, familiar, balanced, niche, obscure }

int depthFetchCount(int count) => (count + 4).clamp(1, 20);

bool articleDepthUsesVitalList(ArticleDepth depth) =>
    depth == ArticleDepth.popular || depth == ArticleDepth.familiar;

const vitalLevel3Page = 'Wikipedia:Vital articles/Level 3';

const vitalLevel4Pages = [
  'Wikipedia:Vital articles/Level 4/Arts',
  'Wikipedia:Vital articles/Level 4/Biology and health sciences',
  'Wikipedia:Vital articles/Level 4/Everyday life',
  'Wikipedia:Vital articles/Level 4/Geography',
  'Wikipedia:Vital articles/Level 4/History',
  'Wikipedia:Vital articles/Level 4/Mathematics',
  'Wikipedia:Vital articles/Level 4/People',
  'Wikipedia:Vital articles/Level 4/Philosophy and religion',
  'Wikipedia:Vital articles/Level 4/Physical sciences',
  'Wikipedia:Vital articles/Level 4/Society and social sciences',
  'Wikipedia:Vital articles/Level 4/Technology',
];

const vitalMinimumCounts = {3: 500, 4: 3000};

double articleDepthViewScale(String languageCode) => switch (languageCode) {
  'zh' => 0.2,
  'ja' => 1,
  'ru' => 0.6,
  'de' => 0.5,
  'he' => 0.4,
  'fr' => 0.3,
  'it' => 0.25,
  'pt' => 0.25,
  'es' => 0.25,
  'pl' => 0.2,
  'ko' => 0.2,
  'hi' => 0.15,
  'ar' => 0.15,
  'nl' => 0.1,
  _ => 1,
};

(double, double) depthDailyViewBand(ArticleDepth depth, String languageCode) {
  final scale = articleDepthViewScale(languageCode);
  final (double low, double high) = switch (depth) {
    ArticleDepth.obscure => (0, 2),
    ArticleDepth.niche => (2, 30),
    ArticleDepth.familiar => (100, 300),
    ArticleDepth.popular => (300, double.infinity),
    ArticleDepth.balanced => (10, double.infinity),
  };
  return (low * scale, high * scale);
}

List<String> knownVitalTitles(List<String> level3, List<String> level4) {
  final essential = level3.toSet();
  return [
    for (final title in level4)
      if (!essential.contains(title)) title,
  ];
}

Set<String> pageviewLagDays(Iterable<Object?> pageviews) {
  final days = <String>{};
  final live = <String>{};
  for (final views in pageviews) {
    if (views is! Map) continue;
    for (final entry in views.entries) {
      final day = entry.key.toString();
      days.add(day);
      final value = entry.value;
      if (value is num && value.isFinite && value >= 0) live.add(day);
    }
  }
  return days.difference(live);
}

double? averageDailyViews(Object? pageviews, Set<String> lagDays) {
  if (pageviews is! Map) return null;
  var sum = 0.0;
  var days = 0;
  var known = false;
  for (final entry in pageviews.entries) {
    if (lagDays.contains(entry.key.toString())) continue;
    final value = entry.value;
    if (value is num && value.isFinite && value >= 0) {
      sum += value;
      days++;
      known = true;
    } else if (value == null) {
      days++;
    }
  }
  if (!known || days == 0) return null;
  return sum / days;
}

List<T> selectByArticleDepth<T>(
  List<T> pages,
  ArticleDepth depth,
  String languageCode, {
  required Object? Function(T page) pageviewsOf,
}) {
  final lag = pageviewLagDays(pages.map(pageviewsOf));
  final known = <({T page, double views})>[];
  for (final page in pages) {
    final views = averageDailyViews(pageviewsOf(page), lag);
    if (views != null) known.add((page: page, views: views));
  }
  if (known.isEmpty) return const [];
  final band = depthDailyViewBand(depth, languageCode);
  final eligible = [
    for (final page in known)
      if (page.views >= band.$1 && page.views <= band.$2) page,
  ];
  if (depth != ArticleDepth.balanced || eligible.length >= 5) {
    return [for (final page in eligible.take(20)) page.page];
  }
  final selected = eligible.map((page) => page.page).toSet();
  final near = known
      .where((page) => !selected.contains(page.page))
      .where((page) => _bandDistance(page.views, band.$1, band.$2) <= math.log(2))
      .toList()
    ..sort(
      (a, b) => _bandDistance(a.views, band.$1, band.$2).compareTo(
        _bandDistance(b.views, band.$1, band.$2),
      ),
    );
  return [
    for (final page in eligible) page.page,
    for (final page in near.take(math.min(3, 5 - eligible.length))) page.page,
  ];
}

double _bandDistance(double views, double low, double high) {
  if (views < low) return _log1p(low) - _log1p(views);
  return _log1p(views) - _log1p(high);
}

double _log1p(double value) => math.log(1 + value);
