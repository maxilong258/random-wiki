import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../history/data/history_repository.dart';
import '../domain/wiki_article.dart';

Future<void> openWikipedia(BuildContext context, WikiArticle article) async {
  unawaited(context.read<HistoryRepository>().record(article));
  final webUri = Uri.parse(article.pageUrl);
  final appUri = webUri.replace(scheme: 'wikipedia');

  if (await _tryLaunch(appUri, LaunchMode.externalApplication)) return;
  if (await _tryLaunch(webUri, LaunchMode.externalNonBrowserApplication)) {
    return;
  }
  await launchUrl(webUri, mode: LaunchMode.externalApplication);
}

Future<bool> _tryLaunch(Uri uri, LaunchMode mode) async {
  try {
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: mode);
  } catch (_) {
    return false;
  }
}
