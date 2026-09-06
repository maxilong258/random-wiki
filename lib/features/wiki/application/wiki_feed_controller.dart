import 'dart:async';

import 'package:flutter/foundation.dart';
import '../data/wiki_repository.dart';
import '../domain/wiki_article.dart';

class WikiFeedController extends ChangeNotifier {
  WikiFeedController(this._repository, this._languageCode);

  final WikiRepository _repository;
  final List<WikiArticle> _articles = [];
  final Set<String> _seenTitles = {};
  String _languageCode;
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _inFlight = false;
  Object? _error;
  Object? _loadMoreError;
  int _generation = 0;

  List<WikiArticle> get articles => List.unmodifiable(_articles);
  int get currentIndex => _currentIndex;
  WikiArticle? get currentArticle {
    if (_articles.isEmpty) return null;
    return _articles[_currentIndex.clamp(0, _articles.length - 1)];
  }

  bool get isLoading => _isLoading;
  Object? get error => _error;
  Object? get loadMoreError => _loadMoreError;

  Future<void> start() async {
    if (_articles.isNotEmpty) return;
    await _loadNext(count: 6);
  }

  Future<void> changeLanguage(String code) async {
    if (code == _languageCode) return;
    _languageCode = code;
    _generation++;
    _currentIndex = 0;
    _isLoading = true;
    _inFlight = false;
    _error = null;
    _loadMoreError = null;
    _articles.clear();
    _seenTitles.clear();
    notifyListeners();
    await start();
  }

  void setCurrentIndex(int index) {
    if (index == _currentIndex || index < 0 || index >= _articles.length) {
      return;
    }
    _currentIndex = index;
    notifyListeners();
    unawaited(loadMoreIfNeeded(index));
  }

  Future<void> loadMoreIfNeeded(int index) async {
    if (index >= _articles.length - 3) {
      await _loadNext(count: 4);
    }
  }

  Future<void> retry() => _loadNext(count: _articles.isEmpty ? 6 : 4);

  Future<void> _loadNext({int count = 4}) async {
    if (_inFlight) return;
    final generation = _generation;
    _inFlight = true;
    _isLoading = true;
    _error = null;
    _loadMoreError = null;
    try {
      var added = await _appendUnique(count, generation);
      if (generation != _generation) return;
      if (added < count) {
        added += await _appendUnique(count - added, generation);
      }
      if (generation != _generation) return;
      if (added == 0) {
        final failure = Exception('Unable to load Wikipedia articles.');
        if (_articles.isEmpty) {
          _error = failure;
        } else {
          _loadMoreError = failure;
        }
      }
    } catch (error) {
      if (generation != _generation) return;
      if (_articles.isEmpty) {
        _error = error;
      } else {
        _loadMoreError = error;
      }
    } finally {
      if (generation == _generation) {
        _inFlight = false;
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<int> _appendUnique(int count, int generation) async {
    final batch = await _repository.randomArticles(
      _languageCode,
      count: count,
    );
    if (generation != _generation) return 0;
    var added = 0;
    for (final article in batch) {
      if (_seenTitles.add(article.title)) {
        _articles.add(article);
        added++;
      }
    }
    return added;
  }
}
