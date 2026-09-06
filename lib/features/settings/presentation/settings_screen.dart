import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/widgets/app_circle_icon_button.dart';
import '../application/app_settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsController>();
    final strings = AppStrings.of(context);
    final colors = Theme.of(context).colorScheme;
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
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'zh', label: Text('中文')),
              ButtonSegment(value: 'en', label: Text('English')),
            ],
            selected: {settings.languageCode},
            showSelectedIcon: false,
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? colors.onPrimary
                    : colors.onSurface,
              ),
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? colors.primary
                    : colors.surface,
              ),
              side: WidgetStatePropertyAll(
                BorderSide(color: colors.outlineVariant),
              ),
            ),
            onSelectionChanged: (value) =>
                settings.setLanguageCode(value.first),
          ),
          const SizedBox(height: 28),
          Text(
            strings.appearance,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          RadioGroup<ThemeMode>(
            groupValue: settings.themeMode,
            onChanged: (value) {
              if (value != null) settings.setThemeMode(value);
            },
            child: Column(
              children: [
                RadioListTile(
                  value: ThemeMode.system,
                  title: Text(strings.followSystem),
                ),
                RadioListTile(
                  value: ThemeMode.light,
                  title: Text(strings.light),
                ),
                RadioListTile(value: ThemeMode.dark, title: Text(strings.dark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
