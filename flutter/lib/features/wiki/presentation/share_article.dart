import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/localization/app_strings.dart';
import '../domain/wiki_article.dart';

String articleShareText(WikiArticle article) =>
    '${article.title}\n${article.pageUrl}';

Future<void> shareArticle(BuildContext context, WikiArticle article) async {
  try {
    await SharePlus.instance.share(
      ShareParams(
        text: articleShareText(article),
        title: article.title,
        subject: article.title,
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).shareFailed)),
      );
  }
}
