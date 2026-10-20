import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../wiki/domain/article_depth.dart';

class ArticleDepthControl extends StatelessWidget {
  const ArticleDepthControl({
    super.key,
    required this.depth,
    required this.onChanged,
  });

  final ArticleDepth depth;
  final ValueChanged<ArticleDepth> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.explore, style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        Text(
          strings.articleDepth,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          strings.articleDepthHint,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colors.onSurface,
            inactiveTrackColor: colors.outlineVariant,
            thumbColor: colors.onSurface,
            overlayColor: colors.onSurface.withValues(alpha: 0.08),
            trackHeight: 2,
          ),
          child: Slider(
            value: depth.index.toDouble(),
            min: 0,
            max: ArticleDepth.values.length - 1,
            divisions: ArticleDepth.values.length - 1,
            label: strings.depthLabel(depth),
            onChanged: (value) =>
                onChanged(ArticleDepth.values[value.round()]),
          ),
        ),
        Row(
          children: [
            for (final item in ArticleDepth.values)
              Expanded(
                child: Text(
                  strings.depthLabel(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: item == depth
                        ? colors.onSurface
                        : colors.onSurfaceVariant,
                    fontWeight: item == depth
                        ? FontWeight.w800
                        : FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
