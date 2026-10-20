import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../wiki/domain/wiki_article.dart';

class SavedArticlesRepository extends ChangeNotifier {
  SavedArticlesRepository(this._box) {
    _listenable = _box.listenable();
    _listenable.addListener(notifyListeners);
  }

  final Box<dynamic> _box;
  late final ValueListenable<Box<dynamic>> _listenable;

  bool contains(WikiArticle article) => _box.containsKey(article.storageKey);

  Future<void> toggle(WikiArticle article) => contains(article)
      ? _box.delete(article.storageKey)
      : _box.put(article.storageKey, article.toMap());

  List<WikiArticle> get all => _box.values
      .whereType<Map>()
      .map(WikiArticle.fromMap)
      .toList()
      .reversed
      .toList();

  @override
  void dispose() {
    _listenable.removeListener(notifyListeners);
    super.dispose();
  }
}
