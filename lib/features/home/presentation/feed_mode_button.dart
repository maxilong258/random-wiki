import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../wiki/domain/wiki_feed_mode.dart';

class FeedModeButton extends StatelessWidget {
  const FeedModeButton({
    super.key,
    required this.mode,
    required this.onSelected,
  });

  final WikiFeedMode mode;
  final ValueChanged<WikiFeedMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final titleStyle = Theme.of(context).appBarTheme.titleTextStyle;
    return PopupMenuButton<WikiFeedMode>(
      tooltip: strings.switchFeed,
      padding: EdgeInsets.zero,
      initialValue: mode,
      position: PopupMenuPosition.under,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final item in WikiFeedMode.values)
          CheckedPopupMenuItem(
            value: item,
            checked: item == mode,
            child: Text(_label(strings, item)),
          ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_label(strings, mode), style: titleStyle),
          Icon(Icons.arrow_drop_down, color: titleStyle?.color),
        ],
      ),
    );
  }
}

String _label(AppStrings strings, WikiFeedMode mode) => switch (mode) {
  WikiFeedMode.random => strings.appName,
  WikiFeedMode.onThisDay => strings.onThisDay,
};
