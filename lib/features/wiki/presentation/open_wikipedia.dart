import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_strings.dart';
import '../../history/data/history_repository.dart';
import '../domain/wiki_article.dart';

Future<void> openWikipedia(BuildContext context, WikiArticle article) async {
  unawaited(context.read<HistoryRepository>().record(article));
  final webUri = Uri.parse(article.pageUrl);
  final appUri = webUri.replace(scheme: 'wikipedia');

  if (await _tryLaunch(appUri, LaunchMode.externalApplication)) return;
  if (await _tryLaunch(webUri, LaunchMode.externalApplication)) return;
  if (await _tryLaunch(webUri, LaunchMode.inAppBrowserView)) return;
  if (await _tryLaunch(webUri, LaunchMode.platformDefault)) return;
  if (!context.mounted) return;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(AppStrings.of(context).openLinkFailed)),
    );
}

Future<bool> _tryLaunch(Uri uri, LaunchMode mode) async {
  try {
    return await launchUrl(uri, mode: mode);
  } catch (_) {
    return false;
  }
}
