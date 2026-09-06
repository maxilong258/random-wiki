import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/layout/app_layout.dart';
import '../../../../core/localization/app_strings.dart';
import '../../domain/wiki_article.dart';
import '../open_wikipedia.dart';

class ArticleContent extends StatelessWidget {
  const ArticleContent({
    super.key,
    required this.article,
    this.paged = false,
    this.onOpenDetail,
  });

  final WikiArticle article;
  final bool paged;
  final VoidCallback? onOpenDetail;

  @override
  Widget build(BuildContext context) => paged
      ? _PagedArticle(article: article, onOpenDetail: onOpenDetail)
      : _FullArticle(article: article);
}

class _PagedArticle extends StatelessWidget {
  const _PagedArticle({required this.article, this.onOpenDetail});

  final WikiArticle article;
  final VoidCallback? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        10,
        24,
        AppLayout.pagedBottomReserve,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ArticleHeader(article: article, maxTitleLines: 3),
          const SizedBox(height: 16),
          if (article.thumbnailUrl != null) ...[
            _ArticleImage(article: article, height: 218, useHero: false),
            const SizedBox(height: 18),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _PagedExtract(
                    text: article.extract,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.58,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (onOpenDetail != null) ...[
                      _MoreButton(onPressed: onOpenDetail!),
                      const SizedBox(width: 8),
                    ],
                    Flexible(child: _WikiButton(article: article)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FullArticle extends StatelessWidget {
  const _FullArticle({required this.article});

  final WikiArticle article;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        12,
        24,
        AppLayout.listBottomReserve,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ArticleHeader(article: article, selectable: true),
            const SizedBox(height: 22),
            if (article.thumbnailUrl != null) ...[
              _ArticleImage(article: article, height: 245),
              const SizedBox(height: 24),
            ],
            SelectableText(
              article.extract,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.65,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            _WikiButton(article: article),
          ],
        ),
      ),
    );
  }
}

class _ArticleHeader extends StatelessWidget {
  const _ArticleHeader({
    required this.article,
    this.maxTitleLines,
    this.selectable = false,
  });

  final WikiArticle article;
  final int? maxTitleLines;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.displaySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (article.description != null) ...[
          Text(
            article.description!.toUpperCase(),
            maxLines: maxTitleLines == null ? null : 1,
            overflow: maxTitleLines == null
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              letterSpacing: 0.6,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: selectable ? 10 : 8),
        ],
        if (selectable)
          SelectableText(article.title, style: titleStyle)
        else
          Text(
            article.title,
            maxLines: maxTitleLines,
            overflow: TextOverflow.ellipsis,
            style: titleStyle,
          ),
        SizedBox(height: selectable ? 10 : 8),
        Text(
          'Wikipedia · ${article.languageCode.toUpperCase()}',
          style: theme.textTheme.labelMedium,
        ),
      ],
    );
  }
}

class _ArticleImage extends StatelessWidget {
  const _ArticleImage({
    required this.article,
    required this.height,
    this.useHero = true,
  });

  final WikiArticle article;
  final double height;
  final bool useHero;

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: CachedNetworkImage(
        imageUrl: article.thumbnailUrl!,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) => const SizedBox.shrink(),
      ),
    );
    return GestureDetector(
      onTap: () => _showImagePreview(context, article, useHero: useHero),
      child: useHero ? Hero(tag: article.imageHeroTag, child: image) : image,
    );
  }
}

class _PagedExtract extends StatelessWidget {
  const _PagedExtract({required this.text, required this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final fadeColor = Theme.of(context).colorScheme.surface;
    return LayoutBuilder(
      builder: (context, constraints) {
        final lineHeight = (style?.fontSize ?? 17) * (style?.height ?? 1.58);
        final maxLines = (constraints.maxHeight / lineHeight).floor().clamp(1, 80);
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              SelectableText(
                text,
                maxLines: maxLines,
                scrollPhysics: const NeverScrollableScrollPhysics(),
                style: style,
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: lineHeight * 1.6,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [fadeColor.withValues(alpha: 0), fadeColor],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

void _showImagePreview(
  BuildContext context,
  WikiArticle article, {
  required bool useHero,
}) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    barrierDismissible: true,
    builder: (context) {
      final colors = Theme.of(context).colorScheme;
      final size = MediaQuery.sizeOf(context);
      final image = CachedNetworkImage(
        imageUrl: article.thumbnailUrl!,
        fit: BoxFit.contain,
      );
      return Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(context),
              ),
            ),
            SafeArea(
              child: Align(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: size.width - 40,
                          maxHeight: size.height * 0.72,
                        ),
                        child: InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 4,
                          child: useHero
                              ? Hero(tag: article.imageHeroTag, child: image)
                              : image,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.surface,
                          foregroundColor: colors.onSurface,
                        ),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: Text(AppStrings.of(context).closePreview),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

ButtonStyle _actionButtonStyle(ColorScheme colors) {
  return OutlinedButton.styleFrom(
    foregroundColor: colors.onSurface,
    backgroundColor: colors.surface,
    side: BorderSide(color: colors.outlineVariant),
    shape: const StadiumBorder(),
    padding: const EdgeInsets.fromLTRB(16, 10, 18, 10),
  );
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: _actionButtonStyle(Theme.of(context).colorScheme),
      icon: const Icon(Icons.article_outlined, size: 18),
      label: Text(AppStrings.of(context).more),
    );
  }
}

class _WikiButton extends StatelessWidget {
  const _WikiButton({required this.article});

  final WikiArticle article;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => openWikipedia(context, article),
      style: _actionButtonStyle(Theme.of(context).colorScheme),
      icon: const Icon(Icons.open_in_new, size: 18),
      label: Text(AppStrings.of(context).readOnWikipedia),
    );
  }
}

