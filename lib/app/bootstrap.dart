import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/storage/app_preferences.dart';
import '../features/favorites/data/saved_articles_repository.dart';
import '../features/history/data/history_repository.dart';
import '../features/settings/application/app_settings_controller.dart';
import '../features/wiki/data/wiki_repository.dart';

Future<void> bootstrap(Widget app) async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = AppPreferences(await SharedPreferences.getInstance());
  await Hive.initFlutter();
  final articleCache = await Hive.openBox<dynamic>('article_cache');
  final savedArticles = await Hive.openBox<dynamic>('saved_articles');
  final readingHistory = await Hive.openBox<dynamic>('reading_history');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppSettingsController(preferences),
        ),
        Provider(
          create: (_) => WikiRepository(articleCache),
          dispose: (_, repository) => repository.dispose(),
        ),
        ChangeNotifierProvider(
          create: (_) => SavedArticlesRepository(savedArticles),
        ),
        ChangeNotifierProvider(
          create: (_) => HistoryRepository(readingHistory),
        ),
      ],
      child: app,
    ),
  );
}
