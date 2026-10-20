import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import '../core/localization/app_language.dart';
import '../features/settings/application/app_settings_controller.dart';
import 'app_router.dart';
import 'app_theme.dart';

class RandomWikiApp extends StatelessWidget {
  const RandomWikiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettingsController>(
      builder: (_, settings, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Random Wiki',
        locale: Locale(settings.languageCode),
        supportedLocales: [
          for (final language in appLanguages) Locale(language.code),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        themeMode: settings.themeMode,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        onGenerateRoute: (route) => AppRouter.generateRoute(route),
        initialRoute: AppRouter.home,
      ),
    );
  }
}
