import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/widgets/app_circle_icon_button.dart';
import '../application/app_settings_controller.dart';
import 'article_depth_control.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsController>();
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 68,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Align(
            child: AppCircleIconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
        ),
        title: Text(strings.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            strings.contentLanguage,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _SettingsDropdown<String>(
            value: settings.languageCode,
            items: [
              for (final language in appLanguages)
                DropdownMenuItem(
                  value: language.code,
                  child: Text(
                    language.nativeName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: settings.setLanguageCode,
          ),
          const SizedBox(height: 28),
          ArticleDepthControl(
            depth: settings.articleDepth,
            onChanged: settings.setArticleDepth,
          ),
          const SizedBox(height: 28),
          Text(
            strings.appearance,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _SettingsDropdown<ThemeMode>(
            value: settings.themeMode,
            items: [
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Text(strings.followSystem),
              ),
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Text(strings.light),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Text(strings.dark),
              ),
            ],
            onChanged: settings.setThemeMode,
          ),
        ],
      ),
    );
  }
}

class _SettingsDropdown<T> extends StatelessWidget {
  const _SettingsDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            borderRadius: BorderRadius.circular(12),
            dropdownColor: colors.surface,
            items: items,
            onChanged: (next) {
              if (next != null) onChanged(next);
            },
          ),
        ),
      ),
    );
  }
}
