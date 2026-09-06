import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpenDetail,
      onLongPress: () => _copyArticleText(context, article),
      child: Padding(
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black,
                        Colors.black,
                        Colors.transparent,
                      ],
                      stops: [0, 0.62, 0.94],
                    ).createShader(bounds),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        article.extract,
                        maxLines: 8,
                        overflow: TextOverflow.clip,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.58,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    bottom: 6,
                    child: _WikiButton(article: article),
                  ),
                ],
              ),
            ),
          ],
        ),
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

Future<void> _copyArticleText(BuildContext context, WikiArticle article) async {
  await Clipboard.setData(
    ClipboardData(text: '${article.title}\n\n${article.extract}'),
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(AppStrings.of(context).copied)));
}

void _showImagePreview(
  BuildContext context,
  WikiArticle article, {
  required bool useHero,
}) {
  final image = CachedNetworkImage(imageUrl: article.thumbnailUrl!);
  showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) {
      final colors = Theme.of(context).colorScheme;
      return Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: useHero
                    ? Hero(tag: article.imageHeroTag, child: image)
                    : image,
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.surface,
                      foregroundColor: colors.onSurface,
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: Text(AppStrings.of(context).closePreview),
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

class _WikiButton extends StatelessWidget {
  const _WikiButton({required this.article});

  final WikiArticle article;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: () => openWikipedia(context, article),
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.onSurface,
        side: BorderSide(color: colors.outlineVariant),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.fromLTRB(16, 10, 18, 10),
      ),
      icon: const Icon(Icons.open_in_new, size: 18),
      label: Text(AppStrings.of(context).readOnWikipedia),
    );
  }
}

